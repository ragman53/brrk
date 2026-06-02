//! JSON persistence layer for Brrk.
//!
//! All functions operate relative to the global `DATA_DIR` set by `init_app()`.
//! If the app is not initialized, all functions return `StorageError::NotInitialized`.
//!
//! ## Atomic writes
//! JSON files are written atomically via a temp-file + rename pattern to avoid
//! corruption on crash or power loss: write to `{name}.tmp`, then rename over
//! the target.

use crate::api::app;
use crate::api::models::validate_relative_path;
use crate::{
    CacheRecord, Note, OcrResult, PaperBook, PaperBooksData, PaperPage, PdfDoc, PdfDocsData,
    StorageError,
};
use std::fs::{self, File};
use std::io::{self, BufWriter, Write};
use std::path::Path;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const FILE_PAPER_BOOKS: &str = "paper_books.json";
const FILE_PDF_DOCS: &str = "pdf_docs.json";
const FILE_CACHE_PAPER: &str = "cache_paper.json";
const FILE_CACHE_PDF: &str = "cache_pdf.json";

const SUBDIRS: &[&str] = &["images", "pdfs", "markdowns", "covers"];

/// Subdir for PDF per-doc assets (manual overrides live here).
const PDF_DOC_SUBDIR: &str = "pdf";

/// Maximum length of a manual Markdown override in Unicode characters.
pub(crate) const MAX_MANUAL_MARKDOWN_LEN: usize = 10_000;

/// Serializes JSON read-modify-write operations to prevent lost updates when
/// multiple FRB calls touch the same metadata/cache file concurrently.
static STORAGE_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());

// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------

/// Creates the data directory, subdirectories, and seed JSON files.
/// Idempotent — safe to call multiple times; subsequent calls are no-ops.
pub(crate) fn init_app(data_dir: String) -> Result<(), StorageError> {
    use std::path::Component;

    let abs = std::path::PathBuf::from(&data_dir);
    if !abs.is_absolute() {
        return Err(StorageError::ValidationError(
            "data_dir must be an absolute path".to_string(),
        ));
    }

    // Reject '..' path traversal in data_dir
    for component in abs.components() {
        if let Component::ParentDir = component {
            return Err(StorageError::ValidationError(
                "data_dir must not contain '..' path components".to_string(),
            ));
        }
    }

    // Set DATA_DIR once
    let existing = app::data_dir();
    if let Some(existing_path) = existing {
        if existing_path == abs {
            return Ok(());
        }
        return Err(StorageError::ValidationError(
            "DATA_DIR already initialized to a different path".to_string(),
        ));
    }

    // Create directory structure
    fs::create_dir_all(&abs)
        .map_err(|e| StorageError::IoError(format!("Failed to create data directory: {}", e)))?;

    for subdir in SUBDIRS {
        let sub_path = abs.join(subdir);
        if !sub_path.exists() {
            fs::create_dir_all(&sub_path).map_err(|e| {
                StorageError::IoError(format!("Failed to create {}: {}", subdir, e))
            })?;
        }
    }

    // Seed JSON files if they don't exist
    seed_json_if_absent(&abs, FILE_PAPER_BOOKS, &PaperBooksData::default())?;
    seed_json_if_absent(&abs, FILE_PDF_DOCS, &PdfDocsData::default())?;
    seed_json_if_absent(&abs, FILE_CACHE_PAPER, &CacheIndex::default())?;
    seed_json_if_absent(&abs, FILE_CACHE_PDF, &CacheIndex::default())?;

    let _ = app::set_data_dir(abs);
    Ok(())
}

/// Writes a JSON value to `path` if the file does not already exist.
fn seed_json_if_absent<T: serde::Serialize>(
    base: &Path,
    file_name: &str,
    value: &T,
) -> Result<(), StorageError> {
    let path = base.join(file_name);
    if path.exists() {
        return Ok(());
    }
    write_json_atomic(path, value)
}

// ---------------------------------------------------------------------------
// Atomic JSON helpers
// ---------------------------------------------------------------------------

/// Writes `value` to `path` atomically: writes to a temp file first, then renames.
pub(crate) fn write_json_atomic<T: serde::Serialize>(
    path: std::path::PathBuf,
    value: &T,
) -> Result<(), StorageError> {
    let parent = path.parent().unwrap_or(Path::new("."));
    let tmp_path = parent.join(format!(".{}", path.file_name().unwrap().to_string_lossy()));
    // Ensure parent exists before creating temp file
    if !parent.exists() {
        fs::create_dir_all(parent).map_err(|e| {
            StorageError::IoError(format!("create parent dir {}: {}", parent.display(), e))
        })?;
    }
    let file = File::create(&tmp_path).map_err(|e| {
        StorageError::IoError(format!("create tmp file {}: {}", tmp_path.display(), e))
    })?;
    let mut writer = BufWriter::new(file);
    serde_json::to_writer_pretty(&mut writer, value)
        .map_err(|e| StorageError::JsonError(format!("serialize: {}", e)))?;
    writer
        .flush()
        .map_err(|e| StorageError::IoError(format!("flush: {}", e)))?;
    drop(writer);
    fs::rename(&tmp_path, &path).map_err(|e| {
        StorageError::IoError(format!(
            "atomic rename {} -> {}: {}",
            tmp_path.display(),
            path.display(),
            e
        ))
    })?;
    Ok(())
}

/// Reads a JSON file. Returns `NotFound` if it does not exist.
fn read_json<T: for<'de> serde::Deserialize<'de>>(path: &Path) -> Result<T, StorageError> {
    let content = fs::read_to_string(path).map_err(|e| match e.kind() {
        io::ErrorKind::NotFound => StorageError::NotFound(path.to_string_lossy().to_string()),
        _ => StorageError::IoError(format!("read: {}", e)),
    })?;
    serde_json::from_str(&content).map_err(|e| StorageError::JsonError(format!("parse: {}", e)))
}

/// Atomically reads, applies `f`, and writes back.
fn update_json_file<T, F>(path: std::path::PathBuf, f: F) -> Result<(), StorageError>
where
    for<'de> T: serde::Serialize + serde::Deserialize<'de>,
    F: FnOnce(&mut T) -> Result<(), StorageError>,
{
    let _guard = STORAGE_LOCK
        .lock()
        .map_err(|_| StorageError::IoError("storage lock poisoned".to_string()))?;
    let mut data: T = read_json(&path)?;
    f(&mut data)?;
    write_json_atomic(path, &data)
}

/// Atomically reads (or defaults if missing), applies `f`, and writes back.
///
/// Unlike `update_json_file`, this does not return `NotFound` when the file
/// is missing; instead it starts from `default` and writes the file on first
/// mutation. Used for per-PDF sidecar files that may not exist yet.
fn update_json_file_or_default<T, F>(
    path: std::path::PathBuf,
    default: T,
    f: F,
) -> Result<(), StorageError>
where
    for<'de> T: serde::Serialize + serde::Deserialize<'de>,
    F: FnOnce(&mut T) -> Result<(), StorageError>,
{
    let _guard = STORAGE_LOCK
        .lock()
        .map_err(|_| StorageError::IoError("storage lock poisoned".to_string()))?;
    let mut data: T = if path.exists() {
        read_json(&path)?
    } else {
        default
    };
    f(&mut data)?;
    write_json_atomic(path, &data)
}

// ---------------------------------------------------------------------------
// Paper books
// ---------------------------------------------------------------------------

/// Saves or updates a paper book.
pub(crate) fn save_paper_book(book: PaperBook) -> Result<(), StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PAPER_BOOKS);
    let normalized_title = normalize_book_title(&book.title)?;
    validate_storage_id("book id", &book.id)?;
    if book.created_at.trim().is_empty() {
        return Err(StorageError::ValidationError(
            "created_at must not be empty".to_string(),
        ));
    }
    validate_updated_at(&book.updated_at)?;
    let mut book = book;
    book.title = normalized_title;
    validate_book_paths(&book)?;
    update_json_file(path, |data: &mut PaperBooksData| {
        if let Some(pos) = data.books.iter().position(|b| b.id == book.id) {
            data.books[pos] = book.clone();
        } else {
            data.books.push(book.clone());
        }
        Ok(())
    })
}

/// Returns all paper books.
pub(crate) fn get_paper_books() -> Result<PaperBooksData, StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PAPER_BOOKS);
    read_json(&path)
}

// ---------------------------------------------------------------------------
// PDF documents
// ---------------------------------------------------------------------------

/// Saves or updates a PDF document.
pub(crate) fn save_pdf_doc(doc: PdfDoc) -> Result<(), StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PDF_DOCS);
    validate_relative_path(&doc.pdf_path).map_err(StorageError::ValidationError)?;
    validate_relative_path(&doc.markdown_path).map_err(StorageError::ValidationError)?;
    update_json_file(path, |data: &mut PdfDocsData| {
        if let Some(pos) = data.docs.iter().position(|d| d.id == doc.id) {
            data.docs[pos] = doc.clone();
        } else {
            data.docs.push(doc.clone());
        }
        Ok(())
    })
}

/// Returns all PDF documents.
pub(crate) fn get_pdf_docs() -> Result<PdfDocsData, StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PDF_DOCS);
    read_json(&path)
}

// ---------------------------------------------------------------------------
// PDF deletion
// ---------------------------------------------------------------------------

/// Deletes a PDF document, its file, markdown, and unreferenced cache entry.
pub(crate) fn delete_pdf_doc(doc_id: String) -> Result<(), StorageError> {
    validate_storage_id("doc id", &doc_id)?;
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;

    // Step 1: read to collect deleted hash and file paths
    let (deleted_hash, pdf_path, md_path): (Option<String>, Option<String>, Option<String>) = {
        let path = data_dir.join(FILE_PDF_DOCS);
        let data: PdfDocsData = read_json(&path)?;
        data.docs
            .iter()
            .find(|d| d.id == doc_id)
            .map(|d| {
                (
                    Some(d.ocr_hash.clone()),
                    Some(d.pdf_path.clone()),
                    Some(d.markdown_path.clone()),
                )
            })
            .unwrap_or((None, None, None))
    };
    if deleted_hash.is_none() {
        return Err(StorageError::NotFound(format!(
            "doc_id '{}' not found",
            doc_id
        )));
    }

    // Step 2: remove doc from pdf_docs.json
    {
        let path = data_dir.join(FILE_PDF_DOCS);
        update_json_file(path, |data: &mut PdfDocsData| {
            let initial_len = data.docs.len();
            data.docs.retain(|d| d.id != doc_id);
            if data.docs.len() == initial_len {
                return Err(StorageError::NotFound(format!(
                    "doc_id '{}' not found",
                    doc_id
                )));
            }
            Ok(())
        })?;
    }

    // Step 3: best-effort delete PDF file and markdown file
    if let Some(p) = pdf_path {
        let _ = fs::remove_file(data_dir.join(&p));
    }
    if let Some(m) = md_path {
        let _ = fs::remove_file(data_dir.join(&m));
    }

    // Step 3b: best-effort delete per-PDF manual override file (F16).
    let manual_path = data_dir
        .join(PDF_DOC_SUBDIR)
        .join(&doc_id)
        .join("manual.json");
    let _ = fs::remove_file(manual_path);

    // Step 4: collect surviving PDF doc hashes
    let surviving_hashes: std::collections::HashSet<String> = {
        let path = data_dir.join(FILE_PDF_DOCS);
        let data: PdfDocsData = read_json(&path)?;
        data.docs.iter().map(|d| d.ocr_hash.clone()).collect()
    };

    // Step 5: clean up PDF OCR cache entry if no remaining doc references it
    if let Some(hash) = deleted_hash {
        if !surviving_hashes.contains(&hash) {
            let cache_path = data_dir.join(FILE_CACHE_PDF);
            update_json_file(cache_path, |cache: &mut CacheIndex| {
                cache.remove(&hash);
                Ok(())
            })?;
        }
    }

    Ok(())
}

// ---------------------------------------------------------------------------
// Manual Markdown (F16)
// ---------------------------------------------------------------------------

/// Returns the manual Markdown override for a paper page, or `None`.
fn normalize_manual_markdown(value: Option<String>) -> Option<String> {
    value.and_then(|s| if s.trim().is_empty() { None } else { Some(s) })
}

/// Validates that `text` does not exceed the manual Markdown char limit.
fn validate_manual_markdown_len(text: &str) -> Result<(), StorageError> {
    if text.chars().count() > MAX_MANUAL_MARKDOWN_LEN {
        return Err(StorageError::ValidationError(format!(
            "manual markdown exceeds maximum length of {} characters",
            MAX_MANUAL_MARKDOWN_LEN
        )));
    }
    Ok(())
}

/// Persists a manual Markdown override for one paper page.
///
/// `manual_markdown` semantics:
/// - `None`: clears the override.
/// - `Some(text)`: stored as-is, but only if `text` is non-empty after trim.
///   Whitespace-only input is treated as a clear.
///
/// Errors: `ValidationError` for length / id issues, `NotFound` if the page
/// or book is unknown.
pub(crate) fn save_paper_page_manual_markdown(
    book_id: String,
    page_id: String,
    manual_markdown: Option<String>,
    updated_at: String,
) -> Result<(), StorageError> {
    validate_storage_id("book id", &book_id)?;
    validate_storage_id("page id", &page_id)?;
    validate_updated_at(&updated_at)?;

    let normalized = normalize_manual_markdown(manual_markdown);
    if let Some(ref s) = normalized {
        validate_manual_markdown_len(s)?;
    }

    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PAPER_BOOKS);

    update_json_file(path, |data: &mut PaperBooksData| {
        let book = data
            .books
            .iter_mut()
            .find(|b| b.id == book_id)
            .ok_or_else(|| StorageError::NotFound(format!("book_id '{}' not found", book_id)))?;

        let page = book
            .pages
            .iter_mut()
            .find(|p| p.id == page_id)
            .ok_or_else(|| {
                StorageError::NotFound(format!(
                    "page_id '{}' not found in book '{}'",
                    page_id, book_id
                ))
            })?;

        page.manual_markdown = normalized;
        book.updated_at = updated_at.clone();
        Ok(())
    })
}

/// Returns all manual Markdown overrides for a PDF, or an empty struct if no
/// manual file exists yet.
pub(crate) fn get_pdf_manual_markdown(
    doc_id: String,
) -> Result<crate::PdfManualMarkdownData, StorageError> {
    validate_storage_id("doc id", &doc_id)?;
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir
        .join(PDF_DOC_SUBDIR)
        .join(&doc_id)
        .join("manual.json");
    if !path.exists() {
        return Ok(crate::PdfManualMarkdownData::default());
    }
    let data: crate::PdfManualMarkdownData = read_json(&path)?;
    if data.version != 1 {
        return Err(StorageError::ValidationError(format!(
            "unsupported manual markdown version {}",
            data.version
        )));
    }
    Ok(data)
}

/// Persists (or clears) a manual Markdown override for one PDF page.
///
/// `page_index` is 0-based. `None` or whitespace-only `manual_markdown`
/// removes the override for the page.
///
/// Errors: `ValidationError` for id / index / length issues, `NotFound` if
/// the PDF doc is unknown.
pub(crate) fn save_pdf_page_manual_markdown(
    doc_id: String,
    page_index: i32,
    manual_markdown: Option<String>,
) -> Result<(), StorageError> {
    validate_storage_id("doc id", &doc_id)?;
    if page_index < 0 {
        return Err(StorageError::ValidationError(format!(
            "page_index must be non-negative, got {}",
            page_index
        )));
    }

    let normalized = normalize_manual_markdown(manual_markdown);
    if let Some(ref s) = normalized {
        validate_manual_markdown_len(s)?;
    }

    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;

    // Validate doc exists and page_index is within page_count.
    {
        let docs_path = data_dir.join(FILE_PDF_DOCS);
        let docs: PdfDocsData = read_json(&docs_path)?;
        let doc = docs
            .docs
            .iter()
            .find(|d| d.id == doc_id)
            .ok_or_else(|| StorageError::NotFound(format!("doc_id '{}' not found", doc_id)))?;
        if page_index >= doc.page_count {
            return Err(StorageError::ValidationError(format!(
                "page_index {} out of range (doc has {} pages)",
                page_index, doc.page_count
            )));
        }
    }

    let path = data_dir
        .join(PDF_DOC_SUBDIR)
        .join(&doc_id)
        .join("manual.json");
    let key = page_index.to_string();

    update_json_file_or_default(path, crate::PdfManualMarkdownData::default(), |data| {
        match &normalized {
            Some(text) => {
                data.pages.insert(key.clone(), text.clone());
            }
            None => {
                data.pages.remove(&key);
            }
        }
        Ok(())
    })
}

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

/// Attaches or replaces a note on a specific page.
pub(crate) fn save_note(page_id: String, note: Note) -> Result<(), StorageError> {
    validate_note_for_page(&page_id, &note)?;
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PAPER_BOOKS);
    update_json_file(path, |data: &mut PaperBooksData| {
        for book in &mut data.books {
            if let Some(page) = book.pages.iter_mut().find(|p| p.id == page_id) {
                if let Some(pos) = page.notes.iter().position(|n| n.id == note.id) {
                    page.notes[pos] = note.clone();
                } else {
                    page.notes.push(note.clone());
                }
                return Ok(());
            }
        }
        Err(StorageError::NotFound(format!(
            "page_id '{}' not found in any book",
            page_id
        )))
    })
}

/// Deletes a note from a specific page.
pub(crate) fn delete_note(page_id: String, note_id: String) -> Result<(), StorageError> {
    validate_relative_path(&page_id).map_err(StorageError::ValidationError)?;
    if note_id.trim().is_empty() || note_id.contains('\0') {
        return Err(StorageError::ValidationError(
            "note id is empty or contains null byte".to_string(),
        ));
    }

    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PAPER_BOOKS);
    update_json_file(path, |data: &mut PaperBooksData| {
        for book in &mut data.books {
            if let Some(page) = book.pages.iter_mut().find(|p| p.id == page_id) {
                let original_len = page.notes.len();
                page.notes.retain(|note| note.id != note_id);
                return if page.notes.len() == original_len {
                    Err(StorageError::NotFound(format!(
                        "note_id '{}' not found on page_id '{}'",
                        note_id, page_id
                    )))
                } else {
                    Ok(())
                };
            }
        }
        Err(StorageError::NotFound(format!(
            "page_id '{}' not found in any book",
            page_id
        )))
    })
}

// ---------------------------------------------------------------------------
// PDF markdown
// ---------------------------------------------------------------------------

/// Returns the Markdown content for a PDF document.
pub(crate) fn get_pdf_markdown(doc_id: String) -> Result<String, StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PDF_DOCS);
    let docs: PdfDocsData = read_json(&path)?;
    let doc = docs
        .docs
        .iter()
        .find(|d| d.id == doc_id)
        .ok_or_else(|| StorageError::NotFound(format!("doc_id '{}' not found", doc_id)))?;
    validate_relative_path(&doc.markdown_path).map_err(StorageError::ValidationError)?;
    let md_path = data_dir.join(&doc.markdown_path);
    fs::read_to_string(&md_path).map_err(|e| match e.kind() {
        io::ErrorKind::NotFound => {
            StorageError::NotFound(format!("markdown file not found: {}", doc.markdown_path))
        }
        _ => StorageError::IoError(format!("read markdown: {}", e)),
    })
}

// ---------------------------------------------------------------------------
// OCR cache
// ---------------------------------------------------------------------------

/// Internal cache index — maps sha256 hash to cache record.
type CacheIndex = std::collections::HashMap<String, CacheRecord>;

/// DocType for cache operations.
#[derive(Clone, Copy)]
pub(crate) enum DocType {
    Paper,
    Pdf,
}

/// Looks up a cache entry.
pub(crate) fn cache_lookup(
    doc_type: DocType,
    hash: &str,
) -> Result<Option<CacheRecord>, StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let file = match doc_type {
        DocType::Paper => FILE_CACHE_PAPER,
        DocType::Pdf => FILE_CACHE_PDF,
    };
    let path = data_dir.join(file);
    let index: CacheIndex = read_json(&path)?;
    Ok(index.get(hash).cloned())
}

/// Stores an OCR result in the appropriate cache file.
pub(crate) fn cache_store(
    doc_type: DocType,
    hash: String,
    file_name: String,
    result: OcrResult,
) -> Result<(), StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let file = match doc_type {
        DocType::Paper => FILE_CACHE_PAPER,
        DocType::Pdf => FILE_CACHE_PDF,
    };
    let path = data_dir.join(file);
    let record = CacheRecord {
        file_name,
        created_at: current_timestamp(),
        result,
    };
    update_json_file(path, |index: &mut CacheIndex| {
        index.insert(hash, record);
        Ok(())
    })
}

/// Clears all OCR cache index entries.
/// Returns the number of entries removed from both paper and PDF cache.
pub(crate) fn clear_ocr_cache() -> Result<u32, StorageError> {
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let mut count = 0u32;

    for cache_file in [FILE_CACHE_PAPER, FILE_CACHE_PDF] {
        let path = data_dir.join(cache_file);
        let mut removed = 0u32;
        update_json_file(path, |index: &mut CacheIndex| {
            removed = index.len() as u32;
            index.clear();
            Ok(())
        })?;
        count = count.saturating_add(removed);
    }
    Ok(count)
}

// ---
// Path validation
// ---------------------------------------------------------------------------

pub(crate) fn validate_storage_id(field: &str, id: &str) -> Result<(), StorageError> {
    validate_relative_path(id).map_err(StorageError::ValidationError)?;
    // P1-4: reject multi-segment and cross-platform unsafe separators.
    if id.contains('/') {
        return Err(StorageError::ValidationError(format!(
            "{} must be a single segment",
            field
        )));
    }
    if id.contains('\\') {
        return Err(StorageError::ValidationError(format!(
            "{} contains a backslash — use forward slash or no separators",
            field
        )));
    }
    Ok(())
}

fn validate_book_paths(book: &PaperBook) -> Result<(), StorageError> {
    validate_storage_id("book id", &book.id)?;
    for page in &book.pages {
        validate_storage_id("page id", &page.id)?;
        validate_relative_path(&page.image_path).map_err(StorageError::ValidationError)?;
        for note in &page.notes {
            validate_note_for_page(&page.id, note)?;
        }
    }
    Ok(())
}

fn validate_note_for_page(page_id: &str, note: &Note) -> Result<(), StorageError> {
    validate_storage_id("page id", page_id)?;
    validate_storage_id("note id", &note.id)?;

    if note.id.trim().is_empty() || note.id.contains('\0') {
        return Err(StorageError::ValidationError(
            "note id is empty or contains null byte".to_string(),
        ));
    }

    if note.page_id != page_id {
        return Err(StorageError::ValidationError(format!(
            "note.page_id '{}' does not match target page_id '{}'",
            note.page_id, page_id
        )));
    }

    if note.content.trim().is_empty() {
        return Err(StorageError::ValidationError(
            "note content must not be empty".to_string(),
        ));
    }

    const MAX_NOTE_CONTENT_LEN: usize = 10_000;
    if note.content.chars().count() > MAX_NOTE_CONTENT_LEN {
        return Err(StorageError::ValidationError(
            "note content exceeds maximum length".to_string(),
        ));
    }

    if note.tags.len() > 5 {
        return Err(StorageError::ValidationError(
            "note must not have more than 5 tags".to_string(),
        ));
    }

    match (note.start_offset, note.end_offset) {
        (Some(start), Some(end)) if start < 0 || end < 0 || end < start => {
            return Err(StorageError::ValidationError(
                "note offsets are invalid".to_string(),
            ));
        }
        (Some(_), None) | (None, Some(_)) => {
            return Err(StorageError::ValidationError(
                "note offsets must both be set or both be null".to_string(),
            ));
        }
        _ => {}
    }

    for tag in &note.tags {
        const MAX_TAG_LEN: usize = 50;
        if tag.chars().count() > MAX_TAG_LEN {
            return Err(StorageError::ValidationError(format!(
                "tag '{}' exceeds maximum length of {} characters",
                tag, MAX_TAG_LEN
            )));
        }
        if tag.contains('/') || tag.contains('\\') || tag.contains('\0') {
            return Err(StorageError::ValidationError(format!(
                "tag contains unsafe characters: '{}'",
                tag
            )));
        }
    }

    Ok(())
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

/// Normalizes a page label: trims whitespace, returns None for empty.
pub(crate) fn normalize_page_label(label: Option<&str>) -> Option<String> {
    match label {
        None => None,
        Some(s) => {
            let trimmed = s.trim();
            if trimmed.is_empty() {
                None
            } else {
                Some(trimmed.to_string())
            }
        }
    }
}

/// Validates a page label: None is valid; Some must be ≤32 chars after trim.
pub(crate) fn validate_page_label(label: Option<&str>) -> Result<(), StorageError> {
    if let Some(s) = label {
        let trimmed = s.trim();
        let count = trimmed.chars().count();
        if count > 32 {
            return Err(StorageError::ValidationError(format!(
                "page_label exceeds 32 characters (got {} chars)",
                count
            )));
        }
    }
    Ok(())
}

/// Normalizes and validates a page label.
pub(crate) fn normalize_and_validate_page_label(
    label: Option<&str>,
) -> Result<Option<String>, StorageError> {
    let normalized = normalize_page_label(label);
    validate_page_label(normalized.as_deref())?;
    Ok(normalized)
}

/// Normalizes and validates a book title: trim, reject empty, reject >120 chars.
pub(crate) fn normalize_book_title(title: &str) -> Result<String, StorageError> {
    let trimmed = title.trim();
    if trimmed.is_empty() {
        return Err(StorageError::ValidationError(
            "book title must not be empty after trimming".to_string(),
        ));
    }
    let count = trimmed.chars().count();
    if count > 120 {
        return Err(StorageError::ValidationError(format!(
            "book title exceeds 120 characters (got {} chars)",
            count
        )));
    }
    Ok(trimmed.to_string())
}

/// Validates that updated_at is non-empty.
pub(crate) fn validate_updated_at(ts: &str) -> Result<(), StorageError> {
    if ts.trim().is_empty() {
        return Err(StorageError::ValidationError(
            "updated_at must not be empty".to_string(),
        ));
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// Paper book deletion
// ---------------------------------------------------------------------------

/// Deletes a paper book by ID, including its image directory.
/// Removes unreferenced paper OCR cache entries.
pub(crate) fn delete_paper_book(book_id: String) -> Result<(), StorageError> {
    validate_storage_id("book id", &book_id)?;
    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;

    // Step 1: collect deleted page hashes
    let deleted_hashes: Vec<String> = {
        let path = data_dir.join(FILE_PAPER_BOOKS);
        let data: PaperBooksData = read_json(&path)?;
        data.books
            .iter()
            .find(|b| b.id == book_id)
            .map(|b| b.pages.iter().map(|p| p.ocr_hash.clone()).collect())
            .unwrap_or_default()
    };

    // Step 2: remove book from JSON
    {
        let path = data_dir.join(FILE_PAPER_BOOKS);
        update_json_file(path, |data: &mut PaperBooksData| {
            let initial_len = data.books.len();
            data.books.retain(|b| b.id != book_id);
            if data.books.len() == initial_len {
                return Err(StorageError::NotFound(format!(
                    "book_id '{}' not found",
                    book_id
                )));
            }
            Ok(())
        })?;
    }

    // Step 3: best-effort delete images/{book_id}/
    {
        let images_dir = data_dir.join("images").join(&book_id);
        let _ = fs::remove_dir_all(images_dir);
    }

    // Step 4: collect surviving hashes from all remaining books
    let surviving_hashes: std::collections::HashSet<String> = {
        let path = data_dir.join(FILE_PAPER_BOOKS);
        let data: PaperBooksData = read_json(&path)?;
        data.books
            .iter()
            .flat_map(|b| b.pages.iter().map(|p| p.ocr_hash.clone()))
            .collect()
    };

    // Step 5: clean up cache entries for hashes no longer referenced
    if !deleted_hashes.is_empty() {
        let deleted_hashes: std::collections::HashSet<String> =
            deleted_hashes.into_iter().collect();
        let cache_path = data_dir.join(FILE_CACHE_PAPER);
        update_json_file(cache_path, |cache: &mut CacheIndex| {
            cache.retain(|hash, _| {
                !deleted_hashes.contains(hash) || surviving_hashes.contains(hash)
            });
            Ok(())
        })?;
    }

    Ok(())
}

// ---------------------------------------------------------------------------
// Paper page upsert
// ---------------------------------------------------------------------------

/// Inserts or replaces a page in a paper book, then saves the book.
/// Returns NotFound if the book does not exist; ValidationError for bad input.
pub(crate) fn upsert_paper_page(
    book_id: String,
    mut page: PaperPage,
    updated_at: String,
) -> Result<(), StorageError> {
    // Validate inputs
    validate_storage_id("book id", &book_id)?;
    validate_storage_id("page id", &page.id)?;
    validate_updated_at(&updated_at)?;
    normalize_and_validate_page_label(page.page_label.as_deref())?;
    validate_relative_path(&page.image_path).map_err(StorageError::ValidationError)?;

    // Normalize the page label
    page.page_label = normalize_page_label(page.page_label.as_deref());

    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PAPER_BOOKS);

    update_json_file(path, |data: &mut PaperBooksData| {
        let book = data
            .books
            .iter_mut()
            .find(|b| b.id == book_id)
            .ok_or_else(|| StorageError::NotFound(format!("book_id '{}' not found", book_id)))?;

        if let Some(pos) = book.pages.iter().position(|p| p.id == page.id) {
            book.pages[pos] = page;
        } else {
            book.pages.push(page);
        }

        book.updated_at = updated_at;
        Ok(())
    })
}

// ---------------------------------------------------------------------------
// Paper page deletion
// ---------------------------------------------------------------------------

/// Deletes a page from a paper book, including its image and embedded notes.
/// Removes unreferenced paper OCR cache entry.
pub(crate) fn delete_paper_page(
    book_id: String,
    page_id: String,
    updated_at: String,
) -> Result<(), StorageError> {
    validate_storage_id("book id", &book_id)?;
    validate_storage_id("page id", &page_id)?;
    validate_updated_at(&updated_at)?;

    let data_dir = app::data_dir().ok_or(StorageError::NotInitialized)?;
    let path = data_dir.join(FILE_PAPER_BOOKS);

    // Step 1: find page and collect its hash
    let deleted_hash: Option<String> = {
        let data: PaperBooksData = read_json(&path)?;
        data.books
            .iter()
            .find(|b| b.id == book_id)
            .and_then(|b| b.pages.iter().find(|p| p.id == page_id))
            .map(|p| p.ocr_hash.clone())
    };

    let deleted_hash = deleted_hash.ok_or_else(|| {
        StorageError::NotFound(format!(
            "page_id '{}' not found in book '{}'",
            page_id, book_id
        ))
    })?;

    // Step 2: remove page from book, update updated_at
    {
        update_json_file(path, |data: &mut PaperBooksData| {
            let book = data
                .books
                .iter_mut()
                .find(|b| b.id == book_id)
                .ok_or_else(|| {
                    StorageError::NotFound(format!("book_id '{}' not found", book_id))
                })?;

            let original_len = book.pages.len();
            book.pages.retain(|p| p.id != page_id);
            if book.pages.len() == original_len {
                return Err(StorageError::NotFound(format!(
                    "page_id '{}' not found in book '{}'",
                    page_id, book_id
                )));
            }

            book.updated_at = updated_at.clone();
            Ok(())
        })?;
    }

    // Step 3: best-effort delete page image
    {
        let img_path = data_dir
            .join("images")
            .join(&book_id)
            .join(format!("{}.jpg", page_id));
        let _ = fs::remove_file(img_path);
    }

    // Step 4: collect surviving hashes; remove unreferenced cache entry
    let surviving_hashes: std::collections::HashSet<String> = {
        let data: PaperBooksData = read_json(&data_dir.join(FILE_PAPER_BOOKS))?;
        data.books
            .iter()
            .flat_map(|b| b.pages.iter().map(|p| p.ocr_hash.clone()))
            .collect()
    };

    if !surviving_hashes.contains(&deleted_hash) {
        let cache_path = data_dir.join(FILE_CACHE_PAPER);
        update_json_file(cache_path, |cache: &mut CacheIndex| {
            cache.remove(&deleted_hash);
            Ok(())
        })?;
    }

    Ok(())
}

// ---------------------------------------------------------------------------
// Timestamp helper
// ---------------------------------------------------------------------------

fn current_timestamp() -> String {
    // Get seconds since Unix epoch
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default();
    let secs = now.as_secs();

    // Convert to UTC date/time components
    let days = secs / 86400;
    let rem = secs % 86400;
    let hours = rem / 3600;
    let mins = (rem % 3600) / 60;
    let seconds = rem % 60;

    // Add days to Unix epoch: 1970-01-01
    // Calculate year by iterating from 1970
    let mut year: u64 = 1970;
    let mut remaining_days = days;

    loop {
        let days_in_year = if is_leap_year(year) { 366 } else { 365 };
        if remaining_days < days_in_year {
            break;
        }
        remaining_days -= days_in_year;
        year += 1;
    }

    // Find month in the remaining days
    let mut month: u64 = 1;
    for &days_in_month in MONTH_DAYS.iter() {
        let dim = days_in_month as u64
            + if month == 2 && is_leap_year(year) {
                1
            } else {
                0
            };
        if remaining_days < dim {
            break;
        }
        remaining_days -= dim;
        month += 1;
    }

    let day = remaining_days + 1;

    format!(
        "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}Z",
        year, month, day, hours, mins, seconds
    )
}

fn is_leap_year(year: u64) -> bool {
    year.is_multiple_of(4) && (!year.is_multiple_of(100) || year.is_multiple_of(400))
}

const MONTH_DAYS: &[i32; 12] = &[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
// ---------------------------------------------------------------------------
// Integration tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use std::fs;
    use std::path::PathBuf;

    fn temp_dir() -> PathBuf {
        use std::time::{SystemTime, UNIX_EPOCH};
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        std::env::temp_dir().join(format!("brrk_test_{}", ts))
    }

    fn setup(dir: &PathBuf) {
        // Run teardown first to clean up any stale state from previous tests.
        // This runs before every test so we start clean.
        teardown(dir);
        fs::create_dir_all(dir).unwrap();
        // Reset the global data dir so this test starts uninitialized.
        // Each test's with_init() will call init_app().
        crate::api::app::reset_for_test();
    }

    fn teardown(dir: &PathBuf) {
        let _ = fs::remove_dir_all(dir);
    }

    // -- init_app --

    #[test]
    fn init_app_creates_subdirectories() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        let result = init_app(dir.to_string_lossy().to_string());
        assert!(result.is_ok(), "init_app failed: {:?}", result);
        for subdir in &["images", "pdfs", "markdowns", "covers"] {
            assert!(dir.join(subdir).is_dir(), "{} should exist", subdir);
        }
        teardown(&dir);
    }

    #[test]
    fn init_app_idempotent() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        let r1 = init_app(dir.to_string_lossy().to_string());
        assert!(r1.is_ok(), "first init_app failed: {:?}", r1);
        let r2 = init_app(dir.to_string_lossy().to_string());
        assert!(r2.is_ok(), "second init_app failed: {:?}", r2);
        teardown(&dir);
    }

    #[test]
    fn init_app_rejects_different_path_after_initialization() {
        use super::*;
        let dir1 = temp_dir();
        let dir2 = dir1.with_file_name(format!(
            "{}_other",
            dir1.file_name().unwrap().to_string_lossy()
        ));
        setup(&dir1);
        fs::create_dir_all(&dir2).unwrap();
        init_app(dir1.to_string_lossy().to_string()).unwrap();
        let result = init_app(dir2.to_string_lossy().to_string());
        assert!(matches!(result, Err(StorageError::ValidationError(_))));
        teardown(&dir1);
        teardown(&dir2);
        crate::api::app::reset_for_test();
    }

    #[test]
    fn init_app_rejects_relative_path() {
        use super::*;
        let result = init_app("relative/path".to_string());
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(err.to_string().contains("absolute"));
    }

    #[test]
    fn init_app_rejects_parent_traversal_in_data_dir() {
        use super::*;
        let result = init_app("/tmp/../../../dangerous".to_string());
        assert!(result.is_err());
    }

    #[test]
    fn init_app_seeds_json_files() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        init_app(dir.to_string_lossy().to_string()).unwrap();
        for file in &[
            "paper_books.json",
            "pdf_docs.json",
            "cache_paper.json",
            "cache_pdf.json",
        ] {
            let path = dir.join(file);
            assert!(path.is_file(), "{} should exist", file);
            let content = fs::read_to_string(&path).unwrap();
            let json: serde_json::Value = serde_json::from_str(&content)
                .unwrap_or_else(|_| panic!("{} should be valid JSON", file));
            if *file == "paper_books.json" || *file == "pdf_docs.json" {
                assert_eq!(
                    json["version"], 1,
                    "{} should start at schema version 1",
                    file
                );
            }
        }
        teardown(&dir);
    }

    // -- paper books --

    fn with_init<F>(dir: &PathBuf, f: F)
    where
        F: Fn(),
    {
        use super::*;
        init_app(dir.to_string_lossy().to_string()).unwrap();
        f();
    }

    #[test]
    fn save_and_get_paper_book() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Test Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![],
            };
            save_paper_book(book.clone()).unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(data.books.len(), 1);
            assert_eq!(data.books[0].id, "book-1");
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_book_replaces_existing() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book1 = PaperBook {
                id: "book-1".into(),
                title: "Version 1".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![],
            };
            let book2 = PaperBook {
                id: "book-1".into(),
                title: "Version 2".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:01Z".into(),
                pages: vec![],
            };
            save_paper_book(book1).unwrap();
            save_paper_book(book2).unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(data.books.len(), 1);
            assert_eq!(data.books[0].title, "Version 2");
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_book_rejects_path_traversal() {
        use super::*;
        use crate::PaperPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let bad_book = PaperBook {
                id: "book-1".into(),
                title: "Bad Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "../etc/passwd".into(),
                    ocr_hash: "sha256:abc".into(),
                    markdown: "".into(),
                    manual_markdown: None,
                    notes: vec![],
                    page_label: None,
                }],
            };
            let result = save_paper_book(bad_book);
            assert!(result.is_err());
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_book_rejects_path_traversal_ids() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let bad_book = PaperBook {
                id: "../bad".into(),
                title: "Bad Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![],
            };
            assert!(matches!(
                save_paper_book(bad_book),
                Err(StorageError::ValidationError(_))
            ));
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_book_rejects_empty_timestamps() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let bad_book = PaperBook {
                id: "book-1".into(),
                title: "Bad Book".into(),
                created_at: "".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![],
            };
            assert!(matches!(
                save_paper_book(bad_book),
                Err(StorageError::ValidationError(_))
            ));
        });
        teardown(&dir);
    }

    #[test]
    fn get_paper_books_when_empty() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let data = get_paper_books().unwrap();
            assert!(data.books.is_empty());
        });
        teardown(&dir);
    }

    // -- PDF docs --

    #[test]
    fn save_and_get_pdf_doc() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let doc = PdfDoc {
                id: "doc-1".into(),
                title: "Test PDF".into(),
                original_file_name: "source.pdf".into(),
                pdf_path: "pdfs/doc-1.pdf".into(),
                markdown_path: "markdowns/doc-1.md".into(),
                ocr_hash: "sha256:def".into(),
                page_count: 5,
                last_read_page_index: 0,
                tags: vec![],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            save_pdf_doc(doc.clone()).unwrap();
            let data = get_pdf_docs().unwrap();
            assert_eq!(data.docs.len(), 1);
            assert_eq!(data.docs[0].id, "doc-1");
            assert_eq!(data.docs[0].page_count, 5);
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_doc_rejects_bad_markdown_path() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let bad_doc = PdfDoc {
                id: "doc-1".into(),
                title: "Bad PDF".into(),
                original_file_name: "source.pdf".into(),
                pdf_path: "pdfs/doc-1.pdf".into(),
                markdown_path: "../etc/passwd.md".into(),
                ocr_hash: "sha256:def".into(),
                page_count: 5,
                last_read_page_index: 0,
                tags: vec![],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            let result = save_pdf_doc(bad_doc);
            assert!(result.is_err());
        });
        teardown(&dir);
    }

    // -- Notes --

    #[test]
    fn save_and_get_note() {
        use super::*;
        use crate::{Note, PaperBook, PaperPage};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    ocr_hash: "sha256:abc".into(),
                    markdown: "# Hello".into(),
                    manual_markdown: None,
                    notes: vec![],
                    page_label: None,
                }],
            };
            save_paper_book(book).unwrap();
            let note = Note {
                id: "note-1".into(),
                page_id: "page-1".into(),
                selected_text: "Hello world".into(),
                start_offset: Some(0),
                end_offset: Some(11),
                content: "My note".into(),
                tags: vec!["important".into()],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            save_note("page-1".into(), note).unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages[0].notes.len(), 1);
            assert_eq!(data.books[0].pages[0].notes[0].content, "My note");
        });
        teardown(&dir);
    }

    #[test]
    fn delete_note_removes_existing_note() {
        use super::*;
        use crate::{Note, PaperBook, PaperPage};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    ocr_hash: "sha256:abc".into(),
                    markdown: "# Hello".into(),
                    manual_markdown: None,
                    notes: vec![Note {
                        id: "note-1".into(),
                        page_id: "page-1".into(),
                        selected_text: "Hello".into(),
                        start_offset: Some(0),
                        end_offset: Some(5),
                        content: "My note".into(),
                        tags: vec![],
                        created_at: "2026-05-20T00:00:00Z".into(),
                        updated_at: "2026-05-20T00:00:00Z".into(),
                    }],
                    page_label: None,
                }],
            };
            save_paper_book(book).unwrap();
            delete_note("page-1".into(), "note-1".into()).unwrap();
            let data = get_paper_books().unwrap();
            assert!(data.books[0].pages[0].notes.is_empty());
        });
        teardown(&dir);
    }

    #[test]
    fn save_note_not_found_for_nonexistent_page() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let note = Note {
                id: "note-1".into(),
                page_id: "nonexistent-page".into(),
                selected_text: "".into(),
                start_offset: Some(0),
                end_offset: Some(0),
                content: "My note".into(),
                tags: vec![],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            let result = save_note("nonexistent-page".into(), note);
            assert!(result.is_err());
        });
        teardown(&dir);
    }

    #[test]
    fn save_note_rejects_mismatched_page_id() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let note = Note {
                id: "note-1".into(),
                page_id: "other-page".into(),
                selected_text: "Hello".into(),
                start_offset: Some(0),
                end_offset: Some(5),
                content: "My note".into(),
                tags: vec![],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            let result = save_note("page-1".into(), note);
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn save_note_rejects_note_content_exceeding_max_length() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let long_content = "x".repeat(10_001);
            let note = Note {
                id: "note-long".into(),
                page_id: "page-1".into(),
                selected_text: "".into(),
                start_offset: None,
                end_offset: None,
                content: long_content,
                tags: vec![],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            let result = save_note("page-1".into(), note);
            match result {
                Err(StorageError::ValidationError(msg)) => {
                    assert!(
                        msg.contains("maximum length"),
                        "expected 'maximum length' in error, got: {}",
                        msg
                    )
                }
                other => panic!("expected ValidationError, got: {:?}", other),
            }
        });
        teardown(&dir);
    }

    #[test]
    fn save_note_accepts_note_content_at_max_length() {
        use super::*;
        use crate::{PaperBook, PaperPage};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            // Create a book and page first so the note has a valid target.
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    ocr_hash: "sha256:abc".into(),
                    markdown: "# Test".into(),
                    manual_markdown: None,
                    notes: vec![],
                    page_label: None,
                }],
            };
            save_paper_book(book).unwrap();

            // Exactly 9_999 chars (one below max) — should be accepted
            let under_max = "x".repeat(9_999);
            let note = Note {
                id: "note-max".into(),
                page_id: "page-1".into(),
                selected_text: "".into(),
                start_offset: None,
                end_offset: None,
                content: under_max,
                tags: vec![],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            let result = save_note("page-1".into(), note);
            assert!(
                result.is_ok(),
                "note with 9_999 chars should be accepted, got: {:?}",
                result
            );
        });
        teardown(&dir);
    }

    #[test]
    fn save_note_rejects_tag_exceeding_max_length() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let long_tag = "x".repeat(51);
            let note = Note {
                id: "note-longtag".into(),
                page_id: "page-1".into(),
                selected_text: "".into(),
                start_offset: None,
                end_offset: None,
                content: "valid note".into(),
                tags: vec![long_tag],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            let result = save_note("page-1".into(), note);
            match result {
                Err(StorageError::ValidationError(msg)) => {
                    assert!(
                        msg.contains("maximum length"),
                        "expected 'maximum length' in error, got: {}",
                        msg
                    )
                }
                other => panic!("expected ValidationError, got: {:?}", other),
            }
        });
        teardown(&dir);
    }

    #[test]
    fn save_note_accepts_tag_at_max_length() {
        use super::*;
        use crate::{PaperBook, PaperPage};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            // Create a book and page first so the note has a valid target.
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    ocr_hash: "sha256:abc".into(),
                    markdown: "# Test".into(),
                    manual_markdown: None,
                    notes: vec![],
                    page_label: None,
                }],
            };
            save_paper_book(book).unwrap();

            // Exactly 49 chars (one below max) — should be accepted
            let under_max = "x".repeat(49);
            let note = Note {
                id: "note-maxtag".into(),
                page_id: "page-1".into(),
                selected_text: "".into(),
                start_offset: None,
                end_offset: None,
                content: "valid note".into(),
                tags: vec![under_max],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            let result = save_note("page-1".into(), note);
            assert!(
                result.is_ok(),
                "tag with 49 chars should be accepted, got: {:?}",
                result
            );
        });
        teardown(&dir);
    }

    // -- PDF markdown --

    #[test]
    fn get_pdf_markdown_not_found() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let result = get_pdf_markdown("nonexistent".into());
            assert!(result.is_err());
        });
        teardown(&dir);
    }

    #[test]
    fn get_pdf_markdown_returns_file_content() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let doc = PdfDoc {
                id: "doc-1".into(),
                title: "Test PDF".into(),
                original_file_name: "source.pdf".into(),
                pdf_path: "pdfs/doc-1.pdf".into(),
                markdown_path: "markdowns/doc-1.md".into(),
                ocr_hash: "sha256:def".into(),
                page_count: 1,
                last_read_page_index: 0,
                tags: vec![],
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
            };
            save_pdf_doc(doc).unwrap();
            let md_content = "# OCR Result\n\nExtracted text here.";
            fs::write(dir.join("markdowns/doc-1.md"), md_content).unwrap();
            let content = get_pdf_markdown("doc-1".into()).unwrap();
            assert_eq!(content, md_content);
        });
        teardown(&dir);
    }

    // -- Cache --

    #[test]
    fn cache_lookup_miss() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let result = cache_lookup(DocType::Paper, "nonexistent_hash");
            assert!(result.unwrap().is_none());
        });
        teardown(&dir);
    }

    #[test]
    fn cache_store_and_lookup_hit() {
        use super::*;
        use crate::OcrPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let ocr_result = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "# Test".into(),
                }],
                source_hash: "sha256:test123".into(),
                cache_hit: false,
            };
            cache_store(
                DocType::Paper,
                "sha256:test123".into(),
                "test.jpg".into(),
                ocr_result,
            )
            .unwrap();
            let record = cache_lookup(DocType::Paper, "sha256:test123").unwrap();
            assert!(record.is_some());
            let rec = record.unwrap();
            assert_eq!(rec.file_name, "test.jpg");
            assert_eq!(rec.result.pages[0].markdown, "# Test");
        });
        teardown(&dir);
    }

    #[test]
    fn clear_ocr_cache_removes_paper_and_pdf_entries() {
        use super::*;
        use crate::OcrPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let paper_result = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "# Paper".into(),
                }],
                source_hash: "sha256:paper".into(),
                cache_hit: false,
            };
            let pdf_result = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "# PDF".into(),
                }],
                source_hash: "sha256:pdf".into(),
                cache_hit: false,
            };
            cache_store(
                DocType::Paper,
                "sha256:paper".into(),
                "paper.jpg".into(),
                paper_result,
            )
            .unwrap();
            cache_store(
                DocType::Pdf,
                "sha256:pdf".into(),
                "pdf.pdf".into(),
                pdf_result,
            )
            .unwrap();

            assert_eq!(clear_ocr_cache().unwrap(), 2);
            assert!(cache_lookup(DocType::Paper, "sha256:paper")
                .unwrap()
                .is_none());
            assert!(cache_lookup(DocType::Pdf, "sha256:pdf").unwrap().is_none());
        });
        teardown(&dir);
    }

    #[test]
    fn clear_ocr_cache_returns_error_for_corrupt_cache_file() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            fs::write(dir.join(FILE_CACHE_PAPER), "not json").unwrap();
            let result = clear_ocr_cache();
            assert!(matches!(result, Err(StorageError::JsonError(_))));
        });
        teardown(&dir);
    }

    // -- Atomic write --

    #[test]
    fn atomic_write_creates_valid_json() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        let path = dir.join("atomic_test.json");
        let data = PaperBooksData::default();
        write_json_atomic(path.clone(), &data).unwrap();
        assert!(path.is_file());
        let content = fs::read_to_string(&path).unwrap();
        assert!(content.contains("books"));
        assert!(serde_json::from_str::<PaperBooksData>(&content).is_ok());
        teardown(&dir);
    }

    // -- page_label validation --

    #[test]
    fn page_label_normalizes_trims_whitespace() {
        use super::*;
        assert_eq!(normalize_page_label(Some("  42  ")), Some("42".into()));
        assert_eq!(normalize_page_label(Some("\txii\t")), Some("xii".into()));
        assert_eq!(
            normalize_page_label(Some("no trim")),
            Some("no trim".into())
        );
        assert_eq!(normalize_page_label(None), None);
    }

    #[test]
    fn page_label_empty_becomes_none() {
        use super::*;
        assert_eq!(normalize_page_label(Some("")), None);
        assert_eq!(normalize_page_label(Some("   ")), None);
        assert_eq!(normalize_page_label(Some("\t\t")), None);
    }

    #[test]
    fn page_label_rejects_over_32_chars() {
        use super::*;
        let long = "a".repeat(33);
        let result = validate_page_label(Some(&long));
        assert!(matches!(result, Err(StorageError::ValidationError(_))));
        // 32 chars is fine
        let ok = "a".repeat(32);
        assert!(validate_page_label(Some(&ok)).is_ok());
    }

    #[test]
    fn page_label_accepts_32_char_boundary() {
        use super::*;
        let max = "a".repeat(32);
        assert!(validate_page_label(Some(&max)).is_ok());
        assert!(normalize_and_validate_page_label(Some(&max)).is_ok());
    }

    #[test]
    fn page_label_limit_counts_chars_not_bytes() {
        use super::*;
        let max = "あ".repeat(32);
        assert!(validate_page_label(Some(&max)).is_ok());
        let too_long = "あ".repeat(33);
        assert!(matches!(
            validate_page_label(Some(&too_long)),
            Err(StorageError::ValidationError(_))
        ));
    }

    // -- book title validation --

    #[test]
    fn book_title_trims_and_rejects_empty() {
        use super::*;
        assert!(normalize_book_title("").is_err());
        assert!(normalize_book_title("   ").is_err());
        let result = normalize_book_title("  My Book  ");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "My Book");
    }

    #[test]
    fn book_title_rejects_over_120_chars() {
        use super::*;
        let long = "a".repeat(121);
        let result = normalize_book_title(&long);
        assert!(matches!(result, Err(StorageError::ValidationError(_))));
        // 120 chars is fine
        let ok = "a".repeat(120);
        assert!(normalize_book_title(&ok).is_ok());
    }

    #[test]
    fn book_title_limit_counts_chars_not_bytes() {
        use super::*;
        let max = "本".repeat(120);
        assert!(normalize_book_title(&max).is_ok());
        let too_long = "本".repeat(121);
        assert!(matches!(
            normalize_book_title(&too_long),
            Err(StorageError::ValidationError(_))
        ));
    }

    // -- upsert_paper_page --

    #[test]
    fn upsert_page_appends_new_page() {
        use super::*;
        use crate::PaperPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![],
            };
            save_paper_book(book).unwrap();

            let page = PaperPage {
                id: "page-1".into(),
                image_path: "images/book-1/page-1.jpg".into(),
                page_label: None,
                ocr_hash: "sha256:abc".into(),
                markdown: "Page text".into(),
                manual_markdown: None,
                notes: vec![],
            };
            upsert_paper_page("book-1".into(), page, "2026-05-20T01:00:00Z".into()).unwrap();

            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages.len(), 1);
            assert_eq!(data.books[0].pages[0].id, "page-1");
            assert_eq!(data.books[0].updated_at, "2026-05-20T01:00:00Z");
        });
        teardown(&dir);
    }

    #[test]
    fn upsert_page_replaces_existing_page() {
        use super::*;
        use crate::PaperPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    page_label: None,
                    ocr_hash: "sha256:abc".into(),
                    markdown: "Original".into(),
                    manual_markdown: None,
                    notes: vec![],
                }],
            };
            save_paper_book(book).unwrap();

            let page = PaperPage {
                id: "page-1".into(),
                image_path: "images/book-1/page-1.jpg".into(),
                page_label: Some("42".into()),
                ocr_hash: "sha256:abc".into(),
                markdown: "Updated".into(),
                manual_markdown: None,
                notes: vec![],
            };
            upsert_paper_page("book-1".into(), page, "2026-05-20T02:00:00Z".into()).unwrap();

            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages.len(), 1);
            assert_eq!(data.books[0].pages[0].markdown, "Updated");
            assert_eq!(data.books[0].pages[0].page_label, Some("42".into()));
        });
        teardown(&dir);
    }

    #[test]
    fn upsert_page_normalizes_label() {
        use super::*;
        use crate::PaperPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![],
            };
            save_paper_book(book).unwrap();

            let page = PaperPage {
                id: "page-1".into(),
                image_path: "images/book-1/page-1.jpg".into(),
                page_label: Some("  42  ".into()),
                ocr_hash: "sha256:abc".into(),
                markdown: "Text".into(),
                manual_markdown: None,
                notes: vec![],
            };
            upsert_paper_page("book-1".into(), page, "2026-05-20T03:00:00Z".into()).unwrap();

            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages[0].page_label, Some("42".into()));
        });
        teardown(&dir);
    }

    #[test]
    fn upsert_page_invalidates_label_too_long() {
        use super::*;
        use crate::PaperPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let page = PaperPage {
                id: "page-1".into(),
                image_path: "images/book-1/page-1.jpg".into(),
                page_label: Some("a".repeat(33)),
                ocr_hash: "sha256:abc".into(),
                markdown: "Text".into(),
                manual_markdown: None,
                notes: vec![],
            };
            let result = upsert_paper_page("book-1".into(), page, "2026-05-20T03:00:00Z".into());
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn upsert_page_book_not_found() {
        use super::*;
        use crate::PaperPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let page = PaperPage {
                id: "page-1".into(),
                image_path: "images/book-1/page-1.jpg".into(),
                page_label: None,
                ocr_hash: "sha256:abc".into(),
                markdown: "Text".into(),
                manual_markdown: None,
                notes: vec![],
            };
            let result = upsert_paper_page(
                "nonexistent-book".into(),
                page,
                "2026-05-20T03:00:00Z".into(),
            );
            assert!(matches!(result, Err(StorageError::NotFound(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn upsert_page_rejects_path_traversal_ids() {
        use super::*;
        use crate::PaperPage;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let page = PaperPage {
                id: "../page".into(),
                image_path: "images/book-1/page-1.jpg".into(),
                page_label: None,
                ocr_hash: "sha256:abc".into(),
                markdown: "Text".into(),
                manual_markdown: None,
                notes: vec![],
            };
            let result = upsert_paper_page("book-1".into(), page, "2026-05-20T03:00:00Z".into());
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
        });
        teardown(&dir);
    }

    // P1-4: backslash and multi-segment rejection in storage IDs
    #[test]
    fn storage_id_rejects_backslash_in_doc_id() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            // delete_pdf_doc uses validate_storage_id for the doc_id
            let err = delete_pdf_doc(r"dir\file.pdf".into());
            assert!(
                matches!(err, Err(StorageError::ValidationError(_))),
                "backslash in doc_id should be rejected"
            );
            let err2 = delete_pdf_doc("dir/file.pdf".into());
            assert!(
                matches!(err2, Err(StorageError::ValidationError(_))),
                "slash in doc_id should be rejected"
            );
        });
        teardown(&dir);
    }

    // -- delete_paper_page --

    #[test]
    fn delete_page_removes_page_and_notes() {
        use super::*;
        use crate::Note;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    page_label: None,
                    ocr_hash: "sha256:unique".into(),
                    markdown: "Text".into(),
                    manual_markdown: None,
                    notes: vec![Note {
                        id: "note-1".into(),
                        page_id: "page-1".into(),
                        selected_text: "sel".into(),
                        start_offset: Some(0),
                        end_offset: Some(3),
                        content: "My note".into(),
                        tags: vec![],
                        created_at: "2026-05-20T00:00:00Z".into(),
                        updated_at: "2026-05-20T00:00:00Z".into(),
                    }],
                }],
            };
            save_paper_book(book).unwrap();
            delete_paper_page(
                "book-1".into(),
                "page-1".into(),
                "2026-05-20T04:00:00Z".into(),
            )
            .unwrap();
            let data = get_paper_books().unwrap();
            assert!(data.books[0].pages.is_empty());
        });
        teardown(&dir);
    }

    #[test]
    fn delete_page_leaves_empty_book() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    page_label: None,
                    ocr_hash: "sha256:abc".into(),
                    markdown: "Text".into(),
                    manual_markdown: None,
                    notes: vec![],
                }],
            };
            save_paper_book(book).unwrap();
            delete_paper_page(
                "book-1".into(),
                "page-1".into(),
                "2026-05-20T05:00:00Z".into(),
            )
            .unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(data.books.len(), 1);
            assert!(data.books[0].pages.is_empty());
        });
        teardown(&dir);
    }

    #[test]
    fn delete_page_removes_unreferenced_cache_entry() {
        use super::*;
        use crate::{CacheRecord, OcrPage, OcrResult};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            // Store cache entry for a unique hash
            let ocr = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "Unique".into(),
                }],
                source_hash: "sha256:unique_hash".into(),
                cache_hit: false,
            };
            cache_store(
                DocType::Paper,
                "sha256:unique_hash".into(),
                "unique.jpg".into(),
                ocr,
            )
            .unwrap();

            // Store book with that hash
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    page_label: None,
                    ocr_hash: "sha256:unique_hash".into(),
                    markdown: "Text".into(),
                    manual_markdown: None,
                    notes: vec![],
                }],
            };
            save_paper_book(book).unwrap();

            // Delete the page
            delete_paper_page(
                "book-1".into(),
                "page-1".into(),
                "2026-05-20T06:00:00Z".into(),
            )
            .unwrap();

            // Cache entry should be gone
            let record = cache_lookup(DocType::Paper, "sha256:unique_hash").unwrap();
            assert!(record.is_none());
        });
        teardown(&dir);
    }

    #[test]
    fn delete_page_rejects_path_traversal_ids() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let result = delete_paper_page(
                "../book".into(),
                "page-1".into(),
                "2026-05-20T00:00:00Z".into(),
            );
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn delete_page_keeps_referenced_cache_hash() {
        use super::*;
        use crate::{CacheRecord, OcrPage, OcrResult};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            // Store cache entry for a shared hash
            let ocr = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "Shared".into(),
                }],
                source_hash: "sha256:shared_hash".into(),
                cache_hit: false,
            };
            cache_store(
                DocType::Paper,
                "sha256:shared_hash".into(),
                "shared.jpg".into(),
                ocr,
            )
            .unwrap();

            // Two books share the same hash
            let book1 = PaperBook {
                id: "book-1".into(),
                title: "Book 1".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    page_label: None,
                    ocr_hash: "sha256:shared_hash".into(),
                    markdown: "Text".into(),
                    manual_markdown: None,
                    notes: vec![],
                }],
            };
            save_paper_book(book1).unwrap();

            let book2 = PaperBook {
                id: "book-2".into(),
                title: "Book 2".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-2".into(),
                    image_path: "images/book-2/page-2.jpg".into(),
                    page_label: None,
                    ocr_hash: "sha256:shared_hash".into(),
                    markdown: "Text".into(),
                    manual_markdown: None,
                    notes: vec![],
                }],
            };
            save_paper_book(book2).unwrap();

            // Delete page from book1
            delete_paper_page(
                "book-1".into(),
                "page-1".into(),
                "2026-05-20T07:00:00Z".into(),
            )
            .unwrap();

            // Cache entry should still exist (book2 still references it)
            let record = cache_lookup(DocType::Paper, "sha256:shared_hash").unwrap();
            assert!(record.is_some());
        });
        teardown(&dir);
    }

    // -- delete_paper_book --

    #[test]
    fn delete_book_removes_unreferenced_cache_entries() {
        use super::*;
        use crate::{OcrPage, OcrResult};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            // Store cache entries
            let ocr1 = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "A".into(),
                }],
                source_hash: "sha256:hash_a".into(),
                cache_hit: false,
            };
            cache_store(DocType::Paper, "sha256:hash_a".into(), "a.jpg".into(), ocr1).unwrap();

            let ocr2 = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "B".into(),
                }],
                source_hash: "sha256:hash_b".into(),
                cache_hit: false,
            };
            cache_store(DocType::Paper, "sha256:hash_b".into(), "b.jpg".into(), ocr2).unwrap();

            // Book with those hashes
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![
                    PaperPage {
                        id: "page-1".into(),
                        image_path: "images/book-1/page-1.jpg".into(),
                        page_label: None,
                        ocr_hash: "sha256:hash_a".into(),
                        markdown: "A".into(),
                        manual_markdown: None,
                        notes: vec![],
                    },
                    PaperPage {
                        id: "page-2".into(),
                        image_path: "images/book-1/page-2.jpg".into(),
                        page_label: None,
                        ocr_hash: "sha256:hash_b".into(),
                        markdown: "B".into(),
                        manual_markdown: None,
                        notes: vec![],
                    },
                ],
            };
            save_paper_book(book).unwrap();

            delete_paper_book("book-1".into()).unwrap();

            // Both cache entries should be gone
            assert!(cache_lookup(DocType::Paper, "sha256:hash_a")
                .unwrap()
                .is_none());
            assert!(cache_lookup(DocType::Paper, "sha256:hash_b")
                .unwrap()
                .is_none());
        });
        teardown(&dir);
    }

    #[test]
    fn delete_book_keeps_unrelated_orphan_cache_entries() {
        use super::*;
        use crate::{OcrPage, OcrResult};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let deleted_ocr = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "Deleted".into(),
                }],
                source_hash: "sha256:deleted".into(),
                cache_hit: false,
            };
            cache_store(
                DocType::Paper,
                "sha256:deleted".into(),
                "deleted.jpg".into(),
                deleted_ocr,
            )
            .unwrap();

            let unrelated_ocr = OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "Orphan".into(),
                }],
                source_hash: "sha256:orphan".into(),
                cache_hit: false,
            };
            cache_store(
                DocType::Paper,
                "sha256:orphan".into(),
                "orphan.jpg".into(),
                unrelated_ocr,
            )
            .unwrap();

            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![PaperPage {
                    id: "page-1".into(),
                    image_path: "images/book-1/page-1.jpg".into(),
                    page_label: None,
                    ocr_hash: "sha256:deleted".into(),
                    markdown: "Deleted".into(),
                    manual_markdown: None,
                    notes: vec![],
                }],
            };
            save_paper_book(book).unwrap();

            delete_paper_book("book-1".into()).unwrap();

            assert!(cache_lookup(DocType::Paper, "sha256:deleted")
                .unwrap()
                .is_none());
            assert!(cache_lookup(DocType::Paper, "sha256:orphan")
                .unwrap()
                .is_some());
        });
        teardown(&dir);
    }

    #[test]
    fn delete_book_removes_book_from_paper_books() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let book = PaperBook {
                id: "book-1".into(),
                title: "Book".into(),
                created_at: "2026-05-20T00:00:00Z".into(),
                updated_at: "2026-05-20T00:00:00Z".into(),
                pages: vec![],
            };
            save_paper_book(book).unwrap();
            delete_paper_book("book-1".into()).unwrap();
            let data = get_paper_books().unwrap();
            assert!(data.books.is_empty());
        });
        teardown(&dir);
    }

    #[test]
    fn delete_book_not_found_returns_error() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let result = delete_paper_book("nonexistent".into());
            assert!(matches!(result, Err(StorageError::NotFound(_))));
        });
        teardown(&dir);
    } // close delete_book_not_found_returns_error

    #[test]
    fn delete_pdf_doc_removes_metadata() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let doc = PdfDoc {
                id: "doc1".into(),
                title: "Test PDF".into(),
                original_file_name: "test.pdf".into(),
                pdf_path: "pdfs/doc1.pdf".into(),
                markdown_path: "markdowns/doc1.md".into(),
                ocr_hash: "sha256:abc".into(),
                page_count: 5,
                last_read_page_index: 0,
                tags: vec![],
                created_at: "2026-01-01T00:00:00Z".into(),
                updated_at: "2026-01-01T00:00:00Z".into(),
            };
            save_pdf_doc(doc).unwrap();
            let before = get_pdf_docs().unwrap();
            assert_eq!(before.docs.len(), 1);
            delete_pdf_doc("doc1".into()).unwrap();
            let after = get_pdf_docs().unwrap();
            assert_eq!(after.docs.len(), 0);
        });
        teardown(&dir);
    }

    #[test]
    fn delete_pdf_doc_cleans_unreferenced_cache() {
        use super::*;
        use crate::{CacheRecord, OcrPage, OcrResult};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let doc = PdfDoc {
                id: "doc1".into(),
                title: "Test".into(),
                original_file_name: "test.pdf".into(),
                pdf_path: "pdfs/doc1.pdf".into(),
                markdown_path: "markdowns/doc1.md".into(),
                ocr_hash: "sha256:sharedhash".into(),
                page_count: 3,
                last_read_page_index: 0,
                tags: vec![],
                created_at: "2026-01-01T00:00:00Z".into(),
                updated_at: "2026-01-01T00:00:00Z".into(),
            };
            save_pdf_doc(doc).unwrap();
            let cache_path = dir.join("cache_pdf.json");
            let entry = CacheRecord {
                file_name: "test.pdf".into(),
                created_at: "2026-01-01T00:00:00Z".into(),
                result: OcrResult {
                    pages: vec![OcrPage {
                        index: 0,
                        markdown: "test".into(),
                    }],
                    source_hash: "sha256:sharedhash".into(),
                    cache_hit: false,
                },
            };
            fs::write(
                &cache_path,
                serde_json::to_string(&serde_json::json!({
                    "sha256:sharedhash": entry
                }))
                .unwrap(),
            )
            .unwrap();
            delete_pdf_doc("doc1".into()).unwrap();
            let cache: serde_json::Value =
                serde_json::from_str(&fs::read_to_string(&cache_path).unwrap()).unwrap();
            assert_eq!(cache.as_object().map(|m| m.len()).unwrap_or(0), 0);
        });
        teardown(&dir);
    }

    #[test]
    fn delete_pdf_doc_preserves_cache_when_referenced() {
        use super::*;
        use crate::{CacheRecord, OcrPage, OcrResult};
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            for id in ["doc1", "doc2"] {
                let doc = PdfDoc {
                    id: id.into(),
                    title: format!("Test {}", id),
                    original_file_name: "test.pdf".into(),
                    pdf_path: format!("pdfs/{}.pdf", id),
                    markdown_path: format!("markdowns/{}.md", id),
                    ocr_hash: "sha256:sharedhash".into(),
                    page_count: 3,
                    last_read_page_index: 0,
                    tags: vec![],
                    created_at: "2026-01-01T00:00:00Z".into(),
                    updated_at: "2026-01-01T00:00:00Z".into(),
                };
                save_pdf_doc(doc).unwrap();
            }
            let cache_path = dir.join("cache_pdf.json");
            let entry = CacheRecord {
                file_name: "test.pdf".into(),
                created_at: "2026-01-01T00:00:00Z".into(),
                result: OcrResult {
                    pages: vec![OcrPage {
                        index: 0,
                        markdown: "test".into(),
                    }],
                    source_hash: "sha256:sharedhash".into(),
                    cache_hit: false,
                },
            };
            fs::write(
                &cache_path,
                serde_json::to_string(&serde_json::json!({
                    "sha256:sharedhash": entry
                }))
                .unwrap(),
            )
            .unwrap();
            delete_pdf_doc("doc1".into()).unwrap();
            let cache: serde_json::Value =
                serde_json::from_str(&fs::read_to_string(&cache_path).unwrap()).unwrap();
            assert_eq!(cache.as_object().map(|m| m.len()).unwrap_or(0), 1);
        });
        teardown(&dir);
    }

    #[test]
    fn delete_pdf_doc_not_found_returns_error() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let result = delete_pdf_doc("nonexistent".into());
            assert!(matches!(result, Err(StorageError::NotFound(_))));
        });
        teardown(&dir);
    }

    // -- F16: Manual Markdown Edit --

    fn make_paper_book_with_page(id: &str, page_id: &str) -> crate::PaperBook {
        use super::*;
        PaperBook {
            id: id.into(),
            title: "Test".into(),
            created_at: "2026-05-20T00:00:00Z".into(),
            updated_at: "2026-05-20T00:00:00Z".into(),
            pages: vec![PaperPage {
                id: page_id.into(),
                image_path: format!("images/{}/{}.jpg", id, page_id),
                page_label: None,
                ocr_hash: "sha256:abc".into(),
                markdown: "Original OCR text".into(),
                manual_markdown: None,
                notes: vec![],
            }],
        }
    }

    fn make_pdf_doc(id: &str, page_count: i32) -> crate::PdfDoc {
        use super::*;
        PdfDoc {
            id: id.into(),
            title: "Test PDF".into(),
            original_file_name: "test.pdf".into(),
            pdf_path: format!("pdfs/{}.pdf", id),
            markdown_path: format!("markdowns/{}.md", id),
            ocr_hash: "sha256:abc".into(),
            page_count,
            last_read_page_index: 0,
            tags: vec![],
            created_at: "2026-01-01T00:00:00Z".into(),
            updated_at: "2026-01-01T00:00:00Z".into(),
        }
    }

    #[test]
    fn save_paper_page_manual_markdown_persists_text() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_paper_book(make_paper_book_with_page("book-1", "page-1")).unwrap();
            save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                Some("Edited text".into()),
                "2026-05-20T01:00:00Z".into(),
            )
            .unwrap();
            let data = get_paper_books().unwrap();
            let page = &data.books[0].pages[0];
            assert_eq!(page.manual_markdown, Some("Edited text".to_string()));
            assert_eq!(page.markdown, "Original OCR text");
            assert_eq!(data.books[0].updated_at, "2026-05-20T01:00:00Z");
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_page_manual_markdown_with_none_clears_existing() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_paper_book(make_paper_book_with_page("book-1", "page-1")).unwrap();
            save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                Some("Edited".into()),
                "2026-05-20T01:00:00Z".into(),
            )
            .unwrap();
            save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                None,
                "2026-05-20T02:00:00Z".into(),
            )
            .unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages[0].manual_markdown, None);
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_page_manual_markdown_with_whitespace_only_clears() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_paper_book(make_paper_book_with_page("book-1", "page-1")).unwrap();
            save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                Some("Edited".into()),
                "2026-05-20T01:00:00Z".into(),
            )
            .unwrap();
            save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                Some("   \n\t  ".into()),
                "2026-05-20T02:00:00Z".into(),
            )
            .unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages[0].manual_markdown, None);
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_page_manual_markdown_preserves_non_empty_exact_whitespace() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_paper_book(make_paper_book_with_page("book-1", "page-1")).unwrap();
            let leading = "  leading space";
            save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                Some(leading.into()),
                "2026-05-20T01:00:00Z".into(),
            )
            .unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(
                data.books[0].pages[0].manual_markdown,
                Some(leading.to_string())
            );
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_page_manual_markdown_rejects_text_over_max_length() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_paper_book(make_paper_book_with_page("book-1", "page-1")).unwrap();
            let overlong: String = "a".repeat(MAX_MANUAL_MARKDOWN_LEN + 1);
            let result = save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                Some(overlong),
                "2026-05-20T01:00:00Z".into(),
            );
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
            // Data unchanged
            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages[0].manual_markdown, None);
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_page_manual_markdown_accepts_text_at_max_length() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_paper_book(make_paper_book_with_page("book-1", "page-1")).unwrap();
            let max: String = "a".repeat(MAX_MANUAL_MARKDOWN_LEN);
            save_paper_page_manual_markdown(
                "book-1".into(),
                "page-1".into(),
                Some(max.clone()),
                "2026-05-20T01:00:00Z".into(),
            )
            .unwrap();
            let data = get_paper_books().unwrap();
            assert_eq!(data.books[0].pages[0].manual_markdown, Some(max));
        });
        teardown(&dir);
    }

    #[test]
    fn save_paper_page_manual_markdown_unknown_page_returns_not_found() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_paper_book(make_paper_book_with_page("book-1", "page-1")).unwrap();
            let result = save_paper_page_manual_markdown(
                "book-1".into(),
                "missing-page".into(),
                Some("x".into()),
                "2026-05-20T01:00:00Z".into(),
            );
            assert!(matches!(result, Err(StorageError::NotFound(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn get_pdf_manual_markdown_returns_default_when_no_file() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 5)).unwrap();
            let data = get_pdf_manual_markdown("doc-1".into()).unwrap();
            assert_eq!(data.version, 1);
            assert!(data.pages.is_empty());
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_page_manual_markdown_creates_file_on_first_save() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 5)).unwrap();
            save_pdf_page_manual_markdown("doc-1".into(), 0, Some("Edited page 1".into())).unwrap();
            let path = dir.join("pdf").join("doc-1").join("manual.json");
            assert!(path.is_file(), "manual.json should exist");
            let data = get_pdf_manual_markdown("doc-1".into()).unwrap();
            assert_eq!(
                data.pages.get("0").map(|s| s.as_str()),
                Some("Edited page 1")
            );
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_page_manual_markdown_writes_multiple_pages() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 10)).unwrap();
            for i in [0, 3, 7] {
                save_pdf_page_manual_markdown(
                    "doc-1".into(),
                    i,
                    Some(format!("Edited page {}", i)),
                )
                .unwrap();
            }
            let data = get_pdf_manual_markdown("doc-1".into()).unwrap();
            assert_eq!(data.pages.len(), 3);
            assert_eq!(data.pages.get("0").unwrap(), "Edited page 0");
            assert_eq!(data.pages.get("3").unwrap(), "Edited page 3");
            assert_eq!(data.pages.get("7").unwrap(), "Edited page 7");
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_page_manual_markdown_with_none_removes_page_override() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 5)).unwrap();
            save_pdf_page_manual_markdown("doc-1".into(), 0, Some("X".into())).unwrap();
            save_pdf_page_manual_markdown("doc-1".into(), 1, Some("Y".into())).unwrap();
            save_pdf_page_manual_markdown("doc-1".into(), 0, None).unwrap();
            let data = get_pdf_manual_markdown("doc-1".into()).unwrap();
            assert_eq!(data.pages.len(), 1);
            assert!(!data.pages.contains_key("0"));
            assert_eq!(data.pages.get("1").unwrap(), "Y");
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_page_manual_markdown_with_whitespace_only_removes_override() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 5)).unwrap();
            save_pdf_page_manual_markdown("doc-1".into(), 0, Some("X".into())).unwrap();
            save_pdf_page_manual_markdown("doc-1".into(), 0, Some("  \n  ".into())).unwrap();
            let data = get_pdf_manual_markdown("doc-1".into()).unwrap();
            assert!(!data.pages.contains_key("0"));
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_page_manual_markdown_rejects_text_over_max_length() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 5)).unwrap();
            let overlong: String = "a".repeat(MAX_MANUAL_MARKDOWN_LEN + 1);
            let result = save_pdf_page_manual_markdown("doc-1".into(), 0, Some(overlong));
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_page_manual_markdown_rejects_invalid_page_index() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 3)).unwrap();
            let result = save_pdf_page_manual_markdown("doc-1".into(), -1, Some("x".into()));
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
            let result = save_pdf_page_manual_markdown("doc-1".into(), 3, Some("x".into()));
            assert!(matches!(result, Err(StorageError::ValidationError(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn save_pdf_page_manual_markdown_rejects_unknown_doc() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            let result = save_pdf_page_manual_markdown("missing-doc".into(), 0, Some("x".into()));
            assert!(matches!(result, Err(StorageError::NotFound(_))));
        });
        teardown(&dir);
    }

    #[test]
    fn delete_pdf_doc_removes_manual_json_file() {
        use super::*;
        let dir = temp_dir();
        setup(&dir);
        with_init(&dir, || {
            save_pdf_doc(make_pdf_doc("doc-1", 5)).unwrap();
            save_pdf_page_manual_markdown("doc-1".into(), 0, Some("X".into())).unwrap();
            let path = dir.join("pdf").join("doc-1").join("manual.json");
            assert!(path.is_file());
            delete_pdf_doc("doc-1".into()).unwrap();
            assert!(!path.exists());
        });
        teardown(&dir);
    }
}

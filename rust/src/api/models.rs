//! Domain models for Brrk reading support app.
//!
//! All structs here are intended to be FRB-compatible (public fields)
//! and serde-serializable for JSON persistence.

use serde::{Deserialize, Serialize};
use std::path::Component;

// ---------------------------------------------------------------------------
// OCR result types
// ---------------------------------------------------------------------------

/// Result of an OCR operation. Returned to Dart via flutter_rust_bridge.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OcrResult {
    /// All pages extracted from the source.
    pub pages: Vec<OcrPage>,
    /// SHA-256 hash of the source bytes, prefixed "sha256:".
    pub source_hash: String,
    /// True when the result was served from cache without calling the Mistral API.
    #[serde(default)]
    pub cache_hit: bool,
}

/// A single OCR page.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OcrPage {
    /// 0-based page index matching the Mistral API response order.
    pub index: i32,
    /// Extracted text in Markdown format.
    pub markdown: String,
}

// ---------------------------------------------------------------------------
// Error types
// ---------------------------------------------------------------------------

/// Error variants for storage operations (JSON file I/O).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum StorageError {
    /// App has not been initialized with a data directory yet.
    NotInitialized,
    /// The requested entity was not found in storage.
    NotFound(String),
    /// A filesystem I/O error occurred.
    IoError(String),
    /// JSON parse or serialization failed.
    JsonError(String),
    /// A validation check (e.g. path traversal) failed.
    ValidationError(String),
}

impl std::fmt::Display for StorageError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            StorageError::NotInitialized => write!(f, "App not initialized"),
            StorageError::NotFound(s) => write!(f, "Not found: {s}"),
            StorageError::IoError(s) => write!(f, "I/O error: {s}"),
            StorageError::JsonError(s) => write!(f, "JSON error: {s}"),
            StorageError::ValidationError(s) => write!(f, "Validation error: {s}"),
        }
    }
}

impl std::error::Error for StorageError {}

/// Error variants for OCR operations (network, API, validation).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum OcrError {
    NetworkError(String),
    TimeoutError,
    ApiKeyError,
    FileSizeError(String),
    /// Unreadable PDF, corrupt image, or unsupported format.
    DocumentError(String),
    ParseError(String),
    RateLimitError,
    StorageError(String),
    UnknownError(String),
}

impl std::fmt::Display for OcrError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OcrError::NetworkError(s) => write!(f, "Network error: {s}"),
            OcrError::TimeoutError => write!(f, "Request timed out"),
            OcrError::ApiKeyError => write!(f, "API key is invalid or expired"),
            OcrError::FileSizeError(s) => write!(f, "File size error: {s}"),
            OcrError::DocumentError(s) => write!(f, "Document error: {s}"),
            OcrError::ParseError(s) => write!(f, "Parse error: {s}"),
            OcrError::RateLimitError => write!(f, "Rate limit exceeded"),
            OcrError::StorageError(s) => write!(f, "Storage error: {s}"),
            OcrError::UnknownError(s) => write!(f, "Unknown error: {s}"),
        }
    }
}

impl std::error::Error for OcrError {}

impl From<StorageError> for OcrError {
    fn from(e: StorageError) -> Self {
        OcrError::StorageError(e.to_string())
    }
}

// ---------------------------------------------------------------------------
// Paper Book domain models
// ---------------------------------------------------------------------------

/// Top-level container for all paper books.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaperBooksData {
    pub version: u32,
    #[serde(default)]
    pub books: Vec<PaperBook>,
}

impl Default for PaperBooksData {
    fn default() -> Self {
        Self {
            version: 1,
            books: Vec::new(),
        }
    }
}

/// A paper book containing one or more captured pages.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaperBook {
    pub id: String,
    pub title: String,
    pub created_at: String,
    pub updated_at: String,
    #[serde(default)]
    pub pages: Vec<PaperPage>,
}

/// A single page inside a paper book.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaperPage {
    pub id: String,
    /// Relative path from data_dir to the captured image.
    pub image_path: String,
    /// Optional display label (e.g. "42", "xii"). Trimmed, max 32 chars. Does not affect order.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub page_label: Option<String>,
    /// SHA-256 hash used for cache lookup.
    pub ocr_hash: String,
    /// Extracted Markdown text.
    #[serde(default)]
    pub markdown: String,
    /// User-edited Markdown. If `Some(_)`, the reader uses this text instead of
    /// `markdown`. The original OCR Markdown is preserved for "Reset to OCR".
    /// Capped at 10,000 chars.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub manual_markdown: Option<String>,
    #[serde(default)]
    pub notes: Vec<Note>,
}

// ---------------------------------------------------------------------------
// PDF domain models
// ---------------------------------------------------------------------------

/// Top-level container for all PDF documents.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfDocsData {
    pub version: u32,
    #[serde(default)]
    pub docs: Vec<PdfDoc>,
}

impl Default for PdfDocsData {
    fn default() -> Self {
        Self {
            version: 1,
            docs: Vec::new(),
        }
    }
}

/// A PDF document with OCR metadata.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfDoc {
    pub id: String,
    pub title: String,
    /// Original file name selected by the user.
    pub original_file_name: String,
    /// Relative path to the stored PDF copy.
    pub pdf_path: String,
    /// Relative path to the generated Markdown.
    pub markdown_path: String,
    /// SHA-256 hash used for cache lookup.
    pub ocr_hash: String,
    /// Total number of pages reported by Mistral OCR.
    pub page_count: i32,
    /// Last read page index (0-based), for resume.
    #[serde(default)]
    pub last_read_page_index: i32,
    #[serde(default)]
    pub tags: Vec<String>,
    pub created_at: String,
    pub updated_at: String,
}

// ---------------------------------------------------------------------------
// PDF manual Markdown
// ---------------------------------------------------------------------------

/// Per-PDF page Markdown overrides.
///
/// Stored at `{data_dir}/pdf/{doc_id}/manual.json`.
/// Keys are 0-based page indices as strings.
/// Empty/whitespace manual text is normalized to absent (key removed).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfManualMarkdownData {
    pub version: u32,
    #[serde(default)]
    pub pages: std::collections::HashMap<String, String>,
}

impl Default for PdfManualMarkdownData {
    fn default() -> Self {
        Self {
            version: 1,
            pages: std::collections::HashMap::new(),
        }
    }
}

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

/// A note attached to a specific page.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Note {
    pub id: String,
    /// The page this note belongs to.
    #[serde(default)]
    pub page_id: String,
    /// The text that was selected when the note was created.
    #[serde(default)]
    pub selected_text: String,
    /// Byte offset of selection start in the page's markdown.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub start_offset: Option<i32>,
    /// Byte offset of selection end in the page's markdown.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub end_offset: Option<i32>,
    /// User-authored text content.
    pub content: String,
    /// Optional tag strings.
    #[serde(default)]
    pub tags: Vec<String>,
    pub created_at: String,
    pub updated_at: String,
}

// ---------------------------------------------------------------------------
// Cache record
// ---------------------------------------------------------------------------

/// Single cache entry stored in cache_paper.json / cache_pdf.json.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheRecord {
    pub file_name: String,
    pub created_at: String,
    pub result: OcrResult,
}

// ---------------------------------------------------------------------------
// Path validation
// ---------------------------------------------------------------------------

/// Validates that a path is safe to use inside the app data directory.
///
/// Returns `Ok(())` if valid, `Err(description)` if the path is dangerous.
///
/// The path must be:
/// - Non-empty
/// - Free of null bytes
/// - Free of backslash characters (cross-platform safety)
/// - Not absolute (no leading `/` or Windows prefix)
/// - Free of `..` traversal components
/// - Free of `.` current-directory components
pub(crate) fn validate_relative_path(path: &str) -> Result<(), String> {
    if path.is_empty() || path.trim().is_empty() {
        return Err("Path is empty".to_string());
    }

    if path.contains('\0') {
        return Err("Path contains null byte".to_string());
    }

    // Reject backslashes on all platforms — prevents Windows absolute paths
    // from bypassing validation on Unix, and blocks backslash-encoded traversal.
    if path.contains('\\') {
        return Err("Backslash characters are not allowed".to_string());
    }

    let path_obj = std::path::Path::new(path);
    let mut components = path_obj.components().peekable();

    if let Some(first) = components.peek() {
        match first {
            Component::RootDir => return Err("Absolute paths are not allowed".to_string()),
            Component::Prefix(_) => return Err("Absolute paths are not allowed".to_string()),
            _ => {}
        }
    }

    for component in components {
        match component {
            Component::ParentDir => {
                return Err("Path traversal (..) is not allowed".to_string());
            }
            Component::CurDir => {
                return Err("Current directory component (.) is not allowed".to_string());
            }
            Component::Normal(_) | Component::RootDir | Component::Prefix(_) => {}
        }
    }

    Ok(())
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    fn ts() -> String {
        "2026-05-20T00:00:00Z".to_string()
    }

    // --- StorageError ---

    #[test]
    fn storage_error_display() {
        assert_eq!(
            StorageError::NotInitialized.to_string(),
            "App not initialized"
        );
        assert_eq!(
            StorageError::NotFound("books.json".into()).to_string(),
            "Not found: books.json"
        );
        assert_eq!(
            StorageError::IoError("file not found".into()).to_string(),
            "I/O error: file not found"
        );
        assert_eq!(
            StorageError::ValidationError("bad path".into()).to_string(),
            "Validation error: bad path"
        );
    }

    #[test]
    fn storage_error_json_roundtrip() {
        for err in [
            StorageError::NotInitialized,
            StorageError::NotFound("x".into()),
            StorageError::IoError("y".into()),
            StorageError::JsonError("z".into()),
            StorageError::ValidationError("w".into()),
        ] {
            let json = serde_json::to_string(&err).unwrap();
            let back: StorageError = serde_json::from_str(&json).unwrap();
            assert_eq!(err, back);
        }
    }

    // --- OcrError ---

    #[test]
    fn ocr_error_display() {
        assert_eq!(
            OcrError::ApiKeyError.to_string(),
            "API key is invalid or expired"
        );
        assert_eq!(OcrError::TimeoutError.to_string(), "Request timed out");
        assert_eq!(OcrError::RateLimitError.to_string(), "Rate limit exceeded");
        assert_eq!(
            OcrError::FileSizeError("50MB".into()).to_string(),
            "File size error: 50MB"
        );
    }

    #[test]
    fn ocr_error_json_roundtrip() {
        for err in [
            OcrError::NetworkError("conn refused".into()),
            OcrError::TimeoutError,
            OcrError::ApiKeyError,
            OcrError::FileSizeError("too large".into()),
            OcrError::DocumentError("encrypted".into()),
            OcrError::ParseError("malformed".into()),
            OcrError::RateLimitError,
            OcrError::StorageError("disk full".into()),
            OcrError::UnknownError("?".into()),
        ] {
            let json = serde_json::to_string(&err).unwrap();
            let back: OcrError = serde_json::from_str(&json).unwrap();
            assert_eq!(err, back);
        }
    }

    #[test]
    fn storage_error_converts_to_ocr_error() {
        let se = StorageError::NotFound("x".into());
        let oe: OcrError = se.into();
        match oe {
            OcrError::StorageError(s) => assert!(s.contains("Not found")),
            _ => panic!("Expected OcrError::StorageError"),
        }
    }

    // --- OcrResult / OcrPage ---

    #[test]
    fn ocr_result_json_roundtrip() {
        let result = OcrResult {
            pages: vec![
                OcrPage {
                    index: 0,
                    markdown: "# Hello".into(),
                },
                OcrPage {
                    index: 1,
                    markdown: "## World".into(),
                },
            ],
            source_hash: "sha256:abc123".into(),
            cache_hit: false,
        };
        let json = serde_json::to_string(&result).unwrap();
        let back: OcrResult = serde_json::from_str(&json).unwrap();
        assert_eq!(back.source_hash, "sha256:abc123");
        assert_eq!(back.cache_hit, false);
        assert_eq!(back.pages.len(), 2);
        assert_eq!(back.pages[0].index, 0);
        assert_eq!(back.pages[1].markdown, "## World");
    }

    #[test]
    fn ocr_result_cache_hit_serializes_to_true() {
        let result = OcrResult {
            pages: vec![],
            source_hash: "sha256:x".into(),
            cache_hit: true,
        };
        let json = serde_json::to_string(&result).unwrap();
        assert!(json.contains("\"cache_hit\":true"));
    }

    // --- PaperBook ---

    #[test]
    fn paper_book_json_roundtrip() {
        let book = PaperBook {
            id: "book-1".into(),
            title: "My Book".into(),
            created_at: ts(),
            updated_at: ts(),
            pages: vec![PaperPage {
                id: "page-1".into(),
                image_path: "images/book-1/page-1.jpg".into(),
                page_label: None,
                ocr_hash: "sha256:abc".into(),
                markdown: "Extracted text".into(),
                manual_markdown: None,
                notes: vec![],
            }],
        };
        let data = PaperBooksData {
            version: 1,
            books: vec![book.clone()],
        };
        let json = serde_json::to_string(&data).unwrap();
        let back: PaperBooksData = serde_json::from_str(&json).unwrap();
        assert_eq!(back.books.len(), 1);
        assert_eq!(back.books[0].title, "My Book");
        assert_eq!(
            back.books[0].pages[0].image_path,
            "images/book-1/page-1.jpg"
        );
        // page_label is None when absent from JSON
        assert!(back.books[0].pages[0].page_label.is_none());
    }

    #[test]
    fn paper_books_data_default() {
        let data = PaperBooksData::default();
        assert_eq!(data.version, 1);
        assert!(data.books.is_empty());
    }

    // --- PdfDoc ---

    #[test]
    fn pdf_doc_json_roundtrip() {
        let doc = PdfDoc {
            id: "doc-1".into(),
            title: "My PDF".into(),
            original_file_name: "source.pdf".into(),
            pdf_path: "pdfs/doc-1.pdf".into(),
            markdown_path: "markdowns/doc-1.md".into(),
            ocr_hash: "sha256:def456".into(),
            page_count: 10,
            last_read_page_index: 2,
            tags: vec!["tag1".into(), "tag2".into()],
            created_at: ts(),
            updated_at: ts(),
        };
        let data = PdfDocsData {
            version: 1,
            docs: vec![doc],
        };
        let json = serde_json::to_string(&data).unwrap();
        let back: PdfDocsData = serde_json::from_str(&json).unwrap();
        assert_eq!(back.docs[0].page_count, 10);
        assert_eq!(back.docs[0].tags, vec!["tag1", "tag2"]);
        assert_eq!(back.docs[0].last_read_page_index, 2);
    }

    #[test]
    fn pdf_docs_data_default() {
        let data = PdfDocsData::default();
        assert_eq!(data.version, 1);
        assert!(data.docs.is_empty());
    }

    // --- Note ---

    #[test]
    fn note_json_roundtrip() {
        let note = Note {
            id: "note-1".into(),
            page_id: "page-1".into(),
            selected_text: "hello world".into(),
            start_offset: Some(0),
            end_offset: Some(11),
            content: "This is a note".into(),
            tags: vec!["important".into(), "ch1".into()],
            created_at: ts(),
            updated_at: ts(),
        };
        let json = serde_json::to_string(&note).unwrap();
        let back: Note = serde_json::from_str(&json).unwrap();
        assert_eq!(back.content, "This is a note");
        assert_eq!(back.tags, vec!["important", "ch1"]);
        assert_eq!(back.selected_text, "hello world");
        assert_eq!(back.start_offset, Some(0));
        assert_eq!(back.end_offset, Some(11));
        assert_eq!(back.page_id, "page-1");
    }

    // --- CacheRecord ---

    #[test]
    fn cache_record_json_roundtrip() {
        let record = CacheRecord {
            file_name: "document.pdf".into(),
            created_at: ts(),
            result: OcrResult {
                pages: vec![OcrPage {
                    index: 0,
                    markdown: "Hello world".into(),
                }],
                source_hash: "sha256:hash123".into(),
                cache_hit: true,
            },
        };
        let json = serde_json::to_string(&record).unwrap();
        let back: CacheRecord = serde_json::from_str(&json).unwrap();
        assert_eq!(back.file_name, "document.pdf");
        assert_eq!(back.result.cache_hit, true);
        assert_eq!(back.result.pages[0].markdown, "Hello world");
    }

    // --- Path validation ---

    #[test]
    fn path_traversal_rejected() {
        assert!(validate_relative_path("../etc/passwd").is_err());
        assert!(validate_relative_path("images/../../../etc/passwd").is_err());
        assert!(validate_relative_path("images/././../../../etc").is_err());
    }

    #[test]
    fn absolute_path_rejected() {
        assert!(validate_relative_path("/etc/passwd").is_err());
        assert!(validate_relative_path("C:\\Windows\\System32").is_err());
    }

    #[test]
    fn valid_relative_path_accepted() {
        assert!(validate_relative_path("images/book1/page1.jpg").is_ok());
        assert!(validate_relative_path("pdfs/doc1.pdf").is_ok());
        assert!(validate_relative_path("markdowns/doc1.md").is_ok());
        assert!(validate_relative_path("a/b/c/d/e/f/g/h.jpg").is_ok());
    }

    #[test]
    fn null_byte_rejected() {
        assert!(validate_relative_path("images\0evil.jpg").is_err());
    }

    #[test]
    fn empty_path_rejected() {
        assert!(validate_relative_path("").is_err());
        assert!(validate_relative_path("   ").is_err());
    }

    #[test]
    fn backslash_rejected() {
        assert!(validate_relative_path(r"..\windows\system32\config").is_err());
        assert!(validate_relative_path("C:\\Windows\\System32").is_err());
        assert!(validate_relative_path("images\\photo.jpg").is_err());
    }
}

// ---------------------------------------------------------------------------
// PDF notes (F17)
// ---------------------------------------------------------------------------

/// A note attached to a specific PDF page.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfNote {
    pub id: String,
    pub doc_id: String,
    /// 0-based page index.
    pub page_index: i32,
    /// The text that was selected when the note was created.
    #[serde(default)]
    pub selected_text: String,
    /// Sentence containing the selected text.
    #[serde(default)]
    pub selected_sentence: String,
    /// User-authored text content.
    pub content: String,
    /// Optional tag strings.
    #[serde(default)]
    pub tags: Vec<String>,
    pub created_at: String,
    pub updated_at: String,
}

/// Container for all PDF notes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfNotesData {
    pub version: u32,
    #[serde(default)]
    pub notes: Vec<PdfNote>,
}

impl Default for PdfNotesData {
    fn default() -> Self {
        Self {
            version: 1,
            notes: Vec::new(),
        }
    }
}

// ---------------------------------------------------------------------------
// Vocabulary (F18)
// ---------------------------------------------------------------------------

/// Errors for vocabulary lookup operations.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum VocabError {
    NetworkError(String),
    TimeoutError,
    ApiKeyError,
    RateLimitError,
    InvalidSelection(String),
    ParseError(String),
    StorageError(String),
    UnknownError(String),
}

impl std::fmt::Display for VocabError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VocabError::NetworkError(s) => write!(f, "Vocabulary network error: {s}"),
            VocabError::TimeoutError => write!(f, "Vocabulary request timed out"),
            VocabError::ApiKeyError => write!(f, "Mistral API key is missing or invalid"),
            VocabError::RateLimitError => write!(f, "Mistral rate limit reached"),
            VocabError::InvalidSelection(s) => write!(f, "Invalid selection: {s}"),
            VocabError::ParseError(s) => write!(f, "Vocabulary parse error: {s}"),
            VocabError::StorageError(s) => write!(f, "Vocabulary storage error: {s}"),
            VocabError::UnknownError(s) => write!(f, "Vocabulary unknown error: {s}"),
        }
    }
}

impl std::error::Error for VocabError {}

/// Source location for a vocabulary encounter.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum VocabSource {
    Paper { book_id: String, page_id: String },
    Pdf { doc_id: String, page_index: i32 },
}

/// One lookup instance for a vocabulary entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VocabEncounter {
    pub id: String,
    pub selected_text: String,
    #[serde(default)]
    pub sentence: String,
    pub source: VocabSource,
    pub lookup_count: u32,
    pub first_seen: String,
    pub last_seen: String,
}

/// One vocabulary entry. Stable per `(language, lemma)`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VocabEntry {
    pub lemma: String,
    pub language: String, // "en" or "ja"
    #[serde(default)]
    pub surface_forms: Vec<String>,
    pub definition: String,
    #[serde(default)]
    pub definition_edited: bool,
    #[serde(default)]
    pub encounters: Vec<VocabEncounter>,
    pub created_at: String,
    pub updated_at: String,
}

impl VocabEntry {
    /// Sum of all encounter lookup counts.
    pub fn total_lookup_count(&self) -> u32 {
        self.encounters.iter().map(|e| e.lookup_count).sum()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VocabData {
    pub version: u32,
    #[serde(default)]
    pub entries: Vec<VocabEntry>,
}

impl Default for VocabData {
    fn default() -> Self {
        Self {
            version: 1,
            entries: Vec::new(),
        }
    }
}

/// Filter for listing vocabulary entries by source.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum VocabSourceFilter {
    PaperBook { book_id: String },
    PdfDoc { doc_id: String },
    All,
}

/// Result of a vocabulary lookup operation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VocabLookupResult {
    pub entry: VocabEntry,
    pub encounter_id: String,
    pub cache_hit: bool,
}

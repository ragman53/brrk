//! FRB-exposed storage API functions for Brrk.
//!
//! All functions require `init_app(data_dir)` to have been called first,
//! otherwise they return `StorageError::NotInitialized`.

use crate::{
    Note, PaperBook, PaperBooksData, PaperPage, PdfDoc, PdfDocsData, PdfManualMarkdownData,
    PdfNote, StorageError, VocabData, VocabEntry, VocabError, VocabLookupResult, VocabSource,
    VocabSourceFilter,
};

/// Must be called once at app start with the application's data directory path.
/// Creates required subdirectories if missing.
#[flutter_rust_bridge::frb(sync)]
pub fn init_app(data_dir: String) -> Result<(), StorageError> {
    crate::api::store::init_app(data_dir)
}

/// Saves or updates a paper book (create or rename).
pub fn save_paper_book(book: PaperBook) -> Result<(), StorageError> {
    crate::api::store::save_paper_book(book)
}

/// Returns all paper books.
pub fn get_paper_books() -> Result<PaperBooksData, StorageError> {
    crate::api::store::get_paper_books()
}

/// Deletes a paper book, its images, and unreferenced cache entries.
pub fn delete_paper_book(book_id: String) -> Result<(), StorageError> {
    crate::api::store::delete_paper_book(book_id)
}

/// Inserts or replaces a page in a paper book.
pub fn upsert_paper_page(
    book_id: String,
    page: PaperPage,
    updated_at: String,
) -> Result<(), StorageError> {
    crate::api::store::upsert_paper_page(book_id, page, updated_at)
}

/// Removes a page from a paper book, including its image and embedded notes.
/// Removes unreferenced paper OCR cache entry.
pub fn delete_paper_page(
    book_id: String,
    page_id: String,
    updated_at: String,
) -> Result<(), StorageError> {
    crate::api::store::delete_paper_page(book_id, page_id, updated_at)
}

/// Saves or updates a PDF document.
pub fn save_pdf_doc(doc: PdfDoc) -> Result<(), StorageError> {
    crate::api::store::save_pdf_doc(doc)
}

/// Returns all PDF documents.
pub fn get_pdf_docs() -> Result<PdfDocsData, StorageError> {
    crate::api::store::get_pdf_docs()
}

/// Attaches or updates a note on a specific page.
pub fn save_note(page_id: String, note: Note) -> Result<(), StorageError> {
    crate::api::store::save_note(page_id, note)
}

/// Deletes a note from a specific page.
pub fn delete_note(page_id: String, note_id: String) -> Result<(), StorageError> {
    crate::api::store::delete_note(page_id, note_id)
}

/// Returns the Markdown content for a PDF document.
pub fn get_pdf_markdown(doc_id: String) -> Result<String, StorageError> {
    crate::api::store::get_pdf_markdown(doc_id)
}

/// Deletes a PDF document, its file, markdown, and unreferenced cache entry.
pub fn delete_pdf_doc(doc_id: String) -> Result<(), StorageError> {
    crate::api::store::delete_pdf_doc(doc_id)
}

/// Clears all OCR cache entries and returns the total count removed.
pub fn clear_ocr_cache() -> Result<u32, StorageError> {
    crate::api::store::clear_ocr_cache()
}

/// Persists a manual Markdown override for a paper page.
/// `None` or whitespace clears the override.
pub fn save_paper_page_manual_markdown(
    book_id: String,
    page_id: String,
    manual_markdown: Option<String>,
    updated_at: String,
) -> Result<(), StorageError> {
    crate::api::store::save_paper_page_manual_markdown(
        book_id,
        page_id,
        manual_markdown,
        updated_at,
    )
}

/// Returns all manual Markdown overrides for a PDF. Returns an empty struct
/// if no manual file exists yet.
pub fn get_pdf_manual_markdown(doc_id: String) -> Result<PdfManualMarkdownData, StorageError> {
    crate::api::store::get_pdf_manual_markdown(doc_id)
}

/// Persists or clears a manual Markdown override for one PDF page.
/// `page_index` is 0-based. `None` or whitespace clears the override.
pub fn save_pdf_page_manual_markdown(
    doc_id: String,
    page_index: i32,
    manual_markdown: Option<String>,
) -> Result<(), StorageError> {
    crate::api::store::save_pdf_page_manual_markdown(doc_id, page_index, manual_markdown)
}

// ---------------------------------------------------------------------------
// F17 — PDF notes
// ---------------------------------------------------------------------------

/// Saves or updates a note attached to a specific PDF page.
pub fn save_pdf_note(note: PdfNote) -> Result<(), StorageError> {
    crate::api::store::save_pdf_note(note)
}

/// Returns PDF notes for a doc, optionally filtered by 0-based page index.
pub fn get_pdf_notes(
    doc_id: String,
    page_index: Option<i32>,
) -> Result<Vec<PdfNote>, StorageError> {
    crate::api::store::get_pdf_notes(doc_id, page_index)
}

/// Deletes a note from a PDF.
pub fn delete_pdf_note(doc_id: String, note_id: String) -> Result<(), StorageError> {
    crate::api::store::delete_pdf_note(doc_id, note_id)
}

// ---------------------------------------------------------------------------
// F18 — Vocabulary
// ---------------------------------------------------------------------------

/// Returns all vocabulary entries, optionally filtered by source.
pub fn list_vocabulary(source_filter: VocabSourceFilter) -> Result<Vec<VocabEntry>, StorageError> {
    crate::api::store::list_vocabulary(source_filter)
}

/// Edits the definition for an existing vocabulary entry and sets the
/// `definition_edited` flag.
pub fn update_vocabulary_definition(
    language: String,
    lemma: String,
    definition: String,
) -> Result<(), StorageError> {
    crate::api::store::update_vocabulary_definition(language, lemma, definition)
}

/// Deletes a vocabulary entry and all of its encounters.
pub fn delete_vocabulary_entry(language: String, lemma: String) -> Result<(), StorageError> {
    crate::api::store::delete_vocabulary_entry(language, lemma)
}

/// Deletes one encounter from a vocabulary entry. If the entry has no
/// encounters left, the entry itself is deleted.
pub fn delete_vocabulary_encounter(
    language: String,
    lemma: String,
    encounter_id: String,
) -> Result<(), StorageError> {
    crate::api::store::delete_vocabulary_encounter(language, lemma, encounter_id)
}

/// Persists a vocabulary lookup result (new entry or merge into existing).
pub fn save_vocabulary_lookup(
    entry: VocabEntry,
    encounter: crate::VocabEncounter,
) -> Result<VocabLookupResult, StorageError> {
    crate::api::store::save_vocabulary_lookup(entry, encounter)
}

/// FRB wrapper: vocabulary lookup that calls Mistral Chat.
/// Implementation lives in `crate::api::vocab::lookup_vocabulary`.
pub fn lookup_vocabulary(
    api_key: String,
    selected_text: String,
    page_context: String,
    selection_start: Option<i32>,
    selection_end: Option<i32>,
    source: VocabSource,
) -> Result<VocabLookupResult, VocabError> {
    crate::api::vocab::lookup_vocabulary(
        api_key,
        selected_text,
        page_context,
        selection_start,
        selection_end,
        source,
    )
}

// Helper: read all vocab data (used by tests and admin tools).
#[allow(dead_code)]
fn _vocab_marker(_: VocabData) {}

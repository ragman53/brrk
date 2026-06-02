pub mod api;
mod frb_generated;

pub use api::models::{
    CacheRecord, Note, OcrError, OcrPage, OcrResult, PaperBook, PaperBooksData, PaperPage, PdfDoc,
    PdfDocsData, PdfManualMarkdownData, StorageError,
};

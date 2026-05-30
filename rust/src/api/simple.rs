//! FRB-exposed OCR API functions for Brrk.
//!
//! Thin wrappers around `ocr.rs` to expose the API surface to Dart via flutter_rust_bridge.

pub use crate::api::ocr::process_image;
pub use crate::api::ocr::process_pdf;

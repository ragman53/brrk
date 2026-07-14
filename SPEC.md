# Brrk Specification (current main)

> **Last updated:** 2026-06-23  
> **App version string:** `0.1.0-beta.2+2`  
> **Package ID:** `com.chikob.brrk`  
> **Platform:** Android 8.0 / API 26+  
> **Stack:** Flutter + Rust via `flutter_rust_bridge`  
> **Storage:** JSON files in app-private storage with atomic writes  
> **Network AI provider:** User-owned Mistral API key  
> **Public docs:** `README.md` and GitHub Pages under `docs/`  
> **Private source of truth:** this file

---

## 1. Product definition

Brrk is an open-source Android reading assistant for paper books and PDFs.

It lets users:

- capture paper book pages with the camera,
- import PDFs through Android's system file picker,
- run OCR with their own Mistral API key,
- read OCR results as reflowable Markdown,
- manually correct OCR Markdown while preserving the original OCR text,
- add local notes and tags,
- look up selected English words and short Japanese terms,
- save vocabulary definitions and encounter examples locally.

Brrk is **local-first**, but not “all local.” OCR and vocabulary lookup send selected content to Mistral API when the user starts those features.

Brrk does **not** have:

- Brrk accounts,
- a Brrk developer-owned OCR/AI backend,
- ads,
- analytics,
- telemetry,
- cloud sync,
- automatic backup.

---

## 2. Current release state

### 2.1 Main branch state

Current `main` includes:

- `0.1.0-beta.2+2` app version metadata.
- F16 Manual Markdown Edit.
- F17 Selected Text Actions and PDF notes.
- F18 Vocabulary lookup/collection via Mistral Chat.
- Long-tap lookup candidate recovery and Japanese sentence offset fixes.
- Reader typography refinements:
  - bundled `NotoSerif` for Latin/English,
  - bundled `NotoSerifJP` for Japanese,
  - regular `400` weight registration,
  - default body size 17sp,
  - natural/start-aligned reader text as the default.
- Reader layout mode groundwork:
  - `Natural` remains default,
  - `Academic` is opt-in,
  - shared reader surface,
  - debug-only soft-hyphen and decorative overlay gate for Emergency word breaking.
- GitHub Pages landing site for closed tester recruitment.
- Japanese GitHub Pages localization under `docs/ja/`.
- Google Form CTA for closed tester signup.

### 2.2 Distributed beta artifacts

The published `v0.1.0-beta.2` release artifacts were built before the latest reader typography changes unless rebuilt after this spec update.

Before uploading a new APK/AAB or Play testing build, rebuild and revalidate from current `main`.

### 2.3 Existing beta.2 artifact checksums

Previously prepared beta.2 artifacts:

```text
APK sha256: 05c4a472f3f2a6bb6f996c18b71605b18fa223fbc9b28171428f6bbde15a752c
AAB sha256: a7f4fb31ffff7fbc51a90ae352cadde73a74c6b3f321debfdc29f629c1c2e2a3
```

These checksums apply only to the corresponding release artifacts, not to future rebuilds.

---

## 3. Feature index

| ID | Feature | Current status |
|----|---------|----------------|
| F1 | Paper Book OCR: camera → crop → Mistral OCR → Markdown | Implemented |
| F2 | PDF OCR: import → Mistral OCR → Markdown | Implemented |
| F3 | BYOK Mistral API key configuration | Implemented |
| F4 | OCR cache by SHA-256 hash | Implemented |
| F5 | Paper notes and tags | Implemented |
| F6 | PDF page reader | Implemented |
| F7 | Error handling + retry + Settings CTA | Implemented |
| F8 | Paper book/page management | Implemented |
| F9 | Capture preview + rectangular crop + OCR save flow | Implemented |
| F10 | Reading appearance controls | Implemented |
| F11 | Paper JSON export | Implemented |
| F12 | Global app theme from reading palette | Implemented |
| F13 | In-reader appearance popup | Implemented |
| F14 | PDF deletion + cleanup | Implemented |
| F15 | OCR cache clear from Settings | Implemented |
| F16 | Manual Markdown edit for paper/PDF OCR results | Implemented |
| F17 | Paper/PDF selected text actions: Add Note + Look up | Implemented |
| F18 | Vocabulary lookup/collection via Mistral Chat | Implemented |
| F19 | GitHub Pages closed tester landing page | Implemented |
| F20 | Japanese GitHub Pages localization | Implemented |
| F21 | Reader typography refinement | Implemented |
| F22 | Reader layout modes + emergency word breaking | In progress: layout mode and debug gate implemented; Paper production integration pending |

---

## 4. Privacy and data handling

### 4.1 Core privacy model

- Brrk stores app data in app-private Android storage.
- Brrk does not operate a developer-owned server for user documents, API keys, OCR output, notes, vocabulary, or analytics.
- Brrk does not send app data to the Brrk developer.
- OCR and vocabulary features use the user’s own Mistral API key.
- Mistral API usage may be billed by Mistral. Do not claim it is free or unlimited.

### 4.2 Mistral API key

- Stored by Flutter using secure storage.
- Passed to Rust per OCR/vocabulary request.
- Never persisted by Rust.
- Must never be printed, logged, included in thrown errors, or included in public bug reports.

### 4.3 OCR network transmission

OCR happens only when started by the user.

| Feature | Data sent | Recipient |
|---------|-----------|-----------|
| Paper OCR | selected/cropped page image + API key in auth header | Mistral OCR API |
| PDF OCR | selected PDF file + API key in auth header | Mistral OCR API |

OCR sends selected images or PDFs to Mistral. Do not claim OCR is fully on-device.

### 4.4 Vocabulary network transmission

Vocabulary lookup happens only when started by the user.

Brrk sends:

- selected word or short term,
- containing sentence context,
- source metadata,
- API key in auth header.

Brrk must not send the full page or full document for vocabulary lookup.

### 4.5 Logging/privacy prohibitions

Do not log:

- API keys,
- selected images/PDF bytes,
- OCR payloads or full OCR responses,
- full page/document text,
- selected sentences,
- vocabulary API payloads/responses containing private text,
- definitions tied to private user content.

---

## 5. Android and Play requirements

### 5.1 Android manifest

Required permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

No broad storage/media permission is required for PDF import; Android's system file picker is used.

### 5.2 Backup and extraction

App data includes private documents and OCR output, so Android backup is disabled:

```xml
android:allowBackup="false"
android:fullBackupContent="false"
android:dataExtractionRules="@xml/data_extraction_rules"
```

Android 12+ data extraction rules exclude app data from backup/device transfer.

### 5.3 Signing and installs

- Package ID is `com.chikob.brrk`.
- Android blocks updating an installed app if the new APK is signed with a different key.
- `INSTALL_FAILED_UPDATE_INCOMPATIBLE` means uninstall first or rebuild with the same signing key.
- Uninstalling removes app-private local data.

---

## 6. Public web/docs

### 6.1 Public surface

Only these are intended as public docs:

- `README.md`,
- `docs/index.html`,
- `docs/privacy.html`,
- `docs/terms.html`,
- `docs/ja/index.html`,
- `docs/ja/privacy.html`,
- `docs/ja/terms.html`,
- static assets referenced by those pages.

Private planning docs (`SPEC.md`, `TODO.md`, local review/worker/oracle docs) are not public source-of-truth docs.

### 6.2 GitHub Pages URL

```text
https://ragman53.github.io/brrk/
```

### 6.3 Landing page

English is the default language.

The landing page recruits Google Play closed testers and explains:

- what Brrk does,
- tester requirements,
- that joining/installing/staying opted in for 14 days helps,
- feedback is appreciated but not required,
- Mistral API key is optional for tester participation,
- Mistral API key is required for OCR/vocabulary features.

Primary CTA URL:

```text
https://forms.gle/QzfGyGroNSmTcXkz5
```

### 6.4 Japanese localization

Japanese pages live under:

```text
docs/ja/
```

English pages include a small first-party language redirect script that redirects browsers with Japanese language preference to the matching Japanese page unless `?lang=en` is present.

This script must remain:

- first-party,
- no analytics,
- no tracking,
- no cookies.

Visible language switch links must remain available.

### 6.5 Policy pages

Policy pages must keep direct links to:

- Privacy Policy,
- Terms of Use,
- GitHub repository,
- contact email `junya.chikob@gmail.com`.

Privacy policy includes closed tester signup language:

- tester signup data is collected via external form,
- used only to invite/communicate about the closed test,
- not collected by the Brrk app itself,
- do not submit API keys/private docs/sensitive personal information.

---

## 7. Architecture

### 7.1 Flutter/Dart

Main app responsibilities:

- UI and navigation,
- camera capture and crop flow,
- Android file picker for PDFs,
- secure API key storage,
- disclosure dialogs,
- local UI state,
- Riverpod providers,
- calling FRB-generated Rust bindings.

### 7.2 Rust

Rust responsibilities:

- app data directory initialization,
- JSON persistence and atomic writes,
- path validation,
- OCR cache,
- Mistral OCR HTTP calls,
- Mistral Chat vocabulary lookup,
- vocabulary merge/cache behavior,
- cleanup of orphaned files/cache/vocabulary encounters.

### 7.3 Generated files

Do not manually edit FRB-generated files, including:

```text
lib/src/rust/frb_generated.dart
rust/src/frb_generated.rs
```

After Rust API/model changes, regenerate bindings:

```bash
flutter_rust_bridge_codegen generate
```

---

## 8. Storage layout

Current app-private data layout:

```text
{app_data}/
├── paper_books.json
├── pdf_docs.json
├── pdf_notes.json
├── vocab.json
├── cache_paper.json
├── cache_pdf.json
├── images/{book_id}/{page_id}.jpg
├── pdfs/{doc_id}.pdf
├── markdowns/{doc_id}.md
├── pdf/{doc_id}/manual.json
└── covers/                    # reserved/future
```

All JSON paths are relative to `data_dir` and validated against traversal.

### 8.1 Atomic write rule

JSON writes use the existing atomic pattern:

1. read current JSON,
2. mutate in memory,
3. write temporary file,
4. rename over the target.

Avoid scattered per-entity JSON files unless there is a clear reason.

### 8.2 Path validation

Relative paths must be:

- non-empty,
- not absolute,
- free of null bytes,
- free of backslashes,
- free of `.` and `..` traversal components.

---

## 9. Rust data models

### 9.1 OCR

```rust
struct OcrResult {
    pages: Vec<OcrPage>,
    source_hash: String,
    cache_hit: bool,
}

struct OcrPage {
    index: i32,
    markdown: String,
}
```

### 9.2 Paper books

```rust
struct PaperBooksData {
    version: u32,
    books: Vec<PaperBook>,
}

struct PaperBook {
    id: String,
    title: String,
    created_at: String,
    updated_at: String,
    pages: Vec<PaperPage>,
}

struct PaperPage {
    id: String,
    image_path: String,
    page_label: Option<String>,
    ocr_hash: String,
    markdown: String,
    manual_markdown: Option<String>,
    notes: Vec<Note>,
}
```

Reader text for a paper page is:

```text
manual_markdown if Some(non-empty after trim), otherwise markdown
```

### 9.3 PDFs

```rust
struct PdfDocsData {
    version: u32,
    docs: Vec<PdfDoc>,
}

struct PdfDoc {
    id: String,
    title: String,
    original_file_name: String,
    pdf_path: String,
    markdown_path: String,
    ocr_hash: String,
    page_count: i32,
    last_read_page_index: i32,
    tags: Vec<String>,
    created_at: String,
    updated_at: String,
}
```

`last_read_page_index` is 0-based; display as `+1`.

### 9.4 Manual PDF Markdown

Stored at:

```text
pdf/{doc_id}/manual.json
```

```rust
struct PdfManualMarkdownData {
    version: u32,
    pages: HashMap<String, String>, // key: 0-based page index as string
}
```

Empty or whitespace manual text clears the page override.

### 9.5 Notes

Paper notes are embedded in `PaperPage.notes`:

```rust
struct Note {
    id: String,
    page_id: String,
    selected_text: String,
    start_offset: Option<i32>,
    end_offset: Option<i32>,
    content: String,
    tags: Vec<String>,
    created_at: String,
    updated_at: String,
}
```

PDF notes are stored globally in `pdf_notes.json`:

```rust
struct PdfNote {
    id: String,
    doc_id: String,
    page_index: i32,
    selected_text: String,
    selected_sentence: String,
    content: String,
    tags: Vec<String>,
    created_at: String,
    updated_at: String,
}

struct PdfNotesData {
    version: u32,
    notes: Vec<PdfNote>,
}
```

Paper notes preserve selected text plus offsets. PDF notes preserve selected text and containing sentence; PDF note offsets are not part of the v1 storage model.

### 9.6 Vocabulary

```rust
enum VocabSource {
    Paper { book_id: String, page_id: String },
    Pdf { doc_id: String, page_index: i32 },
}

struct VocabEncounter {
    id: String,
    selected_text: String,
    sentence: String,
    source: VocabSource,
    lookup_count: u32,
    first_seen: String,
    last_seen: String,
}

struct VocabEntry {
    lemma: String,
    language: String, // "en" or "ja"
    surface_forms: Vec<String>,
    definition: String,
    definition_edited: bool,
    encounters: Vec<VocabEncounter>,
    created_at: String,
    updated_at: String,
}

struct VocabData {
    version: u32,
    entries: Vec<VocabEntry>,
}

enum VocabSourceFilter {
    PaperBook { book_id: String },
    PdfDoc { doc_id: String },
    All,
}

struct VocabLookupResult {
    entry: VocabEntry,
    encounter_id: String,
    cache_hit: bool,
}
```

Vocabulary entries are stable by `(language, lemma)`. Encounters track each source/context.

---

## 10. Validation limits

| Field | Rule |
|-------|------|
| Book title | 1–120 chars after trim |
| Page label | optional, max 32 chars after trim; empty/whitespace → null |
| Note content | 1–10,000 chars |
| Note tags | max 5 tags per note |
| Tag length | max 50 chars |
| Manual Markdown | max 10,000 chars |
| PDF note selected text | max 1,000 chars |
| PDF note selected sentence | max 500 chars |
| Vocabulary selected sentence | max 500 chars stored |
| Vocabulary definition | max 1,000 chars stored |
| English vocabulary selection | max 40 chars, single word, ASCII letters plus `'`, `’`, `-` |
| Japanese vocabulary selection | max 20 chars, no whitespace, kana/kanji/katakana/CJK |
| PDF size | max 50 MB |
| Image bytes | max 10 MB decoded |

String limits are character-count limits unless explicitly byte-size limits.

---

## 11. Error types

### 11.1 StorageError

```rust
enum StorageError {
    NotInitialized,
    NotFound(String),
    IoError(String),
    JsonError(String),
    ValidationError(String),
}
```

### 11.2 OcrError

```rust
enum OcrError {
    NetworkError(String),
    TimeoutError,
    ApiKeyError,
    FileSizeError(String),
    DocumentError(String),
    ParseError(String),
    RateLimitError,
    StorageError(String),
    UnknownError(String),
}
```

### 11.3 VocabError

```rust
enum VocabError {
    NetworkError(String),
    TimeoutError,
    ApiKeyError,
    RateLimitError,
    InvalidSelection(String),
    ParseError(String),
    StorageError(String),
    UnknownError(String),
}
```

User-facing copy should avoid exposing private payloads.

---

## 12. FRB API surface

### 12.1 App/storage

```rust
fn init_app(data_dir: String) -> Result<(), StorageError>;

fn save_paper_book(book: PaperBook) -> Result<(), StorageError>;
fn get_paper_books() -> Result<PaperBooksData, StorageError>;
fn delete_paper_book(book_id: String) -> Result<(), StorageError>;
fn upsert_paper_page(book_id: String, page: PaperPage, updated_at: String) -> Result<(), StorageError>;
fn delete_paper_page(book_id: String, page_id: String, updated_at: String) -> Result<(), StorageError>;

fn save_pdf_doc(doc: PdfDoc) -> Result<(), StorageError>;
fn get_pdf_docs() -> Result<PdfDocsData, StorageError>;
fn get_pdf_markdown(doc_id: String) -> Result<String, StorageError>;
fn delete_pdf_doc(doc_id: String) -> Result<(), StorageError>;

fn save_note(page_id: String, note: Note) -> Result<(), StorageError>;
fn delete_note(page_id: String, note_id: String) -> Result<(), StorageError>;

fn clear_ocr_cache() -> Result<u32, StorageError>;
```

### 12.2 Manual Markdown

```rust
fn save_paper_page_manual_markdown(
    book_id: String,
    page_id: String,
    manual_markdown: Option<String>,
    updated_at: String,
) -> Result<(), StorageError>;

fn get_pdf_manual_markdown(doc_id: String) -> Result<PdfManualMarkdownData, StorageError>;

fn save_pdf_page_manual_markdown(
    doc_id: String,
    page_index: i32,
    manual_markdown: Option<String>,
) -> Result<(), StorageError>;
```

### 12.3 PDF notes

```rust
fn save_pdf_note(note: PdfNote) -> Result<(), StorageError>;
fn get_pdf_notes(doc_id: String, page_index: Option<i32>) -> Result<Vec<PdfNote>, StorageError>;
fn delete_pdf_note(doc_id: String, note_id: String) -> Result<(), StorageError>;
```

### 12.4 OCR

```rust
fn process_image(
    base64_data: String,
    file_name: String,
    api_key: String,
    force_refresh: bool,
) -> Result<OcrResult, OcrError>;

fn process_pdf(
    doc_id: String,
    file_name: String,
    api_key: String,
    force_refresh: bool,
) -> Result<OcrResult, OcrError>;
```

### 12.5 Vocabulary

```rust
fn list_vocabulary(source_filter: VocabSourceFilter) -> Result<Vec<VocabEntry>, StorageError>;
fn update_vocabulary_definition(language: String, lemma: String, definition: String) -> Result<(), StorageError>;
fn delete_vocabulary_entry(language: String, lemma: String) -> Result<(), StorageError>;
fn delete_vocabulary_encounter(language: String, lemma: String, encounter_id: String) -> Result<(), StorageError>;
fn save_vocabulary_lookup(entry: VocabEntry, encounter: VocabEncounter) -> Result<VocabLookupResult, StorageError>;

fn lookup_vocabulary(
    api_key: String,
    selected_text: String,
    page_context: String,
    selection_start: Option<i32>,
    selection_end: Option<i32>,
    source: VocabSource,
) -> Result<VocabLookupResult, VocabError>;
```

---

## 13. OCR behavior

### 13.1 Mistral OCR endpoint

```text
POST https://api.mistral.ai/v1/ocr
```

Model:

```text
mistral-ocr-latest
```

Image payload shape:

```json
{
  "model": "mistral-ocr-latest",
  "document": {
    "type": "image_url",
    "image_url": "data:image/jpeg;base64,<base64>"
  },
  "include_image_base64": false
}
```

PDF payload shape:

```json
{
  "model": "mistral-ocr-latest",
  "document": {
    "type": "document_url",
    "document_url": "data:application/pdf;base64,<base64>"
  },
  "include_image_base64": false,
  "table_format": "markdown"
}
```

Only `pages[].index` and `pages[].markdown` are required from the response.

### 13.2 OCR cache

- Cache files: `cache_paper.json`, `cache_pdf.json`.
- Keyed by source SHA-256 hash.
- `force_refresh=true` bypasses cache.
- Cache entries are removed when their source is no longer referenced.
- Settings can clear all OCR cache entries.

### 13.3 PDF Markdown shape

PDF OCR saves one Markdown file:

```text
markdowns/{doc_id}.md
```

Pages are separated with markers:

```md
<!-- page: 1 -->
...
<!-- page: 2 -->
...
```

Flutter splits this file into page sections for display.

---

## 14. Vocabulary behavior

### 14.1 Mistral Chat endpoint

```text
POST https://api.mistral.ai/v1/chat/completions
```

Current model:

```text
mistral-small-latest
```

### 14.2 Lookup flow

1. Validate selected text.
2. Detect language (`en` or `ja`).
3. Extract containing sentence from page context.
4. Check local `vocab.json` cache by `(language, lemma)`.
5. On cache miss, call Mistral Chat with selected term + sentence only.
6. Parse definition JSON.
7. Save or merge entry and encounter.
8. On failure, do not save partial data.

### 14.3 Lookup candidate recovery

The UI keeps two separate selection concepts:

- raw selected text/offsets for Add Note,
- normalized lookup candidate/offsets for Look up.

For long-press over-selection:

- English can recover a bounded single-word lookup candidate from a small noisy long-press selection.
- Double-tap behavior is preserved.
- Japanese is not aggressively segmented; only conservative trimming/validation is used.

### 14.4 Offset conversion

Flutter/Dart text offsets are UTF-16 code-unit offsets. Rust string slicing uses UTF-8 byte offsets.

Before calling Rust vocabulary lookup, Dart converts selection offsets to UTF-8 byte offsets.

Rust sentence extraction:

- trusts offsets only if the slice equals the selected term or trims to it,
- falls back to unique selected-term match when offsets are bad,
- does not guess when repeated terms make fallback ambiguous.

This fixes Japanese sentence extraction for selected Japanese terms.

---

## 15. UI behavior

### 15.1 Reading appearance

Controls:

- font size: 12–32sp, default 17,
- density: Compact / Standard / Spacious,
- palette: Default / Gruvbox / Solarized / Nord,
- reader layout mode: Natural / Academic.

Reading appearance is persisted with `shared_preferences`.

### 15.2 Typography

Current app typography:

- default app font: bundled `NotoSerif`, weight 400,
- Japanese fallback: bundled `NotoSerifJP`, weight 400,
- font assets:
  - `assets/fonts/NotoSerif-Regular.ttf`,
  - `assets/fonts/NotoSerifJP-Regular.ttf`,
  - `assets/fonts/OFL-NotoSerif.txt`,
  - `assets/fonts/OFL-NotoSerifJP.txt`.

`ThemeData` uses `fontFamily: brrkSerifFontFamily` and `fontFamilyFallback: brrkSerifFontFallback`.

Reader body/editor text explicitly requests regular weight where applicable to avoid thin rendering.

Reader body styles use:

- `letterSpacing: 0.0`,
- `wordSpacing: 0.0`,
- density-specific line heights.

### 15.3 Reader layout

Brrk supports two explicit reader layout modes:

```text
Natural
Academic
```

Rules:

- Natural is the default and stable fallback.
- Academic is opt-in.
- The app must not switch alignment automatically by line, paragraph, page, or document.
- Academic must not be described as having uniform word spacing; Flutter justification changes word spacing by line.

Natural mode:

- `TextAlign.start`,
- no Emergency word breaking,
- no inserted soft hyphens,
- consistent natural word spacing,
- canonical source text in one `SelectableText` for Paper,
- remains the initial default.

Academic mode:

- `TextAlign.justify`,
- Emergency word breaking for eligible long Latin words,
- visible decorative hyphen when Flutter actually uses a soft-hyphen break,
- no dictionary or language model,
- no custom paragraph composer,
- no manual word-spacing engine,
- one primary `SelectableText` for Paper.

PDF reader:

- currently uses `flutter_markdown` with selectable Markdown,
- Natural remains selectable Markdown with start-aligned body text,
- Academic PDF Emergency word breaking is outside the first Paper implementation unless the current public `flutter_markdown` API allows the same behavior through a small localized change.

The top overlay prevents first-long-tap selection layout shifts while keeping action buttons away from bottom controls.

### 15.3.1 Emergency word breaking

Emergency word breaking is Brrk's accepted visual line-fitting mechanism for Academic layout.

It is intentionally not dictionary-based, pattern-based, syllable-aware, linguistically correct English hyphenation, syllabification, or morphological analysis. Break positions may not match formal English hyphenation rules. This tradeoff is accepted in exchange for a smaller and more maintainable implementation.

Purpose:

- reduce extreme word spacing in Academic layout,
- improve line fitting for long Latin words,
- keep Flutter responsible for choosing actual line breaks according to the available width.

Do not reintroduce dictionary-based or linguistically correct automatic hyphenation unless the user explicitly changes this product decision later.

No Emergency word breaking implementation may require:

- a hyphenation package,
- bundled English dictionaries,
- TeX or LibreOffice pattern files,
- dictionary redistribution license investigation,
- language-specific hyphenation services,
- runtime downloads,
- native libraries,
- network services,
- syllabification,
- morphological analysis.

### 15.3.2 Minimal breaking algorithm

Use a small deterministic text transformation.

Eligible tokens:

```text
[A-Za-z]+
```

Rules:

- minimum word length: 7 characters,
- preserve at least 3 visible letters before a break,
- preserve at least 3 visible letters after a break,
- for a word of length `n`, eligible insertion offsets are `3 <= offset <= n - 3`,
- insert `U+00AD SOFT HYPHEN` at every eligible internal ASCII-letter boundary,
- let Flutter choose the actual break position according to the available width,
- do not calculate the final line break inside the word-breaking algorithm,
- remove any existing `U+00AD` before applying the transformation so it is idempotent,
- do not use a dictionary, pattern data, network service, native library, or external dependency.

Example:

```text
philosophical
→ phi<U+00AD>l<U+00AD>o<U+00AD>s<U+00AD>o<U+00AD>p<U+00AD>h<U+00AD>i<U+00AD>cal
```

Do not insert Emergency word breaking opportunities into:

- short words,
- Japanese or other non-Latin scripts,
- mixed-script tokens,
- words containing apostrophes,
- existing hard-hyphen compounds,
- URLs,
- email addresses,
- file paths,
- Markdown link or image destinations,
- inline code,
- fenced code,
- identifiers containing `_`, `/`, `\\`, `@`, or `:`,
- numeric tokens.

The exact implementation may construct the display string in one pass, but it must remain a small pure transformation.

### 15.3.3 Confirmed Flutter behavior

The following behavior is verified on the tested Android device and is not an unresolved research task:

- Flutter breaks the word at an inserted `U+00AD` opportunity.
- Flutter does not paint a visible hyphen glyph at that break.
- Double-tap and long-press selection continue to treat the visually split word as one word.
- Copy returns the canonical word without the soft hyphen.
- Example: visually split `philo` / `sophical` copies as `philosophical`.

The selection and copy gate is complete. Do not add another dictionary-selection or soft-hyphen-selection research phase.

### 15.3.4 Visible hyphen rendering

Academic mode paints a non-selectable visual hyphen when Flutter actually breaks at an inserted `U+00AD`.

Architecture:

```text
AcademicSelectableText
└── Stack
    ├── SelectableText
    └── IgnorePointer
        └── ExcludeSemantics
            └── CustomPaint
                └── VisibleHyphenPainter
```

Requirements:

- keep one `SelectableText`,
- do not split text into line widgets,
- do not insert a visible `-` into selectable text,
- do not insert manual newlines,
- do not replace Flutter line layout,
- do not create a custom selection engine,
- the overlay is purely decorative,
- the overlay does not participate in hit testing,
- the overlay does not participate in semantics,
- the overlay does not appear in Copy, Add Note, Look up, storage, Markdown editing, or export,
- provide canonical source text as `semanticsLabel`.

The overlay-side `TextPainter` must use the same layout-affecting values as `SelectableText`, including:

- display text,
- fully resolved `TextStyle`,
- `TextAlign`,
- `TextDirection`,
- `TextScaler`,
- locale,
- `StrutStyle`,
- `TextWidthBasis`,
- `TextHeightBehavior`,
- `maxLines`,
- ellipsis,
- exact post-padding content width.

For every inserted `U+00AD`:

1. Determine whether the visible character before it and the visible character after it are on different visual lines.
2. Paint nothing when they remain on the same line.
3. When they are on different lines, locate the trailing edge of the preceding fragment.
4. Paint one decorative hyphen glyph at that fragment ending.
5. Keep the glyph inside the content bounds.
6. Do not implement hanging punctuation or a hyphen extending into the margin.
7. If a reliable position cannot be obtained, omit that individual visual hyphen rather than paint it incorrectly.

Use one `CustomPainter` for all visual hyphens. Do not create one widget per hyphen or per line.

### 15.3.5 Canonical text and mapping

The original OCR/manual Markdown remains the source of truth.

The display transformation may contain `U+00AD`, but canonical text must be used for:

- Markdown editing,
- notes,
- vocabulary lookup,
- source context,
- offsets sent to Rust,
- persistence,
- export,
- accessibility semantics.

Retain display-to-source offset mapping only where needed by Add Note and vocabulary lookup. Do not expand it into a general document model.

Required selection flow:

```text
display TextSelection
→ display-to-source mapping
→ canonical raw selection for Add Note
→ vocabularyCandidateFromSelection on canonical source
→ canonical lookup text and offsets
```

`U+00AD` and decorative hyphen artifacts must never reach Rust storage, OCR output, manual Markdown, note text, vocabulary entries, JSON export, logs, or public bug reports.

### 15.3.6 Paper/PDF integration policy

Paper is the first production integration target.

Paper Academic completion requires:

- deterministic Emergency word breaking opportunities for eligible long Latin words,
- decorative overlay visibility in normal unselected reading state,
- canonical copy/Add Note/Look up behavior,
- no selection-handle regressions,
- debug and release device checks.

PDF support is outside this feature unless the current public `flutter_markdown` API allows the same behavior through a small localized change. Do not fork `flutter_markdown`, replace the Markdown renderer, or expand the implementation merely to obtain PDF parity. If the public API cannot support this safely, PDF remains Natural-only for this feature.

### 15.3.7 Files and architecture preference

No new package dependency or dictionary asset is required.

Remove planned files or abstractions that existed only for dictionary-backed hyphenation, such as a general pluggable `HyphenationService`, unless already-used code demonstrates that retaining a very small interface materially simplifies testing.

Prefer a minimal structure such as:

```text
reader/emergency_word_breaker.dart
reader/academic_selectable_text.dart
reader/visible_hyphen_painter.dart
```

The pure word-break transformation and its source/display mapping may share one small file when that is clearer. Do not create multiple layers for hypothetical future variants.

### 15.3.8 Testing and acceptance criteria

Focused tests must cover:

- eligible long Latin word receives Emergency word breaking opportunities,
- minimum 3-character prefix and suffix are preserved,
- short words remain unchanged,
- Japanese remains unchanged,
- mixed-script tokens remain unchanged,
- apostrophe words remain unchanged,
- hard-hyphen compounds remain unchanged,
- URLs, email addresses, paths, code, and identifiers remain unchanged,
- transformation is idempotent,
- display-to-source mapping returns canonical offsets,
- Add Note receives canonical text,
- vocabulary lookup receives canonical text,
- Academic uses `TextAlign.justify`,
- Natural uses `TextAlign.start`,
- Natural does not run the transformation,
- overlay is ignored by pointer handling and semantics,
- visual hyphen is painted only when an inserted `U+00AD` is used as an actual line break.

Real-device validation must include:

- debug and release builds,
- portrait and landscape,
- supported font sizes,
- all density presets,
- double tap,
- long press,
- selection handle dragging,
- Copy,
- Add Note,
- Look up.

The feature is complete when:

1. No hyphenation package, dictionary, pattern file, native library, or network service is added.
2. Natural mode remains unchanged and dependable.
3. Academic mode uses justified text.
4. Eligible long Latin words may break at deterministic internal boundaries.
5. Flutter remains responsible for choosing the actual break according to line width.
6. An actually used Emergency word break shows a visible decorative hyphen.
7. The decorative hyphen is not selectable or copyable.
8. Copy, notes, vocabulary, storage, export, and semantics use canonical text.
9. Existing selection behavior remains correct.
10. No custom line composer or line-per-widget implementation is introduced.
11. Paper reader implementation remains small and locally contained.
12. All tests, analysis, debug build, release build, and real-device checks pass.

### 15.4 Paper capture flow

1. Create/select paper book.
2. Capture image.
3. Normalize/resize JPEG.
4. Preview.
5. Optional rectangular crop.
6. Run OCR.
7. Add page label if desired.
8. Save page only after OCR success.
9. Retry/recrop/retake/cancel paths stay explicit.

### 15.5 PDF reader

- Page indicator: `Page N / total`.
- TOC extracted from Markdown headings.
- Previous/next navigation.
- `last_read_page_index` persisted with debounce.
- Manual page override indicator shown when current page has manual edit.

### 15.6 Notes and selected text actions

Paper and PDF readers provide selected text actions:

- `Look up`,
- `Add Note`.

The action strip is a non-layout-shifting overlay.

Paper Add Note stores selected text and offsets.

PDF Add Note stores selected text and selected sentence context, not offsets.

### 15.7 Vocabulary UI

- Definition bottom sheet during lookup.
- Vocabulary list screen.
- Source filtering by all / paper book / PDF doc.
- Vocabulary detail screen with editable definition.
- Delete entry and delete individual encounters.

---

## 16. Manual Markdown editing

### 16.1 Scope

Users can edit OCR Markdown for paper pages and PDF pages.

Original OCR Markdown is preserved for reset.

### 16.2 Paper

- Manual edit stored in `PaperPage.manual_markdown`.
- Empty/whitespace manual edit clears override.
- Reader displays manual override when present.

### 16.3 PDF

- Manual page edits stored in `pdf/{doc_id}/manual.json`.
- Keys are 0-based page indices as strings.
- Empty/whitespace manual edit removes that page key.
- Reader displays manual page override when present.

### 16.4 Non-goals

- No rich-text editor.
- No side-by-side preview.
- No edit history or diff view.
- No automatic note/vocabulary offset migration when manual text changes.

---

## 17. Cleanup rules

### 17.1 PDF delete

`delete_pdf_doc(doc_id)` removes:

- doc metadata from `pdf_docs.json`,
- `pdfs/{doc_id}.pdf` best-effort,
- `markdowns/{doc_id}.md` best-effort,
- `pdf/{doc_id}/manual.json` best-effort,
- matching `PdfNote`s,
- matching vocabulary encounters,
- unreferenced PDF OCR cache entry.

If a vocabulary entry has no encounters after cleanup, delete the entry.

### 17.2 Paper delete

`delete_paper_book(book_id)` removes:

- book metadata,
- images under the book where applicable,
- embedded page notes,
- matching vocabulary encounters,
- unreferenced paper OCR cache entries.

`delete_paper_page(book_id, page_id, updated_at)` removes:

- page metadata,
- page image best-effort,
- embedded page notes,
- matching vocabulary encounters,
- unreferenced paper OCR cache entry.

### 17.3 Independence rules

- Deleting a note does not affect vocabulary.
- Deleting a vocabulary entry does not affect notes.
- Deleting one vocabulary encounter deletes its entry only if no encounters remain.

---

## 18. Release/build workflow

### 18.1 Standard validation

Before release or major commit:

```bash
flutter analyze
flutter test
cd rust && cargo fmt --check
cd rust && cargo clippy -- -D warnings
cd rust && cargo test -- --test-threads=1
git diff --check
```

For app asset/signing changes, also build:

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

### 18.2 Device install

Debug build:

```bash
flutter run -d ZY32LNFZ8W
```

Release APK:

```bash
adb -s ZY32LNFZ8W install -r build/app/outputs/flutter-apk/app-release.apk
```

If signatures mismatch:

```bash
adb -s ZY32LNFZ8W uninstall com.chikob.brrk
adb -s ZY32LNFZ8W install build/app/outputs/flutter-apk/app-release.apk
```

Uninstalling removes local app data.

### 18.3 GitHub Pages local test

```bash
python3 -m http.server 8000 --directory docs
```

Open:

```text
http://localhost:8000/
http://localhost:8000/ja/
```

Check:

- language switches,
- signup CTA,
- Privacy/Terms links,
- mobile width,
- keyboard tab navigation,
- no analytics/tracking/cookie scripts.

---

## 19. Known limitations / non-goals

Current limitations:

- Android only.
- OCR and vocabulary lookup require the user’s own Mistral API key.
- Closed testers can participate without a Mistral API key, but OCR/vocabulary cannot be tested without one.
- No Brrk account.
- No cloud sync.
- No automatic backup.
- No batch import/export beyond implemented paper JSON export.
- PDF notes do not store offsets in v1.
- Vocabulary lookup supports English words and short Japanese terms; no full Japanese tokenizer/segmentation.
- OCR and vocabulary quality depend on Mistral output and limits.
- Paper Academic Emergency word breaking still requires production implementation cleanup and real-device validation after debug-gate approval.
- PDF Academic Emergency word breaking requires a separate `flutter_markdown` feasibility gate before production integration.

Non-goals for the current release line:

- No developer-hosted AI proxy.
- No analytics SDK.
- No ad SDK.
- No user-account backend.
- No broad Android storage permission.
- No generated FRB hand edits.

---

## 20. Current validation snapshot

Recent validation after reader layout and debug Emergency word breaking gate changes passed:

```text
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
git diff --check
```

Recent full Flutter test count observed:

```text
179/179 passed
```

Rust validation previously passed after vocabulary offset fixes:

```text
cd rust && cargo fmt --check
cd rust && cargo clippy -- -D warnings
cd rust && cargo test -- --test-threads=1
```

Re-run Rust validation before any release artifact rebuild.

# Brrk

<p align="center">
  <img src="assets/readme/readme_icon.png" alt="Brrk app icon" width="128" />
</p>

<p align="center">
  <strong>Turn paper books and PDFs into readable Markdown, notes, and vocabulary on Android.</strong>
</p>

<p align="center">
  Android beta · Local-first · BYOK Mistral OCR and vocabulary lookup
</p>

---

## Status

Brrk is currently in **open beta testing** for Android. The latest beta is **0.1.0-beta.2**.

It is useful for early testers who want to:

- capture physical book pages with a camera,
- import PDFs,
- run OCR with their own Mistral API key,
- read the result as clean, reflowable Markdown,
- manually fix OCR Markdown when needed,
- keep notes, page labels, and vocabulary locally.

This is still beta software. Please keep backups of anything important.

---

## Screenshots

<p align="center">
  <img src="assets/readme/paper_list.png" alt="Paper book list" width="220" />
  <img src="assets/readme/screen_capture.png" alt="Camera page capture" width="220" />
  <img src="assets/readme/ocr_result_paper.png" alt="OCR result reading view" width="220" />
</p>

<p align="center">
  <img src="assets/readme/book_list.png" alt="PDF list" width="220" />
  <img src="assets/readme/ocr_api_setup.png" alt="Mistral API key settings" width="220" />
</p>

---

## Features

### Paper books

- Create a book first, then add captured pages.
- Take a photo of a page from a physical book.
- Adjust crop before OCR.
- Save OCR text as Markdown.
- Manually edit OCR Markdown per page while keeping the original OCR text available for reset.
- Add page labels such as `p. 12`, `xv`, or custom labels.
- Select text to add notes or look up vocabulary.

### PDFs

- Import local PDF files.
- Run OCR with Mistral.
- Read extracted Markdown page by page.
- Manually edit OCR Markdown per page while keeping the original OCR text available for reset.
- Resume from the last-read page.
- Select text to add PDF notes or look up vocabulary.
- Delete imported PDFs and cached OCR data from inside the app.

### Vocabulary

- Look up selected English words and short Japanese terms from paper or PDF readers.
- Save editable definitions and example encounters locally.
- Browse a global vocabulary list or filter by paper book / PDF.
- Remove saved words or individual encounters.

### Reading appearance

- Adjust font size.
- Choose compact, standard, or spacious density.
- Switch color palettes for comfortable reading.

---

## Install the beta

1. Open the latest GitHub Release: <https://github.com/ragman53/brrk/releases/tag/v0.1.0-beta.2>
2. Download [`brrk-v0.1.0-beta.2-android.apk`](https://github.com/ragman53/brrk/releases/download/v0.1.0-beta.2/brrk-v0.1.0-beta.2-android.apk).
3. Optionally verify the SHA-256 checksum using [`brrk-v0.1.0-beta.2-android.apk.sha256`](https://github.com/ragman53/brrk/releases/download/v0.1.0-beta.2/brrk-v0.1.0-beta.2-android.apk.sha256).
4. Install the APK on Android.

Current beta APK checksum:

```text
05c4a472f3f2a6bb6f996c18b71605b18fa223fbc9b28171428f6bbde15a752c  brrk-v0.1.0-beta.2-android.apk
```

Android may show a warning because this is installed outside the Play Store. You may need to allow installation from your browser or file manager.

### Requirements

- Android 8.0 / API 26 or newer
- Internet access for OCR and vocabulary lookup
- A Mistral API key for OCR and vocabulary lookup features

You can create a Mistral API key from:

<https://console.mistral.ai/>

---

## Privacy and data handling

Brrk is local-first and does **not** operate a Brrk server.

Important details:

- Your Mistral API key is stored locally on your Android device using secure storage.
- When you start OCR, the selected PDF or captured page image is sent directly to Mistral OCR using your API key.
- When you look up vocabulary, Brrk sends the selected word/term and its containing sentence to Mistral Chat using your API key. It does not send the full page or full document for vocabulary lookup.
- OCR and vocabulary usage may be billed to your Mistral account. Small definition lookups may fit within Mistral's current free API mode, subject to Mistral's limits and pricing.
- Imported PDFs, captured page images, OCR Markdown, manual edits, notes, tags, vocabulary, and cache data are stored in app-private local storage.
- Android full-data backup is disabled for Brrk.
- Uninstalling the app removes app-private local data from the device.

Please do not share bug reports containing API keys, private documents, OCR response bodies, or sensitive extracted text.

---

## Permissions

Brrk uses only the permissions needed for the current beta:

- **Camera** — capture physical book pages.
- **Internet** — send user-selected files/images to Mistral OCR and selected terms/sentences to Mistral Chat for vocabulary lookup.

PDF import uses Android's file picker.

---

## Known limitations

- Android only.
- OCR and vocabulary lookup require your own Mistral API key.
- No cloud sync.
- No user accounts.
- No analytics.
- No automatic backup.
- Large or unusual PDFs may fail OCR depending on Mistral limits and network conditions.

---

## What's next

Possible future work includes Play Store testing, import/export improvements, and reading/vocabulary polish based on beta feedback.

---

## Feedback and bug reports

Please open a GitHub Issue with:

- app version,
- Android version,
- device model,
- steps to reproduce,
- expected result,
- actual result,
- screenshots if helpful.

Do **not** include API keys, private document contents, full OCR responses, or sensitive personal information.

---

## Build from source

Brrk is built with Flutter and Rust via `flutter_rust_bridge`.

```bash
git clone https://github.com/ragman53/brrk.git
cd brrk
flutter pub get
flutter_rust_bridge_codegen generate
flutter build apk --debug
```

Useful checks:

```bash
flutter analyze
flutter test
cd rust && cargo fmt --check && cargo clippy -- -D warnings && cargo test -- --test-threads=1
```

Release signing files are intentionally not included in the repository.

---

## License

Brrk is licensed under the Apache License 2.0. See `LICENSE`.

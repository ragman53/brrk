## Review
- Correct: No blocker found for the FEAT-SPEC.md Phase A diff. The tracked source/test diff is limited to reading appearance, Paper/PDF reader layout wiring, and tests, with the new relevant untracked `ReaderSurface` files; no staged files are present.
- Correct: Scope stays within Phase A. The implementation adds `ReaderLayoutMode` and honest UI copy without hyphenation claims (`lib/src/app/reading_appearance.dart:14-23`, `lib/src/app/reading_appearance.dart:150-172`), updates typography defaults/spacing (`lib/src/app/reading_appearance.dart:26-29`, `lib/src/app/reading_appearance.dart:207-221`, `lib/src/app/reading_appearance.dart:253-290`), and adds only a small centered reader surface (`lib/src/app/reader/reader_surface.dart:15-61`). A pubspec/Rust/storage/assets diff check produced no output.
- Correct: Selection semantics are not broken. Paper still renders exactly one `SelectableText` over `_displayedText` (`lib/src/app/paper_book_detail_screen.dart:902-906`, `lib/src/app/paper_book_detail_screen.dart:1080-1086`), and the existing selection, Add Note, and lookup offsets still come from that same canonical string (`lib/src/app/paper_book_detail_screen.dart:921-980`). No soft-hyphen/display-source transform was introduced.
- Correct: Persistence/default behavior is safe. Natural remains the constructor default (`lib/src/app/reading_appearance.dart:217-221`) and SharedPreferences fallback (`lib/src/app/reading_appearance.dart:321-325`); Academic is opt-in and persisted through `setLayoutMode` (`lib/src/app/reading_appearance.dart:360-364`).
- Correct: PDF changes stay safe for Phase A. PDF is wrapped in `ReaderSurface` and keeps `Markdown(selectable: true)` with the existing selection callback (`lib/src/app/pdf_viewer_screen.dart:586-625`); its style sheet applies typography only and does not wire `appearance.bodyTextAlign`/Academic justification (`lib/src/app/pdf_viewer_screen.dart:626-637`).
- Correct: Tests cover the requested hardening and layout-mode surface: word spacing is asserted as `0.0` for body/paragraph styles (`test/reading_appearance_test.dart:68-76`), default 17sp/density values/layout persistence/alignment mapping are covered (`test/reading_appearance_test.dart:60-129`), Paper Natural/Academic and one-`SelectableText` behavior are covered (`test/paper_book_detail_test.dart:224-279`), and `ReaderSurface` padding/max width are covered (`test/reader_surface_test.dart:7-31`).
- Fixed: none; review only.
- Blocker: none.
- Note: Unrelated untracked docs images are present (`docs/example-github-pages-design.jpg`, `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`). They are not staged and are not part of the reviewed Phase A diff; exclude them from a text-layout commit unless intentional.

### Evidence
- Reviewer commands run:
  - `git status --short && git diff --cached --name-status && git diff --name-status` — passed; no staged files.
  - `git diff --check` — passed; no output.
  - `git diff -- pubspec.yaml pubspec.lock rust lib/src/rust assets THIRD_PARTY_NOTICES 2>/dev/null || true` — passed; no unsafe dependency/Rust/storage/assets diff output.
  - `rg -n "softHyphen|soft hyphen|\\u00AD|hyphenation|TextAlign\\.justify|wordSpacing" lib test pubspec.yaml pubspec.lock` — passed; only expected Phase A `TextAlign.justify`/`wordSpacing`/comment/test references were found.
- Validation reported as already passed by the prompt/worker: `flutter analyze`, `flutter test` 138/138, `flutter build apk --debug`, and `git diff --check`.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "No blockers found. The diff is limited to FEAT-SPEC.md Phase A layout-mode/typography/ReaderSurface work; no pubspec, Rust, storage, OCR, asset, hyphenation, or soft-hyphen production changes were found. Paper keeps one canonical SelectableText and PDF remains typography/surface-only."
    }
  ],
  "changedFiles": [
    "lib/src/app/paper_book_detail_screen.dart",
    "lib/src/app/pdf_viewer_screen.dart",
    "lib/src/app/reading_appearance.dart",
    "lib/src/app/reader/reader_surface.dart (untracked, reviewed)",
    "test/paper_book_detail_test.dart",
    "test/reading_appearance_test.dart",
    "test/reader_surface_test.dart (untracked, reviewed)",
    "docs/example-github-pages-design.jpg (untracked, unrelated/not reviewed as feature)",
    "docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png (untracked, unrelated/not reviewed as feature)"
  ],
  "testsAddedOrUpdated": [
    "test/reading_appearance_test.dart",
    "test/paper_book_detail_test.dart",
    "test/reader_surface_test.dart"
  ],
  "commandsRun": [
    {
      "command": "git status --short && git diff --cached --name-status && git diff --name-status",
      "result": "passed",
      "summary": "Confirmed modified/untracked files and that no files are staged."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "No whitespace errors; command produced no output."
    },
    {
      "command": "git diff -- pubspec.yaml pubspec.lock rust lib/src/rust assets THIRD_PARTY_NOTICES 2>/dev/null || true",
      "result": "passed",
      "summary": "No dependency, Rust/storage, asset, or notices diff output found."
    },
    {
      "command": "rg -n \"softHyphen|soft hyphen|\\\\u00AD|hyphenation|TextAlign\\\\.justify|wordSpacing\" lib test pubspec.yaml pubspec.lock",
      "result": "passed",
      "summary": "Only expected Phase A justify/wordSpacing/comment/test references were found; no soft-hyphen integration."
    },
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "Reported already passed by prompt/worker; not rerun during blocker-only final review."
    },
    {
      "command": "flutter test",
      "result": "passed",
      "summary": "Reported already passed by prompt/worker, 138/138 tests; not rerun during blocker-only final review."
    },
    {
      "command": "flutter build apk --debug",
      "result": "passed",
      "summary": "Reported already passed by prompt/worker; not rerun during blocker-only final review."
    }
  ],
  "validationOutput": [
    "Reviewer git diff --check: passed with no output.",
    "Prompt/worker reported flutter analyze: passed.",
    "Prompt/worker reported flutter test: passed, 138/138.",
    "Prompt/worker reported flutter build apk --debug: passed.",
    "Prompt/worker reported git diff --check: passed."
  ],
  "residualRisks": [
    "Full FEAT-SPEC hyphenation, real-device selection gate, dictionary/license gate, and PDF public-API feasibility gate remain deferred beyond Phase A.",
    "Academic mode can still have line-dependent spacing because it uses Flutter TextAlign.justify without hyphenation; the UI copy is honest about this.",
    "PDF exposes shared reading appearance controls but intentionally does not apply Academic justification in Phase A.",
    "Unrelated untracked docs images are present in the worktree and should not be included in a text-layout commit unless intentional."
  ],
  "noStagedFiles": true,
  "notes": "Final blocker-only review after wordSpacing hardening: no blockers found."
}
```

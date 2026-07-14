# Text Layout Phase A Worker Report

## Scope implemented

Implemented the oracle-approved safe Phase A of `FEAT-SPEC.md` only.

Included:
- `ReaderLayoutMode { natural, academic }`, defaulting to Natural.
- SharedPreferences persistence for layout mode.
- Reading appearance controls for Layout with honest copy:
  - Natural: left/start aligned with consistent word spacing.
  - Academic: justified text where word spacing may vary by line.
- Typography updates:
  - default font size 17sp,
  - density line heights compact 1.35 / standard 1.50 / spacious 1.65,
  - body and paragraph letter spacing fixed at 0,
  - body and paragraph word spacing explicitly fixed at 0.
- Small shared `ReaderSurface` for centered constrained reader width/padding.
- Paper reader integration:
  - keeps exactly one `SelectableText`,
  - Natural uses `TextAlign.start`,
  - Academic uses `TextAlign.justify`,
  - selection/Add Note/Look up flow remains canonical and unchanged.
- PDF reader only uses typography/surface changes; no PDF Academic justification or hyphenation.

Explicitly not included:
- no soft hyphen insertion,
- no hyphenation package/dictionary/assets,
- no display/source offset mapping,
- no Rust/storage/OCR/model changes,
- no WebView/custom renderer/per-line widgets/adaptive fallback/flutter_markdown fork.

## Changed files

- `lib/src/app/reading_appearance.dart`
- `lib/src/app/reader/reader_surface.dart`
- `lib/src/app/paper_book_detail_screen.dart`
- `lib/src/app/pdf_viewer_screen.dart`
- `test/reading_appearance_test.dart`
- `test/reader_surface_test.dart`
- `test/paper_book_detail_test.dart`

## Tests added/updated

- Reading appearance tests for default 17sp, letter spacing 0, word spacing 0, density values, layout mode default/persistence/alignment mapping.
- Reader surface tests for padding and max body width behavior.
- Paper reader tests for Natural/Academic alignment and exactly one `SelectableText`.

## Commands run

- `dart format lib/src/app/reading_appearance.dart lib/src/app/reader/reader_surface.dart lib/src/app/paper_book_detail_screen.dart lib/src/app/pdf_viewer_screen.dart test/reading_appearance_test.dart test/reader_surface_test.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart` — passed.
- `flutter analyze` — passed, no issues found.
- `flutter test test/reading_appearance_test.dart test/reader_surface_test.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart` — passed.
- `flutter test` — passed, 138/138 tests.
- `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check` — passed.

## Residual risks / deferred FEAT-SPEC items

- Academic mode currently has justified alignment only; English hyphenation remains deferred pending the real-device selection gate and dictionary/license checks.
- Academic justified spacing can still vary by line; UI copy is honest about this.
- PDF Academic justification/hyphenation remains deferred because the public API feasibility gate has not been completed.
- Real-device visual/gesture validation is still required before any production hyphenation work.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Implemented only oracle-approved Phase A: layout mode, typography, ReaderSurface, Paper alignment, and tests; no hyphenation/dependencies/Rust/storage/OCR changes."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Changed files, tests, validation commands, residual risks, and no staged files status are reported in this artifact."
    }
  ],
  "changedFiles": [
    "lib/src/app/reading_appearance.dart",
    "lib/src/app/reader/reader_surface.dart",
    "lib/src/app/paper_book_detail_screen.dart",
    "lib/src/app/pdf_viewer_screen.dart",
    "test/reading_appearance_test.dart",
    "test/reader_surface_test.dart",
    "test/paper_book_detail_test.dart"
  ],
  "testsAddedOrUpdated": [
    "test/reading_appearance_test.dart",
    "test/reader_surface_test.dart",
    "test/paper_book_detail_test.dart"
  ],
  "commandsRun": [
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "No issues found."
    },
    {
      "command": "flutter test",
      "result": "passed",
      "summary": "All tests passed, 138/138."
    },
    {
      "command": "flutter build apk --debug",
      "result": "passed",
      "summary": "Built build/app/outputs/flutter-apk/app-debug.apk."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "No whitespace errors."
    }
  ],
  "validationOutput": [
    "flutter analyze: No issues found.",
    "flutter test: 138/138 passed.",
    "flutter build apk --debug: built debug APK.",
    "git diff --check: passed."
  ],
  "residualRisks": [
    "Hyphenation is deferred pending mandatory real-device selection gate and license checks.",
    "PDF Academic layout remains deferred pending public API feasibility gate.",
    "Academic justified word spacing may vary by line."
  ],
  "noStagedFiles": true,
  "notes": "Original async worker paused with an incomplete artifact; parent completed the safe Phase A fixes and validation."
}
```

## Review
- Correct: The current visible diff and the prior blocker fixes were inspected against `FEAT-SPEC.md` overlay requirements (`FEAT-SPEC.md:482-685`, `FEAT-SPEC.md:904-915`, `FEAT-SPEC.md:985-998`). Tracked dirty files are `lib/src/app/paper_book_detail_screen.dart`, `lib/src/app/pdf_viewer_screen.dart`, `lib/src/app/reading_appearance.dart`, `lib/src/app/settings_screen.dart`, `test/paper_book_detail_test.dart`, and `test/reading_appearance_test.dart`; the overlay/debug-gate files and tests are untracked. `git diff --cached --name-only` produced no output.
- Correct: `cursorWidth` is aligned with `SelectableText` and passed explicitly. `AcademicSelectableText` defaults `cursorWidth` to `2.0` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:30-38`), passes it to the primary `SelectableText` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:76-90`), and passes the same value to `VisibleHyphenPainter` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:99-103`). The painter mirrors the same default (`lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:44-47`, `lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:100-104`). Tests assert default and custom widths (`test/academic_selectable_text_test.dart:121-128`, `test/academic_selectable_text_test.dart:132-159`).
- Correct: `VisibleHyphenPainter` effective width uses the same `cursorWidth`. The caret margin is `_kCaretGap + cursorWidth` (`lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:49-67`), and both probe layout plus placement clamping use that effective width (`lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:138-145`, `lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:268-278`). Tests cover default/custom effective widths and repaint on cursor-width changes (`test/visible_hyphen_painter_test.dart:80-91`, `test/visible_hyphen_painter_test.dart:192-199`).
- Correct: `textScaler` resolves identically in `AcademicSelectableText`. A null scaler is resolved from `MediaQuery.textScalerOf(context)` once (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:61-68`), then the resolved spec is passed to both `SelectableText` and `VisibleHyphenPainter` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:76-103`). The duplicate `TextPainter` and painted glyph measurements consume `spec.resolvedTextScaler` (`lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:125-137`, `lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:225-245`).
- Correct: Overlay tests now exercise `computePlacements` directly for the required cases: ordinary no-marker returns zero (`test/visible_hyphen_painter_test.dart:201-207`), marked/no-wrap returns zero (`test/visible_hyphen_painter_test.dart:209-215`), forced wrap returns one in-bounds placement (`test/visible_hyphen_painter_test.dart:217-233`), and multiple markers return the expected offsets/count with in-bounds x checks (`test/visible_hyphen_painter_test.dart:235-252`).
- Correct: The fallback vertical midpoint now uses glyph box height in the normal path, not width (`lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:197-204`).
- Correct: No real `-` plus newline is inserted to create the selectable hyphenation effect. The overlay proof selectable text is `philo\u00ADsophical` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:57-60`, `lib/src/app/reader/hyphenation/selection_gate_screen.dart:476-488`), the painter paints `U+2010` separately (`lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:116-117`, `lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:287-294`), and the mapping helper only inserts/removes `U+00AD` (`lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart:74-83`, `lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart:98-115`, `lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart:146-153`). Existing debug paragraph newlines/hard-hyphen words are regression examples, not a forced hyphenation mechanism (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:39-55`).
- Correct: The overlay remains non-interactive and excluded from semantics: `Positioned.fill` wraps `CustomPaint` with `IgnorePointer` and `ExcludeSemantics` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:94-107`), while the primary `SelectableText` carries `semanticsLabel: sourceText` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:76-90`). Widget tests assert one primary `SelectableText`, one overlay paint, and the `IgnorePointer`/`ExcludeSemantics` wrappers (`test/academic_selectable_text_test.dart:12-43`, `test/academic_selectable_text_test.dart:46-93`).
- Correct: I found no production hyphen-overlay/hyphenation integration into Paper, PDF, Rust, storage, or OCR. `AcademicSelectableText` is only used by the debug gate (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:476-489`), and the gate is reachable from Settings only under `if (kDebugMode)` (`lib/src/app/settings_screen.dart:1-5`, `lib/src/app/settings_screen.dart:416-437`). Production Paper still renders a single `SelectableText` over `_displayedText` without the overlay (`lib/src/app/paper_book_detail_screen.dart:1080-1086`), and PDF still uses `Markdown(selectable: true)` without overlay/hyphenation imports (`lib/src/app/pdf_viewer_screen.dart:586-638`). A Rust/storage/OCR/dependency status check produced no output.
- Fixed: none; review only.
- Blocker: none.
- Note: Parent-reported validation already passed: `flutter analyze`, `flutter test` 179/179, `flutter build apk --debug`, and `git diff --check`. I did not rerun those commands.
- Note: Remaining real-device checks: physical Android debug and release overlay gate across portrait/landscape, narrow forced debug surface and normal reader width, font sizes 12/17/24/32, compact/standard/spacious density, `philo\u00ADsophical`, multiple automatic/manual soft-hyphen cases, ordinary prose, Japanese/mixed-language prose, hard-hyphen compounds, punctuation-adjacent words, selection handles, double-tap/long-press, canonical Copy/Add Note/Look up, TalkBack, baseline/attachment/no drift/no clipping, plus at least 10 representative academic pages (`FEAT-SPEC.md:932-979`).

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Inspected current git status/diff, FEAT-SPEC.md §§10/15/16/20, AcademicSelectableText, VisibleHyphenPainter, ReaderTextLayoutSpec, SelectionGateScreen, production Paper/PDF surfaces, and overlay tests. Prior fixes for cursorWidth, effective width, textScaler, computePlacements coverage, fallback midpoint, no selectable real hyphen/newline, IgnorePointer/ExcludeSemantics, and no production overlay integration are verified with file/line evidence."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Blocker: none."
    }
  ],
  "changedFiles": [
    "lib/src/app/paper_book_detail_screen.dart",
    "lib/src/app/pdf_viewer_screen.dart",
    "lib/src/app/reading_appearance.dart",
    "lib/src/app/settings_screen.dart",
    "test/paper_book_detail_test.dart",
    "test/reading_appearance_test.dart",
    "lib/src/app/reader/hyphenation/academic_selectable_text.dart (untracked, reviewed)",
    "lib/src/app/reader/hyphenation/hyphenated_text.dart (untracked, reviewed)",
    "lib/src/app/reader/hyphenation/reader_text_layout_spec.dart (untracked, reviewed)",
    "lib/src/app/reader/hyphenation/selection_gate_screen.dart (untracked, reviewed)",
    "lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart (untracked, reviewed)",
    "lib/src/app/reader/hyphenation/visible_hyphen_painter.dart (untracked, reviewed)",
    "lib/src/app/reader/reader_surface.dart (untracked, pre-existing Phase A dirty file)",
    "test/academic_selectable_text_test.dart (untracked, reviewed)",
    "test/reader_surface_test.dart (untracked, pre-existing Phase A dirty file)",
    "test/reader_text_layout_spec_test.dart (untracked, reviewed)",
    "test/soft_hyphen_mapping_test.dart (untracked, reviewed)",
    "test/visible_hyphen_painter_test.dart (untracked, reviewed)",
    "docs/example-github-pages-design.jpg (untracked, unrelated/not reviewed)",
    "docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png (untracked, unrelated/not reviewed)",
    "example-layout.png (untracked, unrelated/not reviewed)"
  ],
  "testsAddedOrUpdated": [
    "test/academic_selectable_text_test.dart",
    "test/visible_hyphen_painter_test.dart",
    "test/reader_text_layout_spec_test.dart",
    "test/soft_hyphen_mapping_test.dart",
    "test/reader_surface_test.dart",
    "test/paper_book_detail_test.dart",
    "test/reading_appearance_test.dart"
  ],
  "commandsRun": [
    {
      "command": "git status --short && git diff --cached --name-only && git diff --stat",
      "result": "passed",
      "summary": "Confirmed visible tracked/untracked files and no staged files."
    },
    {
      "command": "git diff -- lib/src/app/reading_appearance.dart lib/src/app/paper_book_detail_screen.dart lib/src/app/pdf_viewer_screen.dart lib/src/app/settings_screen.dart test/paper_book_detail_test.dart test/reading_appearance_test.dart",
      "result": "passed",
      "summary": "Reviewed tracked source/test diff."
    },
    {
      "command": "git ls-files --others --exclude-standard | sort",
      "result": "passed",
      "summary": "Enumerated untracked overlay/debug-gate files, tests, and unrelated images."
    },
    {
      "command": "rg -n \"AcademicSelectableText|VisibleHyphenPainter|HyphenatedText|SoftHyphenMapping|\\\\u00AD|\\\\u2010|visibleHyphen|selection_gate_screen|reader/hyphenation\" lib --glob \"*.dart\"",
      "result": "passed",
      "summary": "Overlay/hyphenation references are limited to debug gate, helper files, tests, and kDebugMode Settings route; no production Paper/PDF overlay import found."
    },
    {
      "command": "git status --short rust rust_builder lib/src/rust android assets pubspec.yaml pubspec.lock integration_test test_driver",
      "result": "passed",
      "summary": "No Rust/storage/OCR/dependency/native asset changes were reported."
    },
    {
      "command": "nl -ba FEAT-SPEC.md lib/src/app/reader/hyphenation/*.dart lib/src/app/settings_screen.dart test/academic_selectable_text_test.dart test/visible_hyphen_painter_test.dart",
      "result": "passed",
      "summary": "Collected file/line evidence for spec requirements and prior blocker fixes."
    },
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "Parent-reported passed; not rerun in this review."
    },
    {
      "command": "flutter test",
      "result": "passed",
      "summary": "Parent-reported passed, 179/179; not rerun in this review."
    },
    {
      "command": "flutter build apk --debug",
      "result": "passed",
      "summary": "Parent-reported passed; not rerun in this review."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "Parent-reported passed; not rerun in this review."
    }
  ],
  "validationOutput": [
    "Reviewer git diff --cached --name-only: no output; no staged files.",
    "Reviewer Rust/storage/OCR/dependency status check: no output.",
    "Parent-reported flutter analyze: passed.",
    "Parent-reported flutter test: passed, 179/179.",
    "Parent-reported flutter build apk --debug: passed.",
    "Parent-reported git diff --check: passed."
  ],
  "residualRisks": [
    "FEAT-SPEC real-device overlay matrix remains to be executed/recorded on physical Android for debug and release, including orientation, width, font size, density, content, selection, copy, TalkBack, drift, clipping, and at least 10 representative academic pages.",
    "Widget/unit tests verify structure and placement computation, but FEAT-SPEC.md explicitly does not allow overlay safety to be claimed from widget tests alone.",
    "Release APK build/install/launch and material debug-vs-release rendering comparison were not included in the parent-reported validation for this prompt."
  ],
  "noStagedFiles": true,
  "notes": "Review-only; no source files were modified. This artifact was written as requested. Unrelated untracked docs/example images remain present and should be excluded unless intentionally scoped."
}
```
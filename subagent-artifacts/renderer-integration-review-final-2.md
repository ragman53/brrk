## Review
- Correct: Paper and PDF are both routed through the shared reader widget. `PaperBookDetailScreen` builds `BrrkReaderPage(markdown: _displayedText, appearance: appearance, onSelectionChanged: _handleReaderSelection)` at `lib/src/app/paper_book_detail_screen.dart:1094-1098`; `PdfViewerScreen` builds the same widget at `lib/src/app/pdf_viewer_screen.dart:625-629`.
- Correct: Production strategy selection is centralized in `BrrkReaderPage`: `planReaderMarkdown(markdown)` is called by the widget getter at `lib/src/app/reader/brrk_reader_page.dart:43-47`, and the build switch selects native vs fallback at `lib/src/app/reader/brrk_reader_page.dart:51-62`. The Paper/PDF screens only pass markdown and handle source-specific selection effects.
- Correct: The shared native path reuses the Paper stack: `ReaderParagraphLayout` calls `EmergencyWordBreaker` and returns `AcademicSelectableText` via `BrrkReaderParagraph` (`lib/src/app/reader/reader_paragraph_layout.dart:63-91`, `170-185`). No PDF-specific hyphenation files were found (`find lib/src/app/reader -type f | grep -E 'pdf.*hyphen|hyphen.*pdf'` returned none).
- Correct: Selection cause and canonical context are preserved through native and fallback callbacks (`lib/src/app/reader/brrk_reader_page.dart:168-185`, `210-229`; `lib/src/app/reader/reader_paragraph_layout.dart:127-165`). Fallback source offsets stay null (`lib/src/app/reader/brrk_reader_page.dart:222-229`). Paper native source offsets are converted to UTF-8 byte offsets before note persistence (`lib/src/app/paper_book_detail_screen.dart:947-956`), matching the Rust `Note` byte-offset contract (`rust/src/api/models.rs:245-250`).
- Fixed: The two previously named planner cases are covered for the tested forms: indented heading/rule-like lines now return `LegacyMarkdownPlan('indented block')` at `lib/src/app/reader/reader_markdown_plan.dart:101-103`, with tests at `test/reader_markdown_plan_test.dart:165-175`; `# Heading #` now falls back at `lib/src/app/reader/reader_markdown_plan.dart:119-125`, with the test at `test/reader_markdown_plan_test.dart:177-184`.
- Fixed: Integration coverage is materially stronger: shared reader, Paper, PDF, paragraph, selection, and cross-source parity tests were added/updated (`test/brrk_reader_page_test.dart`, `test/reader_markdown_plan_test.dart`, `test/reader_paragraph_layout_test.dart`, `test/reader_selection_test.dart`, `test/renderer_integration_test.dart`, `test/paper_book_detail_test.dart`, `test/pdf_viewer_screen_test.dart`). Focused validation passed 74/74.
- Blocker: The native planner is still too permissive for unsupported Markdown. Lines that CommonMark treats as ATX headings but that do not match `_headingMatch` can fall through as native paragraphs, and reference-style links/definitions are not detected. Evidence: `_headingMatch` only handles a restricted heading shape (`lib/src/app/reader/reader_markdown_plan.dart:119-124`, `167-171`), `_isUnsupportedBlock` does not catch `#` or reference definitions (`lib/src/app/reader/reader_markdown_plan.dart:186-192`), and `_containsUnsupportedInline` only catches inline `[text](url)` links, not reference links (`lib/src/app/reader/reader_markdown_plan.dart:195-205`). Probe result: `planReaderMarkdown('# #hashtag')`, `planReaderMarkdown('# #')`, and `planReaderMarkdown('See [foo][bar].\n\n[bar]: https://example.com')` all returned `NativeReaderPlan`; `package:markdown` renders these respectively as `<h1>#hashtag</h1>`, `<h1></h1>`, and a link. This violates FEAT-SPEC §5.2's unsupported Markdown fallback requirement for links/ambiguous constructs and §6's “prefer fallback over partial Markdown corruption.”
- Note: `flutter analyze` passed and the focused renderer/Paper/PDF test command passed 74/74. `git diff --check` passed. A full `dart format --output=none --set-exit-if-changed lib test` check exits 1 because 13 unrelated baseline files would be reformatted; none of the feature files were in that formatter output.
- Note: `git status --short` includes untracked docs/image files outside FEAT-SPEC scope: `docs/example-github-pages-design.jpg`, `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`, and `example-layout.png`. They are not staged, but they should be kept out of the renderer PR unless intentionally scoped.
- Note: No Rust/storage/OCR/generated changes are present in `git status --short -- rust lib/src/rust android ios build .dart_tool pubspec.yaml pubspec.lock`; `git diff --cached --name-only` is empty.

Remaining physical-device gates:
- Verify Paper and PDF parity on device for identical supported prose in Natural and Academic modes, including visible hanging hyphens and canonical copy/selection behavior.
- Verify unsupported Markdown fallback on device for both Paper and PDF, including formatting, selection cause behavior, and null page-source offsets.
- Verify Paper manual override, image/label display, note creation/edit/delete, and vocabulary lookup still work on device.
- Verify PDF manual override, TOC, page navigation selection clearing, last-read-page persistence, note creation/edit/delete, and vocabulary lookup still work on device.
- After fixing the planner blocker, rerun full `flutter test`, `flutter build apk --debug`, and `flutter build apk --release` as planned.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "not_satisfied",
      "evidence": "Most renderer integration scope is contained and source/storage/generated files were not changed, but the strict native Markdown subset is still too broad for reference links and some ATX heading forms; git status also shows untracked docs/image files outside FEAT-SPEC scope."
    }
  ],
  "changedFiles": [
    "lib/src/app/paper_book_detail_screen.dart",
    "lib/src/app/pdf_viewer_screen.dart",
    "lib/src/app/reader/brrk_reader_page.dart",
    "lib/src/app/reader/reader_markdown_plan.dart",
    "lib/src/app/reader/reader_paragraph_layout.dart",
    "lib/src/app/reader/reader_selection.dart",
    "lib/src/app/reader/hyphenation/paper_academic_hyphenation.dart",
    "test/brrk_reader_page_test.dart",
    "test/reader_markdown_plan_test.dart",
    "test/reader_paragraph_layout_test.dart",
    "test/reader_selection_test.dart",
    "test/renderer_integration_test.dart",
    "test/paper_book_detail_test.dart",
    "test/pdf_viewer_screen_test.dart",
    "test/paper_production_hyphenation_test.dart",
    "docs/example-github-pages-design.jpg",
    "docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png",
    "example-layout.png"
  ],
  "testsAddedOrUpdated": [
    "test/brrk_reader_page_test.dart",
    "test/reader_markdown_plan_test.dart",
    "test/reader_paragraph_layout_test.dart",
    "test/reader_selection_test.dart",
    "test/renderer_integration_test.dart",
    "test/paper_book_detail_test.dart",
    "test/pdf_viewer_screen_test.dart",
    "test/paper_production_hyphenation_test.dart"
  ],
  "commandsRun": [
    {
      "command": "git status --short",
      "result": "passed",
      "summary": "Showed modified Paper/PDF files, deleted old Paper hyphenation seam/test, new shared reader/test files, and untracked docs/images."
    },
    {
      "command": "git diff --cached --name-only",
      "result": "passed",
      "summary": "No staged files."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "No whitespace errors in tracked diff."
    },
    {
      "command": "git status --short -- rust lib/src/rust android ios build .dart_tool pubspec.yaml pubspec.lock",
      "result": "passed",
      "summary": "No Rust/storage/OCR/generated/build/pubspec changes in status."
    },
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "No issues found."
    },
    {
      "command": "flutter test test/reader_markdown_plan_test.dart test/reader_paragraph_layout_test.dart test/reader_selection_test.dart test/brrk_reader_page_test.dart test/renderer_integration_test.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart",
      "result": "passed",
      "summary": "74/74 focused renderer/Paper/PDF tests passed."
    },
    {
      "command": "dart format --output=none --set-exit-if-changed lib test",
      "result": "failed",
      "summary": "Formatter check reports 13 unrelated baseline files would change; no feature files were listed and output=none did not modify files."
    },
    {
      "command": "dart run /tmp/check_plan.dart",
      "result": "passed",
      "summary": "Confirmed planReaderMarkdown currently returns NativeReaderPlan for '# #hashtag', '# #', and a reference-style link plus definition."
    },
    {
      "command": "dart --packages=.dart_tool/package_config.json /tmp/check_markdown.dart",
      "result": "passed",
      "summary": "Confirmed package:markdown renders those probes as headings/link, proving they are unsupported Markdown constructs that should not be native prose."
    }
  ],
  "validationOutput": [
    "flutter analyze: No issues found!",
    "focused flutter test: 00:02 +74: All tests passed!",
    "planner probe: '# #hashtag', '# #', and reference-style link markdown all returned NativeReaderPlan",
    "markdown probe: same inputs render as <h1>#hashtag</h1>, <h1></h1>, and a link"
  ],
  "residualRisks": [
    "Blocker: strict native planner still accepts unsupported Markdown/reference links and some ATX heading forms as native prose.",
    "Physical-device Paper/PDF parity has not been verified in this review.",
    "Full flutter test and APK debug/release builds are still pending after blocker fix.",
    "Untracked docs/image files are present outside FEAT-SPEC scope."
  ],
  "noStagedFiles": true,
  "diffSummary": "Adds shared BrrkReaderPage, ReaderMarkdownPlan, ReaderParagraphLayout, and ReaderSelection; migrates Paper and PDF body rendering to BrrkReaderPage; removes the old Paper-specific hyphenation seam/test; adds focused shared/Paper/PDF/integration coverage. Untracked docs/image files are also present outside the renderer scope.",
  "reviewFindings": [
    "blocker: lib/src/app/reader/reader_markdown_plan.dart:119-205 - planner still returns NativeReaderPlan for unsupported ATX heading forms and reference-style links/definitions instead of shared fallback.",
    "note: no staged files; no Rust/storage/OCR/generated/pubspec changes detected.",
    "note: physical-device parity gates remain."
  ],
  "manualNotes": "Review-only: no source files were edited. This report was written to the required subagent artifact path."
}
```

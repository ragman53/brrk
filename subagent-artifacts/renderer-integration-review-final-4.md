## Review
- Correct: Previously reported strict-planner blockers are covered in code and tests. The planner rejects any indented nonblank line before heading/rule recognition (`lib/src/app/reader/reader_markdown_plan.dart:101`), ATX close markers (`lib/src/app/reader/reader_markdown_plan.dart:123`), malformed `# #hashtag` / `# #` / `#  Heading` forms (`lib/src/app/reader/reader_markdown_plan.dart:141`), backslash escapes and reference-style links (`lib/src/app/reader/reader_markdown_plan.dart:199`), and definitions (`lib/src/app/reader/reader_markdown_plan.dart:194`). Tests cover these cases in `test/reader_markdown_plan_test.dart:165` through `test/reader_markdown_plan_test.dart:223`.
- Correct: Paper and PDF both route page rendering through `BrrkReaderPage` (`lib/src/app/paper_book_detail_screen.dart:1094`, `lib/src/app/pdf_viewer_screen.dart:625`). Strategy selection is centralized in `BrrkReaderPage.plan` / switch dispatch (`lib/src/app/reader/brrk_reader_page.dart:44`, `lib/src/app/reader/brrk_reader_page.dart:52`).
- Correct: Unsupported Markdown fallback is shared in one `MarkdownBody(selectable: true)` path (`lib/src/app/reader/brrk_reader_page.dart:206`) and emits null source offsets by constructing `ReaderSelection` without `sourceStart/sourceEnd` (`lib/src/app/reader/brrk_reader_page.dart:224`).
- Correct: The shared paragraph path reuses the Paper stack: `EmergencyWordBreaker`, `HyphenatedText`, `AcademicSelectableText`, and `ReaderTextLayoutSpec` are imported/used in `lib/src/app/reader/reader_paragraph_layout.dart:4` and Academic rendering returns `AcademicSelectableText` at `lib/src/app/reader/reader_paragraph_layout.dart:180`. No PDF-specific hyphenation path was found.
- Correct: Paper native source offsets are converted from Flutter UTF-16 code-unit offsets to UTF-8 byte offsets before note persistence (`lib/src/app/paper_book_detail_screen.dart:947`), matching the Rust/generated Note byte-offset contract (`rust/src/api/models.rs:245`, `lib/src/rust/api/models.dart:25`). Fallback offsets remain null.
- Correct: Selection cause is preserved through native heading, native paragraph, and fallback callbacks (`lib/src/app/reader/brrk_reader_page.dart:183`, `lib/src/app/reader/reader_paragraph_layout.dart:163`, `lib/src/app/reader/brrk_reader_page.dart:228`). Canonical callback text is sourced from canonical/mapped text, with tests checking no U+00AD reaches callbacks (`test/brrk_reader_page_test.dart:165`, `test/reader_paragraph_layout_test.dart:55`).
- Correct: Obsolete Paper seam/test are migrated out: `lib/src/app/reader/hyphenation/paper_academic_hyphenation.dart` and `test/paper_production_hyphenation_test.dart` are deleted; replacement coverage is in `test/reader_paragraph_layout_test.dart` and `test/renderer_integration_test.dart`.
- Fixed: none applied; review-only run.
- Blocker: none.
- Note: `flutter analyze` passed and focused renderer/Paper/PDF tests passed locally (77/77). Changed feature files pass `dart format --output=none --set-exit-if-changed`; repo-wide `dart format --output=none --set-exit-if-changed lib test` still exits 1 due unrelated pre-existing files outside this renderer diff.
- Note: Remaining gates: full `flutter test`, `flutter build apk --debug`, `flutter build apk --release`, and physical-device Paper/PDF parity verification.
- Note: Worktree status includes three untracked image artifacts outside the FEAT-SPEC file list (`docs/example-github-pages-design.jpg`, `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`, `example-layout.png`). They are not staged; exclude or confirm before commit if this feature should remain renderer-only.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Renderer integration stays in the FEAT-SPEC scope: Paper/PDF screens call shared BrrkReaderPage, strategy/fallback live in the shared reader layer, Paper-specific seam is removed/migrated, and git diff shows no Rust/storage/OCR/generated/pubspec changes. Untracked image artifacts are noted separately for parent cleanup/confirmation."
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
      "command": "git status --short --untracked-files=all && git diff --stat && git diff --name-only",
      "result": "passed",
      "summary": "Inspected worktree; renderer code/test changes plus three untracked image artifacts; no staged files."
    },
    {
      "command": "flutter analyze && flutter test test/reader_markdown_plan_test.dart test/brrk_reader_page_test.dart test/reader_paragraph_layout_test.dart test/reader_selection_test.dart test/renderer_integration_test.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart",
      "result": "passed",
      "summary": "Analyze clean; focused renderer/Paper/PDF tests passed 77/77."
    },
    {
      "command": "dart format --output=none --set-exit-if-changed lib/src/app/paper_book_detail_screen.dart lib/src/app/pdf_viewer_screen.dart lib/src/app/reader/brrk_reader_page.dart lib/src/app/reader/reader_markdown_plan.dart lib/src/app/reader/reader_paragraph_layout.dart lib/src/app/reader/reader_selection.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart test/brrk_reader_page_test.dart test/reader_markdown_plan_test.dart test/reader_paragraph_layout_test.dart test/reader_selection_test.dart test/renderer_integration_test.dart",
      "result": "passed",
      "summary": "Formatted 13 changed feature files; 0 would change."
    },
    {
      "command": "dart format --output=none --set-exit-if-changed lib test",
      "result": "failed",
      "summary": "Repo-wide format check reports 13 unrelated pre-existing files outside this renderer diff would change."
    },
    {
      "command": "git diff --cached --quiet",
      "result": "passed",
      "summary": "No staged files."
    }
  ],
  "validationOutput": [
    "flutter analyze: No issues found.",
    "focused flutter test: All tests passed (77/77).",
    "changed-feature-files dart format check: 0 changed.",
    "git diff --check: no whitespace errors.",
    "repo-wide dart format check: failed on unrelated files outside renderer diff."
  ],
  "residualRisks": [
    "Full flutter test not rerun in this review.",
    "Debug/release APK builds not rerun in this review.",
    "Physical-device Paper/PDF parity remains unverified and required by FEAT-SPEC acceptance.",
    "Three untracked image artifacts are present outside the renderer integration file list; exclude or confirm before commit.",
    "Repo-wide format gate currently fails on unrelated files outside the reviewed diff."
  ],
  "noStagedFiles": true,
  "diffSummary": "Adds shared BrrkReaderPage, strict native/legacy Markdown planner, shared paragraph layout and selection value; migrates Paper/PDF screens to the shared renderer; deletes obsolete Paper hyphenation seam/test; adds focused planner/page/layout/selection/parity coverage.",
  "reviewFindings": [
    "blocker: none",
    "note: remaining gates are full test/build and physical-device Paper/PDF parity",
    "note: untracked image artifacts are present outside the FEAT-SPEC renderer scope"
  ],
  "manualNotes": "Review-only. No source files were modified by this review. Findings written to /home/devuser/develop/brrk/subagent-artifacts/renderer-integration-review-final-4.md."
}
```

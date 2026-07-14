## Review
- Correct: The previously named planner cases are fixed for the tested forms. `# #hashtag` and `# #` now hit the `trimmed.startsWith('#')` fallback path in `lib/src/app/reader/reader_markdown_plan.dart:141-143`, and reference-style links/definitions are rejected by `_containsUnsupportedInline` / `_isUnsupportedBlock` at `lib/src/app/reader/reader_markdown_plan.dart:194,202-203`. Probe output confirmed all four cases returned `LegacyMarkdownPlan`.
- Correct: Paper and PDF both route page content through `BrrkReaderPage` (`lib/src/app/paper_book_detail_screen.dart:1094-1098`, `lib/src/app/pdf_viewer_screen.dart:625-629`), while strategy selection is inside `BrrkReaderPage` (`lib/src/app/reader/brrk_reader_page.dart:43-62`).
- Correct: The shared native paragraph path reuses the Paper stack (`EmergencyWordBreaker`, `HyphenatedText`, `AcademicSelectableText`, `ReaderTextLayoutSpec`) in `lib/src/app/reader/reader_paragraph_layout.dart:63-91,170-185`; I found no new PDF-specific hyphenation file/path and no `flutter_markdown` fork/copy/custom selection engine in the changed production paths.
- Correct: Native/fallback selection callbacks preserve `SelectionChangedCause` and fallback source offsets stay null (`lib/src/app/reader/brrk_reader_page.dart:168-185,210-229`; `lib/src/app/reader/reader_paragraph_layout.dart:127-165`). Paper converts exact native page-source UTF-16 offsets to UTF-8 byte offsets before note persistence (`lib/src/app/paper_book_detail_screen.dart:947-956`), matching the Rust/Dart byte-offset note contract (`rust/src/api/models.rs:245-250`, `lib/src/rust/api/models.dart:25-29`).
- Correct: Paper/PDF manual override, navigation/TOC/last-read, notes, and vocabulary code paths remain source-owned in the screens: Paper manual display at `lib/src/app/paper_book_detail_screen.dart:904-908`, Paper selection/note/vocab handling at `:924-997`; PDF page splitting/TOC at `lib/src/app/pdf_viewer_screen.dart:124-160`, selection clearing on navigation at `:471-484`, manual override at `:487-494`, PDF note/vocab handling at `:265-319,365-378`.
- Fixed: none by me; review-only task. Current diff removes the obsolete Paper seam/test and migrates coverage into shared reader tests.
- Blocker: The native planner is still too permissive for unsupported/ambiguous Markdown, so the strict native-subset gate is not complete. `_headingMatch` accepts `#  Heading` as native and computes the heading body from only one post-marker space (`lib/src/app/reader/reader_markdown_plan.dart:119-135,170-174`), but `package:markdown` renders that source as `<h1>Heading</h1>` (without the extra leading space). Also, the comment says escapes are rejected (`:170-174`), but `_containsUnsupportedInline` has no general backslash-escape check (`:199-210`), and `planReaderMarkdown(r'Escaped \[bracket]')` returns `NativeReaderPlan` while Markdown renders `Escaped [bracket]`. This violates FEAT-SPEC's requirement to fallback for constructs whose visible text/source mapping is ambiguous (`FEAT-SPEC.md:141-159`, `FEAT-SPEC.md:331-337`).
- Note: Validation I ran is clean aside from the planner probe: `flutter analyze` passed, and the focused renderer/Paper/PDF test suite passed 76/76. No staged files were present before writing this required review artifact. No Rust/storage/OCR/generated/pubspec changes are in the implementation diff.
- Note: Untracked docs/image files remain in the worktree (`docs/example-github-pages-design.jpg`, `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`, `example-layout.png`). They are not staged; keep them out of the renderer PR unless intentionally scoped.
- Note: Remaining physical-device gates: Paper/PDF parity on Android for native and fallback fixtures; Natural/Academic modes; visible hanging hyphens; selection gestures/handles/Copy/Add Note/Look up; Paper manual override/images/labels/notes/vocab; PDF manual override/TOC/navigation clearing/last-read/notes/vocab; portrait/landscape; debug and release APKs.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "not_satisfied",
      "evidence": "Scope is mostly contained, and the prior ATX/reference planner cases are fixed, but reader_markdown_plan.dart still accepts unsupported/ambiguous Markdown escapes and a non-canonical ATX spacing form as native instead of using the shared fallback. Untracked docs/images also remain outside FEAT-SPEC scope but are not staged."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Reviewed FEAT-SPEC.md, oracle scope, git status/diff, changed source/tests, planner probes, grep/find checks, flutter analyze, focused flutter tests, and no-staged-files status with cited file/line evidence."
    }
  ],
  "changedFiles": [
    "M lib/src/app/paper_book_detail_screen.dart",
    "M lib/src/app/pdf_viewer_screen.dart",
    "D lib/src/app/reader/hyphenation/paper_academic_hyphenation.dart",
    "?? lib/src/app/reader/brrk_reader_page.dart",
    "?? lib/src/app/reader/reader_markdown_plan.dart",
    "?? lib/src/app/reader/reader_paragraph_layout.dart",
    "?? lib/src/app/reader/reader_selection.dart",
    "M test/paper_book_detail_test.dart",
    "D test/paper_production_hyphenation_test.dart",
    "M test/pdf_viewer_screen_test.dart",
    "?? test/brrk_reader_page_test.dart",
    "?? test/reader_markdown_plan_test.dart",
    "?? test/reader_paragraph_layout_test.dart",
    "?? test/reader_selection_test.dart",
    "?? test/renderer_integration_test.dart",
    "?? docs/example-github-pages-design.jpg",
    "?? docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png",
    "?? example-layout.png"
  ],
  "testsAddedOrUpdated": [
    "M test/paper_book_detail_test.dart",
    "D test/paper_production_hyphenation_test.dart",
    "M test/pdf_viewer_screen_test.dart",
    "?? test/brrk_reader_page_test.dart",
    "?? test/reader_markdown_plan_test.dart",
    "?? test/reader_paragraph_layout_test.dart",
    "?? test/reader_selection_test.dart",
    "?? test/renderer_integration_test.dart"
  ],
  "commandsRun": [
    {
      "command": "git status --short && git diff --stat && git diff --name-only",
      "result": "passed",
      "summary": "Enumerated modified/deleted tracked files and untracked shared reader/test/docs-image files."
    },
    {
      "command": "flutter analyze && flutter test test/reader_markdown_plan_test.dart test/brrk_reader_page_test.dart test/reader_paragraph_layout_test.dart test/reader_selection_test.dart test/renderer_integration_test.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart",
      "result": "passed",
      "summary": "Analyze clean; focused renderer/Paper/PDF tests passed 76/76."
    },
    {
      "command": "dart --packages=.dart_tool/package_config.json /tmp/check_reader_plan_final_cases.dart",
      "result": "passed",
      "summary": "Confirmed # #hashtag, # #, reference link+definition, and reference definition only now return LegacyMarkdownPlan; backslash escape still returns NativeReaderPlan."
    },
    {
      "command": "dart --packages=.dart_tool/package_config.json /tmp/check_markdown_escape.dart",
      "result": "passed",
      "summary": "Confirmed package:markdown renders escaped brackets/punctuation without backslashes and trims #  Heading to Heading."
    },
    {
      "command": "git diff --cached --name-only; git status --short --untracked-files=all; git diff --name-only",
      "result": "passed",
      "summary": "Confirmed no staged files; implementation diff excludes Rust/storage/OCR/generated/pubspec files."
    },
    {
      "command": "grep/find inspections for flutter_markdown, PaperAcademicHyphenation/PaperHyphenation, PDF hyphenation, custom selection/line-composer terms",
      "result": "passed",
      "summary": "No remaining PaperAcademicHyphenation references, no changed PDF-specific hyphenation path, and no fork/custom selection engine found in changed production paths."
    }
  ],
  "validationOutput": [
    "flutter analyze: No issues found! (ran in 2.1s)",
    "focused flutter test: 00:02 +76: All tests passed!",
    "planner probe: unsupported atx hashtag/reference cases => LegacyMarkdownPlan; backslash escape => NativeReaderPlan",
    "markdown probe: Escaped \\[bracket] => <p>Escaped [bracket]</p>; #  Heading => <h1>Heading</h1>",
    "git diff --cached --name-only: no output (no staged files)"
  ],
  "residualRisks": [
    "Blocker: strict native planner still accepts backslash escapes and #  Heading-style ambiguous ATX spacing as native.",
    "Physical-device Paper/PDF parity gates remain before completion can be claimed.",
    "Full flutter test and debug/release APK builds are still planned after final planner fix.",
    "Untracked docs/image files are present outside FEAT-SPEC scope but are not staged."
  ],
  "noStagedFiles": true,
  "diffSummary": "Adds shared BrrkReaderPage, ReaderMarkdownPlan, ReaderParagraphLayout/BrrkReaderParagraph, and ReaderSelection; migrates Paper and PDF screens to BrrkReaderPage; removes the old Paper-specific hyphenation seam/test; updates/adds focused shared/Paper/PDF/parity tests. Untracked docs/image files are also present.",
  "reviewFindings": [
    "blocker: lib/src/app/reader/reader_markdown_plan.dart:119-135,170-174,199-210 - planner still accepts ambiguous Markdown escapes and #  Heading as native instead of shared fallback.",
    "note: prior named ATX forms (# #hashtag, # #) and reference-style link/definition cases now fallback.",
    "note: no staged files; no Rust/storage/OCR/generated/pubspec changes detected in the implementation diff.",
    "note: physical-device Paper/PDF parity remains required."
  ],
  "manualNotes": "Review-only: no implementation files were edited by me. This report was written to the required subagent artifact path."
}
```

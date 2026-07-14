## Review
- Correct: Paper and PDF now both route reader content through `BrrkReaderPage`: Paper at `lib/src/app/paper_book_detail_screen.dart:1094-1098`, PDF at `lib/src/app/pdf_viewer_screen.dart:625-629`. The screen code does not branch on render strategy.
- Correct: `BrrkReaderPage` owns the plan/strategy switch and fallback body (`lib/src/app/reader/brrk_reader_page.dart:51-63`, `206-244`), matching FEAT-SPEC's shared-renderer direction (`FEAT-SPEC.md:114-159`, `427-445`).
- Correct: The source-neutral paragraph layout reuses the existing Paper stack rather than duplicating it: `EmergencyWordBreaker`, `HyphenatedText`, `AcademicSelectableText`, and `ReaderTextLayoutSpec` are imported/used in `lib/src/app/reader/reader_paragraph_layout.dart:4-8`, `68-91`, `180-184`. No PDF-specific hyphenation class/path was found.
- Correct: Legacy fallback emits null page-source offsets and preserves `SelectionChangedCause` in `lib/src/app/reader/brrk_reader_page.dart:210-230`; native paragraph/heading events also preserve cause in `lib/src/app/reader/reader_paragraph_layout.dart:127-166` and `lib/src/app/reader/brrk_reader_page.dart:168-186`.
- Correct: Paper note offsets are converted from exact native code-unit offsets to UTF-8 byte offsets before being passed to note persistence (`lib/src/app/paper_book_detail_screen.dart:947-956`), aligning with the Rust/Dart byte-offset contract (`rust/src/api/models.rs:245-250`, `lib/src/rust/api/models.dart:25-29`). Fallback offsets remain null by construction.
- Correct: No Rust/storage/OCR/generated/native config files are in the worktree diff. `git diff --name-status` only lists app/test renderer files plus the deleted Paper seam/test; untracked docs/example images are still present but not staged.
- Correct: Deletion of `paper_academic_hyphenation.dart` is functionally migrated into `ReaderParagraphLayout` (`lib/src/app/reader/reader_paragraph_layout.dart:10-91`). Much of `paper_production_hyphenation_test.dart` is migrated into `test/reader_paragraph_layout_test.dart:17-98` and paragraph widget tests at `test/reader_paragraph_layout_test.dart:100-166`, but integration coverage gaps remain below.
- Fixed: none; review-only task, no source files modified.
- Blocker: Native planner is too permissive and can render unsupported Markdown natively instead of using the shared fallback. `planReaderMarkdown` trims each line (`lib/src/app/reader/reader_markdown_plan.dart:87-90`) and processes comments/horizontal rules/headings before the indentation fallback (`lib/src/app/reader/reader_markdown_plan.dart:101-137`), so inputs such as a four-space indented heading or rule can be treated as native heading/rule rather than indented-code fallback. Also, the heading comment says trailing `#` closers are rejected, but the regex accepts bodies containing trailing `#` (`lib/src/app/reader/reader_markdown_plan.dart:163-168`), so `# Heading #` becomes native text `Heading #` and bypasses `MarkdownBody`. This violates the strict native subset and fallback requirements in `FEAT-SPEC.md:131-159` and `FEAT-SPEC.md:442-445`.
- Blocker: Required acceptance coverage is still incomplete. FEAT-SPEC requires Paper tests for note actions, vocabulary lookup, visible hanging hyphens, and unsupported formatting fallback (`FEAT-SPEC.md:622-631`) and PDF tests for page splitting/TOC, navigation clearing selection, notes/vocabulary, same Academic paragraph widget, and fallback formatting (`FEAT-SPEC.md:633-643`). Current changed integration tests only assert shared reader routing/alignment for Paper (`test/paper_book_detail_test.dart:225-282`) and natural shared-reader routing for PDF (`test/pdf_viewer_screen_test.dart:107-130`). The planner tests also miss the overly-permissive cases above, despite the oracle requiring indented block and ambiguous-mapping fallback tests (`renderer-integration-oracle.md:56-63`).
- Note: Generated soft hyphen leakage was not found in the normal Academic path: selections are mapped back through `HyphenatedText` before `ReaderSelection` creation (`lib/src/app/reader/reader_paragraph_layout.dart:141-166`), and fallback does not run Emergency word breaking. If source Markdown can already contain U+00AD, add explicit coverage/handling; the Natural path preserves source text as-is (`lib/src/app/reader/reader_paragraph_layout.dart:77-83`).
- Note: I did not find a Paper/PDF navigation/manual/notes/vocab code regression in the inspected paths: Paper page changes clear selection (`lib/src/app/paper_book_detail_screen.dart:910-921`), PDF page jumps clear selection and preserve last-read behavior (`lib/src/app/pdf_viewer_screen.dart:471-484`), PDF manual override lookup remains in `_currentPageContent` (`lib/src/app/pdf_viewer_screen.dart:487-494`), and PDF vocab source remains `VocabSource.pdf(...)` (`lib/src/app/pdf_viewer_screen.dart:371-378`). The missing tests above are still an acceptance blocker.
- Note: Remaining physical-device gate: FEAT-SPEC requires physical Paper/PDF parity before completion (`FEAT-SPEC.md:657-677`). User-supplied validation says physical device testing has not yet been performed. Required manual gate should cover native and fallback fixtures in Paper and PDF, Natural/Academic, visible hanging hyphens, selection gestures/handles, Copy/Add Note/Look up, portrait/landscape, and debug/release APKs.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "not_satisfied",
      "evidence": "Renderer migration is mostly in scope, but the native Markdown planner accepts unsupported/ambiguous Markdown natively (reader_markdown_plan.dart:87-137, 163-168), violating FEAT-SPEC.md:131-159 and FEAT-SPEC.md:442-445. Required integration/planner tests are also missing."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Reviewed FEAT-SPEC.md, oracle scope, current tracked diff, untracked added files, deleted Paper seam/test, relevant source paths, tests, grep evidence, git status, no-staged-files, merge-base, and git diff --check. Findings cite concrete paths and line numbers."
    }
  ],
  "changedFiles": [
    "M lib/src/app/paper_book_detail_screen.dart",
    "M lib/src/app/pdf_viewer_screen.dart",
    "D lib/src/app/reader/hyphenation/paper_academic_hyphenation.dart",
    "M test/paper_book_detail_test.dart",
    "D test/paper_production_hyphenation_test.dart",
    "M test/pdf_viewer_screen_test.dart",
    "?? docs/example-github-pages-design.jpg",
    "?? docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png",
    "?? example-layout.png",
    "?? lib/src/app/reader/brrk_reader_page.dart",
    "?? lib/src/app/reader/reader_markdown_plan.dart",
    "?? lib/src/app/reader/reader_paragraph_layout.dart",
    "?? lib/src/app/reader/reader_selection.dart",
    "?? test/brrk_reader_page_test.dart",
    "?? test/reader_markdown_plan_test.dart",
    "?? test/reader_paragraph_layout_test.dart",
    "?? test/reader_selection_test.dart",
    "?? test/renderer_integration_test.dart"
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
      "command": "pwd && git status --short --branch && git branch --show-current && git diff --name-status && git diff --stat",
      "result": "passed",
      "summary": "Confirmed branch feat/renderer-integration and enumerated tracked/untracked worktree changes."
    },
    {
      "command": "nl -ba FEAT-SPEC.md /tmp/pi-subagents-uid-1000/chain-runs/92c8088d/subagent-artifacts/renderer-integration-oracle.md and relevant lib/test files",
      "result": "passed",
      "summary": "Collected line-numbered evidence for spec requirements, oracle scope, implementation, deleted seam/test migration, and test coverage."
    },
    {
      "command": "grep for flutter_markdown/MarkdownBody, PaperAcademicHyphenation/PaperHyphenationRender, hyphenation stack classes, and custom selection/line-composer terms",
      "result": "passed",
      "summary": "Verified no remaining PaperAcademicHyphenation references, shared fallback lives in BrrkReaderPage, and no new PDF-specific hyphenation/custom selection path was found."
    },
    {
      "command": "git merge-base --is-ancestor origin/main HEAD && echo origin-main-is-ancestor || echo origin-main-is-not-ancestor",
      "result": "passed",
      "summary": "origin/main is an ancestor of HEAD."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "No whitespace errors reported."
    },
    {
      "command": "git status --short --untracked-files=all && test -z \"$(git diff --cached --name-only)\" && echo no-staged-files",
      "result": "passed",
      "summary": "No staged files; worktree has tracked changes and untracked files listed above."
    }
  ],
  "validationOutput": [
    "Reviewer-ran: git diff --check passed with no output.",
    "Reviewer-ran: git merge-base --is-ancestor origin/main HEAD passed.",
    "Reviewer-ran: no staged files confirmed before writing this artifact.",
    "User-supplied validation: flutter analyze clean; flutter test 270/270 passed; debug and release APK builds passed; git diff --check passed; touched-file format check passed.",
    "User-supplied validation: full-tree dart format check reports pre-existing unrelated formatting drift in 13 files.",
    "User-supplied validation: physical device parity not yet tested."
  ],
  "residualRisks": [
    "Blocker remains: native planner must reject/fallback ambiguous unsupported Markdown such as indented code-like headings/rules and ATX closing-marker headings.",
    "Blocker remains: required Paper/PDF integration and planner coverage is incomplete.",
    "Physical Android Paper/PDF parity gate remains before completion can be claimed.",
    "Untracked unrelated image files remain in the worktree; they were not reviewed as part of renderer integration."
  ],
  "noStagedFiles": true,
  "diffSummary": "Adds shared BrrkReaderPage, ReaderMarkdownPlan, ReaderParagraphLayout/BrrkReaderParagraph, and ReaderSelection; migrates Paper and PDF screens to BrrkReaderPage; removes the Paper-specific hyphenation seam and production hyphenation test; updates/adds renderer tests. Untracked unrelated images are present.",
  "reviewFindings": [
    "blocker: lib/src/app/reader/reader_markdown_plan.dart:87-137 and 163-168 - planner accepts unsupported/ambiguous Markdown as native, including indented heading/rule-like lines and ATX headings with closing # markers, bypassing the shared flutter_markdown fallback.",
    "blocker: test/paper_book_detail_test.dart:225-282 and test/pdf_viewer_screen_test.dart:107-130 - required Paper/PDF notes, vocabulary, fallback formatting, navigation/TOC, and visible-hyphen integration coverage is missing; planner tests also miss the bad native cases.",
    "note: physical-device Paper/PDF parity has not been run and remains a completion gate.",
    "note: no flutter_markdown fork/copy, no PDF-specific hyphenation, no custom selection engine, no Rust/storage/OCR/generated changes, and no staged files were found."
  ],
  "manualNotes": "Do not claim feature completion until the planner blocker and coverage blocker are fixed and physical-device parity is completed. The Paper-specific seam deletion is functionally migrated, but integration coverage from the deleted test is only partially replaced."
}
```

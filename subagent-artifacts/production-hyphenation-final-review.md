## Review
- Correct: Current branch is `feat/production-reader-hyphenation`; I inspected the current tracked diff, untracked files, `SPEC.md` visible-hyphen/canonical-operation requirements, `FEAT-SPEC.md` mapping/Paper integration/fallback requirements, and prior review artifacts for Phase B/visible-hyphen blockers. Formatting blocker is resolved for touched Dart files: `dart format --output=none --set-exit-if-changed ...` reported `Formatted 13 files (0 changed)`.
- Correct: Selection cause is preserved through the Paper Academic path. `AcademicSelectableText` forwards `(selection, cause)` from its primary `SelectableText` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:80-96`), `_PaperBodyText` forwards the same `(selection, cause)` to its caller (`lib/src/app/paper_book_detail_screen.dart:1174-1178`), and `_PageViewState._handleSelectionChanged` passes `cause` into `vocabularyCandidateFromSelection` (`lib/src/app/paper_book_detail_screen.dart:952-988`). The wrapper test covers `SelectionChangedCause.longPress` and `tap` forwarding (`test/academic_selectable_text_test.dart:162-208`).
- Correct: `HyphenatedText` preserves reversed selection base/extent by mapping `baseOffset` and `extentOffset` independently (`lib/src/app/reader/hyphenation/hyphenated_text.dart:127-140`). The regression test asserts a reversed display selection remains reversed in canonical coordinates (`test/hyphenated_text_test.dart:65-82`).
- Correct: Natural remains the default and release hyphenation remains no-op. `ReadingAppearance` defaults to `ReaderLayoutMode.natural` (`lib/src/app/reading_appearance.dart:217-222`); Paper resolves to `PaperAcademicHyphenation.withReleaseNoop()` unless a test-only override is installed (`lib/src/app/paper_book_detail_screen.dart:858-873`); the default provider returns `NoopHyphenationService` (`lib/src/app/reader/hyphenation/hyphenation_provider.dart:18-30`), whose `breakOffsets` always returns an empty list (`lib/src/app/reader/hyphenation/hyphenation_service.dart:68-82`). Tests verify Natural uses one canonical `SelectableText`, Academic/no-op uses justified canonical text with no `U+00AD`, and fake/test-only backend is the only path that enables overlay markers (`test/paper_production_hyphenation_test.dart:80-155`, `test/paper_production_hyphenation_test.dart:158-215`).
- Correct: No real `-`, `U+2010`, or newline is inserted into production selectable content to fake hyphenation. `HyphenatedText.fromInsertionOffsets` writes source code units and only `U+00AD` markers (`lib/src/app/reader/hyphenation/hyphenated_text.dart:73-87`); `VisibleHyphenPainter` paints the decorative `U+2010` separately (`lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:101-122`, `lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:216-225`, `lib/src/app/reader/hyphenation/visible_hyphen_painter.dart:280-287`); `AcademicSelectableText` keeps the decorative layer inside `IgnorePointer` + `ExcludeSemantics` (`lib/src/app/reader/hyphenation/academic_selectable_text.dart:98-107`). Debug-gate hard-hyphen/newline examples remain in `SelectionGateScreen` only and are not the production Paper path.
- Correct: U+00AD/decorative hyphen artifacts remain display-only for app actions. Paper maps the display selection back through `render.canonicalSelection(...)` before Add Note / Look up / vocabulary candidate recovery (`lib/src/app/paper_book_detail_screen.dart:971-996`), and lookup passes `pageContext: _render().sourceText` rather than display text (`lib/src/app/paper_book_detail_screen.dart:1019-1027`). Export still uses the page manual/OCR markdown (`lib/src/app/paper_book_detail_screen.dart:1200-1214`), not `render.displayText`.
- Correct: No PDF/Rust/storage/OCR/generated/pubspec/dictionary changes were found. The relevant status check returned no output for `pubspec.yaml`, `pubspec.lock`, Rust/generated paths, Android/assets/notices, PDF, OCR, and hyphenation-asset paths; `git ls-files --others --exclude-standard` showed only unrelated images plus the new Dart hyphenation scaffold/tests.
- Correct: Validation is clean. I reran `flutter analyze` (`No issues found`), focused hyphenation tests (`37/37`, all passed), full `flutter test` (`212/212`, all passed), `git diff --check` (no output), and staged-file checks (no staged files). Parent-reported debug and release APK builds also passed.
- Fixed: none; review only.
- Blocker: none.
- Note: Remaining gates before enabling real release hyphenation: choose/approve a dictionary/backend and record package/dictionary licenses; keep release default no-op until that decision; run the physical-device Paper overlay/copy/selection/TalkBack matrix with real markers in debug and release; validate representative academic pages; keep PDF hyphenation behind its separate feasibility gate; run release/Rust/appbundle gates if preparing Play/release artifacts. Unrelated untracked images remain present and should be excluded unless intentionally scoped.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Inspected current branch/diff/status, SPEC.md §§15.3.1-15.3.3, FEAT-SPEC.md §§7-8/10-12/17-18, prior Phase B and visible-hyphen review artifacts, current Paper/AcademicSelectableText/HyphenatedText/HyphenationService/ReaderHyphenator code, and focused/full tests. Formatting was directly rechecked with dart format reporting 0 changed files."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Blocker: none."
    }
  ],
  "changedFiles": [
    "M lib/src/app/paper_book_detail_screen.dart",
    "M lib/src/app/reader/hyphenation/academic_selectable_text.dart",
    "M lib/src/app/reader/hyphenation/hyphenated_text.dart",
    "M lib/src/app/reader/hyphenation/selection_gate_screen.dart",
    "M test/academic_selectable_text_test.dart",
    "?? lib/src/app/reader/hyphenation/debug_fake_hyphenation_provider.dart",
    "?? lib/src/app/reader/hyphenation/hyphenation_provider.dart",
    "?? lib/src/app/reader/hyphenation/hyphenation_service.dart",
    "?? lib/src/app/reader/hyphenation/paper_academic_hyphenation.dart",
    "?? lib/src/app/reader/hyphenation/reader_hyphenator.dart",
    "?? test/hyphenated_text_test.dart",
    "?? test/paper_production_hyphenation_test.dart",
    "?? test/reader_hyphenator_test.dart",
    "?? docs/example-github-pages-design.jpg (unrelated/unreviewed image)",
    "?? docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png (unrelated/unreviewed image)",
    "?? example-layout.png (unrelated/unreviewed image)"
  ],
  "testsAddedOrUpdated": [
    "test/academic_selectable_text_test.dart",
    "test/hyphenated_text_test.dart",
    "test/paper_production_hyphenation_test.dart",
    "test/reader_hyphenator_test.dart"
  ],
  "commandsRun": [
    {
      "command": "git status --short && git diff --name-status && git diff --cached --name-status",
      "result": "passed",
      "summary": "Enumerated tracked/untracked changes and confirmed no staged files."
    },
    {
      "command": "git branch --show-current && git rev-parse --abbrev-ref HEAD",
      "result": "passed",
      "summary": "Confirmed branch feat/production-reader-hyphenation."
    },
    {
      "command": "dart format --output=none --set-exit-if-changed <13 touched Dart files>",
      "result": "passed",
      "summary": "Formatted 13 files (0 changed); formatting blocker resolved for touched files."
    },
    {
      "command": "flutter test test/academic_selectable_text_test.dart test/hyphenated_text_test.dart test/paper_production_hyphenation_test.dart test/reader_hyphenator_test.dart",
      "result": "passed",
      "summary": "Focused hyphenation tests passed, 37/37."
    },
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "No issues found."
    },
    {
      "command": "flutter test",
      "result": "passed",
      "summary": "Full Flutter test suite passed, 212/212."
    },
    {
      "command": "git diff --check && git diff --cached --name-status && git status --short",
      "result": "passed",
      "summary": "No whitespace errors, no staged files; worktree changes remain unstaged."
    },
    {
      "command": "git status --short -- pubspec.yaml pubspec.lock rust lib/src/rust android assets THIRD_PARTY_NOTICES lib/src/rust/frb_generated.dart rust/src/frb_generated.rs lib/src/app/pdf_viewer_screen.dart lib/src/app/ocr_disclosure.dart lib/src/app/camera_screen.dart lib/src/app/reader/hyphenation/assets assets/hyphenation",
      "result": "passed",
      "summary": "No PDF/Rust/storage/OCR/generated/pubspec/dictionary/asset/notices changes reported."
    },
    {
      "command": "flutter build apk --debug",
      "result": "passed",
      "summary": "Parent-reported after formatting; not rerun by this reviewer."
    },
    {
      "command": "flutter build apk --release",
      "result": "passed",
      "summary": "Parent-reported after formatting; not rerun by this reviewer."
    }
  ],
  "validationOutput": [
    "dart format: Formatted 13 files (0 changed) in 0.06 seconds.",
    "flutter analyze: No issues found!",
    "focused flutter test: +37 All tests passed!",
    "full flutter test: +212 All tests passed!",
    "git diff --check: no output.",
    "git diff --cached --name-status: no output; no staged files.",
    "relevant PDF/Rust/storage/OCR/generated/pubspec/dictionary status check: no output.",
    "parent-reported flutter build apk --debug: passed.",
    "parent-reported flutter build apk --release: passed."
  ],
  "residualRisks": [
    "Automatic release hyphenation is intentionally still no-op until a dictionary/backend and redistribution license are approved and documented.",
    "Physical Android debug/release overlay/copy/selection/TalkBack validation with real markers remains a gate before enabling real release hyphenation.",
    "PDF hyphenation remains a separate feasibility gate and is unchanged in this branch.",
    "Debug/release APK builds were parent-reported passed; this reviewer did not rerun builds.",
    "Unrelated untracked image files remain in the worktree and should be excluded unless intentionally scoped."
  ],
  "noStagedFiles": true,
  "notes": "Review artifact only; no source files were modified by this review."
}
```

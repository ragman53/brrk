## Review

- Blocker: none found in the Phase A text-layout diff.

- Correct: Phase A scope matches the oracle-approved boundaries. The implemented code adds the `ReaderLayoutMode` model/default/persistence in `lib/src/app/reading_appearance.dart:14-23`, `lib/src/app/reading_appearance.dart:217-222`, and `lib/src/app/reading_appearance.dart:306-333`; applies Paper-only alignment via one `SelectableText` in `lib/src/app/paper_book_detail_screen.dart:1080-1086`; and keeps PDF to typography/surface only while preserving `Markdown(selectable: true)` in `lib/src/app/pdf_viewer_screen.dart:586-638`. I found no pubspec/Rust/storage/OCR/model changes and no production soft-hyphen/hyphenation integration.

- Correct: Natural/default and persistence behavior are safe. Natural remains the constructor default (`lib/src/app/reading_appearance.dart:217-222`) and the SharedPreferences fallback (`lib/src/app/reading_appearance.dart:319-323`); invalid or absent persisted layout values fall back to Natural. Academic is opt-in through `setLayoutMode` (`lib/src/app/reading_appearance.dart:358-362`).

- Correct: UI copy is honest for Phase A. The Layout control says Natural is left-aligned with consistent word spacing and Academic is justified with word spacing that may vary by line (`lib/src/app/reading_appearance.dart:151-172`), which avoids the FEAT-SPEC-forbidden claim that Academic has uniform/fixed spacing.

- Correct: Typography and reader surface match the approved Phase A values: default 17sp/range 12-32 (`lib/src/app/reading_appearance.dart:207-210`), density line heights/paragraph spacing with letter spacing 0 (`lib/src/app/reading_appearance.dart:26-38`), body/paragraph `letterSpacing: 0.0` (`lib/src/app/reading_appearance.dart:253-260`, `lib/src/app/reading_appearance.dart:284-291`), and a small centered constrained `ReaderSurface` with 640dp max width and 18/24dp horizontal padding (`lib/src/app/reader/reader_surface.dart:15-61`).

- Correct: Selection-offset safety is preserved for Phase A because no display/source text transform is introduced. Paper still selects from the canonical displayed string (`lib/src/app/paper_book_detail_screen.dart:902-906`), clamps/stores offsets on that same string (`lib/src/app/paper_book_detail_screen.dart:925-952`), sends raw selected text/offsets to Add Note (`lib/src/app/paper_book_detail_screen.dart:955-960`), and sends canonical page context/lookup offsets to lookup (`lib/src/app/paper_book_detail_screen.dart:972-980`). Since there are no inserted soft hyphens, display/source offset mapping is not needed yet.

- Correct: PDF safety is preserved. The PDF body remains `Markdown` with `selectable: true` and the existing `onSelectionChanged` note/lookup state path (`lib/src/app/pdf_viewer_screen.dart:586-625`). The style sheet still applies typography only (`lib/src/app/pdf_viewer_screen.dart:626-637`); it does not apply Academic justification or hyphenation before the PDF feasibility gate.

- Correct: Tests were added/updated for the Phase A surface: default font size, density values, letter spacing, layout mode default/persistence/alignment mapping (`test/reading_appearance_test.dart:60-127`); Paper Natural/Academic alignment and exactly one `SelectableText` (`test/paper_book_detail_test.dart:224-280`); and ReaderSurface padding/max-width (`test/reader_surface_test.dart:7-31`). Existing Paper tests still cover manual Markdown display remaining canonical (`test/paper_book_detail_test.dart:170-191`), and existing PDF tests still cover manual override and non-justified natural Markdown behavior (`test/pdf_viewer_screen_test.dart:64-117`).

- Note: `wordSpacing` is not explicitly pinned to `0.0` in `bodyStyle` or `paragraphStyle` (`lib/src/app/reading_appearance.dart:253-260`, `lib/src/app/reading_appearance.dart:284-291`) even though FEAT-SPEC lists a word-spacing baseline of 0 (`FEAT-SPEC.md:267-276`). Current repo code has no other `wordSpacing` override, so the effective behavior is still the default/no extra fixed spacing; if strict hardening is desired, the smallest follow-up is to add `wordSpacing: 0.0` to both styles and assert it in `test/reading_appearance_test.dart`.

- Note: The shared `ReadingAppearanceControls` are available from PDF (`lib/src/app/pdf_viewer_screen.dart:480-485`), so users can choose Academic while PDF body alignment intentionally remains unchanged in Phase A (`lib/src/app/pdf_viewer_screen.dart:626-637`). This matches the oracle's PDF-typography/surface-only gate, but it is a UX limitation to document until the PDF feasibility gate is completed.

- Note: `git status --short --untracked-files=all` shows unrelated untracked docs images (`docs/example-github-pages-design.jpg`, `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`). They are not part of the worker's text-layout changed-file list and should be excluded from a text-layout commit unless intentionally handled separately.

- Fixed: none. I did not modify project/source files; I only wrote this requested ignored review artifact.

### Evidence

- Changed source/test files reviewed: `lib/src/app/reading_appearance.dart`, `lib/src/app/reader/reader_surface.dart`, `lib/src/app/paper_book_detail_screen.dart`, `lib/src/app/pdf_viewer_screen.dart`, `test/reading_appearance_test.dart`, `test/reader_surface_test.dart`, `test/paper_book_detail_test.dart`.
- Other untracked files observed: `docs/example-github-pages-design.jpg`, `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`.
- Commands run by reviewer:
  - `git status --short --untracked-files=all && git diff --cached --name-only && git diff --name-only && git ls-files --others --exclude-standard` — passed; no staged files.
  - `git diff --check` — passed.
  - `flutter test test/reading_appearance_test.dart test/reader_surface_test.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart` — passed, 41 tests.
  - `rg -n ... lib test pubspec.yaml pubspec.lock` and `git diff -- pubspec.yaml pubspec.lock ...` — passed; no new hyphenation/pubspec/Rust/storage/OCR changes found.
- Validation reported by prompt/worker: `flutter analyze` passed, full `flutter test` passed 138/138, `flutter build apk --debug` passed, and `git diff --check` passed.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Reviewed the current branch diff against FEAT-SPEC.md typography/layout/PDF/acceptance sections and oracle Phase A scope in subagent-artifacts/text-layout-oracle.md lines 40-57. No blockers found; implementation stays within Phase A."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Concrete findings cite file/line evidence for reading_appearance.dart, paper_book_detail_screen.dart, pdf_viewer_screen.dart, reader_surface.dart, and the updated tests."
    },
    {
      "id": "criterion-3",
      "status": "satisfied",
      "evidence": "No project/source files were modified by this review; only the requested ignored artifact subagent-artifacts/text-layout-review.md was written. git diff --cached --name-only remained empty before artifact write."
    }
  ],
  "changedFiles": [
    "lib/src/app/paper_book_detail_screen.dart",
    "lib/src/app/pdf_viewer_screen.dart",
    "lib/src/app/reading_appearance.dart",
    "lib/src/app/reader/reader_surface.dart",
    "test/paper_book_detail_test.dart",
    "test/reading_appearance_test.dart",
    "test/reader_surface_test.dart",
    "docs/example-github-pages-design.jpg (untracked, unrelated to reviewed feature)",
    "docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png (untracked, unrelated to reviewed feature)"
  ],
  "testsAddedOrUpdated": [
    "test/reading_appearance_test.dart",
    "test/reader_surface_test.dart",
    "test/paper_book_detail_test.dart"
  ],
  "commandsRun": [
    {
      "command": "git status --short --untracked-files=all && git diff --cached --name-only && git diff --name-only && git ls-files --others --exclude-standard",
      "result": "passed",
      "summary": "Confirmed modified/untracked files and no staged files."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "No whitespace errors."
    },
    {
      "command": "flutter test test/reading_appearance_test.dart test/reader_surface_test.dart test/paper_book_detail_test.dart test/pdf_viewer_screen_test.dart",
      "result": "passed",
      "summary": "All targeted changed-area tests passed, 41 tests."
    },
    {
      "command": "rg -n soft-hyphen/hyphenation/ReaderSurface/TextAlign.justify scan and git diff -- pubspec/Rust/storage/OCR paths",
      "result": "passed",
      "summary": "No production soft-hyphen/hyphenation dependency, pubspec, Rust, storage, or OCR changes found."
    }
  ],
  "validationOutput": [
    "Reviewer run: git diff --check passed.",
    "Reviewer run: targeted flutter test command passed, 41 tests.",
    "Prompt/worker reported: flutter analyze passed with no issues.",
    "Prompt/worker reported: full flutter test passed, 138/138.",
    "Prompt/worker reported: flutter build apk --debug passed.",
    "Prompt/worker reported: git diff --check passed."
  ],
  "residualRisks": [
    "Full FEAT-SPEC remains gated: no real-device selection gate, no production hyphenation, no dictionary/license decision, and no PDF feasibility gate in Phase A.",
    "Academic mode without hyphenation can still show uneven word spacing; UI copy is honest about this.",
    "wordSpacing is effectively default/no extra spacing but not explicitly asserted as 0.0 in code/tests.",
    "PDF exposes the shared Layout control but intentionally does not apply Academic justification in Phase A.",
    "Unrelated untracked docs images are present in the worktree and should not be included in the text-layout commit unless intentional."
  ],
  "noStagedFiles": true,
  "notes": "Review findings: no blockers. Smallest optional follow-ups are to explicitly set/test wordSpacing: 0.0 and to document or contextualize the PDF Layout control until the PDF gate is completed."
}
```
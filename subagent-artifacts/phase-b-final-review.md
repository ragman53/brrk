## Review
- Blocker: none found in the corrected Phase B diff.

### Evidence reviewed
- Prior Markdown nesting blocker is resolved: the gate body is a parent `ListView` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:241-244`), and the nested `Markdown` is now `shrinkWrap: true` with `NeverScrollableScrollPhysics` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:278-284`).
- Prior Markdown mapping blocker is resolved: the Markdown callback stores the callback-visible `text` in `_mdLastText` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:125-132`), and `_mdObservation()` maps from that display text via `SoftHyphenMapping.fromDisplayText(display)` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:200-213`; helper at `lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart:92-117`).
- Prior narrow-width blocker is resolved: both gate surfaces are wrapped in `Center` + `SizedBox(width: 280)` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:247-249`, `lib/src/app/reader/hyphenation/selection_gate_screen.dart:270-272`).
- Scope remains non-production for hyphenation: the gate is explicitly marked spike-only and not for Paper/PDF, Add Note, vocabulary, Rust, OCR, or storage writes (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:3-12`), and the Settings entry is guarded by `if (kDebugMode)` (`lib/src/app/settings_screen.dart:416-438`). A dependency/Rust/storage/OCR diff check produced no output.
- Mapping tests cover callback/display-text canonicalization and soft-hyphen boundaries (`test/soft_hyphen_mapping_test.dart:131-154`) plus clamping/reversed/multiple-soft-hyphen cases (`test/soft_hyphen_mapping_test.dart:65-129`).

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "No blockers found. The corrected Phase B changes remain limited to the debug-only soft-hyphen selection gate, spike mapping helper, kDebugMode Settings entry, and mapping tests; no pubspec/dependency, Rust/storage/OCR, or production Paper/PDF soft-hyphen integration was found."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "This final review records changed files, tests, inspection commands, validation status, residual risks, no-staged-files status, and file/line evidence for each previously blocked area."
    }
  ],
  "changedFiles": [
    "lib/src/app/settings_screen.dart",
    "lib/src/app/reader/hyphenation/selection_gate_screen.dart (untracked, reviewed)",
    "lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart (untracked, reviewed)",
    "test/soft_hyphen_mapping_test.dart (untracked, reviewed)",
    "pre-existing Phase A dirty files also present: lib/src/app/paper_book_detail_screen.dart, lib/src/app/pdf_viewer_screen.dart, lib/src/app/reading_appearance.dart, lib/src/app/reader/reader_surface.dart, test/paper_book_detail_test.dart, test/reading_appearance_test.dart, test/reader_surface_test.dart",
    "unrelated untracked docs images remain present: docs/example-github-pages-design.jpg, docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png"
  ],
  "testsAddedOrUpdated": [
    "test/soft_hyphen_mapping_test.dart",
    "test/reader_surface_test.dart (pre-existing Phase A dirty file)",
    "test/paper_book_detail_test.dart (pre-existing Phase A dirty file)",
    "test/reading_appearance_test.dart (pre-existing Phase A dirty file)"
  ],
  "commandsRun": [
    {
      "command": "git status --short && git diff --stat && git diff --name-only",
      "result": "passed",
      "summary": "Confirmed tracked dirty files and untracked Phase B/Phase A files plus unrelated docs images."
    },
    {
      "command": "git diff -- . ':(exclude)subagent-artifacts/phase-b-final-review.md'",
      "result": "passed",
      "summary": "Reviewed tracked Phase A/Phase B diff."
    },
    {
      "command": "nl -ba lib/src/app/reader/hyphenation/selection_gate_screen.dart | sed -n '1,80p'",
      "result": "passed",
      "summary": "Verified spike-only comments and fixed hand-authored U+00AD gate examples."
    },
    {
      "command": "nl -ba lib/src/app/reader/hyphenation/selection_gate_screen.dart | sed -n '100,290p'",
      "result": "passed",
      "summary": "Verified callback-visible Markdown text handling, parent ListView, Center/SizedBox width, and shrinkWrapped/non-scrolling Markdown."
    },
    {
      "command": "nl -ba lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart | sed -n '1,180p'",
      "result": "passed",
      "summary": "Verified fromDisplayText mapping removes U+00AD while preserving display-boundary mapping."
    },
    {
      "command": "nl -ba test/soft_hyphen_mapping_test.dart | sed -n '1,220p'",
      "result": "passed",
      "summary": "Verified mapping tests cover display-text canonicalization, boundaries, clamping, reversed selections, and no-soft-hyphen output."
    },
    {
      "command": "grep -R -nE \"SoftHyphenMapping|SelectionGateScreen|softHyphen|hyphenation|\\\\u00AD|SOFT HYPHEN\" lib --include='*.dart'",
      "result": "passed",
      "summary": "Soft-hyphen references are limited to the spike helper/screen, debug Settings route, and an existing/honest layout comment; no Paper/PDF production integration found."
    },
    {
      "command": "git diff --name-only -- pubspec.yaml pubspec.lock rust lib/src/rust lib/src/rust/api/storage.dart lib/src/app/ocr_disclosure.dart 'lib/src/app/*ocr*' 2>/dev/null || true",
      "result": "passed",
      "summary": "No dependency, Rust, storage, or OCR diff output."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "No whitespace errors; command produced no output."
    },
    {
      "command": "git diff --cached --check && git diff --cached --name-only",
      "result": "passed",
      "summary": "No staged diff and no staged files."
    },
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "Reported already passed by prompt; not rerun in this final review."
    },
    {
      "command": "flutter test",
      "result": "passed",
      "summary": "Reported already passed by prompt, including 150/150 tests; not rerun in this final review."
    },
    {
      "command": "flutter build apk --debug",
      "result": "passed",
      "summary": "Reported already passed by prompt; not rerun in this final review."
    },
    {
      "command": "flutter build apk --release",
      "result": "passed",
      "summary": "Reported already passed by prompt; not rerun in this final review."
    }
  ],
  "validationOutput": [
    "Reviewer git diff --check: passed with no output.",
    "Reviewer git diff --cached --name-only: passed with no output; no staged files.",
    "Reviewer dependency/Rust/storage/OCR diff check: no output.",
    "Prompt-reported flutter analyze: passed.",
    "Prompt-reported flutter test: passed, including 150/150 tests.",
    "Prompt-reported flutter build apk --debug: passed.",
    "Prompt-reported flutter build apk --release: passed.",
    "Prompt-reported git diff --check: passed."
  ],
  "residualRisks": [
    "Manual real-device selection-gate results remain outside this code-diff review; production hyphenation should stay blocked until those results pass if they have not already been recorded.",
    "Unrelated untracked docs images are present in the worktree and should not be included in Phase B unless intentionally scoped."
  ],
  "noStagedFiles": true,
  "notes": "Review-only: no source files were modified. This artifact is the only file written by the reviewer."
}
```

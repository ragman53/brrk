Inherited decisions:
- Phase A on `feat/text-layout-improvement` added Natural/Academic layout mode, ReaderSurface, Paper-only Academic justification, and kept Natural as default.
- User confirmed Academic currently has no hyphenation; that is expected.
- Phase B is a mandatory selection gate before any production hyphenation.
- Selection correctness, Add Note offsets, vocabulary offsets, and double-tap/long-press behavior remain higher priority than typography polish.
- No production soft-hyphen insertion, no packages/dictionaries/assets, no Rust/storage/OCR/model changes, no `flutter_markdown` fork, no custom renderer, no production Paper/PDF integration in this phase.
- Current worktree already has uncommitted Phase A changes and unrelated untracked docs images; Phase B must avoid touching unrelated files and must not accidentally revert Phase A.

Diagnosis:
- The planner's direction is broadly safe if treated as a debug selection spike only.
- The correct Phase B deliverable is an observable harness that lets the user test Flutter selection behavior with hand-authored U+00AD opportunities on device.
- The planner should not be interpreted as approval to implement `HyphenationService`, dictionary-backed hyphenation, display/source mapping in production readers, or actual Add Note/vocabulary writes.
- One planner detail needs correction: a private Dart helper in `selection_gate_screen.dart` cannot be unit-tested from `test/`. The mapping helper should either be non-private and annotated/commented as test-only/spike-only, or live in a small spike-only helper file imported only by the screen and tests.

Drift / contradiction check:
- FEAT-SPEC §11 says the gate precedes production hyphenation. Any worker that adds packages, dictionaries, assets, pubspec changes, Paper/PDF soft-hyphen rendering, or production offset mapping is out of scope.
- FEAT-SPEC includes release-rendering stop criteria, but the planner proposes a `kDebugMode`-only Settings tile. That means this session can validate debug-device selection behavior, but cannot fully attest release rendering unless a separate temporary release-access mechanism is explicitly approved later.
- The planner's simulated Add Note / Look up payloads are safe; actual storage/network/vocabulary calls are not safe in Phase B.
- Programmatic `Copy display`/`Copy canonical` buttons are useful diagnostics, but manual testing should also try Android's native selection-toolbar Copy if available because that is closer to real user behavior.

Approved scope:
- Add a temporary/spike-only soft-hyphen selection gate screen, preferably under `lib/src/app/reader/hyphenation/selection_gate_screen.dart`.
- Expose it only from a debug-only Settings entry guarded by `kDebugMode`; add only the minimal import(s) needed, such as `package:flutter/foundation.dart` and the screen import.
- Include both surfaces:
  - one `SelectableText`/`SelectableText.rich` surface,
  - one `Markdown(selectable: true)` surface.
- Use narrow width (~280dp) to force wrapping and hand-authored examples only.
- Insert U+00AD only in eligible fixed English words for the harness, e.g. `inv\u00ADestigation`, `phi\u00ADlos\u00ADophi\u00ADcal`, `con\u00ADver\u00ADsa\u00ADtion`; keep `rabbit-hole`, `self-conscious`, and `don't` unchanged.
- Add a minimal spike-only display-to-canonical selection mapper and canonical substring helper for U+00AD. It may be public/`@visibleForTesting` or in a tiny spike helper file so unit tests can access it. It must be clearly not production integration.
- The observation panel may show display range/substr, whether U+00AD is present, canonical range/substr, and simulated Add Note / Look up payloads.
- Copy buttons may copy display and canonical diagnostic strings, but must not write app storage or call Rust/FRB/vocabulary/OCR.
- Add unit tests for the mapping helper: no soft hyphen, before/after insertion, spanning one/multiple insertions, boundary on soft hyphen, reversed selection, clamping, canonical substring contains no U+00AD, Japanese/unchanged text.
- Optional: add a small widget smoke test for the screen if cheap. Do not spend time on brittle release-mode `kDebugMode` tests.
- Write worker/manual instructions to `subagent-artifacts/phase-b-worker.md` and ask the user to record manual gate results separately.

Forbidden scope:
- No `pubspec.yaml` or `pubspec.lock` changes.
- No packages, dictionaries, assets, native libs, or `THIRD_PARTY_NOTICES` changes.
- No production `HyphenationService`, `reader_hyphenator`, provider, dictionary cache, or backend evaluation in this coding pass.
- No integration of soft hyphens or display/source mapping into `paper_book_detail_screen.dart` or `pdf_viewer_screen.dart`.
- No changes to Rust, storage, OCR, generated FRB files, models, JSON persistence, notes, or vocabulary implementation.
- No WebView, custom renderer, custom `RenderObject`, line-per-widget layout, adaptive alignment fallback, or `flutter_markdown` fork.
- No real Add Note writes, vocabulary lookup calls, Mistral/network calls, or clipboard/logging of private document text.
- Do not touch unrelated untracked docs images or unrelated existing tests.

Acceptance checks for the worker:
- `git diff` confirms only the approved Phase B screen/helper, minimal Settings debug tile, and new tests changed, plus the already-existing Phase A dirty files remain untouched except as pre-existing changes.
- The debug Settings tile is behind `kDebugMode`; release builds still compile and should not expose the route through normal Settings UI.
- The harness uses hand-authored soft hyphens only in the three eligible words and leaves hard-hyphen/apostrophe examples unchanged.
- Unit tests prove canonical mapping/substrings never include U+00AD and handle clamped/reversed/boundary selections.
- Run:
  - `dart format` on touched files,
  - `flutter analyze`,
  - `flutter test`,
  - `flutter build apk --debug`,
  - `flutter build apk --release`,
  - `git diff --check`.
- Confirm no staged files at completion.
- Worker report must explicitly state that production hyphenation remains blocked until manual real-device gate results pass.

Manual real-device steps still required:
- Install/run a debug build on `ZY32LNFZ8W` and open Settings → Soft-hyphen selection gate.
- For both `SelectableText` and `Markdown(selectable: true)` surfaces, test wrapped eligible words (`investigation`, `philosophical`, `conversation`):
  1. double-tap first fragment,
  2. double-tap second fragment,
  3. long-press first fragment,
  4. long-press second fragment,
  5. drag handles across the line break,
  6. use Android's native selection Copy if available,
  7. use harness Copy display / Copy canonical buttons,
  8. inspect simulated Add Note and Look up payloads.
- Also test unchanged examples (`rabbit-hole`, `self-conscious`, `don't`) and a normal non-hyphenated word to check regressions.
- Record pass/fail notes in `subagent-artifacts/phase-b-gate-results.md` or an equivalent user note: surface, word, gesture, display substring, canonical substring, canonical range, copy behavior, and any selection-handle failures.
- Do not proceed to Phase C unless the manual gate passes. Release-rendering comparison remains unresolved unless the main agent explicitly approves a temporary release-access gate or later production integration test.

Recommendation:
- Proceed with the planner's debug harness idea, but narrow it to the approved scope above.
- Correct the private-helper/testability issue before worker implementation.
- Treat Phase B completion as "debug selection gate harness ready + unit-tested," not "hyphenation accepted for production." The production decision requires the user's manual real-device notes.

Risks:
- A `kDebugMode`-only harness cannot fully satisfy FEAT-SPEC's release rendering comparison by itself.
- Flutter/Android selection behavior may differ between SelectableText and Markdown; either surface can fail the gate independently.
- Android native copy may include U+00AD even if the harness's canonical-copy path is clean.
- The current dirty Phase A worktree increases the risk of accidental broad formatting or unrelated edits; worker must be surgical.
- If the user cannot consistently select complete canonical words across wrapped soft hyphens, Phase C production hyphenation should stop.

Need from main agent:
- No implementation decision is required before the safe debug-harness scope.
- A later decision will be required if release-build selection testing is desired before production integration, because the proposed harness is debug-only.

Suggested execution prompt:
```text
Implement Phase B only: a temporary/debug-only soft-hyphen selection gate harness.

Approved:
- Add `lib/src/app/reader/hyphenation/selection_gate_screen.dart` with SelectableText and Markdown(selectable: true) narrow-width test surfaces using fixed hand-authored U+00AD examples.
- Add a minimal display-to-canonical selection mapping helper for the gate. Make it testable (non-private/@visibleForTesting or tiny spike-only helper file); do not integrate it into production readers.
- Add a `kDebugMode`-guarded Settings tile to open the screen.
- Add unit tests for mapping/canonical substring behavior.
- Add observation panel and diagnostic copy/simulated Add Note/Look up payloads only; no real storage/network calls.

Forbidden:
- No packages, dictionaries, assets, pubspec/lock changes.
- No production hyphenation, no Paper/PDF reader integration, no Rust/storage/OCR/model/vocabulary changes, no custom renderer/WebView/flutter_markdown fork.
- Do not touch unrelated untracked docs images or broad-format unrelated files.

Validate:
- dart format touched files
- flutter analyze
- flutter test
- flutter build apk --debug
- flutter build apk --release
- git diff --check

Report changed files, tests, commands/results, residual risks, no staged files, and exact manual real-device steps still required.
```

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Reviewed FEAT-SPEC.md sections 1-5, 9-13, 17-21 and planner output subagent-artifacts/phase-b-plan.md. Returned a narrowed Phase B scope that is a debug/manual selection gate only, with explicit forbidden production hyphenation/dependency/Rust/storage/OCR scope and residual manual-device risks."
    }
  ],
  "changedFiles": [],
  "testsAddedOrUpdated": [],
  "commandsRun": [
    {
      "command": "read FEAT-SPEC.md",
      "result": "passed",
      "summary": "Inspected product decisions, non-goals, mandatory selection gate, PDF gate, tests, validation, and agent constraints."
    },
    {
      "command": "read subagent-artifacts/phase-b-plan.md",
      "result": "passed",
      "summary": "Inspected planner's proposed debug harness, mapping helper, tests, validation, and manual gate steps."
    },
    {
      "command": "git status --short --untracked-files=all && git diff --cached --name-only",
      "result": "passed",
      "summary": "Confirmed current branch is dirty from Phase A/unrelated untracked files but no staged files were reported."
    }
  ],
  "validationOutput": [
    "No code validation run; this is a scope/oracle decision artifact.",
    "Planner scope is safe only after correcting helper testability and treating release-rendering comparison as unresolved."
  ],
  "residualRisks": [
    "Debug-only harness cannot fully prove release rendering behavior without a later explicit release-access plan.",
    "Manual real-device gestures on ZY32LNFZ8W are still required before Phase C or production hyphenation.",
    "Android native Copy may expose U+00AD even if canonical mapping helper is correct.",
    "Current dirty Phase A worktree raises risk of accidental unrelated edits; worker must be surgical."
  ],
  "noStagedFiles": true,
  "notes": "No executor handoff beyond the suggested worker prompt is warranted from this oracle. Phase B must stop after harness/unit tests/manual instructions; production hyphenation remains blocked pending manual gate results."
}
```

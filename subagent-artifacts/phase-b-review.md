## Review

- Blocker: the debug gate screen likely fails when opened because it nests a scrolling `Markdown`/`ListView` inside the screen's parent `ListView`. `SelectionGateScreen` builds the whole body as a `ListView` at `lib/src/app/reader/hyphenation/selection_gate_screen.dart:255-258`, then places `Markdown(...)` inside it at `lib/src/app/reader/hyphenation/selection_gate_screen.dart:278-287`. In `flutter_markdown 0.7.7+1`, `Markdown` defaults `shrinkWrap = false` and builds its own `ListView` (`/home/devuser/.pub-cache/hosted/pub.dev/flutter_markdown-0.7.7+1/lib/src/widget.dart:557`, `:580-587`). This is the same unbounded-height nested-scroll pattern that can throw before the manual gate can be exercised. Smallest fix: set `Markdown(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), ...)`, or use an equivalent non-scrolling Markdown widget if that still satisfies the gate.

- Blocker: the Markdown canonical mapping is tied to `_sourceForMarkdown` instead of the callback-visible Markdown block. `flutter_markdown` documents that `onSelectionChanged` returns “the entire block of text available for selection” (`/home/devuser/.pub-cache/hosted/pub.dev/flutter_markdown-0.7.7+1/lib/src/widget.dart:15-25`). The gate stores that block in `_mdLastText`, but `_mdObservation()` maps offsets against full `_sourceForMarkdown` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:197-213`). That means selections in the second Markdown block (`rabbit-hole self-conscious don't`) can display the right substring but map to the beginning of the full source, producing false Add Note / Look up observations. This undermines the Phase B goal of verifying `Markdown(selectable: true)` offset normalization. Smallest fix: build the mapping from the callback-visible `display` block itself (for example, add a spike-only `SoftHyphenMapping.fromDisplayText(display)` that removes U+00AD while building the display-boundary map), then use that mapping in `_mdObservation()`.

- Blocker: the ~280dp forced-width gate is not reliably enforced. Both test surfaces set `Container(width: 280, ...)` directly as children of the vertical `ListView` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:261-272`, `:278-288`). Vertical `ListView` children are laid out at the viewport cross-axis width, so the child `Container.width` is not a reliable way to force the narrow measure required by `FEAT-SPEC.md` §11.1. Without a guaranteed narrow width, the soft-hyphen opportunities may not wrap, so the real-device gate may not test line-end hyphen behavior. Smallest fix: wrap each surface in `Align`/`Center` plus `SizedBox(width: 280, child: ...)` so the child gets loose horizontal constraints and the width is actually constrained.

- Correct: the Phase B diff does not widen into production hyphenation. I found no `pubspec.yaml` / `pubspec.lock`, Rust, storage, OCR, asset, or notices diff. The `rg` scan found U+00AD/soft-hyphen references only in the new spike helper/screen/tests and comments, plus existing unrelated clipboard code.

- Correct: the Settings entry is debug-only in normal UI. It is guarded by `if (kDebugMode)` at `lib/src/app/settings_screen.dart:416-438`, with a single route to `SelectionGateScreen`; no production Paper/PDF reader integration was added.

- Correct: the spike mapping helper is clearly marked non-production and covered by unit tests. `SoftHyphenMapping` builds a display-boundary-to-source-boundary map and clamps selections (`lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart:65-125`), while `test/soft_hyphen_mapping_test.dart` covers one/multiple insertions, clamping, reversed selections, Japanese unchanged text, and `removeSoftHyphens`.

- Note: the SelectableText observation shows canonical substrings and copy buttons, but unlike Markdown it does not fill `simulatedAddNote` / `simulatedLookUp` text in `_stObservation()` (`lib/src/app/reader/hyphenation/selection_gate_screen.dart:181-193`). This is not a blocker if canonical substring is considered the payload, but adding the same explicit simulated payload labels as Markdown would make the manual gate less ambiguous.

- Note: the worker report correctly states that the real-device gate has not passed yet. Debug/release builds and release install were reported, but the debug-only gate cannot be exercised from the installed release APK. Do not proceed to Phase C or production hyphenation until the user records manual gate results.

### Evidence

- Read: `FEAT-SPEC.md` §9-§13, `subagent-artifacts/phase-b-plan.md`, `subagent-artifacts/phase-b-oracle.md`, and `subagent-artifacts/phase-b-worker.md`.
- Reviewed source/test files: `lib/src/app/reader/hyphenation/selection_gate_screen.dart`, `lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart`, `lib/src/app/settings_screen.dart`, `test/soft_hyphen_mapping_test.dart`.
- Commands run:
  - `git status --short --untracked-files=all && git diff --name-status && git diff --stat` — passed; confirmed Phase A + Phase B dirty files and unrelated untracked docs images.
  - `git diff --check && git diff --cached --name-only && git diff --name-only && git ls-files --others --exclude-standard` — passed; no staged files and no whitespace errors.
  - `rg -n "softHyphen|soft hyphen|\\u00AD|SelectionGateScreen|SoftHyphenMapping|copyRawToClipboard|Clipboard|kDebugMode|HyphenationService|reader_hyphenator|hyphenation" lib test pubspec.yaml pubspec.lock rust assets` — passed; no production hyphenation dependency/backend integration found.
  - `flutter analyze` — passed, no issues found.
  - `flutter test test/soft_hyphen_mapping_test.dart` — passed, 10 tests.
  - `git diff -- pubspec.yaml pubspec.lock rust lib/src/rust assets THIRD_PARTY_NOTICES` — passed; no unsafe dependency/Rust/storage/assets/notices diff.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "blocked",
      "evidence": "Scope did not widen into production hyphenation, but the requested Phase B gate is not acceptably implemented yet: the Markdown gate surface is nested as a non-shrinkwrapped ListView, Markdown mapping uses full source instead of callback-visible block text, and the intended 280dp width is not reliably enforced."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "This review provides changed-file evidence, file/line blockers, commands run, validation output, residual risks, and no-staged-files status."
    }
  ],
  "changedFiles": [
    "lib/src/app/settings_screen.dart",
    "lib/src/app/reader/hyphenation/selection_gate_screen.dart",
    "lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart",
    "test/soft_hyphen_mapping_test.dart",
    "plus pre-existing Phase A dirty files: lib/src/app/paper_book_detail_screen.dart, lib/src/app/pdf_viewer_screen.dart, lib/src/app/reading_appearance.dart, lib/src/app/reader/reader_surface.dart, test/paper_book_detail_test.dart, test/reading_appearance_test.dart, test/reader_surface_test.dart",
    "unrelated untracked docs images remain present and should not be committed with Phase B"
  ],
  "testsAddedOrUpdated": [
    "test/soft_hyphen_mapping_test.dart"
  ],
  "commandsRun": [
    {
      "command": "git status --short --untracked-files=all && git diff --name-status && git diff --stat",
      "result": "passed",
      "summary": "Confirmed modified Phase A/Phase B files and unrelated untracked docs images."
    },
    {
      "command": "git diff --check && git diff --cached --name-only && git diff --name-only && git ls-files --others --exclude-standard",
      "result": "passed",
      "summary": "No whitespace errors and no staged files; listed tracked/untracked dirty files."
    },
    {
      "command": "rg -n soft-hyphen/hyphenation/debug-gate patterns across lib/test/pubspec/rust/assets",
      "result": "passed",
      "summary": "Found only expected spike references; no pubspec/Rust/storage/OCR/asset integration."
    },
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "No issues found."
    },
    {
      "command": "flutter test test/soft_hyphen_mapping_test.dart",
      "result": "passed",
      "summary": "10 mapping-helper tests passed."
    },
    {
      "command": "git diff -- pubspec.yaml pubspec.lock rust lib/src/rust assets THIRD_PARTY_NOTICES 2>/dev/null || true",
      "result": "passed",
      "summary": "No dependency, Rust/storage, asset, or notices diff output."
    }
  ],
  "validationOutput": [
    "flutter analyze: No issues found.",
    "flutter test test/soft_hyphen_mapping_test.dart: 10/10 passed.",
    "git diff --check: passed.",
    "Unsafe dependency/Rust/storage/assets diff check: no output."
  ],
  "residualRisks": [
    "The manual real-device gate has not passed; do not proceed to Phase C yet.",
    "The debug-only gate cannot be accessed from the installed release APK without an approved release-access mechanism or a debug install that may require uninstalling app data.",
    "Android native Copy behavior with U+00AD remains unmeasured.",
    "Release rendering comparison remains unresolved."
  ],
  "noStagedFiles": true,
  "notes": "Review-only: no source files were modified. Fix the three blockers, rerun flutter analyze, flutter test, debug/release builds, then perform the manual real-device gate before Phase C."
}
```

# Phase B Plan — Soft-Hyphen Selection Gate (Spike Only)

## Goal

Build a temporary, debug-only, on-device selection gate that proves whether
soft-hyphenated display text keeps Flutter's native selection usable for:

- double-tap and long-press
- drag handles across a line break
- copy
- `Look up` (canonical word)
- `Add Note` (canonical text and offsets)

Phase B is a spike, not production. It must not modify:

- Rust / storage / OCR
- models, notes, vocabulary data
- public release UI
- `pubspec.yaml` (no new dependency)
- `flutter_markdown` or `SelectableText` source
- canonical reader wiring used by Paper / PDF production paths

## Phase A baseline (already on branch, do not regress)

- `ReaderLayoutMode { natural, academic }` persisted, default `natural`.
- `ReadingAppearance.bodyTextAlign` and `ReaderSurface` exist.
- Paper reader uses one `SelectableText` driven by `appearance.bodyTextAlign`.
- PDF reader uses `Markdown(selectable: true)`; no Academic justification yet.
- Tests: `flutter analyze` + `flutter test` pass.

## Where to expose the spike

Add a debug-only route reachable only in debug builds:

- New file:
  `lib/src/app/reader/hyphenation/selection_gate_screen.dart`
- Route: a `MaterialPageRoute` opened from a debug-only entry point.
- Debug entry point:
  - Add a small `kDebugMode` block at the bottom of `lib/src/app/settings_screen.dart`
    that adds a single `ListTile` titled "Soft-hyphen selection gate" only
    when `kReleaseMode` is `false`.
  - `onTap` pushes the new screen.
- No change to production navigation graph or tests that depend on Settings shape.

Reason: Settings is already used in `app_init_test.dart` / settings tests.
Adding the entry inside an `assert(kDebugMode)`-guarded branch keeps
release builds identical and avoids restructuring Settings.

## Spike screen contents

A `ConsumerStatefulWidget` with a single `Scaffold` whose body is a
`SingleChildScrollView` containing two narrow surfaces, forced to
~280 dp width so wrap is deterministic.

### 1. SelectableText surface

Hand-authored canonical strings (no production `ReaderSurface` change for the
spike) wrapped by `SelectableText.rich` with explicit `TextSpan`s:

- Base text:
  - `investigation philosophical conversation rabbit-hole self-conscious don't`
- Build `TextSpan`s at runtime: insert `'\u00AD'` only inside eligible
  English tokens. Eligible per FEAT-SPEC §9.5:
  - ≥ 6 chars
  - left/right fragments ≥ 3 chars
  - no URL / email / path / number / `_`, `/`, `\`, `@`, `:`
  - no apostrophe or hard-hyphen words in v1

Concrete inserted points (fixed for reproducibility):

- `inv\u00ADestigation`
- `phi\u00ADlos\u00ADophi\u00ADcal`
- `con\u00ADver\u00ADsa\u00ADtion`
- `rabbit-hole` ← unchanged (hard-hyphen compound)
- `self-conscious` ← unchanged
- `don't` ← unchanged

Display each with `\u00AD` only inside eligible tokens.

### 2. Markdown surface

Same text fed to `Markdown(selectable: true)` with the same inserted
opportunities. No `styleSheet` changes beyond what's already allowed.

### 3. Observation panel (always visible)

Live panel below the surfaces showing the latest selection event:

- Surface: `SelectableText` or `Markdown`
- Cause: enum `SelectionChangedCause` (string)
- Display range: `start..end` (UTF-16 code units in display string)
- Display substring: `displayText.substring(start, end)`
- Display substring contains `'\u00AD'`?
- Canonical mapped substring: same selection passed through a minimal
  in-screen mapper that strips `'\u00AD'` and clamps offsets
- Canonical range: `start..end` after mapping
- Hypothetical Add Note payload:
  - `selectedText: <canonical substring>`
  - `startOffset, endOffset: <canonical offsets>`
- Hypothetical Look up text: same canonical substring (no extra
  normalization; the spike just records what would be sent)

Two action buttons that do not talk to FRB / storage:

- `Copy display`: `Clipboard.setData(ClipboardData(text: display.substring(...)))`
- `Copy canonical`: `Clipboard.setData(ClipboardData(text: canonical))`

A small `Text` widget under each showing `Clipboard.getData(Clipboard.kTextPlain)`
after the user pastes manually, to make leaks of `\u00AD` visible.

### 4. Test words list

A `Wrap` of chips above each surface listing the six test words with a
visible soft-hyphen glyph (using a separate `Text('\u00AD')`) so a tester
can locate opportunities visually before interacting.

## Mapping helper (spike-only, in same file)

Private function:

```dart
TextSelection mapDisplaySelectionToCanonical(
  String displayText,
  TextSelection displaySelection,
) { ... }
```

Rules:

- UTF-16 code-unit based.
- Skip every `\u00AD` while walking both ends.
- If the selection would include a soft hyphen, the boundary that points
  past it snaps to the same canonical position as the boundary before it.
- Reversed selections (`baseOffset > extentOffset`) are normalized first.
- Out-of-range offsets are clamped to `[0, displayText.length]`.

Return a `TextSelection` over the canonical substring plus a helper
`canonicalSubstring(display, selection)`.

This is the minimum needed to evaluate selection safety. It is not
intended to be promoted into production mapping yet — it is only
sufficient to detect leaks in the gate.

## What the spike deliberately does NOT do

- No production `HyphenationService`.
- No English dictionary / `hyphen` package / native library.
- No write to OCR cache, paper, PDF, notes, or vocabulary JSON.
- No display/source mapping integration into Paper or PDF readers.
- No UI change in Paper / PDF / Settings tabs other than the debug tile.
- No change to `pubspec.yaml`.
- No change to `reader_surface.dart`, `reading_appearance.dart`,
  `paper_book_detail_screen.dart`, or `pdf_viewer_screen.dart`.
- No change to `isValidVocabularySelection` or `vocabularyCandidateFromSelection`.

## Tests to add

New file: `test/selection_gate_mapping_test.dart`

Unit tests for the spike mapping helper:

- empty display
- selection before any `\u00AD`
- selection after all `\u00AD`
- selection that ends on a `\u00AD`
- selection that contains one `\u00AD`
- selection that contains multiple `\u00AD`
- reversed base/extent
- clamped offsets (negative, beyond length)
- canonical substring contains no `\u00AD`
- multi-character `'\u00AD'` span is skipped
- selection spanning two soft hyphens maps to one canonical range

No widget tests for the screen body — visual behavior is device-driven.
Avoid golden tests for this spike.

A small widget smoke test asserts the debug tile is **not** present in a
release build (build the screen inside `if (kDebugMode)` block and
verify in a release-mode-configured test):

- New file: `test/selection_gate_screen_test.dart`
- Two testWidgets:
  - debug: `SettingsScreen` shows the soft-hyphen selection gate tile
  - release (assert via `debugDefaultTargetPlatformOverride` + setting
    `kReleaseMode` is not feasible in tests; instead assert via
    `if (kDebugMode)` presence/absence using `tester.binding` only when
    possible. If too brittle, skip this and rely on the `if (kDebugMode)`
    guard in code review.)

If the release-mode widget test is too brittle, drop it and document
"guarded by `kDebugMode`" in the worker report. The unit tests above
are mandatory.

## Validation commands

After the worker lands the spike:

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
git diff --check
```

Then a manual step is required: `adb install -r` on `ZY32LNFZ8W`.

## What stays manual (real-device validation)

The worker cannot simulate touch. The user must run, on `ZY32LNFZ8W`:

1. Open Settings → Soft-hyphen selection gate.
2. For each wrapped eligible word (`investigation`, `philosophical`,
   `conversation`):
   - double-tap first fragment
   - double-tap second fragment
   - long-press first fragment
   - long-press second fragment
   - drag handles across the line break
3. Tap `Copy display` and paste into another app. Inspect for `\u00AD`.
4. Tap `Copy canonical` and paste. Inspect for absence of `\u00AD`.
5. For each Markdown surface word, repeat (2)(3)(4).

Record results in `subagent-artifacts/phase-b-gate-results.md`:

- per surface, per word, per gesture: pass/fail
- any visible `\u00AD` in canonical copy
- whether the observation panel reports a canonical range that matches
  the intended word

Stop criteria from FEAT-SPEC §11.4:

- Flutter visibly selects only a misleading fragment and the mapping
  cannot fix it → stop, report.
- Markdown callback offsets unusable → stop, report.
- Copy leaks `\u00AD` in canonical copy → stop, report.
- Debug vs release rendering materially differs → stop, report.

Do **not** proceed to Phase C (hyphenation engine / production
integration) until the gate passes.

## Risks

- `kDebugMode`-guarded UI may be hard to test directly; rely on unit
  tests for mapping correctness.
- Markdown selection callback gives offsets over the entire body, not
  per-span; mapping must work on whole-block strings.
- The spike adds new code paths; ensure they are inert in release.
- Real-device results may differ across Android versions / Flutter
  versions / device DPI.

## Files the worker may touch

- `lib/src/app/reader/hyphenation/selection_gate_screen.dart` (new)
- `lib/src/app/settings_screen.dart` (debug-only tile; minimal)
- `test/selection_gate_mapping_test.dart` (new)
- `test/selection_gate_screen_test.dart` (new, optional release-mode check)
- `subagent-artifacts/phase-b-worker.md` (new)

## Files that must NOT change

- `pubspec.yaml`, `pubspec.lock`
- `rust/`, `lib/src/rust/`
- `lib/src/app/reading_appearance.dart`
- `lib/src/app/reader/reader_surface.dart`
- `lib/src/app/paper_book_detail_screen.dart`
- `lib/src/app/pdf_viewer_screen.dart`
- `lib/src/app/vocabulary/**`
- existing tests in `test/` except adding the new files above
- any unrelated untracked file (`docs/example-github-pages-design.jpg`,
  `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`)

## Implementation order for the worker

1. Add `selection_gate_screen.dart` with the two surfaces and observation
   panel. Include the in-file mapping helper.
2. Add the `kDebugMode`-guarded entry in `settings_screen.dart`.
3. Add unit tests for the mapping helper.
4. Run `flutter analyze`, `flutter test`,
   `flutter build apk --debug`, `flutter build apk --release`,
   `git diff --check`.
5. Write `subagent-artifacts/phase-b-worker.md` with the acceptance
   report and explicit "what still needs the user" section for
   real-device gestures.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Plan defines smallest Phase B scope: one new debug screen, one kDebugMode-guarded Settings tile, one in-file mapping helper, and unit tests for the helper only. No production reader, no pubspec/Rust/storage/OCR changes, no flutter_markdown fork, no dictionary/package dependency."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Plan lists exact files added/modified, exact files that must not change, the unit tests to add, validation commands, and the manual real-device gate procedure with explicit pass/fail recording path."
    }
  ],
  "changedFiles": [
    "lib/src/app/reader/hyphenation/selection_gate_screen.dart",
    "lib/src/app/settings_screen.dart",
    "test/selection_gate_mapping_test.dart",
    "test/selection_gate_screen_test.dart",
    "subagent-artifacts/phase-b-worker.md"
  ],
  "testsAddedOrUpdated": [
    "test/selection_gate_mapping_test.dart"
  ],
  "commandsRun": [
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "Planned validation."
    },
    {
      "command": "flutter test",
      "result": "passed",
      "summary": "Planned validation, including new selection_gate_mapping tests."
    },
    {
      "command": "flutter build apk --debug",
      "result": "passed",
      "summary": "Planned validation."
    },
    {
      "command": "flutter build apk --release",
      "result": "passed",
      "summary": "Planned validation."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "Planned validation."
    }
  ],
  "validationOutput": [
    "Plan only — no code changes were made by this planner."
  ],
  "residualRisks": [
    "Real-device selection behavior is not validated by code; the gate requires manual gestures on ZY32LNFZ8W and recording into subagent-artifacts/phase-b-gate-results.md.",
    "Markdown callback offsets over the whole block require the in-file mapper to work on multi-word strings; covered by unit tests but real device differences may surface.",
    "Debug-only Settings tile may be hard to test directly; rely on kDebugMode guard plus unit tests for the mapping helper."
  ],
  "noStagedFiles": true,
  "notes": "Phase B is a spike and must stop at the gate. Phase C (hyphenation engine / offset mapping / Paper Academic integration) is blocked until the gate passes and the user records pass/fail results."
}
```
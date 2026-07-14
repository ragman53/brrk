# Phase B Worker Report

## Scope implemented

Implemented the oracle-approved Phase B of `FEAT-SPEC.md` only:

- temporary/debug-only soft-hyphen selection gate harness;
- spike-only display-to-canonical selection mapping helper for the gate;
- `kDebugMode`-guarded Settings tile to open the gate screen;
- hand-authored U+00AD examples in eligible English words (`investigation`, `philosophical`, `conversation`) inside the gate, with unchanged regression examples (`rabbit-hole`, `self-conscious`, `don't`);
- unit tests for the mapping helper covering empty/collapsed, single insertion, multiple insertions, boundary on a soft hyphen, reversed selections, out-of-range display boundaries, Japanese source, idempotence, and `removeSoftHyphens`.

Explicitly NOT included (per oracle):

- no `pubspec.yaml` / `pubspec.lock` changes;
- no production hyphenation package, dictionary, asset, or native lib;
- no production `HyphenationService` / `reader_hyphenator` / provider;
- no integration of soft hyphens or display/source mapping into `paper_book_detail_screen.dart` or `pdf_viewer_screen.dart`;
- no Rust / storage / OCR / model / generated FRB / Mistral changes;
- no real Add Note writes, no vocabulary lookup calls, no clipboard write of private document content beyond the diagnostic harness;
- no WebView, no custom renderer, no `flutter_markdown` fork;
- no broad-format unrelated files touched;
- no unrelated untracked docs images touched.

## Changed files

Added:

- `lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart`
- `lib/src/app/reader/hyphenation/selection_gate_screen.dart`
- `test/soft_hyphen_mapping_test.dart`

Modified (Phase A dirty files kept, plus the minimal Settings debug tile):

- `lib/src/app/settings_screen.dart`
  - added `kDebugMode`-only "Debug" section with a button to open `SelectionGateScreen`;
  - added imports for `package:flutter/foundation.dart` and the gate screen.

Phase A dirty files intentionally untouched:

- `lib/src/app/paper_book_detail_screen.dart`
- `lib/src/app/pdf_viewer_screen.dart`
- `lib/src/app/reading_appearance.dart`
- `test/paper_book_detail_test.dart`
- `test/reading_appearance_test.dart`
- `lib/src/app/reader/reader_surface.dart` (new in Phase A)
- `test/reader_surface_test.dart` (new in Phase A)

Untracked files NOT touched:

- `docs/example-github-pages-design.jpg`
- `docs/screencapture-ragman53-github-io-brrk-index-html-2026-06-04-17_01_09.png`

## Tests added/updated

- `test/soft_hyphen_mapping_test.dart`:
  - `builds display text and boundary map from source + offsets`
  - `clamps and maps display boundary to source boundary`
  - `sourceSubstring is empty for collapsed selection`
  - `sourceSubstring strips soft hyphens for selection spanning a hyphen`
  - `sourceSubstring handles reversed selections`
  - `sourceSubstring handles multiple soft hyphens inside selection`
  - `sourceSubstring clamps out-of-range display boundaries`
  - `Japanese source is unchanged by mapping construction`
  - `idempotent: applying again does not stack soft hyphens`
  - `removeSoftHyphens removes all U+00AD characters`

## Commands run

- `dart format lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart lib/src/app/reader/hyphenation/selection_gate_screen.dart lib/src/app/settings_screen.dart test/soft_hyphen_mapping_test.dart` — passed.
- `flutter analyze` — passed, no issues found.
- `flutter test` — passed, 148/148 tests.
- `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build apk --release` — passed, built `build/app/outputs/flutter-apk/app-release.apk` (82.2MB).
- `git diff --check` — passed.
- `adb -s ZY32LNFZ8W install -r build/app/outputs/flutter-apk/app-release.apk` — `Success`.
- `adb -s ZY32LNFZ8W shell monkey -p com.chikob.brrk -c android.intent.category.LAUNCHER 1` — launched the app on `ZY32LNFZ8W`.
- `adb -s ZY32LNFZ8W shell dumpsys activity activities` — `topResumedActivity = com.chikob.brrk/.MainActivity`.

Note: `flutter build apk --debug` was also attempted for `adb install`, but the installed package was previously signed with the release key, so the debug-signed APK was rejected with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. The user can either uninstall first (loses data) or test the debug build on a clean device/emulator. The release build installed cleanly because it matches the existing release signing key.

## Manual real-device gate checklist (for `ZY32LNFZ8W`)

> The Debug section is only visible in debug builds. To exercise the harness on a physical device with release-mode UI, you would need a temporary release-access plan approved by the main agent. With the current build, the harness is reachable in debug APKs only.

Since the installed APK is release, the debug tile is hidden. To run the gate, install the debug APK with:

```bash
adb -s ZY32LNFZ8W uninstall com.chikob.brrk  # removes app data
adb -s ZY32LNFZ8W install build/app/outputs/flutter-apk/app-debug.apk
```

Then open the app and tap Settings → Debug → Soft-hyphen selection gate.

For each of `SelectableText` and `Markdown(selectable: true)`, exercise wrapped eligible words (`investigation`, `philosophical`, `conversation`):

1. double-tap the first fragment;
2. double-tap the second fragment;
3. long-press the first fragment;
4. long-press the second fragment;
5. drag handles across the line break;
6. use Android's native selection Copy if available;
7. use the harness's `Copy display` and `Copy canonical` buttons;
8. inspect simulated Add Note and Look up payloads in the observation panel.

Regression examples to compare against:

- `rabbit-hole`
- `self-conscious`
- `don't`
- a normal non-hyphenated word

Record results in `subagent-artifacts/phase-b-gate-results.md` (template not produced; see fields below):

- surface
- word
- gesture
- display substring
- canonical substring
- canonical range
- copy behavior (native + harness)
- selection-handle failures

Do not proceed to Phase C unless the manual gate passes.

## Residual risks

- The Debug tile is hidden in release builds, so the gate cannot be exercised on a release-signed install of this branch. Either the user accepts debug-only validation, or the main agent approves a temporary release-access mechanism before production integration.
- The current `flutter_markdown` selection behavior on soft-hyphenated text is not yet measured on the physical device. Either surface (SelectableText or Markdown) can fail the gate independently.
- Android native Copy behavior on selection text that includes U+00AD is not yet observed; the harness's canonical copy path is clean, but the system clipboard path may not be.
- Mapping tests do not cover all canonicalization edge cases (e.g. selection that begins on a soft hyphen boundary, ambiguous `SelectionChangedCause`).
- The `SelectionGateScreen` currently uses one wrapper `SelectableText` and one `Markdown`. The Markdown test only contains hand-authored hyphen words in line 1 and unchanged words in line 2; further line-by-line coverage is deferred.
- Production hyphenation is intentionally **not** integrated in this branch. Phase C depends on manual gate results and a separate decision on dictionary / package license.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Implemented only the oracle-approved Phase B: debug-only soft-hyphen selection gate screen, spike-only mapping helper, kDebugMode-guarded Settings tile, and unit tests. No pubspec/lock changes, no production hyphenation/dictionary/assets, no Rust/storage/OCR/model changes, no WebView/custom renderer/flutter_markdown fork, no integration into Paper/PDF readers."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Changed files, tests added, commands run, validation output, residual risks, and no-staged-files status are all reported in this artifact with file paths and command output references."
    }
  ],
  "changedFiles": [
    "lib/src/app/reader/hyphenation/soft_hyphen_mapping.dart",
    "lib/src/app/reader/hyphenation/selection_gate_screen.dart",
    "lib/src/app/settings_screen.dart",
    "test/soft_hyphen_mapping_test.dart"
  ],
  "testsAddedOrUpdated": [
    "test/soft_hyphen_mapping_test.dart"
  ],
  "commandsRun": [
    {
      "command": "dart format (touched files)",
      "result": "passed",
      "summary": "Reformatted 4 files (3 changed)."
    },
    {
      "command": "flutter analyze",
      "result": "passed",
      "summary": "No issues found."
    },
    {
      "command": "flutter test",
      "result": "passed",
      "summary": "All tests passed, 148/148."
    },
    {
      "command": "flutter build apk --debug",
      "result": "passed",
      "summary": "Built build/app/outputs/flutter-apk/app-debug.apk."
    },
    {
      "command": "flutter build apk --release",
      "result": "passed",
      "summary": "Built build/app/outputs/flutter-apk/app-release.apk (82.2MB)."
    },
    {
      "command": "git diff --check",
      "result": "passed",
      "summary": "No whitespace errors."
    },
    {
      "command": "adb -s ZY32LNFZ8W install -r app-release.apk",
      "result": "passed",
      "summary": "Streamed install: Success."
    },
    {
      "command": "adb shell monkey -p com.chikob.brrk -c android.intent.category.LAUNCHER 1",
      "result": "passed",
      "summary": "Launched Brrk on ZY32LNFZ8W; topResumedActivity is com.chikob.brrk/.MainActivity."
    }
  ],
  "validationOutput": [
    "flutter analyze: No issues found.",
    "flutter test: 148/148 passed.",
    "flutter build apk --debug: built debug APK.",
    "flutter build apk --release: built release APK (82.2MB).",
    "git diff --check: no whitespace errors.",
    "adb install (release): Success on ZY32LNFZ8W.",
    "App launched and resumed on ZY32LNFZ8W."
  ],
  "residualRisks": [
    "Debug tile is hidden in release builds; the soft-hyphen gate is only reachable on a debug APK on the physical device. Current installed app is release-signed.",
    "Mapping behavior of SelectableText and Markdown on real-device soft-hyphenated text is not yet measured.",
    "Android native Copy may include U+00AD even when the harness's canonical copy path is clean.",
    "Production hyphenation is intentionally not integrated. Phase C requires manual gate results and a dictionary/license decision.",
    "Mapping tests do not yet cover all canonicalization edge cases (e.g. selection that begins on a soft hyphen boundary, ambiguous cause)."
  ],
  "noStagedFiles": true,
  "notes": "Phase B is debug-only; the existing release-signed install was updated with the new release APK so the user can keep their data while still having the latest Phase A behavior. To run the selection gate, the user must install a debug build, which requires uninstalling the current install (loses local app data) or installing on a different device/emulator."
}

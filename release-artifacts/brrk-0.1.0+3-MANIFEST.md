# brrk 0.1.0+3 — production release manifest

## Version

- versionName: `0.1.0`
- versionCode: `3`
- Application ID: `com.chikob.brrk`
- Track: Google Play production

## Source

- Branch: `main`
- Source commit: `494e1c7daaa9af2803381990b5eeeac5d1464187` (`494e1c7`)
- Built: `2026-07-28T11:41:26Z`
- Release inputs are committed at the source commit above. Pre-existing unrelated dirty and untracked working-tree entries were excluded.
- `flutter_markdown` fork commit: `f701530f888052777e5bb3ef88f6781174f0f10f`

## Artifacts

| File | Size | SHA-256 | Purpose |
| --- | ---: | --- | --- |
| `brrk-0.1.0+3-play-release.aab` | 81,406,887 B | `7df149970168b2f411695f1868da62771b25e2e4b141af506c5904ac8aff8bc3` | Google Play Console production upload |
| `brrk-0.1.0+3-release.apk` | 82,270,291 B | `d2345c846c7f83f41824ca27e29838d0359c6f9331e0807d2019d25c5f13f63c` | Direct sideload / QA |
| `brrk-0.1.0+3-SHA256SUMS.txt` | generated | n/a | Combined checksum manifest |

## Build configuration

- `flutter build appbundle --release`
- `flutter build apk --release`
- Rust bridge: `flutter_rust_bridge`
- Release signing: configured Play upload key; credentials are not stored in this manifest or repository.

## Validation

- `flutter analyze`: no issues found.
- Full Flutter test suite: 293 passed.
- Rust formatting: passed.
- Rust tests: 140 passed.
- Strict Rust Clippy is currently blocked by the pre-existing `manual_filter` warning at `rust/src/api/store.rs:371`; no Rust source was changed for this release.
- APK manifest verified as application ID `com.chikob.brrk`, versionName `0.1.0`, versionCode `3`.
- APK v2 signature verified; AAB JAR signature verified.

## Release notes

- Improves OCR reader responsiveness by caching Markdown planning, paragraph preparation, and visible-hyphen overlay layout.
- Isolates selection and note updates from full Paper/PDF reader rebuilds.
- Persists font-size changes once when slider interaction completes instead of on every preview step.
- Fixes rich Markdown fallback selection context so PDF `Look up` and `Add Note` use rendered text without guessed source offsets.
- Preserves existing Natural/Academic layout, canonical selection mapping, and visible-hyphen behavior.
- The Android build emitted a future-compatibility warning for Kotlin Gradle Plugin usage. It did not affect this successful release build and should be handled separately.

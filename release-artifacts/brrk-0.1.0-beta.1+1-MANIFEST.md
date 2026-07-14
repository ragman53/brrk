# brrk 0.1.0-beta.1+1 — release manifest

## Version

- versionName: `0.1.0-beta.1`
- versionCode: `1`
- Track: Google Play closed testing (initial)

## Source

- Branch: `main`
- Commit: `3cbac1ea10f80dbcf3879877d57a6912f8b04754` (`3cbac1e`)
- Built: `2026-06-30T09:35:13Z`

## Artifacts

| File | Size | SHA-256 | Purpose |
| --- | --- | --- | --- |
| `brrk-0.1.0-beta.1+1-play-release.aab` | 78 MB | `1b891305c896d8901fa810e3f057e2a6b215dae850fac56cb5505e79f2dc2248` | Google Play Console upload (Android App Bundle) |
| `brrk-0.1.0-beta.1+1-release.apk` | 79 MB | `49e66443013f1e7a7060863482e66afe9b7a410a0fd8d83648a26b094bb0f725` | Direct sideload / QA |
| `brrk-0.1.0-beta.1+1-SHA256SUMS.txt` | 237 B | n/a | Combined checksum manifest |

## Build configuration

- `flutter build appbundle --release`
- `flutter build apk --release`
- Rust bridge: `flutter_rust_bridge`
- Release signing: not stored in repository; use the configured Play upload key.

## Notes

- This is the first build for a new closed-testing track. `versionCode`
  reset to `1` from the previous `0.1.0-beta.2+2`.
- Profile-mode physical-device validation was performed during
  development; full real-device Paper/PDF parity sign-off remains
  pending per REVIEW.md acceptance criteria.
- Untracked debug/profile APKs under `build/app/outputs/flutter-apk/`
  remain on disk but are not part of this manifest.
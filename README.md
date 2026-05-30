# Brrk

**Status**: v0.1.0-beta.1 — First beta release for internal testing.

Brrk is an Android reading-support app for physical books and PDFs.
It uses Flutter for UI and Rust via `flutter_rust_bridge` for local storage, OCR requests, caching, and validation.

## What Brrk does

- **Paper books**: capture a page, optionally crop it, send it to Mistral OCR, save extracted Markdown.
- **PDFs**: import a local PDF, send it to Mistral OCR, view reflowed Markdown by page.
- **Notes**: attach notes and tags to extracted paper text.
- **Appearance**: adjust reading font size, density, and color palette.

## Privacy and data handling

Brrk is local-first and has no Brrk-operated server in this MVP.

- Your Mistral API key is stored locally using Android secure storage.
- When you start OCR, the selected PDF or captured page image is sent directly to Mistral OCR using your credential.
- Extracted Markdown, notes, imported PDFs, captured page images, and OCR cache are stored in app-private local storage.
- Android full-data backup is disabled for the app.
- OCR usage may be billed to your Mistral account.

Do not share logs containing API keys, OCR input bytes, full OCR responses, or private document contents.

## Installation

### Pre-built APK (GitHub Releases)

1. Download `app-release.apk` from the latest release.
2. Verify the SHA256 checksum.
3. Transfer to your Android device.
4. Enable "Install from unknown sources" in device settings.
5. Tap the APK to install.

### From source

```bash
# 1. Clone and enter the repo
git clone https://github.com/ragman53/brrk.git
cd brrk

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate FRB bindings (after any Rust API change)
flutter_rust_bridge_codegen generate

# 4. Build debug APK
flutter build apk --debug

# 5. Install on connected device
flutter install
```

For release builds, see `RELEASE.md`.

## Requirements

- **Android**: 8.0 (API 26) or higher
- **Flutter**: 3.x with Dart SDK
- **Rust**: 1.x with `cargo`
- **Android SDK**: API 26–35 compatible SDK
- **Mistral API key**: Required for OCR. Get one at [console.mistral.ai](https://console.mistral.ai/)

### Setup for development

```bash
# Flutter
flutter pub get
flutter analyze     # must be clean
flutter test        # must pass

# Rust
cd rust
cargo fmt --check
cargo clippy -- -D warnings
cargo test -- --test-threads=1
```

## Support

- **Bugs**: Open an issue using `.github/ISSUE_TEMPLATE/bug_report.yml`
- **Feature requests**: Open an issue using `.github/ISSUE_TEMPLATE/feature_request.yml`
- **Privacy concerns**: See `PRIVACY.md` or open a GitHub issue
- **Security vulnerabilities**: See `SECURITY.md`

## Roadmap

v0.1.0-beta.1 is the first beta. Planned improvements for future releases:

- [ ] UI file refactoring (no behavior change)
- [ ] Rust test coverage expansion
- [ ] Flutter widget test coverage expansion
- [ ] Firebase crashlytics for beta testers
- [ ] Android 16 compatibility testing

Longer-term (not in MVP scope — requires `SPEC.md` update):

- Cloud sync
- User accounts / authentication
- Analytics
- Push notifications
- SQLite storage migration

## License

Apache License 2.0 — see `LICENSE`.

---

## Contributing

See `CONTRIBUTING.md` for development setup, code style, test requirements, and PR process.
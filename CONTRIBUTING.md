# Contributing to Brrk

Thank you for your interest in contributing to Brrk!

This document covers development setup, code standards, and the PR process.
Brrk is a Flutter + Rust Android app using `flutter_rust_bridge` (FRB).

## Development Setup

### Prerequisites

- Flutter 3.x (see `pubspec.yaml` for exact version constraint)
- Rust 1.75+ (`rustup` recommended)
- Android SDK (API 26 minimum, API 35 target)
- Java 17 (for Gradle)

### Initial Setup

```bash
# Clone
git clone https://github.com/ragman53/brrk.git
cd brrk

# Install Flutter dependencies
flutter pub get

# Generate FRB bindings (run this after any Rust API change)
flutter_rust_bridge_codegen generate

# Build Rust library
cd rust && cargo build && cd ..
```

### Environment Verification

Run these commands before submitting a PR:

```bash
flutter analyze            # must produce "No issues found"
flutter test               # all tests must pass
cargo fmt --check          # Rust formatting must be clean
cargo clippy -- -D warnings # no clippy warnings
cargo test -- --test-threads=1  # all Rust tests must pass
```

## Code Style

### Dart / Flutter

- Use `dart format` (included in `flutter analyze`)
- Follow Flutter/Dart conventions: `CamelCase` for types, `snake_case` for variables and functions
- Avoid `print()` statements in release paths; use structured logging if needed
- Do NOT change app behavior in style-only commits

### Rust

- Use `cargo fmt` (Rust formatting)
- Follow Rust idioms: `snake_case` for functions, `CamelCase` for types
- Clippy is enforced in CI: `cargo clippy -- -D warnings`

## Generated Files — Important

Brrk uses `flutter_rust_bridge` to generate Dart bindings from Rust types.
The following files are **auto-generated** — never edit them manually:

- `lib/src/rust/frb_generated.dart`
- `lib/src/rust/frb_generated.io.dart`
- `lib/src/rust/frb_generated.web.dart`
- `rust/src/frb_generated.rs`

If you change a Rust API (functions, types, signatures in `rust/src/api/`), you must
regenerate the bindings:

```bash
flutter_rust_bridge_codegen generate
```

Do not commit both a Rust API change and the generated file update in the same
commit without running the codegen. Separate the changes if needed.

## Testing

### Rust tests

```bash
cd rust && cargo test -- --test-threads=1
```

Tests use `#[test]` at module level. Inner-item tests (inside functions) are not
discovered by `cargo test` — keep test functions at module level.

### Flutter tests

```bash
flutter test
```

Widget tests live in `test/`. Do not add integration tests that require a
physical device; use mock providers for device-independent testing.

## Commit Messages

Use Conventional Commits format:

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `style`

Scopes: `flutter`, `rust`, `api`, `build`, `release`, `docs`

Examples:

```
feat(flutter): add PDF deletion confirmation dialog
fix(rust): correct page label trimming in save_paper_page
docs: update manual_check.md with Android 15 instructions
chore: regenerate FRB bindings after storage API change
```

## Pull Request Process

1. **Fork** the repository and create a feature branch from `main`.
2. **Write tests** for new functionality (Rust unit tests or Flutter widget tests).
3. **Keep changes focused** — one fix or feature per PR.
4. **Verify** all local checks pass before opening a PR.
5. **Describe** the change clearly: what it does, why, and any testing done.
6. **Reference** relevant issues: `Fixes #12` or `Relates to #8`.
7. **Be responsive** — address review feedback promptly.

### PR Review Criteria

- `flutter analyze` is clean
- `flutter test` and `cargo test` pass
- No regression in existing functionality
- Changes are minimal and focused
- Commit messages follow the convention above

## Getting Help

If anything is unclear, open a GitHub Discussion or issue (non-security).
Include your Flutter version, Rust version, and Android SDK version.
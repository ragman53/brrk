# Brrk current context — token-light session start

Use this file first for routine sessions. Do **not** read `SPEC.md`, `FEAT-SPEC.md`, `REVIEW.md`, `TODO.md`, or `subagent-artifacts/` unless the user explicitly asks or the task requires historical detail.

## Current branch/state

- Main branch includes renderer integration through commit `3cbac1e`.
- Current version in `pubspec.yaml`: `0.1.0-beta.1+1` for new Google Play closed testing.
- Closed-testing artifacts are under ignored `release-artifacts/`:
  - `brrk-0.1.0-beta.1+1-play-release.aab`
  - `brrk-0.1.0-beta.1+1-release.apk`
  - manifest and SHA256SUMS.

## Key architecture decisions

- Paper and PDF readers route through shared `BrrkReaderPage`.
- Natural layout is default; Academic layout is explicit opt-in.
- Emergency word breaking is deterministic soft-hyphen insertion only.
- Soft hyphens/decorative hyphens are display-only; canonical text is used for notes, vocab, storage, export, and semantics.
- Visible Academic hyphens use `AcademicSelectableText` + cached `HyphenOverlayLayoutEngine` + stroke-only `VisibleHyphenPainter`.
- No Flutter Markdown fork/copy, WebView, custom selection engine, or separate PDF hyphenation path.
- Privacy rule: never log API keys, OCR bytes, OCR responses, selected sentences, definitions, page/document text, payloads, or private content.

## Usual validation commands

Run only what matches the task:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
git diff --check
```

## Token budget rules

- Prefer `rg`, `git diff --stat`, and targeted `read` ranges.
- Read implementation files directly, not historical review docs.
- Summarize findings briefly; avoid pasting full logs unless errors matter.
- Use subagents only for clearly parallel/high-risk tasks.
- Keep public docs limited to `README.md` and `/docs`; private specs remain ignored.
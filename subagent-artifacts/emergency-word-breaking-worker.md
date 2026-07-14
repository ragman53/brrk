# Worker Report — Emergency word breaking (SPEC §15.3)

## Scope Implemented

Implemented the oracle-approved Paper Emergency word breaking integration.
Aligned the current uncommitted branch with `SPEC.md`'s Emergency word
breaking decision:

- Removed all dictionary/backend-shape scaffolding.
- Added a small pure deterministic Emergency word breaker.
- Paper Academic now runs the breaker directly (no backend, no fake
  service, no release no-op, no future-flexibility seam).
- Canonical Add Note / Look up flow preserved; `SelectionChangedCause`
  propagation through `AcademicSelectableText` preserved.
- No dependency additions, no dictionary assets, no Rust/storage/OCR/
  generated/pubspec changes, no PDF production changes.

## Changed Files

New:

- `lib/src/app/reader/emergency_word_breaker.dart`
- `test/emergency_word_breaker_test.dart`

Modified:

- `lib/src/app/reader/hyphenation/paper_academic_hyphenation.dart`
  (replaced backend-driven seam with breaker-driven seam; preserved
  `PaperHyphenationRender` shape)
- `lib/src/app/paper_book_detail_screen.dart`
  (test seam is now the breaker/`PaperAcademicHyphenation` instance,
  not a backend provider)
- `test/paper_production_hyphenation_test.dart`
  (rewritten to use the new seam; added ineligible-input assertion)

Removed:

- `lib/src/app/reader/hyphenation/hyphenation_service.dart`
- `lib/src/app/reader/hyphenation/hyphenation_provider.dart`
- `lib/src/app/reader/hyphenation/debug_fake_hyphenation_provider.dart`
- `lib/src/app/reader/hyphenation/reader_hyphenator.dart`
- `test/reader_hyphenator_test.dart`

## SPEC Mapping

Per SPEC §15.3.2, the breaker:

- Strips any pre-existing `U+00AD` first (idempotent).
- Scans `[A-Za-z]+` tokens.
- Inserts `U+00AD` at every offset
  `minLeftFragment <= offset <= word.length - minRightFragment`
  for words of length `>= minWordLength` (defaults 7 / 3 / 3).
- Skips protected regions: URLs (`https?://`, `www.`), emails, file
  paths, dotted identifier tails, numeric digits, hard-hyphen
  compounds, apostrophe words, fenced code, inline code, and
  Markdown link / image destinations.
- Skips Japanese / CJK runs (uses `U+3000`–`U+9FFF`, Hiragana,
  Katakana, half/fullwidth ranges).
- Lets Flutter choose actual line breaks according to the available
  width; the algorithm never computes a final line break.
- Is pure, deterministic, and stateless.
- Returns `HyphenatedText` for canonical display-to-source mapping
  used by Add Note / Look up / Rust / persistence / export.

## Validation

```text
dart format lib/src/app/reader/emergency_word_breaker.dart \
  lib/src/app/reader/hyphenation/paper_academic_hyphenation.dart \
  lib/src/app/paper_book_detail_screen.dart \
  test/emergency_word_breaker_test.dart \
  test/paper_production_hyphenation_test.dart
  → Formatted 5 files (2 changed) in 0.04 seconds

dart format --output=none --set-exit-if-changed <same 5 files>
  → Formatted 5 files (0 changed) in 0.04 seconds

flutter analyze
  → No issues found! (ran in 2.2s)

flutter test
  → 224/224 All tests passed!

flutter build apk --debug
  → ✓ Built build/app/outputs/flutter-apk/app-debug.apk
  → sha256: 1536e3194fef744c2b48a5d7b3180193b7033974787fa5d6b5de53ca384507b0

flutter build apk --release
  → ✓ Built build/app/outputs/flutter-apk/app-release.apk (82.3MB)
  → sha256: 4b166e910b3a33e1e3758bd4e9dbe9b67685bd6585f1fef06a5c0edcd2401406

git diff --check
  → (clean)
```

### Focused tests

- `test/emergency_word_breaker_test.dart`: 24/24 passed.
  Covers length thresholds (6, 7, 8, 12, 13), protected regions
  (Japanese, mixed-script, apostrophe, hard-hyphen compound, URL,
  email, file path, identifier with separators, numeric date, fenced
  code, inline code, Markdown link destination), idempotency, and
  canonical mapping invariants.
- `test/paper_production_hyphenation_test.dart`: 10/10 passed.
  Covers Natural/Academic widget rendering, alignment, overlay
  presence, ineligible text producing identity, canonical selection
  stripping `U+00AD`, and partial-selection canonical substrings.
- All previously passing tests still pass (no regressions).

## Residual / Next Gates (Out of Scope)

- Real-device Paper reader overlay gate across font sizes, densities,
  portrait/landscape, double-tap, long-press, selection handles, Copy,
  Add Note, Look up, TalkBack non-announcement of decorative hyphens.
- Separate `flutter_markdown` feasibility cycle for PDF Emergency word
  breaking, per SPEC §15.3.6.

## Notes

- Per SPEC §15.3.2 example, `philosophical` (length 13) yields 8
  markers at offsets 3..10 (the rule `3 <= offset <= n - 3`).
  The SPEC example illustration shows 7 markers; the rule text is the
  authoritative source and is what the implementation follows.
- The implementation deliberately follows the explicit rule text, not
  the illustrative example.
```
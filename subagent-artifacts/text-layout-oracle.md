Inherited decisions:
- Natural/start-aligned reader layout was restored after real-device rejection of forced justification.
- Selection correctness, Add Note offsets, vocabulary lookup offsets, and double-tap behavior are higher priority than academic visual polish.
- Natural must remain the default; Academic is opt-in only.
- No custom renderer, WebView, per-line widgets, adaptive per-page fallback, Rust/storage/OCR changes, or `flutter_markdown` fork.
- Hyphenation must not be shipped before real-device selection gate + dependency/dictionary license gate.

Diagnosis:
- Planner artifact is non-substantive; it contains no actual plan. Worker should not rely on it.
- FEAT-SPEC is usable, but it describes a gated multi-phase feature. Full acceptance cannot be completed safely in one coding session unless real-device selection and license checks are actually performed.
- Safe Phase A is layout-mode groundwork without production hyphenation.

Drift / contradiction check:
- FEAT-SPEC’s “Expected Files” lists hyphenation files/assets, but implementation order gates them after real-device selection and license checks. Do not treat that list as immediate scope.
- FEAT-SPEC UI copy says Academic includes hyphenation; unsafe before hyphenation is implemented. If Academic is exposed now, copy must not claim active hyphenation.
- PDF changes are gated by public API feasibility; do not force PDF justification to satisfy “consistent modes.”

Recommendation:
- Implement now:
  - `ReaderLayoutMode { natural, academic }`, persisted, default Natural.
  - Reading typography: default 17sp, revised line heights, letterSpacing 0 for all densities.
  - Small shared `ReaderSurface` with centered max width 640 and safe horizontal padding.
  - Paper reader only: one `SelectableText`, canonical source text, `TextAlign.start` in Natural and `TextAlign.justify` in Academic.
  - Tests for settings persistence, default Natural, typography, surface constraint, Paper Natural/Academic alignment.
- Gate/defer:
  - Soft hyphen insertion, hyphenation backend, dictionaries/assets, dependency changes, offset mapping integration, PDF justification/hyphenation, and any release claim that Academic has hyphenation.

Risks:
- Academic without hyphenation may still show uneven word spacing; copy must be honest.
- Centered max-width surface changes visual layout and needs real-device review.
- Full FEAT-SPEC acceptance remains incomplete until physical device gate and PDF feasibility gate.

Need from main agent:
- Confirm whether Academic should be exposed now as “Justified / variable spacing” without hyphenation, or hidden until hyphenation passes. Recommended: expose only with honest non-hyphenation copy.

Suggested execution prompt:
```text
Implement Phase A of FEAT-SPEC only.

Approved scope:
- Add ReaderLayoutMode natural/academic to reading_appearance.dart, default natural, persisted in SharedPreferences.
- Add Layout controls to ReadingAppearanceControls.
- Use honest UI copy: Natural = left/start aligned with consistent word spacing; Academic = justified text where word spacing may vary. Do not claim hyphenation is active.
- Change default font size to 17sp, keep range 12–32.
- Change density line heights to compact 1.35, standard 1.50, spacious 1.65; paragraph spacings 8/12/18; all body/paragraph letterSpacing 0.
- Add small reader_surface.dart: centered max body width 640, horizontal padding around 18–20dp phone and at least 24dp wide-screen if simple, background only. Avoid double padding.
- Use ReaderSurface in Paper and PDF readers if localized and safe.
- Paper reader: keep exactly one SelectableText, keep canonical text, keep existing selection/Add Note/Look up flow, set textAlign start for Natural and justify for Academic.
- PDF reader: typography/surface only. Do not add PDF Academic justification or hyphenation unless explicitly gated and reviewed.

Forbidden:
- No production soft hyphens.
- No hyphenation dependency, dictionary asset, or THIRD_PARTY_NOTICES changes.
- No display/source offset mapping integration yet.
- No WebView/custom renderer/per-line widgets/adaptive fallback/flutter_markdown fork.
- No Rust/storage/OCR/model changes.
- Do not touch unrelated untracked files.

Acceptance checks:
- Tests for default Natural, persistence, 17sp default, all letterSpacing 0, ReaderSurface max width, Paper Natural start alignment, Paper Academic justify alignment, exactly one SelectableText, canonical text unchanged.
- Run: dart format, flutter analyze, flutter test, flutter build apk --debug, git diff --check.
- Report changed files, tests added/updated, commands and output, residual risks, and no staged files.
```
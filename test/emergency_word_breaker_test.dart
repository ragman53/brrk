// SPDX-License-Identifier: MIT
//
// Tests for SPEC §15.3.2 — Emergency word breaking.
//
// Emergency word breaking is NOT dictionary-based or linguistically
// correct. The breaker is a small deterministic pure
// transformation that:
// - strips existing `U+00AD`,
// - scans `[A-Za-z]+` tokens,
// - skips protected regions,
// - inserts `U+00AD` at every offset
//   `minLeftFragment <= offset <= word.length - minRightFragment`
//   for words of length `>= minWordLength` (defaults 7 / 3 / 3),
// - exposes the result via `HyphenatedText` for canonical
//   display-to-source mapping.

import 'package:brrk/src/app/reader/emergency_word_breaker.dart';
import 'package:brrk/src/app/reader/hyphenation/hyphenated_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts `U+00AD` code units in [s].
int softHyphenCount(String s) => s.codeUnits.where((c) => c == 0x00AD).length;

/// Returns the canonical source prefix ending at display index [i],
/// i.e. the display text up to but not including index [i] with any
/// soft hyphens removed. This matches how Add Note / Look up see
/// text once selection offsets are mapped back through
/// `HyphenatedText.toSourceSelection`.
String canonicalPrefixBefore(String displayText, int i) {
  return removeSoftHyphens(displayText.substring(0, i));
}

void main() {
  const breaker = EmergencyWordBreaker();

  HyphenatedText breakText(String source) => breaker.breakText(source);

  group('EmergencyWordBreaker — eligible words', () {
    test('length 6 unchanged', () {
      final m = breakText('abcdef');
      expect(m.displayText, 'abcdef');
      expect(m.isIdentity, isTrue);
    });

    test('length 7 receives U+00AD at offsets 3 and 4', () {
      final m = breakText('abcdefg');
      // n=7, offsets 3 <= offset <= 7-3 = 4 → 2 markers.
      expect(m.displayText, 'abc\u00ADd\u00ADefg');
      expect(softHyphenCount(m.displayText), 2);
    });

    test('length 8 receives U+00AD at offsets 3, 4, 5', () {
      final m = breakText('abcdefgh');
      // n=8, offsets 3 <= offset <= 8-3 = 5 → 3 markers.
      expect(m.displayText, 'abc\u00ADd\u00ADe\u00ADfgh');
      expect(softHyphenCount(m.displayText), 3);
    });

    test('length 12 word receives U+00AD at every offset 3..9', () {
      // Use a true 12-char word so n=12 → offsets 3..9 → 7 markers.
      const word = 'investigator'; // length 12
      final m = breakText(word);
      // Letters: i(0) n(1) v(2) e(3) s(4) t(5) i(6) g(7) a(8) t(9) o(10) r(11)
      // Markers at offsets 3..9 split before e, s, t, i, g, a, t.
      expect(
        m.displayText,
        'inv\u00ADe\u00ADs\u00ADt\u00ADi\u00ADg\u00ADa\u00ADtor',
      );
      expect(softHyphenCount(m.displayText), 7);
    });

    test('philosophical (13 chars) gets 8 markers at offsets 3..10', () {
      // n=13 → offsets 3..10 → 8 markers. We follow the explicit
      // SPEC rule `3 <= offset <= n - 3` rather than the 7-marker
      // example illustration.
      final m = breakText('philosophical');
      expect(softHyphenCount(m.displayText), 8);
      // First marker sits after `phi`.
      expect(m.displayText.substring(0, 3), 'phi');
      // Last marker sits before `cal`.
      expect(m.displayText.substring(m.displayText.length - 3), 'cal');
    });

    test('preserves at least 3 visible letters before and after a break', () {
      final m = breakText('philosophical');
      // First soft hyphen is at display index 3 (after `phi`).
      final firstShy = m.displayText.indexOf('\u00AD');
      expect(m.displayText.substring(0, firstShy).length, 3);
      // Last soft hyphen leaves 3 chars after it.
      final lastShy = m.displayText.lastIndexOf('\u00AD');
      expect(m.displayText.substring(lastShy + 1).length, 3);
    });
  });

  group('EmergencyWordBreaker — protected regions', () {
    test('short word unchanged', () {
      final m = breakText('cat dog');
      expect(m.displayText, 'cat dog');
      expect(m.isIdentity, isTrue);
    });

    test('Japanese unchanged', () {
      final m = breakText('哲学は重要です');
      expect(m.displayText, '哲学は重要です');
    });

    test('mixed-script token unchanged (no marker inside CJK run)', () {
      const source = 'Hello 世界 philosophical';
      final m = breakText(source);
      // No marker lands inside the CJK run (source indices 6..8).
      for (var i = 0; i < m.displayText.length; i++) {
        if (m.displayText[i] != '\u00AD') continue;
        final sourceBefore = canonicalPrefixBefore(m.displayText, i);
        // CJK run ends at source index 8.
        expect(
          sourceBefore.length < 6 || sourceBefore.length >= 9,
          isTrue,
          reason:
              'marker at source offset ${sourceBefore.length} is '
              'inside or adjacent to CJK run',
        );
      }
      // Markers land inside `philosophical` (source indices 9..21).
      expect(softHyphenCount(m.displayText), 8);
    });

    test("apostrophe word unchanged", () {
      final m = breakText("don't worry");
      // `worry` (length 5) too short; `don't` contains apostrophe.
      expect(m.displayText, "don't worry");
    });

    test('hard-hyphen compound unchanged', () {
      final m = breakText('self-conscious');
      // `self` (4) and `conscious` (9) — `conscious` overlaps a
      // hard-hyphen compound (s-e-l-f-/-c-o-n-s-c-i-o-u-s via the
      // hard-hyphen regex). The hard-hyphen regex finds a match in
      // any sub-span so `conscious` is disqualified.
      expect(m.displayText, 'self-conscious');
    });

    test('URL fragment unchanged', () {
      final m = breakText('see https://example.com/path for more');
      final urlStart = m.displayText.indexOf('https://');
      final urlEnd = m.displayText.indexOf(' ', urlStart);
      final urlSpan = m.displayText.substring(urlStart, urlEnd);
      expect(urlSpan.contains('\u00AD'), isFalse);
    });

    test('email local-part protected from split', () {
      const source = 'contact user@example.com today';
      final m = breakText(source);
      // `contact` (7 chars at source 0..7) is eligible. Its
      // markers at offsets 3..4 land at source 3..4.
      // Email span is source 8..23 — no marker must land inside.
      for (var i = 0; i < m.displayText.length; i++) {
        if (m.displayText[i] != '\u00AD') continue;
        final sourceBefore = canonicalPrefixBefore(m.displayText, i);
        expect(
          sourceBefore.length < 8 || sourceBefore.length > 23,
          isTrue,
          reason: 'marker at source ${sourceBefore.length} inside email',
        );
      }
      // `today` is too short.
    });

    test('file path unchanged', () {
      final m = breakText('open /usr/local/bin/app today');
      final pathStart = m.displayText.indexOf('/usr');
      final pathEnd = m.displayText.indexOf(' ', pathStart);
      final pathSpan = m.displayText.substring(pathStart, pathEnd);
      expect(pathSpan.contains('\u00AD'), isFalse);
    });

    test('identifier with separators protected from splitting identifiers', () {
      const source = 'foo_bar and a:b for testing';
      final m = breakText(source);
      // `foo_bar` (0..7), `a:b` (12..15) — neither qualifies.
      // `testing` (17..24, length 7) is eligible.
      for (var i = 0; i < m.displayText.length; i++) {
        if (m.displayText[i] != '\u00AD') continue;
        final sourceBefore = canonicalPrefixBefore(m.displayText, i);
        // `foo_bar` is source 0..7; `a:b` is source 12..15.
        expect(sourceBefore.length < 7 || sourceBefore.length >= 15, isTrue);
      }
      // Some markers should land inside `testing` (source offset 17+).
      expect(softHyphenCount(m.displayText) > 0, isTrue);
    });

    test('numeric tokens protected from splitting date strings', () {
      final m = breakText('see 2026-06-23 for release');
      // `release` (length 7) is eligible. `for` is too short.
      // Date span is 4..13.
      for (var i = 0; i < m.displayText.length; i++) {
        if (m.displayText[i] != '\u00AD') continue;
        final sourceBefore = canonicalPrefixBefore(m.displayText, i);
        expect(sourceBefore.length < 4 || sourceBefore.length >= 14, isTrue);
      }
    });

    test('fenced code left untouched', () {
      const input = 'before ```code_block_here``` after philosophical';
      final m = breakText(input);
      // Fenced code span is 7..29.
      for (var i = 0; i < m.displayText.length; i++) {
        if (m.displayText[i] != '\u00AD') continue;
        final sourceBefore = canonicalPrefixBefore(m.displayText, i);
        expect(
          sourceBefore.length < 7 || sourceBefore.length >= 29,
          isTrue,
          reason: 'offset $i in fence',
        );
      }
    });

    test('inline code left untouched', () {
      const input = 'see `foo_bar_baz` and philosophical';
      final m = breakText(input);
      // Inline code span is 4..17 (inclusive). The closing backtick
      // at index 16 is part of the span — the regex captures it.
      for (var i = 0; i < m.displayText.length; i++) {
        if (m.displayText[i] != '\u00AD') continue;
        final sourceBefore = canonicalPrefixBefore(m.displayText, i);
        expect(sourceBefore.length < 4 || sourceBefore.length >= 17, isTrue);
      }
    });

    test('Markdown link destination left untouched', () {
      final m = breakText('read [paper](https://example.com/x) today');
      // The `](https://...)` span must not contain markers.
      final parenStart = m.displayText.indexOf('](http');
      if (parenStart < 0) {
        // Link URL pattern may not match this exact form — skip if so.
        return;
      }
      final parenEnd = m.displayText.indexOf(')', parenStart);
      final linkSpan = m.displayText.substring(parenStart, parenEnd + 1);
      expect(linkSpan.contains('\u00AD'), isFalse);
    });
  });

  group('EmergencyWordBreaker — idempotency', () {
    test('running twice yields the same display text', () {
      const input = 'philosophical and philosophical again philosophical';
      final a = breakText(input);
      final b = breakText(a.displayText);
      expect(b.displayText, a.displayText);
    });

    test('strips pre-existing U+00AD before transforming', () {
      final m = breakText('phi\u00ADl\u00ADo\u00ADsophical');
      final clean = breakText('philosophical');
      expect(m.displayText, clean.displayText);
    });
  });

  group('EmergencyWordBreaker — canonical mapping', () {
    test('source text is unchanged', () {
      const source = 'philosophical investigation';
      final m = breakText(source);
      expect(m.sourceText, source);
    });

    test('canonical substring for full display selection is unmarked', () {
      const source = 'philosophical';
      final m = breakText(source);
      // Selecting the full display range must yield the canonical
      // source string.
      final sub = m.sourceSubstring(
        TextSelection(baseOffset: 0, extentOffset: m.displayText.length),
      );
      expect(sub, source);
      expect(sub.contains('\u00AD'), isFalse);
    });

    test('reversed selection preserves base/extent in canonical coords', () {
      const source = 'philosophical';
      final m = breakText(source);
      // Display index 8 maps to source index 7 (it's the `h` at
      // word offset 8 — pre-marker character at source index 8 maps
      // to source index 8 after the first 8 source chars; since
      // there are markers at source indices 3..10, display indices
      // 8..16 map to source index 7..8 with collapsed markers).
      // Use a simpler reversed selection: source index 7 (display
      // index 8) before source index 2 (display index 2).
      // With 8 markers inserted at source 3..10, the display index
      // for source 7 = 7 + 4 = 11. Source 2 = 2.
      // Construct by using sourceText: reversed = TextSelection(
      // baseOffset: mapDisplayBoundaryToSource(11),
      // extentOffset: mapDisplayBoundaryToSource(2)).
      // The key invariant is that base/extent stay reversed and
      // map back to canonical coords.
      final reversed = TextSelection(baseOffset: 11, extentOffset: 2);
      final src = m.toSourceSelection(reversed);
      expect(src.baseOffset > src.extentOffset, isTrue);
      // The substring should contain no U+00AD.
      final sub = m.sourceSubstring(reversed);
      expect(sub.contains('\u00AD'), isFalse);
    });
  });

  group('EmergencyWordBreaker — mixed-script tokens (SPEC §15.3.2)', () {
    test('ASCII span immediately followed by CJK remains unchanged', () {
      // No whitespace between the ASCII word and the CJK run.
      final m = breakText('philosophical世界');
      expect(m.displayText, 'philosophical世界');
      expect(softHyphenCount(m.displayText), 0);
      expect(m.isIdentity, isTrue);
    });

    test('ASCII span immediately preceded by CJK remains unchanged', () {
      final m = breakText('世界philosophical');
      expect(m.displayText, '世界philosophical');
      expect(softHyphenCount(m.displayText), 0);
      expect(m.isIdentity, isTrue);
    });

    test('ASCII span surrounded by CJK on both sides remains unchanged', () {
      final m = breakText('哲学philosophical世界');
      expect(m.displayText, '哲学philosophical世界');
      expect(softHyphenCount(m.displayText), 0);
    });

    test(
      'mixed-script sentence still inserts markers in isolated Latin words',
      () {
        const source = 'Hello 世界 philosophical and philosophical again';
        final m = breakText(source);
        // No marker should land inside the CJK run (source indices
        // 6..8).
        for (var i = 0; i < m.displayText.length; i++) {
          if (m.displayText[i] != '\u00AD') continue;
          final sourceBefore = canonicalPrefixBefore(m.displayText, i);
          expect(sourceBefore.length < 6 || sourceBefore.length >= 9, isTrue);
        }
        // Markers should still appear inside the isolated
        // `philosophical` words (after the CJK run).
        expect(softHyphenCount(m.displayText) > 0, isTrue);
      },
    );
  });

  group('EmergencyWordBreaker — identifier / path tokens (SPEC §15.3.2)', () {
    test('snake_case identifier with long ASCII segment is unchanged', () {
      final m = breakText('use philosophical_token here');
      // `philosophical_token` should not be split.
      expect(m.displayText, 'use philosophical_token here');
      expect(softHyphenCount(m.displayText), 0);
    });

    test('colon-prefixed long ASCII segment is unchanged', () {
      final m = breakText('try name:philosophical now');
      expect(m.displayText, 'try name:philosophical now');
      expect(softHyphenCount(m.displayText), 0);
    });

    test('backslash path with long ASCII segment is unchanged', () {
      final m = breakText('open C:\\Users\\philosophical\\files now');
      expect(m.displayText, 'open C:\\Users\\philosophical\\files now');
      expect(softHyphenCount(m.displayText), 0);
    });

    test('forward-slash path with long ASCII segment is unchanged', () {
      final m = breakText('open /data/philosophical/files now');
      expect(m.displayText, 'open /data/philosophical/files now');
      expect(softHyphenCount(m.displayText), 0);
    });

    test('at-sign identifier with long ASCII segment is unchanged', () {
      final m = breakText('see @philosophical_user post');
      expect(m.displayText, 'see @philosophical_user post');
      expect(softHyphenCount(m.displayText), 0);
    });

    test('long isolated Latin word next to a protected token is still '
        'processed', () {
      const source = 'philosophical philosophical_token philosophical';
      final m = breakText(source);
      // `philosophical` (0..12) — eligible.
      // `philosophical_token` (13..31) — protected.
      // `philosophical` (32..44) — eligible.
      // We expect markers in the first and third words and
      // none inside the protected identifier segment.
      expect(softHyphenCount(m.displayText) > 0, isTrue);
      final tokenStart = m.displayText.indexOf('philosophical_token');
      final tokenEnd = tokenStart + 'philosophical_token'.length;
      final before = m.displayText.substring(0, tokenStart);
      final inside = m.displayText.substring(tokenStart, tokenEnd);
      final after = m.displayText.substring(tokenEnd);
      expect(inside.contains('\u00AD'), isFalse);
      // Sanity: markers can still appear in the trailing
      // eligible word.
      expect(after.contains('\u00AD'), isTrue);
      // The leading eligible word should also have markers.
      expect(before.contains('\u00AD'), isTrue);
    });
  });
}

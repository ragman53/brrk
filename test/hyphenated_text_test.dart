// SPDX-License-Identifier: MIT
//
// Tests for FEAT-SPEC §8 — production display-to-source mapping
// (`HyphenatedText`).
//
// Phase B soft-hyphen mapping tests continue to live in
// `test/soft_hyphen_mapping_test.dart`; this file exercises the
// production-shaped class.

import 'package:brrk/src/app/reader/hyphenation/hyphenated_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HyphenatedText.fromInsertionOffsets', () {
    test('identity when no insertions', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'philosophical',
        insertBeforeSourceBoundary: const <int>[],
      );
      expect(m.sourceText, 'philosophical');
      expect(m.displayText, 'philosophical');
      expect(m.isIdentity, isTrue);
      expect(
        m.sourceSubstring(const TextSelection(baseOffset: 0, extentOffset: 5)),
        'philo',
      );
    });

    test('single soft hyphen', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'philosophical',
        insertBeforeSourceBoundary: const <int>[5],
      );
      expect(m.displayText, 'philo\u00ADsophical');
      expect(m.displayText.length, 'philosophical'.length + 1);
      expect(
        m.displayBoundaryToSourceBoundary.length,
        m.displayText.length + 1,
      );
      // Both display boundaries around the marker map to source 5.
      expect(m.displayBoundaryToSourceBoundary[5], 5);
      expect(m.displayBoundaryToSourceBoundary[6], 5);
    });

    test('multiple soft hyphens preserve boundary mapping', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'philosophical',
        insertBeforeSourceBoundary: const <int>[5, 10],
      );
      expect(m.displayText, 'philo\u00ADsophi\u00ADcal');
      // Both display boundaries surrounding each soft hyphen must
      // map to the same canonical source boundary. The factory
      // inserts each marker at index (marker display position +
      // marker count) so we look up by display position of the soft
      // hyphen itself.
      final firstShy = m.displayText.indexOf('\u00AD');
      final secondShy = m.displayText.indexOf('\u00AD', firstShy + 1);
      expect(m.displayBoundaryToSourceBoundary[firstShy], 5);
      expect(m.displayBoundaryToSourceBoundary[firstShy + 1], 5);
      expect(m.displayBoundaryToSourceBoundary[secondShy], 10);
      expect(m.displayBoundaryToSourceBoundary[secondShy + 1], 10);
    });

    test('reversed selections preserve base/extent', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'philosophical',
        insertBeforeSourceBoundary: const <int>[5],
      );
      // Display: 'philo\u00ADsophical'. Display index 7 is the 's'
      // after the soft hyphen (display offset 5). Display index 3 is
      // 'l'. base/extent must be mapped independently so callers
      // that care about anchor/extent order still see the same
      // direction in canonical source coordinates.
      final reversed = TextSelection(baseOffset: 7, extentOffset: 3);
      final src = m.toSourceSelection(reversed);
      // Display 7 is 's' in 'sophical' → source 6.
      // Display 3 is 'l' in 'philo' → source 3.
      expect(src.baseOffset, 6);
      expect(src.extentOffset, 3);
      expect(src.baseOffset > src.extentOffset, isTrue);
      expect(m.sourceSubstring(reversed), 'los');
    });

    test('forward selections preserve base/extent', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'philosophical',
        insertBeforeSourceBoundary: const <int>[5],
      );
      final sel = TextSelection(baseOffset: 0, extentOffset: 6);
      final src = m.toSourceSelection(sel);
      // Display 0 maps to source 0. Display 6 is the soft hyphen,
      // which collapses to source boundary 5.
      expect(src.baseOffset, 0);
      expect(src.extentOffset, 5);
      expect(src.baseOffset < src.extentOffset, isTrue);
    });

    test('clamping for out-of-range display boundaries', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'philosophical',
        insertBeforeSourceBoundary: const <int>[5],
      );
      expect(m.mapDisplayBoundaryToSource(-10), 0);
      expect(
        m.mapDisplayBoundaryToSource(m.displayText.length + 50),
        m.sourceText.length,
      );
    });

    test('canonical substring contains no U+00AD', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'philosophical',
        insertBeforeSourceBoundary: const <int>[5, 8, 11],
      );
      for (final sel in [
        const TextSelection(baseOffset: 0, extentOffset: 5),
        const TextSelection(baseOffset: 0, extentOffset: 6),
        const TextSelection(baseOffset: 5, extentOffset: 6),
        const TextSelection(baseOffset: 5, extentOffset: 13),
        const TextSelection(baseOffset: 0, extentOffset: 13),
        const TextSelection.collapsed(offset: 4),
      ]) {
        final sub = m.sourceSubstring(sel);
        expect(sub.contains('\u00AD'), isFalse, reason: 'sel=$sel sub="$sub"');
      }
    });

    test('insertion offset outside valid range is ignored', () {
      final m = HyphenatedText.fromInsertionOffsets(
        'hi',
        insertBeforeSourceBoundary: const <int>[0, 3, -1, 5],
      );
      expect(m.displayText, 'hi');
    });
  });

  group('HyphenatedText.fromDisplayText', () {
    test('rebuilds source by stripping soft hyphens', () {
      final m = HyphenatedText.fromDisplayText('philo\u00ADsophi\u00ADcal');
      expect(m.sourceText, 'philosophical');
      expect(
        m.sourceSubstring(const TextSelection(baseOffset: 0, extentOffset: 6)),
        'philo',
      );
    });

    test('Japanese unchanged (no soft hyphens present)', () {
      const display = '哲学は重要です';
      final m = HyphenatedText.fromDisplayText(display);
      expect(m.sourceText, display);
      expect(m.isIdentity, isTrue);
    });
  });
}

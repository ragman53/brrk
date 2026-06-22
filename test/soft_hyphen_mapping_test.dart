// SPDX-License-Identifier: MIT
//
// Phase B soft-hyphen selection gate mapping tests.
//
// Tests the spike-only helper, not production hyphenation.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/reader/hyphenation/soft_hyphen_mapping.dart';

void main() {
  group('SoftHyphenMapping', () {
    test('builds display text and boundary map from source + offsets', () {
      const source = 'philosophical';
      // Insert at source boundaries 3, 6, 10 (phi|los|ophi|cal).
      final mapping = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [3, 6, 10],
      );
      expect(mapping.sourceText, source);
      expect(mapping.displayText, 'phi\u00ADlos\u00ADophi\u00ADcal');
      expect(
        mapping.displayBoundaryToSourceBoundary.length,
        mapping.displayText.length + 1,
      );
      expect(mapping.displayBoundaryToSourceBoundary.first, 0);
      expect(mapping.displayBoundaryToSourceBoundary.last, source.length);
    });

    test('clamps and maps display boundary to source boundary', () {
      const source = 'philosophical';
      final mapping = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [3, 6, 10],
      );
      // First soft hyphen sits at display boundaries 3 and 4.
      expect(mapping.mapDisplayBoundaryToSource(3), 3);
      expect(mapping.mapDisplayBoundaryToSource(4), 3);
      // Second soft hyphen sits at display boundaries 7 and 8.
      expect(mapping.mapDisplayBoundaryToSource(7), 6);
      expect(mapping.mapDisplayBoundaryToSource(8), 6);
      // Third soft hyphen sits at display boundaries 12 and 13.
      expect(mapping.mapDisplayBoundaryToSource(12), 10);
      expect(mapping.mapDisplayBoundaryToSource(13), 10);
      // Clamping.
      expect(mapping.mapDisplayBoundaryToSource(-5), 0);
      expect(
        mapping.mapDisplayBoundaryToSource(mapping.displayText.length + 10),
        source.length,
      );
    });

    test('sourceSubstring is empty for collapsed selection', () {
      const source = 'philosophical';
      final mapping = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [3, 6, 10],
      );
      expect(
        mapping.sourceSubstring(const TextSelection.collapsed(offset: 4)),
        '',
      );
    });

    test(
      'sourceSubstring strips soft hyphens for selection spanning a hyphen',
      () {
        const source = 'philosophical';
        final mapping = SoftHyphenMapping.fromInsertionOffsets(
          source,
          insertBeforeSourceBoundary: const [3, 6, 10],
        );
        // Display: 'phi\u00ADlos\u00ADophi\u00ADcal' length 16.
        // Selecting 'phi\u00ADlos' (display 0..7) maps to source 0..6.
        final sel = const TextSelection(baseOffset: 0, extentOffset: 7);
        final s = mapping.sourceSubstring(sel);
        expect(s, 'philos');
        expect(s.contains('\u00AD'), isFalse);
      },
    );

    test('sourceSubstring handles reversed selections', () {
      const source = 'philosophical';
      final mapping = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [3, 6, 10],
      );
      final sel = const TextSelection(baseOffset: 7, extentOffset: 0);
      final s = mapping.sourceSubstring(sel);
      expect(s, 'philos');
      expect(s.contains('\u00AD'), isFalse);
    });

    test('sourceSubstring handles multiple soft hyphens inside selection', () {
      const source = 'philosophical';
      final mapping = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [3, 6, 10],
      );
      // Display: 'phi\u00ADlos\u00ADophi\u00ADcal' length 16.
      // Selecting 0..12 covers two soft hyphens and the source span
      // 'philosophi' (length 11).
      final sel = const TextSelection(baseOffset: 0, extentOffset: 12);
      final s = mapping.sourceSubstring(sel);
      expect(s, 'philosophi');
      expect(s.contains('\u00AD'), isFalse);
    });

    test('sourceSubstring clamps out-of-range display boundaries', () {
      const source = 'philosophical';
      final mapping = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [3, 6, 10],
      );
      // Boundary clamps for out-of-range display positions.
      expect(mapping.mapDisplayBoundaryToSource(-5), 0);
      expect(
        mapping.mapDisplayBoundaryToSource(mapping.displayText.length + 99),
        source.length,
      );
      // Full-display selection still produces the full source string.
      final fullDisplaySel = TextSelection(
        baseOffset: 0,
        extentOffset: mapping.displayText.length,
      );
      final s = mapping.sourceSubstring(fullDisplaySel);
      expect(s, source);
      expect(s.contains('\u00AD'), isFalse);
    });

    test('fromDisplayText builds canonical mapping for callback text', () {
      const display = 'phi\u00ADlos\u00ADophi\u00ADcal';
      final mapping = SoftHyphenMapping.fromDisplayText(display);
      expect(mapping.sourceText, 'philosophical');
      expect(mapping.displayText, display);
      expect(mapping.mapDisplayBoundaryToSource(3), 3);
      expect(mapping.mapDisplayBoundaryToSource(4), 3);
      expect(
        mapping.sourceSubstring(
          const TextSelection(baseOffset: 0, extentOffset: 7),
        ),
        'philos',
      );
    });

    test('selection starting on a soft hyphen boundary maps canonically', () {
      const display = 'phi\u00ADlos\u00ADophi\u00ADcal';
      final mapping = SoftHyphenMapping.fromDisplayText(display);
      final s = mapping.sourceSubstring(
        const TextSelection(baseOffset: 3, extentOffset: 8),
      );
      expect(s, 'los');
      expect(s.contains('\u00AD'), isFalse);
    });

    test('forced visual proof word maps to philosophical', () {
      const display = 'philo\u00ADsophical';
      final mapping = SoftHyphenMapping.fromDisplayText(display);
      expect(mapping.sourceText, 'philosophical');
      expect(mapping.mapDisplayBoundaryToSource(5), 5);
      expect(mapping.mapDisplayBoundaryToSource(6), 5);
      expect(
        mapping.sourceSubstring(
          TextSelection(baseOffset: 0, extentOffset: display.length),
        ),
        'philosophical',
      );
    });

    test('Japanese source is unchanged by mapping construction', () {
      const source = '存在';
      final mapping = SoftHyphenMapping.fromInsertionOffsets(
        source,
        // No insertions; verify empty list is fine.
        insertBeforeSourceBoundary: const [],
      );
      expect(mapping.sourceText, source);
      expect(mapping.displayText, source);
      final sel = TextSelection(baseOffset: 0, extentOffset: source.length);
      expect(mapping.sourceSubstring(sel), source);
    });

    test('idempotent: applying again does not stack soft hyphens', () {
      const source = 'philosophical';
      final first = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [3, 6, 10],
      );
      // The display text already has soft hyphens; a second pass on
      // the source has nothing to insert, so the mapping is the same.
      final second = SoftHyphenMapping.fromInsertionOffsets(
        source,
        insertBeforeSourceBoundary: const [],
      );
      expect(second.displayText, source);
      expect(first.sourceText, second.sourceText);
    });
  });

  group('removeSoftHyphens', () {
    test('removes all U+00AD characters', () {
      expect(
        removeSoftHyphens('phi\u00ADlos\u00ADophi\u00ADcal'),
        'philosophical',
      );
      expect(removeSoftHyphens('investigation'), 'investigation');
      expect(removeSoftHyphens(''), '');
    });
  });
}

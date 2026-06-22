// SPDX-License-Identifier: MIT
//
// Tests for FEAT-SPEC §10.4 / §10.5 / §10.6 / §10.7 / §10.8 painter.
//
// These tests focus on the parts of the painter that do not require a
// real Android device: shouldRepaint, buildProbePainter, the
// non-breaking-marker guard, and the inside-bounds policy. The
// actual painted pixel position of the decorative hyphen on a real
// device is FEAT-SPEC §16 stop-condition territory and is validated
// by the real-device overlay gate.

import 'dart:ui' show Locale, PictureRecorder, Canvas, Size;

import 'package:brrk/src/app/reader/hyphenation/reader_text_layout_spec.dart';
import 'package:brrk/src/app/reader/hyphenation/visible_hyphen_painter.dart';
import 'package:flutter/painting.dart'
    show TextAlign, TextDirection, TextStyle, TextWidthBasis;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 17);

  ReaderTextLayoutSpec spec({
    String displayText = 'philosophical',
    TextAlign textAlign = TextAlign.justify,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return ReaderTextLayoutSpec(
      displayText: displayText,
      resolvedTextStyle: baseStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      textWidthBasis: TextWidthBasis.parent,
      locale: const Locale('en', 'US'),
    );
  }

  Canvas newCanvas() => Canvas(PictureRecorder());

  group('VisibleHyphenPainter.shouldRepaint', () {
    test('returns false when spec and maxWidth are equal', () {
      final a = VisibleHyphenPainter(spec: spec(), maxWidth: 320);
      final b = VisibleHyphenPainter(spec: spec(), maxWidth: 320);
      expect(b.shouldRepaint(a), isFalse);
    });

    test('returns true when displayText differs', () {
      final a = VisibleHyphenPainter(spec: spec(), maxWidth: 320);
      final b = VisibleHyphenPainter(
        spec: spec(displayText: 'philo\u00ADsophical'),
        maxWidth: 320,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when maxWidth changes', () {
      final a = VisibleHyphenPainter(spec: spec(), maxWidth: 320);
      final b = VisibleHyphenPainter(spec: spec(), maxWidth: 360);
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when textAlign changes (defensive)', () {
      final a = VisibleHyphenPainter(spec: spec(), maxWidth: 320);
      final b = VisibleHyphenPainter(
        spec: spec(textAlign: TextAlign.start),
        maxWidth: 320,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when textDirection changes', () {
      final a = VisibleHyphenPainter(spec: spec(), maxWidth: 320);
      final b = VisibleHyphenPainter(
        spec: spec(textDirection: TextDirection.rtl),
        maxWidth: 320,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when cursorWidth changes', () {
      final a = VisibleHyphenPainter(
        spec: spec(),
        maxWidth: 320,
        cursorWidth: 2.0,
      );
      final b = VisibleHyphenPainter(
        spec: spec(),
        maxWidth: 320,
        cursorWidth: 4.0,
      );
      expect(b.shouldRepaint(a), isTrue);
    });
  });

  group('VisibleHyphenPainter.buildProbePainter', () {
    test('mirrors spec.textAlign (not hardcoded justify)', () {
      final painter = VisibleHyphenPainter(
        spec: spec(textAlign: TextAlign.start),
        maxWidth: 320,
      );
      final probe = painter.buildProbePainter();
      expect(probe.textAlign, TextAlign.start);
    });

    test('layout succeeds with a positive finite width', () {
      final painter = VisibleHyphenPainter(spec: spec(), maxWidth: 320);
      final probe = painter.buildProbePainter();
      expect(probe.width, isNonZero);
      expect(probe.width, lessThanOrEqualTo(320));
    });

    test('layout succeeds when maxWidth is non-finite', () {
      final painter = VisibleHyphenPainter(
        spec: spec(),
        maxWidth: double.infinity,
      );
      final probe = painter.buildProbePainter();
      expect(probe.width, greaterThan(0));
    });
  });

  group('VisibleHyphenPainter paint guards (FEAT-SPEC §10.5 / §10.7)', () {
    test('does not throw when textAlign is not justify', () {
      final painter = VisibleHyphenPainter(
        spec: spec(textAlign: TextAlign.start),
        maxWidth: 320,
      );
      final probe = painter.buildProbePainter();
      // We only assert "does not throw" and "is a no-op" — the
      // gate skip is the structural contract.
      expect(
        () => painter.paint(newCanvas(), Size(probe.width, probe.height)),
        returnsNormally,
      );
    });

    test('does not throw on empty display text', () {
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: ''),
        maxWidth: 320,
      );
      final probe = painter.buildProbePainter();
      expect(
        () => painter.paint(newCanvas(), Size(probe.width, probe.height)),
        returnsNormally,
      );
    });

    test('does not throw when maxWidth is zero / non-finite', () {
      final painter = VisibleHyphenPainter(spec: spec(), maxWidth: 0);
      expect(
        () => painter.paint(newCanvas(), const Size(320, 200)),
        returnsNormally,
      );
      final painter2 = VisibleHyphenPainter(
        spec: spec(),
        maxWidth: double.infinity,
      );
      expect(
        () => painter2.paint(newCanvas(), const Size(320, 200)),
        returnsNormally,
      );
    });

    test('does not throw on a soft hyphen at display-text boundaries', () {
      // FEAT-SPEC §10.5 step 1: markers at offset 0/length are ignored.
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: '\u00ADhi'),
        maxWidth: 320,
      );
      final probe = painter.buildProbePainter();
      expect(
        () => painter.paint(newCanvas(), Size(probe.width, probe.height)),
        returnsNormally,
      );
    });

    test('does not throw when forced wrap text does not break', () {
      // Same width as the word fits — no `U+00AD` break expected,
      // painter must simply omit the glyph.
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: 'philo\u00ADsophical'),
        maxWidth: 1024,
      );
      expect(
        () => painter.paint(newCanvas(), const Size(1024, 200)),
        returnsNormally,
      );
    });
  });

  group('VisibleHyphenPainter.computePlacements', () {
    test('uses SelectableText effective width by default', () {
      expect(visibleHyphenEffectiveWidth(containerWidth: 104), 101.0);
      expect(
        visibleHyphenEffectiveWidth(containerWidth: 104, cursorWidth: 4),
        99.0,
      );
    });

    test('returns zero without soft hyphen markers', () {
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: 'philosophical philosophical'),
        maxWidth: 80,
      );
      expect(painter.computePlacements(), isEmpty);
    });

    test('returns zero when marked word fits without wrapping', () {
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: 'philo\u00ADsophical'),
        maxWidth: 1024,
      );
      expect(painter.computePlacements(), isEmpty);
    });

    test('returns one placement for forced soft-hyphen wrap', () {
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: 'philo\u00ADsophical'),
        maxWidth: 60,
      );

      final placements = painter.computePlacements();

      expect(placements, hasLength(1));
      expect(placements.single.shyOffset, 5);
      expect(placements.single.x, greaterThanOrEqualTo(0));
      expect(
        placements.single.x,
        lessThanOrEqualTo(visibleHyphenEffectiveWidth(containerWidth: 60)),
      );
      expect(placements.single.y.isFinite, isTrue);
    });

    test('returns one placement per confirmed soft-hyphen wrap', () {
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: 'philo\u00ADsophi\u00ADcal'),
        maxWidth: 60,
      );

      final placements = painter.computePlacements();

      expect(placements.map((p) => p.shyOffset), [5, 11]);
      for (final placement in placements) {
        expect(placement.x, greaterThanOrEqualTo(0));
        expect(
          placement.x,
          lessThanOrEqualTo(visibleHyphenEffectiveWidth(containerWidth: 60)),
        );
        expect(placement.y.isFinite, isTrue);
      }
    });

    test('returns zero for non-justified text', () {
      final painter = VisibleHyphenPainter(
        spec: spec(
          displayText: 'philo\u00ADsophical',
          textAlign: TextAlign.start,
        ),
        maxWidth: 60,
      );
      expect(painter.computePlacements(), isEmpty);
    });
  });
}

// SPDX-License-Identifier: MIT
//
// Tests for FEAT-SPEC §10.4 / §10.5 / §10.6 / §10.7 / §10.8 painter.
//
// These tests focus on the parts of the painter that do not require a
// real Android device: shouldRepaint, buildProbePainter, the
// non-breaking-marker guard, and the hanging paint-gutter policy. The
// actual painted pixel position of the decorative hyphen on a real
// device is FEAT-SPEC §16 stop-condition territory and is validated
// by the real-device overlay gate.

import 'dart:ui' show Locale, PictureRecorder, Canvas, Size, TextBaseline;

import 'package:brrk/src/app/reader/hyphenation/reader_text_layout_spec.dart';
import 'package:brrk/src/app/reader/hyphenation/visible_hyphen_painter.dart';
import 'package:flutter/painting.dart'
    show
        TextAlign,
        TextDirection,
        TextPainter,
        TextSpan,
        TextStyle,
        TextWidthBasis;
import 'package:flutter/rendering.dart' show TextPosition;
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

  double hyphenWidth(ReaderTextLayoutSpec spec) {
    final painter = TextPainter(
      text: TextSpan(
        text: VisibleHyphenPainter.decorativeHyphen,
        style: spec.resolvedTextStyle,
      ),
      textDirection: spec.textDirection,
      textScaler: spec.resolvedTextScaler,
      locale: spec.locale,
      textHeightBehavior: spec.textHeightBehavior,
    )..layout();
    return painter.width;
  }

  group('VisibleHyphenPainter.shouldRepaint', () {
    test('returns false when spec and layoutWidth are equal', () {
      final a = VisibleHyphenPainter(spec: spec(), layoutWidth: 320);
      final b = VisibleHyphenPainter(spec: spec(), layoutWidth: 320);
      expect(b.shouldRepaint(a), isFalse);
    });

    test('returns true when displayText differs', () {
      final a = VisibleHyphenPainter(spec: spec(), layoutWidth: 320);
      final b = VisibleHyphenPainter(
        spec: spec(displayText: 'philo\u00ADsophical'),
        layoutWidth: 320,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when layoutWidth changes', () {
      final a = VisibleHyphenPainter(spec: spec(), layoutWidth: 320);
      final b = VisibleHyphenPainter(spec: spec(), layoutWidth: 360);
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when textAlign changes (defensive)', () {
      final a = VisibleHyphenPainter(spec: spec(), layoutWidth: 320);
      final b = VisibleHyphenPainter(
        spec: spec(textAlign: TextAlign.start),
        layoutWidth: 320,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when textDirection changes', () {
      final a = VisibleHyphenPainter(spec: spec(), layoutWidth: 320);
      final b = VisibleHyphenPainter(
        spec: spec(textDirection: TextDirection.rtl),
        layoutWidth: 320,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when cursorWidth changes', () {
      final a = VisibleHyphenPainter(
        spec: spec(),
        layoutWidth: 320,
        cursorWidth: 2.0,
      );
      final b = VisibleHyphenPainter(
        spec: spec(),
        layoutWidth: 320,
        cursorWidth: 4.0,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when right paint overflow changes', () {
      final a = VisibleHyphenPainter(
        spec: spec(),
        layoutWidth: 320,
        rightPaintOverflow: 0,
      );
      final b = VisibleHyphenPainter(
        spec: spec(),
        layoutWidth: 320,
        rightPaintOverflow: 16,
      );
      expect(b.shouldRepaint(a), isTrue);
    });
  });

  group('VisibleHyphenPainter.buildProbePainter', () {
    test('mirrors spec.textAlign (not hardcoded justify)', () {
      final painter = VisibleHyphenPainter(
        spec: spec(textAlign: TextAlign.start),
        layoutWidth: 320,
      );
      final probe = painter.buildProbePainter();
      expect(probe.textAlign, TextAlign.start);
    });

    test('layout succeeds with a positive finite width', () {
      final painter = VisibleHyphenPainter(spec: spec(), layoutWidth: 320);
      final probe = painter.buildProbePainter();
      expect(probe.width, isNonZero);
      expect(probe.width, lessThanOrEqualTo(320));
    });

    test('layout succeeds when layoutWidth is non-finite', () {
      final painter = VisibleHyphenPainter(
        spec: spec(),
        layoutWidth: double.infinity,
      );
      final probe = painter.buildProbePainter();
      expect(probe.width, greaterThan(0));
    });
  });

  group('VisibleHyphenPainter paint guards (FEAT-SPEC §10.5 / §10.7)', () {
    test('does not throw when textAlign is not justify', () {
      final painter = VisibleHyphenPainter(
        spec: spec(textAlign: TextAlign.start),
        layoutWidth: 320,
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
        layoutWidth: 320,
      );
      final probe = painter.buildProbePainter();
      expect(
        () => painter.paint(newCanvas(), Size(probe.width, probe.height)),
        returnsNormally,
      );
    });

    test('does not throw when layoutWidth is zero / non-finite', () {
      final painter = VisibleHyphenPainter(spec: spec(), layoutWidth: 0);
      expect(
        () => painter.paint(newCanvas(), const Size(320, 200)),
        returnsNormally,
      );
      final painter2 = VisibleHyphenPainter(
        spec: spec(),
        layoutWidth: double.infinity,
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
        layoutWidth: 320,
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
        layoutWidth: 1024,
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
        layoutWidth: 80,
      );
      expect(painter.computePlacements(), isEmpty);
    });

    test('returns zero when marked word fits without wrapping', () {
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: 'philo\u00ADsophical'),
        layoutWidth: 1024,
      );
      expect(painter.computePlacements(), isEmpty);
    });

    test('returns one hanging placement for forced soft-hyphen wrap', () {
      const layoutWidth = 55.0;
      const rightPaintOverflow = 16.0;
      final currentSpec = spec(displayText: 'acc\u00ADelerated');
      final painter = VisibleHyphenPainter(
        spec: currentSpec,
        layoutWidth: layoutWidth,
        rightPaintOverflow: rightPaintOverflow,
      );

      final placements = painter.computePlacements();
      final width = hyphenWidth(currentSpec);
      final effective = visibleHyphenEffectiveWidth(
        containerWidth: layoutWidth,
      );

      expect(placements, hasLength(1));
      expect(placements.single.shyOffset, 3);
      expect(placements.single.x.isFinite, isTrue);
      expect(placements.single.x, greaterThanOrEqualTo(0));
      expect(
        placements.single.x,
        greaterThan(effective - width),
        reason: 'the hyphen must not be shifted left over the glyph',
      );
      expect(
        placements.single.x + width,
        greaterThan(effective),
        reason: 'the hyphen may hang beyond effective text width',
      );
      expect(
        placements.single.x + width,
        lessThanOrEqualTo(layoutWidth + rightPaintOverflow),
      );
      expect(placements.single.y.isFinite, isTrue);
    });

    test('omits a hanging placement that cannot fit in the paint gutter', () {
      const layoutWidth = 55.0;
      final painter = VisibleHyphenPainter(
        spec: spec(displayText: 'acc\u00ADelerated'),
        layoutWidth: layoutWidth,
        rightPaintOverflow: 0,
      );

      expect(painter.computePlacements(), isEmpty);
    });

    test('returns one placement per confirmed soft-hyphen wrap', () {
      const layoutWidth = 60.0;
      const rightPaintOverflow = 16.0;
      final currentSpec = spec(displayText: 'philo\u00ADsophi\u00ADcal');
      final painter = VisibleHyphenPainter(
        spec: currentSpec,
        layoutWidth: layoutWidth,
        rightPaintOverflow: rightPaintOverflow,
      );

      final placements = painter.computePlacements();
      final width = hyphenWidth(currentSpec);

      expect(placements.map((p) => p.shyOffset), [5, 11]);
      for (final placement in placements) {
        expect(placement.x, greaterThanOrEqualTo(0));
        expect(
          placement.x + width,
          lessThanOrEqualTo(layoutWidth + rightPaintOverflow),
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
        layoutWidth: 60,
      );
      expect(painter.computePlacements(), isEmpty);
    });
  });

  group('VisibleHyphenPainter baseline alignment', () {
    test('placement uses alphabetic baseline, not TextBox.top', () {
      const layoutWidth = 55.0;
      const rightPaintOverflow = 16.0;
      final currentSpec = spec(displayText: 'acc\u00ADelerated');
      final painter = VisibleHyphenPainter(
        spec: currentSpec,
        layoutWidth: layoutWidth,
        rightPaintOverflow: rightPaintOverflow,
      );

      final placements = painter.computePlacements();
      expect(placements, isNotEmpty);

      final probe = painter.buildProbePainter(width: layoutWidth);
      final lineMetrics = probe.computeLineMetrics();
      expect(lineMetrics, isNotEmpty);

      // Build hyphen painter and measure its ascent — it must match the
      // same spec so the baseline alignment is correct.
      final hyphenPainter = TextPainter(
        text: TextSpan(
          text: VisibleHyphenPainter.decorativeHyphen,
          style: currentSpec.resolvedTextStyle,
        ),
        textDirection: currentSpec.textDirection,
        textScaler: currentSpec.resolvedTextScaler,
        locale: currentSpec.locale,
        textHeightBehavior: currentSpec.textHeightBehavior,
      )..layout();
      final hyphenAscent = hyphenPainter.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );

      for (final placement in placements) {
        // Compute the expected y from the alphabetic baseline of the
        // text line.
        final lineBoundary = probe.getLineBoundary(
          TextPosition(offset: placement.shyOffset - 1),
        );
        final lineStarts = <int>[];
        var checkOffset = 0;
        for (var i = 0; i < lineMetrics.length; i++) {
          final boundary = probe.getLineBoundary(
            TextPosition(offset: checkOffset),
          );
          lineStarts.add(boundary.start);
          checkOffset = boundary.end.clamp(0, probe.text!.toPlainText().length);
        }
        final lineIdx = lineStarts.indexOf(lineBoundary.start);
        expect(lineIdx, greaterThanOrEqualTo(0));
        var lineTop = 0.0;
        for (var i = 0; i < lineIdx; i++) {
          lineTop += lineMetrics[i].height;
        }
        final expectedY =
            lineTop + lineMetrics[lineIdx].baseline - hyphenAscent;

        expect(placement.y, closeTo(expectedY, 1.0));
      }
    });

    test('TextStyle and TextScaler match between surfaces', () {
      const layoutWidth = 55.0;
      final currentSpec = spec(displayText: 'acc\u00ADelerated');
      final painter = VisibleHyphenPainter(
        spec: currentSpec,
        layoutWidth: layoutWidth,
        rightPaintOverflow: 16,
      );

      final probe = painter.buildProbePainter(width: layoutWidth);

      // The probe text style must share the same font, size, weight,
      // and scaler as the spec.
      expect(
        probe.text!.style!.fontFamily,
        currentSpec.resolvedTextStyle.fontFamily,
      );
      expect(
        probe.text!.style!.fontSize,
        currentSpec.resolvedTextStyle.fontSize,
      );
      expect(probe.textScaler, currentSpec.resolvedTextScaler);
    });
  });
}

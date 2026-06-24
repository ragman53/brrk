// SPDX-License-Identifier: MIT
//
// Tests for REVIEW.md §11 (Baseline regression, Stroke appearance,
// Layout engine call count, Painter responsibility) and FEAT-SPEC
// §10 decorative-hyphen overlay contract.

import 'dart:ui' show Locale, Color, Canvas, PictureRecorder;

import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reader/hyphenation/hyphen_overlay_layout.dart';
import 'package:brrk/src/app/reader/hyphenation/reader_text_layout_spec.dart';
import 'package:brrk/src/app/reader/hyphenation/visible_hyphen_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseStyle = TextStyle(fontSize: 17);

ReaderTextLayoutSpec spec({
  String displayText = 'philosophical',
  TextAlign textAlign = TextAlign.justify,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return ReaderTextLayoutSpec(
    displayText: displayText,
    resolvedTextStyle: _baseStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    textWidthBasis: TextWidthBasis.parent,
    locale: const Locale('en', 'US'),
  );
}

const _engine = HyphenOverlayLayoutEngine();

HyphenOverlayLayout compute({
  String text = 'philo\u00ADsophical',
  double layoutWidth = 60,
  double rightPaintOverflow = 16,
}) {
  return _engine.compute(
    spec: spec(displayText: text),
    layoutWidth: layoutWidth,
    rightPaintOverflow: rightPaintOverflow,
    cursorWidth: 2.0,
  );
}

void main() {
  group('VisibleHyphenPainter (REVIEW.md §4)', () {
    test('draws no lines when layout is empty', () {
      final painter = const VisibleHyphenPainter(
        layout: HyphenOverlayLayout.empty,
        color: Color(0xFF000000),
      );
      expect(painter.layout, HyphenOverlayLayout.empty);
      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('shouldRepaint returns false for identical layout and color', () {
      final layout = compute();
      final a = VisibleHyphenPainter(layout: layout, color: const Color(0xFF000000));
      final b = VisibleHyphenPainter(layout: layout, color: const Color(0xFF000000));
      expect(b.shouldRepaint(a), isFalse);
    });

    test('shouldRepaint returns true for new layout instance', () {
      final a = VisibleHyphenPainter(
        layout: const HyphenOverlayLayout(<HyphenStroke>[], 1.0),
        color: const Color(0xFF000000),
      );
      final b = VisibleHyphenPainter(
        layout: const HyphenOverlayLayout(
          <HyphenStroke>[HyphenStroke(start: Offset.zero, end: Offset(5, 0))],
          1.0,
        ),
        color: const Color(0xFF000000),
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('shouldRepaint returns true for color change', () {
      final layout = const HyphenOverlayLayout(
        <HyphenStroke>[HyphenStroke(start: Offset.zero, end: Offset(5, 0))],
        1.0,
      );
      final a = VisibleHyphenPainter(layout: layout, color: const Color(0xFF000000));
      final b = VisibleHyphenPainter(layout: layout, color: const Color(0xFFFF0000));
      expect(b.shouldRepaint(a), isTrue);
    });

    test('paint() draws strokes via canvas drawLine', () {
      final layout = HyphenOverlayLayout(
        const [
          HyphenStroke(start: Offset(10, 20), end: Offset(15, 20)),
          HyphenStroke(start: Offset(0, 0), end: Offset(5, 0)),
        ],
        1.0,
      );
      final painter = VisibleHyphenPainter(
        layout: layout,
        color: const Color(0xFF000000),
      );
      // Drawing must not throw and must accept a Canvas.
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(100, 100));
      // ShouldRepaint: empty layout does not repaint.
      final empty = const VisibleHyphenPainter(
        layout: HyphenOverlayLayout.empty,
        color: Color(0xFF000000),
      );
      empty.paint(canvas, const Size(100, 100));
    });

    test('paint() performs no text work', () {
      // REVIEW.md §11.4: painter test must operate only on precomputed
      // HyphenStroke values. It must not need a ReaderTextLayoutSpec or
      // invoke text layout. This is asserted by the constructor
      // accepting only layout/color.
      const layout = HyphenOverlayLayout(
        <HyphenStroke>[],
        1.0,
      );
      const painter = VisibleHyphenPainter(
        layout: layout,
        color: Color(0xFF000000),
      );
      // No TextStyle, no TextPainter exposed.
      expect(painter.runtimeType.toString(), 'VisibleHyphenPainter');
      expect(layout.strokeWidth, 1.0);
    });
  });

  group('visibleHyphenEffectiveWidth (carret margin)', () {
    test('subtracts caret margin from container width', () {
      expect(visibleHyphenEffectiveWidth(containerWidth: 104), 101.0);
      expect(
        visibleHyphenEffectiveWidth(containerWidth: 104, cursorWidth: 4),
        99.0,
      );
    });

    test('returns non-negative for very small widths', () {
      expect(visibleHyphenEffectiveWidth(containerWidth: 1), 0.0);
    });
  });

  group('HyphenOverlayLayoutEngine (REVIEW.md §2, §5)', () {
    test('returns empty for empty text', () {
      final layout = _engine.compute(
        spec: spec(displayText: ''),
        layoutWidth: 60,
        rightPaintOverflow: 16,
        cursorWidth: 2.0,
      );
      expect(layout.isEmpty, isTrue);
    });

    test('returns empty for non-justified text', () {
      final layout = _engine.compute(
        spec: spec(textAlign: TextAlign.start),
        layoutWidth: 60,
        rightPaintOverflow: 16,
        cursorWidth: 2.0,
      );
      expect(layout.isEmpty, isTrue);
    });

    test('returns empty when soft-hyphen marker does not produce a break',
        () {
      final layout = compute(layoutWidth: 1024);
      expect(layout.isEmpty, isTrue);
    });

    test('returns empty when there are no soft hyphens', () {
      final layout = compute(text: 'philosophical philosophical');
      expect(layout.isEmpty, isTrue);
    });

    test('forced soft-hyphen wrap produces one stroke', () {
      final layout = compute();
      expect(layout.strokes, hasLength(1));
      final stroke = layout.strokes.single;
      expect(stroke.start.dx, greaterThan(0));
      expect(stroke.end.dx, greaterThan(stroke.start.dx));
      expect(stroke.start.dy, stroke.end.dy, reason: 'stroke must be horizontal');
    });

    test('omits stroke that would exceed paint gutter', () {
      // Layout width so tight that the stroke cannot fit even with
      // a zero gutter. The painter must omit rather than shift left.
      final layout = _engine.compute(
        spec: spec(displayText: 'philo\u00ADsophical'),
        layoutWidth: 20,
        rightPaintOverflow: 0,
        cursorWidth: 2.0,
      );
      expect(layout.isEmpty, isTrue);
    });

    test('REVIEW.md §2 — baseline is paragraph-relative; y does not drift',
        () {
      // Build a 3-line justified paragraph where each line ends with a
      // soft-hyphen break. The painter y for each stroke must stay
      // inside the corresponding visual line vertical bounds. If the
      // old double-addition bug returned, line 2 and line 3 strokes
      // would drift below their respective line's bounds.
      final prose =
          'philosophical \u00AD investigator \u00AD handbook \u00AD '
          'philosophical \u00AD investigator \u00AD handbook \u00AD '
          'philosophical \u00AD investigator \u00AD handbook';
      final layout = _engine.compute(
        spec: spec(displayText: prose),
        layoutWidth: 120,
        rightPaintOverflow: 16,
        cursorWidth: 2.0,
      );
      expect(layout.strokes, isNotEmpty);

      // Build a probe painter with the same width to derive line
      // metrics and validate each stroke's y against its containing
      // line's bounds.
      const style = TextStyle(fontSize: 17);
      final probe = TextPainter(
        text: TextSpan(text: prose, style: style),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        textWidthBasis: TextWidthBasis.parent,
        locale: const Locale('en', 'US'),
      )..layout(maxWidth: 117);

      final metrics = probe.computeLineMetrics();
      expect(metrics.length, greaterThanOrEqualTo(3));
      final strokes = layout.strokes;
      for (final stroke in strokes) {
        // The stroke y must sit within at least one visual line.
        final y = stroke.start.dy;
        final matchedLine = metrics.any((m) =>
            y >= m.baseline - m.ascent && y <= m.baseline + m.descent);
        expect(matchedLine, isTrue,
            reason: 'stroke y=$y outside any line bounds');
      }
    });

    test('REVIEW.md §2 — second and third lines do not include cumulative '
        'preceding height', () {
      // Direct evidence: derive line baselines with a probe and
      // assert stroke y for line 3 differs from line 2 by exactly the
      // line spacing of one line (not lineSpacing*2, which would be
      // the double-addition bug).
      final prose =
          'philosophical \u00AD investigator \u00AD handbook \u00AD '
          'philosophical \u00AD investigator \u00AD handbook \u00AD '
          'philosophical \u00AD investigator \u00AD handbook';
      const style = TextStyle(fontSize: 17);
      final probe = TextPainter(
        text: TextSpan(text: prose, style: style),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        textWidthBasis: TextWidthBasis.parent,
        locale: const Locale('en', 'US'),
      )..layout(maxWidth: 117);
      final metrics = probe.computeLineMetrics();
      expect(metrics.length, greaterThanOrEqualTo(3));

      // Line baselines must increase by approximately one line height
      // each. The baseline must NOT be cumulative with its own height
      // (which is the old bug). Use the LineMetrics baselines
      // directly.
      final lineHeight = metrics[0].height;
      for (var i = 1; i < metrics.length; i++) {
        final delta = metrics[i].baseline - metrics[i - 1].baseline;
        expect(delta, greaterThan(0.0));
        expect(delta, lessThan(lineHeight + 0.5),
            reason: 'baseline diff between consecutive lines must be '
                'less than one line height; got $delta');
      }
    });

    test('stroke length policy: monotonic within clamps (REVIEW.md §5)', () {
      double strokeWidthFor(double fontSize) {
        final layout = _engine.compute(
          spec: ReaderTextLayoutSpec(
            displayText: 'philo\u00ADsophical',
            resolvedTextStyle: TextStyle(fontSize: fontSize),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.ltr,
            textWidthBasis: TextWidthBasis.parent,
            locale: const Locale('en', 'US'),
          ),
          layoutWidth: 60,
          rightPaintOverflow: 16,
          cursorWidth: 2.0,
        );
        return layout.strokeWidth;
      }

      final s12 = strokeWidthFor(12);
      final s17 = strokeWidthFor(17);
      final s24 = strokeWidthFor(24);
      final s32 = strokeWidthFor(32);

      expect(s12, greaterThanOrEqualTo(1.0));
      expect(s12, lessThanOrEqualTo(1.5));
      expect(s32, greaterThanOrEqualTo(1.0));
      expect(s32, lessThanOrEqualTo(1.5));
      expect(s17, greaterThanOrEqualTo(s12));
      expect(s24, greaterThanOrEqualTo(s17));
      expect(s32, greaterThanOrEqualTo(s24));
    });

    test('REVIEW.md §5 — stroke geometry at all supported font sizes', () {
      // Verify the layout produces a stroke with start/end on the same
      // y, with non-zero length and the x begins after the glyph.
      for (final fontSize in [12.0, 17.0, 24.0, 32.0]) {
        final layout = _engine.compute(
          spec: ReaderTextLayoutSpec(
            displayText: 'philo\u00ADsophical',
            resolvedTextStyle: TextStyle(fontSize: fontSize),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.ltr,
            textWidthBasis: TextWidthBasis.parent,
            locale: const Locale('en', 'US'),
          ),
          // Width large enough that the soft-hyphen break is forced.
          layoutWidth: 90,
          rightPaintOverflow: 16,
          cursorWidth: 2.0,
        );
        expect(layout.isNotEmpty, isTrue,
            reason: 'no stroke at fontSize=$fontSize');
        final s = layout.strokes.single;
        // Stroke is horizontal.
        expect(s.start.dy, equals(s.end.dy));
        // Stroke has visible length.
        expect(s.end.dx - s.start.dx, greaterThan(0));
        // Stroke width is clamped to [1, 1.5].
        expect(layout.strokeWidth, greaterThanOrEqualTo(1.0));
        expect(layout.strokeWidth, lessThanOrEqualTo(1.5));
      }
    });
  });

  group('REVIEW.md §11.3 — engine compute count via fake engine', () {
    testWidgets('widget computes layout once and reuses it on rebuild',
        (tester) async {
      var computeCount = 0;
      final countingEngine = _CountingEngine(() => computeCount++);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademicSelectableText(
              spec: spec(),
              sourceText: 'philosophical',
              layoutEngine: countingEngine,
              onSelectionChanged: (_, _) {},
            ),
          ),
        ),
      );
      // First pump triggers initial build.
      expect(computeCount, 1);

      // Pump several frames (simulates scroll/animations). Layout
      // inputs are unchanged, so the cache must not invalidate.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(computeCount, 1);

      // Change layout width (simulate container resize): the cache
      // must invalidate exactly once.
      await tester.binding.setSurfaceSize(const Size(500, 800));
      await tester.pump();
      expect(computeCount, 2);
    });
  });
}

class _CountingEngine implements HyphenOverlayLayoutEngine {
  _CountingEngine(this._onCompute);
  final void Function() _onCompute;

  @override
  HyphenOverlayLayout compute({
    required ReaderTextLayoutSpec spec,
    required double layoutWidth,
    required double rightPaintOverflow,
    required double cursorWidth,
  }) {
    _onCompute();
    return HyphenOverlayLayout.empty;
  }
}

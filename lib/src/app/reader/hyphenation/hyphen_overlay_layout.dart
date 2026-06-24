// SPDX-License-Identifier: MIT
//
// Decorative line-end hyphen overlay layout engine.
//
// REVIEW.md §4-§7: paint must not redo paragraph layout or marker
// analysis. `HyphenOverlayLayoutEngine.compute` builds all expensive
// data once for a given set of layout inputs and returns an immutable
// list of stroke coordinates. `VisibleHyphenPainter` then draws only
// those precomputed strokes and does no text work.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

import 'reader_text_layout_spec.dart';
import 'visible_hyphen_painter.dart';

/// One decorative horizontal stroke placed at a confirmed line break.
@immutable
final class HyphenStroke {
  const HyphenStroke({required this.start, required this.end});

  /// Top-left (begin) of the stroke.
  final Offset start;

  /// Bottom-right (end) of the stroke.
  final Offset end;

  @override
  String toString() => 'HyphenStroke(start: $start, end: $end)';
}

/// Immutable precomputed layout for the decorative hyphen overlay.
@immutable
class HyphenOverlayLayout {
  const HyphenOverlayLayout(this.strokes, this.strokeWidth);

  const HyphenOverlayLayout._empty()
      : strokes = const <HyphenStroke>[],
        strokeWidth = 0;

  static const empty = HyphenOverlayLayout._empty();

  bool get isEmpty => strokes.isEmpty;
  bool get isNotEmpty => strokes.isNotEmpty;

  final List<HyphenStroke> strokes;
  final double strokeWidth;

  @override
  String toString() =>
      'HyphenOverlayLayout(strokes: ${strokes.length})';
}

/// Source-neutral layout engine for the decorative hyphen overlay.
///
/// Performs the full layout analysis once and returns an immutable
/// [HyphenOverlayLayout]. Does not depend on any widget, painter, or
/// Flutter `BuildContext`. Safe to call from `State` or tests.
class HyphenOverlayLayoutEngine {
  const HyphenOverlayLayoutEngine();

  /// Computes the overlay layout.
  ///
  /// Returns [HyphenOverlayLayout.empty] when:
  /// * the layout width is not positive / not finite,
  /// * the spec text is empty,
  /// * text alignment is not justified.
  HyphenOverlayLayout compute({
    required ReaderTextLayoutSpec spec,
    required double layoutWidth,
    required double rightPaintOverflow,
    required double cursorWidth,
  }) {
    if (spec.displayText.isEmpty) return HyphenOverlayLayout.empty;
    if (!layoutWidth.isFinite || layoutWidth <= 0) {
      return HyphenOverlayLayout.empty;
    }
    if (spec.textAlign != TextAlign.justify) {
      return HyphenOverlayLayout.empty;
    }

    // Step 1: build the probe painter once.
    final effectiveWidth = visibleHyphenEffectiveWidth(
      containerWidth: layoutWidth,
      cursorWidth: cursorWidth,
    );
    if (!effectiveWidth.isFinite || effectiveWidth <= 0) {
      return HyphenOverlayLayout.empty;
    }

    final probe = TextPainter(
      text: TextSpan(text: spec.displayText, style: spec.resolvedTextStyle),
      textAlign: spec.textAlign,
      textDirection: spec.textDirection,
      textScaler: spec.resolvedTextScaler,
      locale: spec.locale,
      strutStyle: spec.strutStyle,
      textWidthBasis: spec.textWidthBasis,
      textHeightBehavior: spec.textHeightBehavior,
      maxLines: spec.maxLines,
      ellipsis: spec.ellipsis,
    )..layout(maxWidth: effectiveWidth);

    // Step 2: collect soft-hyphen offsets once.
    final shys = _softHyphenOffsets(spec.displayText);
    if (shys.isEmpty) return HyphenOverlayLayout.empty;

    // Step 3: line metrics once.
    final metrics = probe.computeLineMetrics();
    if (metrics.isEmpty) return HyphenOverlayLayout.empty;

    // Step 4: x-height reference painter once. Used to derive a
    // baseline-anchored y for the stroke (see REVIEW.md §5).
    final xReference = TextPainter(
      text: TextSpan(text: 'x', style: spec.resolvedTextStyle),
      textDirection: spec.textDirection,
      textScaler: spec.resolvedTextScaler,
      locale: spec.locale,
      textHeightBehavior: spec.textHeightBehavior,
    )..layout();

    final xReferenceBaseline = xReference
        .computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final xReferenceBoxes = xReference.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );

    // Stroke geometry scaled from the body font size.
    final baseFontSize = spec.resolvedTextStyle.fontSize ?? 14.0;
    final scaledFontSize = spec.resolvedTextScaler.scale(baseFontSize);
    final strokeLength =
        (scaledFontSize * 0.34).clamp(5.0, 9.0).toDouble();
    final strokeWidth =
        (scaledFontSize * 0.065).clamp(1.0, 1.5).toDouble();
    final opticalGap = (scaledFontSize * 0.04).clamp(0.25, 1.0).toDouble();

    final paintRightLimit = layoutWidth + rightPaintOverflow;
    final strokes = <HyphenStroke>[];

    // Step 5: iterate markers; everything else is cached.
    for (final shy in shys) {
      if (!_isConfirmedBreak(probe, shy)) continue;

      final box = _trailingGlyphBox(probe, shy);
      if (box == null) continue;

      // REVIEW.md §2: use the preceding glyph box's vertical center
      // to identify the containing line directly.
      final line = _findContainingLine(metrics, box);
      if (line == null) continue;

      final x = box.right + opticalGap;
      if (x < 0) continue;
      if (x + strokeLength > paintRightLimit) continue;

      // REVIEW.md §5: stroke y sits near the center of the font's
      // x-height on the chosen line.
      final lineBaseline = line.baseline;
      final lineTop = lineBaseline - line.ascent;
      final lineBottom = lineBaseline + line.descent;

      TextBox xBox;
      if (xReferenceBoxes.isNotEmpty && xReferenceBoxes.first.bottom > xReferenceBoxes.first.top) {
        xBox = xReferenceBoxes.first;
      } else {
        xBox = _fallbackXBox(xReference, xReferenceBaseline);
      }
      final translatedTop =
          lineBaseline - xReferenceBaseline + xBox.top;
      final translatedBottom =
          lineBaseline - xReferenceBaseline + xBox.bottom;
      final strokeY = (translatedTop + translatedBottom) / 2;

      // Keep the stroke inside the visual line vertical bounds.
      final clampedY = strokeY.clamp(
        lineTop + strokeWidth / 2,
        lineBottom - strokeWidth / 2,
      );

      final start = Offset(x, clampedY);
      final end = Offset(x + strokeLength, clampedY);
      strokes.add(HyphenStroke(start: start, end: end));
    }

    return HyphenOverlayLayout(strokes, strokeWidth);
  }

  /// Returns the display-text offsets of every `U+00AD` that is
  /// followed and preceded by at least one visible code unit.
  List<int> _softHyphenOffsets(String text) {
    final result = <int>[];
    for (var i = 0; i < text.length; i++) {
      if (text[i] != '\u00AD') continue;
      if (i == 0 || i == text.length - 1) continue;
      if (i - 1 < 0 || i + 1 >= text.length) continue;
      if (text[i - 1] == '\u00AD' || text[i + 1] == '\u00AD') continue;
      result.add(i);
    }
    return result;
  }

  bool _isConfirmedBreak(TextPainter probe, int shyOffset) {
    final before = probe.getLineBoundary(TextPosition(offset: shyOffset - 1));
    final after = probe.getLineBoundary(TextPosition(offset: shyOffset + 1));
    return before.start != after.start || before.end != after.end;
  }

  TextBox? _trailingGlyphBox(TextPainter probe, int shyOffset) {
    final boxes = probe.getBoxesForSelection(
      TextSelection(baseOffset: shyOffset - 1, extentOffset: shyOffset),
    );
    if (boxes.isEmpty) return null;
    final TextBox box = boxes.last;
    if (box.right <= box.left || box.bottom <= box.top) return null;
    if (!box.right.isFinite || !box.top.isFinite) return null;
    return box;
  }

  /// Identify the visual line whose vertical bounds contain the
  /// centre of [box].
  ///
  /// REVIEW.md §2: prefer glyph-box identification over fragile
  /// line-boundary reconstruction. The glyph centre is a stable
  /// reference point that uniquely identifies a line.
  ui.LineMetrics? _findContainingLine(
    List<ui.LineMetrics> metrics,
    TextBox box,
  ) {
    final centerY = (box.top + box.bottom) / 2;
    for (final metric in metrics) {
      final lineTop = metric.baseline - metric.ascent;
      final lineBottom = metric.baseline + metric.descent;
      if (centerY >= lineTop && centerY <= lineBottom) {
        return metric;
      }
    }
    // Fallback: pick the line whose baseline is closest to the box
    // centre.
    ui.LineMetrics? best;
    var bestDistance = double.infinity;
    for (final metric in metrics) {
      final distance = (metric.baseline - centerY).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = metric;
      }
    }
    return best;
  }

  TextBox _fallbackXBox(TextPainter xReference, double baseline) {
    final width = xReference.width;
    final ascent = xReference.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    return TextBox.fromLTRBD(
      0,
      baseline - ascent,
      width,
      baseline,
      TextDirection.ltr,
    );
  }
}

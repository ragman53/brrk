// SPDX-License-Identifier: MIT
//
// Lightweight stroke-only painter for the decorative line-end hyphen
// overlay (REVIEW.md §4 Stage B).
//
// `VisibleHyphenPainter.paint()` does no text layout, no marker
// analysis, and no `TextPainter` work. It draws precomputed
// `HyphenStroke` coordinates produced by `HyphenOverlayLayoutEngine`.

import 'dart:ui';

import 'package:flutter/rendering.dart' show CustomPainter;

import 'hyphen_overlay_layout.dart';

/// Caret gap mirrored from `RenderEditable._kCaretGap` (private to
/// `package:flutter/src/rendering/editable.dart`). Keep in sync if
/// Flutter changes the default.
const double _kCaretGap = 1.0;

/// Default `cursorWidth` for `Material`-hosted `SelectableText`.
const double _kDefaultCursorWidth = 2.0;

/// Total caret margin subtracted from the container width before
/// laying out the duplicate `TextPainter` used by the layout engine.
double visibleHyphenCaretMargin({double cursorWidth = _kDefaultCursorWidth}) {
  return _kCaretGap + cursorWidth;
}

/// Effective content width available to the probe `TextPainter`.
///
/// Subtracts the mirrored `RenderEditable._caretMargin` from the raw
/// container width so the probe shares the same break opportunities
/// as the selectable surface.
double visibleHyphenEffectiveWidth({
  required double containerWidth,
  double cursorWidth = _kDefaultCursorWidth,
}) {
  if (!containerWidth.isFinite) return containerWidth;
  final margin = visibleHyphenCaretMargin(cursorWidth: cursorWidth);
  final result = containerWidth - margin;
  return result < 0 ? 0.0 : result;
}

/// Stroke-only painter.
///
/// Operates only on precomputed [HyphenOverlayLayout] geometry. Paint
/// is constant-time per stroke. No text work is performed here.
class VisibleHyphenPainter extends CustomPainter {
  const VisibleHyphenPainter({
    required this.layout,
    required this.color,
    this.strokeCap = StrokeCap.square,
  });

  /// Precomputed geometry produced by [HyphenOverlayLayoutEngine].
  final HyphenOverlayLayout layout;

  /// Stroke colour.
  final Color color;

  /// Stroke end cap.
  final StrokeCap strokeCap;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = layout.strokeWidth
      ..strokeCap = strokeCap
      ..isAntiAlias = true;
    for (final stroke in layout.strokes) {
      canvas.drawLine(stroke.start, stroke.end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VisibleHyphenPainter old) {
    return !identical(old.layout, layout) ||
        old.color != color ||
        old.strokeCap != strokeCap;
  }
}

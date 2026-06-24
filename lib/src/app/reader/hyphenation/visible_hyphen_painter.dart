// SPDX-License-Identifier: MIT
//
// FEAT-SPEC §10.1 / §10.5 / §10.6 / §10.7: decorative line-end hyphen.
//
// This painter draws a single `U+2010 HYPHEN` at every `U+00AD SOFT
// HYPHEN` position where the duplicate `TextPainter` proves that
// Flutter actually broke the line. It must not:
//   - choose its own line breaks (the duplicate painter inherits them
//     from the same spec),
//   - affect selection, copy, or semantics (it is wrapped in
//     `IgnorePointer` + `ExcludeSemantics` by `AcademicSelectableText`),
//   - insert real `-` characters into selectable text,
//   - paint when neither the preceding glyph box nor caret fallback
//     yields a stable trailing position (FEAT-SPEC §10.6).
//
// Per FEAT-SPEC §20: prefer omission of one uncertain decorative
// hyphen over painting a misplaced glyph.
//
// Width parity (FEAT-SPEC §10.3 + review blocker):
// `SelectableText` renders through `EditableText` → `RenderEditable`.
// `RenderEditable` subtracts a caret margin
// (`_kCaretGap + cursorWidth`) from its constraints before laying
// out its internal `TextPainter` (see
// `flutter/packages/flutter/lib/src/rendering/editable.dart`:
// `_caretMargin` ≈ `_kCaretGap + cursorWidth`,
// `availableMaxWidth = math.max(0.0, maxWidth - _caretMargin)`).
// `SelectableText` uses the default `cursorWidth: 2.0` for
// `Material`, so the effective content width on Android is
// `constraints.maxWidth - 3.0`. The probe painter subtracts the same
// amount from the original selectable layout width so its line breaks
// mirror the actual selectable surface. The decorative hyphen may
// hang into a separate paint-only gutter, but that gutter is never
// used for text layout.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show CustomPainter;

import 'reader_text_layout_spec.dart';

/// Caret gap mirrored from `RenderEditable._kCaretGap` (private to
/// `package:flutter/src/rendering/editable.dart`). Keep in sync if
/// Flutter changes the default.
const double _kCaretGap = 1.0;

/// Default `cursorWidth` for `Material`-hosted `SelectableText`.
/// We mirror it and pass the same value explicitly from
/// `AcademicSelectableText` to avoid probe/selectable drift.
const double _kDefaultCursorWidth = 2.0;

/// Total caret margin subtracted from the container width before
/// laying out the duplicate `TextPainter`. Mirrors
/// `RenderEditable._caretMargin = _kCaretGap + cursorWidth`.
double visibleHyphenCaretMargin({double cursorWidth = _kDefaultCursorWidth}) {
  return _kCaretGap + cursorWidth;
}

/// Effective content width available to the duplicate `TextPainter`.
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
  return math.max(0.0, containerWidth - margin);
}

/// A confirmed decorative hyphen placement computed from the probe
/// `TextPainter`.
///
/// Exposed for testability. The painter derives a list of these
/// placements and renders `U+2010` for each one.
class HyphenPlacement {
  const HyphenPlacement({
    required this.shyOffset,
    required this.x,
    required this.y,
  });

  /// Display-text offset of the `U+00AD` that produced this
  /// placement.
  final int shyOffset;

  /// Painted x coordinate of the decorative hyphen glyph. The
  /// decorative hyphen may hang into the existing reader margin, but
  /// it must never be shifted left over the preceding glyph.
  final double x;

  /// Painted top-left y coordinate of the decorative hyphen glyph.
  ///
  /// `TextPainter.getOffsetForCaret` returns the caret paint offset,
  /// not a text baseline. Painting at `y - glyphHeight` can move the
  /// first-line hyphen above the clip bounds, making it invisible.
  final double y;

  @override
  String toString() => 'HyphenPlacement(shyOffset: $shyOffset, x: $x, y: $y)';
}

/// Paints a single decorative `U+2010 HYPHEN` at every confirmed
/// `U+00AD` line break in [spec.displayText].
class VisibleHyphenPainter extends CustomPainter {
  const VisibleHyphenPainter({
    required this.spec,
    required this.layoutWidth,
    this.rightPaintOverflow = 0,
    this.cursorWidth = _kDefaultCursorWidth,
  });

  final ReaderTextLayoutSpec spec;

  /// Original selectable text layout width as reported by
  /// `LayoutBuilder`. The probe painter subtracts the caret margin
  /// from this value before laying out. Do not include
  /// [rightPaintOverflow] here; doing so would change line breaks.
  final double layoutWidth;

  /// Paint-only right gutter for the decorative hyphen. This expands
  /// the overlay canvas but is not part of text measurement.
  final double rightPaintOverflow;

  /// Mirrored `SelectableText` / `RenderEditable` `cursorWidth`.
  final double cursorWidth;

  /// The character painted as the decorative line-end hyphen.
  static const String decorativeHyphen = '\u2010';

  /// Builds the duplicate `TextPainter` used to detect breaks and to
  /// position glyphs. The probe uses the same effective width as
  /// `SelectableText`/`RenderEditable` (FEAT-SPEC §10.3).
  ///
  /// Public for testability. Callers must use exactly the same
  /// `TextStyle` and `textAlign` as the primary `SelectableText`.
  TextPainter buildProbePainter({double? width}) {
    final painter = TextPainter(
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
    );
    final containerWidth = width ?? layoutWidth;
    final effective = visibleHyphenEffectiveWidth(
      containerWidth: containerWidth,
      cursorWidth: cursorWidth,
    );
    if (effective.isFinite && effective > 0) {
      painter.layout(maxWidth: effective);
    } else {
      painter.layout();
    }
    return painter;
  }

  /// Returns the display-text offsets of every `U+00AD` that is
  /// followed and preceded by at least one visible code unit.
  ///
  /// Markers at offset 0 or `displayText.length` are ignored.
  List<int> _softHyphenOffsets() {
    final result = <int>[];
    final text = spec.displayText;
    for (var i = 0; i < text.length; i++) {
      if (text[i] != '\u00AD') continue;
      if (i == 0 || i == text.length - 1) continue;
      if (i - 1 < 0 || i + 1 >= text.length) continue;
      // Both surrounding units must be non-soft-hyphen to be a real
      // break opportunity inside a word.
      if (text[i - 1] == '\u00AD' || text[i + 1] == '\u00AD') continue;
      result.add(i);
    }
    return result;
  }

  /// Confirms that Flutter actually broke at [shyOffset] in [probe].
  /// Markers whose before/after visible neighbours fall on the same
  /// visual line are skipped.
  bool _isConfirmedBreak(TextPainter probe, int shyOffset) {
    final before = probe.getLineBoundary(TextPosition(offset: shyOffset - 1));
    final after = probe.getLineBoundary(TextPosition(offset: shyOffset + 1));
    return before.start != after.start || before.end != after.end;
  }

  /// Returns the trailing edge of the last visible glyph before the
  /// marker. This is the preferred anchor because caret positions can
  /// resolve to the next visual line at a soft-hyphen break.
  Offset? _trailingGlyphBox(TextPainter probe, int shyOffset) {
    final boxes = probe.getBoxesForSelection(
      TextSelection(baseOffset: shyOffset - 1, extentOffset: shyOffset),
    );
    if (boxes.isEmpty) return null;
    final TextBox box = boxes.last;
    if (box.right <= box.left || box.bottom <= box.top) return null;
    if (!box.right.isFinite || !box.top.isFinite) return null;
    return Offset(box.right, box.top);
  }

  /// Returns the alphabetic baseline y for the visual line that
  /// contains [shyOffset] in [probe], or `null` if line metrics are
  /// unavailable.
  double? _lineBaseline(TextPainter probe, int shyOffset) {
    final lineBoundary = probe.getLineBoundary(
      TextPosition(offset: shyOffset - 1),
    );
    final lineStartOffset = lineBoundary.start;

    final lineMetrics = probe.computeLineMetrics();
    if (lineMetrics.isEmpty) return null;

    // Map line-boundary start offsets to line indices so we can look
    // up the correct LineMetrics entry.
    final lineStarts = <int>[];
    var checkOffset = 0;
    for (var i = 0; i < lineMetrics.length; i++) {
      final boundary = probe.getLineBoundary(TextPosition(offset: checkOffset));
      lineStarts.add(boundary.start);
      checkOffset = boundary.end.clamp(
        0,
        math.min(probe.text!.toPlainText().length, boundary.end + 1),
      );
    }

    final idx = lineStarts.indexOf(lineStartOffset);
    if (idx < 0 || idx >= lineMetrics.length) return null;

    // Cumulative height of preceding lines.
    var lineTop = 0.0;
    for (var i = 0; i < idx; i++) {
      lineTop += lineMetrics[i].height;
    }

    // LineMetrics.baseline is the alphabetic baseline relative to the
    // top of its own line.
    return lineTop + lineMetrics[idx].baseline;
  }

  /// Builds a `TextPainter` for the single decorative hyphen glyph at
  /// the resolved style.
  TextPainter _buildHyphenPainter() {
    return TextPainter(
      text: TextSpan(text: decorativeHyphen, style: spec.resolvedTextStyle),
      textDirection: spec.textDirection,
      textScaler: spec.resolvedTextScaler,
      locale: spec.locale,
      textHeightBehavior: spec.textHeightBehavior,
    )..layout();
  }

  /// Measures the width of `U+2010 HYPHEN` at the resolved style using
  /// the same spec, so both surfaces share one font source.
  double _measureHyphenWidth() {
    final tp = TextPainter(
      text: TextSpan(text: decorativeHyphen, style: spec.resolvedTextStyle),
      textDirection: spec.textDirection,
      textScaler: spec.resolvedTextScaler,
      locale: spec.locale,
      textHeightBehavior: spec.textHeightBehavior,
    )..layout();
    return tp.width;
  }

  /// Computes the list of decorative hyphen placements for the probe
  /// layout. Public for testability (FEAT-SPEC §15.4).
  ///
  /// Returns at most one [HyphenPlacement] per confirmed `U+00AD`
  /// break. The x coordinate starts just after the trailing visible
  /// glyph. It may hang into the existing reader margin, but it is
  /// never clamped left over the preceding glyph.
  List<HyphenPlacement> computePlacements({
    double? testLayoutWidth,
    double? testRightPaintOverflow,
  }) {
    if (spec.displayText.isEmpty) return const [];
    final currentLayoutWidth = testLayoutWidth ?? layoutWidth;
    final currentRightPaintOverflow =
        testRightPaintOverflow ?? rightPaintOverflow;
    if (!currentLayoutWidth.isFinite || currentLayoutWidth <= 0) {
      return const [];
    }
    if (spec.textAlign != TextAlign.justify) {
      // Decorative hyphens only matter when justified; otherwise the
      // user already opted out of academic layout.
      return const [];
    }

    final probe = buildProbePainter(width: currentLayoutWidth);
    final hyphenStyleWidth = _measureHyphenWidth();
    if (hyphenStyleWidth <= 0) return const [];

    final paintRightLimit = currentLayoutWidth + currentRightPaintOverflow;
    const opticalGap = 0.5;
    final placements = <HyphenPlacement>[];
    for (final shy in _softHyphenOffsets()) {
      if (!_isConfirmedBreak(probe, shy)) continue;
      final trailingGlyph = _trailingGlyphBox(probe, shy);
      if (trailingGlyph == null || !trailingGlyph.dx.isFinite) continue;
      final x = trailingGlyph.dx + opticalGap;
      if (x < 0) continue;
      if (x + hyphenStyleWidth > paintRightLimit) {
        // Fail safe: omit this decorative hyphen rather than overlap
        // the preceding glyph by shifting it left.
        continue;
      }

      // Align the decorative hyphen-glyph's alphabetic baseline with
      // the containing text line's alphabetic baseline so the hyphen
      // reads as a horizontal bar, not a misplaced dot.
      final baseline = _lineBaseline(probe, shy);
      if (baseline == null) continue;
      final hyphenAscent = _buildHyphenPainter()
          .computeDistanceToActualBaseline(TextBaseline.alphabetic);
      final y = baseline - hyphenAscent;
      if (!y.isFinite) continue;
      placements.add(HyphenPlacement(shyOffset: shy, x: x, y: y));
    }
    return placements;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final placements = computePlacements();
    if (placements.isEmpty) return;
    for (final placement in placements) {
      final hp = _buildHyphenPainter();
      hp.paint(canvas, Offset(placement.x, placement.y));
    }
  }

  @override
  bool shouldRepaint(covariant VisibleHyphenPainter old) {
    return old.spec != spec ||
        old.layoutWidth != layoutWidth ||
        old.rightPaintOverflow != rightPaintOverflow ||
        old.cursorWidth != cursorWidth;
  }
}

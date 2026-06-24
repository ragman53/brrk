// SPDX-License-Identifier: MIT
//
// Paper Academic surface for the decorative soft-hyphen overlay.
//
// REVIEW.md §4-§6: layout analysis lives in `HyphenOverlayLayoutEngine`
// and is cached by complete layout inputs. `AcademicSelectableText` is
// a `StatefulWidget` that owns one cached `HyphenOverlayLayout`. The
// painter (`VisibleHyphenPainter`) draws only precomputed geometry and
// does no text work.
//
// The selectable surface uses `spec.displayText`. The layout engine
// also uses `spec.displayText`. There is no separate "displayText"
// field on the widget so the two sides cannot diverge.
//
// Shared layout inputs (FEAT-SPEC §10.3 + REVIEW.md §6):
// - The widget resolves `spec.textScaler` from `MediaQuery` when it is
//   null and passes the concrete scaler to both the selectable
//   surface and the layout engine. This mirrors `EditableText`'s
//   fallback to `MediaQuery.textScalerOf(context)`.
// - The probe painter inside the engine subtracts the mirrored
//   `RenderEditable` `_caretMargin` (`_kCaretGap + cursorWidth`) from
//   the `LayoutBuilder` width so its line breaks match the selectable
//   surface.

import 'package:flutter/material.dart';

import 'hyphen_overlay_layout.dart';
import 'reader_text_layout_spec.dart';
import 'visible_hyphen_painter.dart';

/// Combined surface for the visible decorative hyphen overlay used
/// by the Paper Academic reader. Also exercised by the debug-only
/// soft-hyphen selection gate.
class AcademicSelectableText extends StatefulWidget {
  /// Paint-only gutter that lets the decorative hyphen hang into the
  /// existing right reader margin without reducing the selectable
  /// text width or changing line breaks.
  static const double hangingHyphenGutter = 16.0;

  const AcademicSelectableText({
    super.key,
    required this.spec,
    required this.sourceText,
    required this.onSelectionChanged,
    this.focusNode,
    this.showCursor = true,
    this.cursorWidth = 2.0,
    this.layoutEngine = const HyphenOverlayLayoutEngine(),
  });

  /// Layout spec shared by the selectable surface and the layout
  /// engine.
  final ReaderTextLayoutSpec spec;

  /// Canonical source text. Used only as the `SelectableText`
  /// `semanticsLabel` so TalkBack / copy paths continue to see the
  /// canonical word (FEAT-SPEC §10.9).
  final String sourceText;

  /// Selection callback in display coordinates, with the original
  /// `SelectionChangedCause` forwarded so the caller can preserve
  /// long-press / double-tap semantics for vocabulary recovery.
  /// Callers must run the selection through a
  /// `HyphenatedText.toSourceSelection` mapping before passing to
  /// Add Note / Vocabulary.
  final void Function(TextSelection selection, SelectionChangedCause? cause)
  onSelectionChanged;

  final FocusNode? focusNode;
  final bool showCursor;

  /// Mirrored `SelectableText` `cursorWidth`. Used by the layout
  /// engine to derive the same effective content width as
  /// `RenderEditable`.
  final double cursorWidth;

  /// Test seam to inject a counting/fake engine.
  @visibleForTesting
  final HyphenOverlayLayoutEngine layoutEngine;

  @override
  State<AcademicSelectableText> createState() => _AcademicSelectableTextState();
}

class _AcademicSelectableTextState extends State<AcademicSelectableText> {
  _HyphenOverlayCacheKey? _cachedKey;
  HyphenOverlayLayout _cachedLayout = HyphenOverlayLayout.empty;

  @override
  Widget build(BuildContext context) {
    // Mirror `EditableText`'s scaler fallback so the selectable
    // surface and the layout engine see the same effective scaler
    // (FEAT-SPEC §10.3).
    final resolvedScaler = widget.spec.textScaler ??
        MediaQuery.textScalerOf(context);
    final resolvedSpec = widget.spec.textScaler == null
        ? widget.spec.copyWith(textScaler: resolvedScaler)
        : widget.spec;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SelectableText(
              resolvedSpec.displayText,
              key: const Key('academic-selectable-text'),
              textAlign: resolvedSpec.textAlign,
              textDirection: resolvedSpec.textDirection,
              textScaler: resolvedSpec.textScaler,
              strutStyle: resolvedSpec.strutStyle,
              textWidthBasis: resolvedSpec.textWidthBasis,
              textHeightBehavior: resolvedSpec.textHeightBehavior,
              maxLines: resolvedSpec.maxLines,
              style: resolvedSpec.resolvedTextStyle,
              focusNode: widget.focusNode,
              showCursor: widget.showCursor,
              cursorWidth: widget.cursorWidth,
              semanticsLabel: widget.sourceText,
              onSelectionChanged: (selection, cause) =>
                  widget.onSelectionChanged(selection, cause),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: -AcademicSelectableText.hangingHyphenGutter,
              bottom: 0,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: _AcademicOverlayPaint(
                    spec: resolvedSpec,
                    layoutWidth: width,
                    rightPaintOverflow:
                        AcademicSelectableText.hangingHyphenGutter,
                    cursorWidth: widget.cursorWidth,
                    layoutEngine: widget.layoutEngine,
                    cachedKey: _cachedKey,
                    cachedLayout: _cachedLayout,
                    onResolved: (key, layout) {
                      // Pure setState-free cache write.
                      _cachedKey = key;
                      _cachedLayout = layout;
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Pure widget that resolves and paints the precomputed overlay
/// layout. The layout is supplied through a callback so the parent
/// `State` can store it without rebuilding itself.
class _AcademicOverlayPaint extends StatelessWidget {
  const _AcademicOverlayPaint({
    required this.spec,
    required this.layoutWidth,
    required this.rightPaintOverflow,
    required this.cursorWidth,
    required this.layoutEngine,
    required this.cachedKey,
    required this.cachedLayout,
    required this.onResolved,
  });

  final ReaderTextLayoutSpec spec;
  final double layoutWidth;
  final double rightPaintOverflow;
  final double cursorWidth;
  final HyphenOverlayLayoutEngine layoutEngine;
  final _HyphenOverlayCacheKey? cachedKey;
  final HyphenOverlayLayout cachedLayout;
  final void Function(_HyphenOverlayCacheKey?, HyphenOverlayLayout) onResolved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = _HyphenOverlayCacheKey(
      displayText: spec.displayText,
      style: spec.resolvedTextStyle,
      textAlign: spec.textAlign,
      textDirection: spec.textDirection,
      textScaler: spec.resolvedTextScaler,
      locale: spec.locale,
      strutStyle: spec.strutStyle,
      textWidthBasis: spec.textWidthBasis,
      textHeightBehavior: spec.textHeightBehavior,
      maxLines: spec.maxLines,
      ellipsis: spec.ellipsis,
      layoutWidth: layoutWidth,
      rightPaintOverflow: rightPaintOverflow,
      cursorWidth: cursorWidth,
    );
    final layout = key == cachedKey ? cachedLayout : layoutEngine.compute(
      spec: spec,
      layoutWidth: layoutWidth,
      rightPaintOverflow: rightPaintOverflow,
      cursorWidth: cursorWidth,
    );
    if (key != cachedKey) {
      onResolved(key, layout);
    }
    return CustomPaint(
      key: const Key('academic-overlay-paint'),
      painter: VisibleHyphenPainter(
        layout: layout,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// Cache key covering every input that can change line layout or
/// stroke geometry.
class _HyphenOverlayCacheKey {
  const _HyphenOverlayCacheKey({
    required this.displayText,
    required this.style,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.locale,
    required this.strutStyle,
    required this.textWidthBasis,
    required this.textHeightBehavior,
    required this.maxLines,
    required this.ellipsis,
    required this.layoutWidth,
    required this.rightPaintOverflow,
    required this.cursorWidth,
  });

  final String displayText;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final int? maxLines;
  final String? ellipsis;
  final double layoutWidth;
  final double rightPaintOverflow;
  final double cursorWidth;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _HyphenOverlayCacheKey &&
        other.displayText == displayText &&
        other.style == style &&
        other.textAlign == textAlign &&
        other.textDirection == textDirection &&
        other.textScaler == textScaler &&
        other.locale == locale &&
        other.strutStyle == strutStyle &&
        other.textWidthBasis == textWidthBasis &&
        other.textHeightBehavior == textHeightBehavior &&
        other.maxLines == maxLines &&
        other.ellipsis == ellipsis &&
        other.layoutWidth == layoutWidth &&
        other.rightPaintOverflow == rightPaintOverflow &&
        other.cursorWidth == cursorWidth;
  }

  @override
  int get hashCode => Object.hash(
        displayText,
        style,
        textAlign,
        textDirection,
        textScaler,
        locale,
        strutStyle,
        textWidthBasis,
        textHeightBehavior,
        maxLines,
        ellipsis,
        layoutWidth,
        rightPaintOverflow,
        cursorWidth,
      );
}

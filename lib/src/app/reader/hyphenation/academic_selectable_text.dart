// SPDX-License-Identifier: MIT
//
// FEAT-SPEC §10.2: combined surface for the debug overlay proof.
//
// `AcademicSelectableText` is a single `SelectableText` plus one
// non-interactive decorative `CustomPaint` layer. It is the only
// debug-gate surface that exercises the overlay.
//
// The selectable surface uses `spec.displayText`. The painter also
// uses `spec.displayText`. There is no separate "displayText" field
// on the widget so the two sides cannot diverge.
//
// Shared layout inputs (FEAT-SPEC §10.3):
// - The widget resolves `spec.textScaler` from `MediaQuery` when it is
//   null and passes the concrete scaler to both the selectable
//   surface and the painter. This mirrors `EditableText`'s fallback
//   to `MediaQuery.textScalerOf(context)`.
// - The probe painter subtracts the mirrored `RenderEditable`
//   `_caretMargin` (`_kCaretGap + cursorWidth`) from the
//   `LayoutBuilder` width so its line breaks match the selectable
//   surface.

import 'package:flutter/material.dart';

import 'reader_text_layout_spec.dart';
import 'visible_hyphen_painter.dart';

/// Combined surface for the visible decorative hyphen overlay used
/// by the Paper Academic reader. Also exercised by the debug-only
/// soft-hyphen selection gate.
class AcademicSelectableText extends StatelessWidget {
  const AcademicSelectableText({
    super.key,
    required this.spec,
    required this.sourceText,
    required this.onSelectionChanged,
    this.focusNode,
    this.showCursor = true,
    this.cursorWidth = 2.0,
  });

  /// Layout spec shared by the selectable surface and the painter.
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

  /// Mirrored `SelectableText` `cursorWidth`. Used by the painter to
  /// derive the same effective content width as `RenderEditable`.
  final double cursorWidth;

  @override
  Widget build(BuildContext context) {
    // Mirror `EditableText`'s scaler fallback so the selectable
    // surface and the probe painter see the same effective scaler
    // (FEAT-SPEC §10.3).
    final resolvedScaler = spec.textScaler ?? MediaQuery.textScalerOf(context);
    final resolvedSpec = spec.textScaler == null
        ? spec.copyWith(textScaler: resolvedScaler)
        : spec;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.hardEdge,
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
              focusNode: focusNode,
              showCursor: showCursor,
              cursorWidth: cursorWidth,
              semanticsLabel: sourceText,
              onSelectionChanged: (selection, cause) =>
                  onSelectionChanged(selection, cause),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: const Key('academic-overlay-paint'),
                    painter: VisibleHyphenPainter(
                      spec: resolvedSpec,
                      maxWidth: width,
                      cursorWidth: cursorWidth,
                    ),
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

// SPDX-License-Identifier: MIT
//
// FEAT-SPEC §10.3: the primary `SelectableText` and the probe
// `TextPainter` must receive the same layout-affecting values.
//
// This value object centralises those inputs so `AcademicSelectableText`
// can hand the same spec to its `SelectableText` child and to its
// `VisibleHyphenPainter` child without divergence.
//
// The spec is intentionally Flutter-only-free: it stores Dart-side
// values and performs no widget calls. Glyph measurement and clamping
// happen inside the painter (FEAT-SPEC §10.6 / §10.7).

import 'dart:ui' show Locale, TextHeightBehavior;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart'
    show
        StrutStyle,
        TextAlign,
        TextDirection,
        TextScaler,
        TextStyle,
        TextWidthBasis;

/// Default text scaler used when [ReaderTextLayoutSpec.textScaler]
/// is null. Matches the `EditableText` / `RenderEditable` fallback
/// (`MediaQuery.textScalerOf(context)`), so when the widget inherits
/// from `MediaQuery`, the probe painter and the selectable surface
/// see the same effective scaler.
const TextScaler _kDefaultTextScaler = TextScaler.noScaling;

/// Immutable layout input shared by the selectable surface and the
/// decorative hyphen painter.
///
/// Equality is structural so `VisibleHyphenPainter.shouldRepaint` can
/// cheaply compare two specs. The set of compared fields is exactly
/// the FEAT-SPEC §10.3 / §10.8 list.
@immutable
class ReaderTextLayoutSpec {
  /// Display text. May contain U+00AD SOFT HYPHEN markers.
  ///
  /// This is the single source of text for both the selectable surface
  /// and the probe painter. Callers must not pass a different text to
  /// either side.
  final String displayText;

  /// Fully resolved body style. Do not merge an inherited style on one
  /// side and the explicit style on the other (FEAT-SPEC §10.4).
  final TextStyle resolvedTextStyle;

  final TextAlign textAlign;
  final TextDirection textDirection;

  /// Optional. When null, callers must resolve from `MediaQuery` and
  /// pass a concrete [TextScaler] to surfaces that need it.
  final TextScaler? textScaler;

  /// Returns the concrete text scaler that both the selectable
  /// surface and the probe painter must use. When [textScaler] is
  /// null, the widget host resolves it from `MediaQuery` via
  /// `AcademicSelectableText.build`; the spec defaults to
  /// `TextScaler.noScaling` only as a non-null fallback for unit
  /// tests that exercise the painter directly.
  TextScaler get resolvedTextScaler => textScaler ?? _kDefaultTextScaler;

  /// Optional. When null, the widget inherits from the ambient locale.
  final Locale? locale;

  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  /// `null` means unbounded (no maxLines).
  final int? maxLines;
  final String? ellipsis;

  const ReaderTextLayoutSpec({
    required this.displayText,
    required this.resolvedTextStyle,
    this.textAlign = TextAlign.start,
    this.textDirection = TextDirection.ltr,
    this.textScaler,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.maxLines,
    this.ellipsis,
  });

  /// Returns a copy with the supplied fields overridden.
  ReaderTextLayoutSpec copyWith({
    String? displayText,
    TextStyle? resolvedTextStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    TextScaler? textScaler,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    int? maxLines,
    String? ellipsis,
  }) {
    return ReaderTextLayoutSpec(
      displayText: displayText ?? this.displayText,
      resolvedTextStyle: resolvedTextStyle ?? this.resolvedTextStyle,
      textAlign: textAlign ?? this.textAlign,
      textDirection: textDirection ?? this.textDirection,
      textScaler: textScaler ?? this.textScaler,
      locale: locale ?? this.locale,
      strutStyle: strutStyle ?? this.strutStyle,
      textWidthBasis: textWidthBasis ?? this.textWidthBasis,
      textHeightBehavior: textHeightBehavior ?? this.textHeightBehavior,
      maxLines: maxLines ?? this.maxLines,
      ellipsis: ellipsis ?? this.ellipsis,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReaderTextLayoutSpec) return false;
    return displayText == other.displayText &&
        resolvedTextStyle == other.resolvedTextStyle &&
        textAlign == other.textAlign &&
        textDirection == other.textDirection &&
        textScaler == other.textScaler &&
        locale == other.locale &&
        strutStyle == other.strutStyle &&
        textWidthBasis == other.textWidthBasis &&
        textHeightBehavior == other.textHeightBehavior &&
        maxLines == other.maxLines &&
        ellipsis == other.ellipsis;
  }

  @override
  int get hashCode => Object.hash(
    displayText,
    resolvedTextStyle,
    textAlign,
    textDirection,
    textScaler,
    locale,
    strutStyle,
    textWidthBasis,
    textHeightBehavior,
    maxLines,
    ellipsis,
  );

  @override
  String toString() {
    return 'ReaderTextLayoutSpec(displayText.length=${displayText.length}, '
        'textAlign=$textAlign, textDirection=$textDirection, '
        'locale=$locale, maxLines=$maxLines)';
  }
}

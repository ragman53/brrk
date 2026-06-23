// SPDX-License-Identifier: MIT
//
// SPEC §15.3.1 — §15.3.7 — Paper academic rendering seam.
//
// Given the canonical Paper page text and the user's
// `ReaderLayoutMode`, this seam produces one of:
//
// - Natural: identity mapping (canonical text only, no markers,
//   no overlay).
// - Academic: a `HyphenatedText` containing deterministic Emergency
//   word breaking opportunities (`U+00AD` at every eligible
//   `[A-Za-z]+` boundary `3 <= offset <= n - 3` for words of length
//   `>= 7`), ready for `AcademicSelectableText` +
//   `VisibleHyphenPainter`.
//
// There is no dictionary backend, no service interface, and no
// release no-op. Emergency word breaking is the chosen visual
// line-fitting mechanism, and Paper Academic runs it directly.
//
// Canonical text is always preserved and the mapping is always
// non-decreasing, so Add Note / Look up / copy can be routed
// through `HyphenatedText.toSourceSelection` before any canonical
// operation.

import 'package:flutter/rendering.dart';

import '../../reading_appearance.dart';
import '../emergency_word_breaker.dart';
import 'hyphenated_text.dart';
import 'reader_text_layout_spec.dart';

/// Output of building a Paper reader surface for one page.
class PaperHyphenationRender {
  /// Canonical source text (never contains `U+00AD`).
  final String sourceText;

  /// Display text passed to the `SelectableText`. May contain
  /// `U+00AD` if the breaker produced markers.
  final String displayText;

  /// Mapping from display UTF-16 boundary → canonical source UTF-16
  /// boundary. Never null. Maps display length to source length.
  final HyphenatedText mapping;

  /// Whether the visible decorative hyphen overlay should be drawn.
  /// True only for Academic layout when at least one
  /// Emergency word break opportunity was inserted.
  final bool overlayEnabled;

  /// `TextAlign` for the body text. Natural uses start; Academic
  /// uses justify (and Academic without markers still gets justify).
  final TextAlign textAlign;

  /// Body `TextStyle` from the reading appearance.
  final TextStyle bodyStyle;

  /// `TextStyle` for headings. Unchanged by the layout mode.
  final TextStyle headingStyle;

  const PaperHyphenationRender({
    required this.sourceText,
    required this.displayText,
    required this.mapping,
    required this.overlayEnabled,
    required this.textAlign,
    required this.bodyStyle,
    required this.headingStyle,
  });

  bool get hasMarkers => sourceText != displayText;

  /// Returns the canonical source selection for a display selection.
  TextSelection canonicalSelection(TextSelection displaySelection) {
    return mapping.toSourceSelection(displaySelection);
  }

  /// Returns the canonical source substring for a display selection.
  String canonicalSubstring(TextSelection displaySelection) {
    return mapping.sourceSubstring(displaySelection);
  }

  /// Builds a [ReaderTextLayoutSpec] for the `AcademicSelectableText`
  /// (or null when Academic is not active / not enabled).
  ReaderTextLayoutSpec? toReaderTextLayoutSpec() {
    if (!overlayEnabled) return null;
    return ReaderTextLayoutSpec(
      displayText: displayText,
      resolvedTextStyle: bodyStyle,
      textAlign: textAlign,
    );
  }
}

/// Builds a Paper academic render for one canonical page source.
///
/// Uses the given [breaker] (or the default `EmergencyWordBreaker`
/// when none is supplied) to compute display-only `U+00AD`
/// opportunities for Academic layout. Natural layout never runs
/// the breaker.
class PaperAcademicHyphenation {
  final EmergencyWordBreaker breaker;

  PaperAcademicHyphenation({EmergencyWordBreaker? breaker})
    : breaker = breaker ?? const EmergencyWordBreaker();

  PaperHyphenationRender render({
    required String canonicalSource,
    required ReadingAppearance appearance,
  }) {
    final layoutMode = appearance.layoutMode;
    final isAcademic = layoutMode == ReaderLayoutMode.academic;
    HyphenatedText mapping;
    bool overlayEnabled;

    if (!isAcademic) {
      // Natural layout: canonical text, no markers, no overlay.
      mapping = HyphenatedText.fromInsertionOffsets(
        canonicalSource,
        insertBeforeSourceBoundary: const <int>[],
      );
      overlayEnabled = false;
    } else {
      // Academic layout: run Emergency word breaking directly.
      mapping = breaker.breakText(canonicalSource);
      overlayEnabled = mapping.sourceText != mapping.displayText;
    }

    return PaperHyphenationRender(
      sourceText: mapping.sourceText,
      displayText: mapping.displayText,
      mapping: mapping,
      overlayEnabled: overlayEnabled,
      textAlign: appearance.bodyTextAlign,
      bodyStyle: appearance.bodyStyle,
      headingStyle: appearance.heading1Style(),
    );
  }
}

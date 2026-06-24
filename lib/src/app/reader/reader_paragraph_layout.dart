import 'package:flutter/material.dart';

import '../reading_appearance.dart';
import 'emergency_word_breaker.dart';
import 'hyphenation/academic_selectable_text.dart';
import 'hyphenation/hyphenated_text.dart';
import 'hyphenation/reader_text_layout_spec.dart';
import 'reader_selection.dart';

/// Render output for one paragraph widget.
class ReaderParagraphRender {
  const ReaderParagraphRender({
    required this.sourceText,
    required this.displayText,
    required this.mapping,
    required this.overlayEnabled,
    required this.textAlign,
    required this.style,
  });

  /// Canonical source text (never contains display-only `U+00AD`).
  final String sourceText;

  /// Display text passed to the selectable widget. May contain `U+00AD`.
  final String displayText;

  /// Display → canonical mapping.
  final HyphenatedText mapping;

  /// Whether the visible decorative hanging hyphen overlay should be drawn.
  final bool overlayEnabled;

  /// Text alignment for this paragraph.
  final TextAlign textAlign;

  /// Body text style.
  final TextStyle style;

  bool get hasMarkers => sourceText != displayText;

  /// Maps a display selection into canonical source coordinates.
  TextSelection canonicalSelection(TextSelection displaySelection) {
    return mapping.toSourceSelection(displaySelection);
  }

  /// Returns the canonical source substring for a display selection.
  String canonicalSubstring(TextSelection displaySelection) {
    return mapping.sourceSubstring(displaySelection);
  }

  /// Builds a `ReaderTextLayoutSpec` for the academic selectable surface,
  /// or null when the overlay is not enabled.
  ReaderTextLayoutSpec? toReaderTextLayoutSpec() {
    if (!overlayEnabled) return null;
    return ReaderTextLayoutSpec(
      displayText: displayText,
      resolvedTextStyle: style,
      textAlign: textAlign,
    );
  }
}

/// Source-neutral paragraph layout that generalizes the production Paper
/// academic rendering seam. Reuses the working Paper stack:
/// [EmergencyWordBreaker], [HyphenatedText], [AcademicSelectableText],
/// [VisibleHyphenPainter] (via [AcademicSelectableText]), and
/// [ReaderTextLayoutSpec].
class ReaderParagraphLayout {
  const ReaderParagraphLayout({this.breaker = const EmergencyWordBreaker()});

  final EmergencyWordBreaker breaker;

  ReaderParagraphRender render({
    required String canonicalText,
    required ReadingAppearance appearance,
  }) {
    final isAcademic = appearance.layoutMode == ReaderLayoutMode.academic;
    final mapping = isAcademic
        ? breaker.breakText(canonicalText)
        : HyphenatedText.fromInsertionOffsets(
            canonicalText,
            insertBeforeSourceBoundary: const <int>[],
          );
    return ReaderParagraphRender(
      sourceText: mapping.sourceText,
      displayText: mapping.displayText,
      mapping: mapping,
      overlayEnabled: isAcademic && mapping.sourceText != mapping.displayText,
      textAlign: appearance.bodyTextAlign,
      style: appearance.bodyStyle,
    );
  }
}

/// Shared paragraph widget for native prose.
///
/// Natural: one canonical `SelectableText`, `TextAlign.start`, no markers,
/// no overlay. Academic: one `AcademicSelectableText`, `TextAlign.justify`,
/// deterministic `U+00AD` Emergency word breaking, existing visible
/// hanging-hyphen overlay. Source-aware: when [sourceStart] is provided,
/// emitted [ReaderSelection] carries exact page-source code-unit offsets
/// that callers can convert to UTF-8 byte offsets before persisting.
class BrrkReaderParagraph extends StatelessWidget {
  const BrrkReaderParagraph({
    super.key,
    required this.text,
    required this.appearance,
    required this.onSelectionChanged,
    this.sourceStart,
    this.layout = const ReaderParagraphLayout(),
  });

  final String text;
  final ReadingAppearance appearance;
  final ReaderSelectionChanged onSelectionChanged;

  /// Page-source code-unit offset where this paragraph starts in the page
  /// Markdown, when known. Used to produce exact native selection offsets.
  final int? sourceStart;

  final ReaderParagraphLayout layout;

  @override
  Widget build(BuildContext context) {
    final render = layout.render(canonicalText: text, appearance: appearance);

    void handleSelection(
      TextSelection selection,
      SelectionChangedCause? cause,
    ) {
      if (!selection.isValid || selection.isCollapsed) {
        onSelectionChanged(null);
        return;
      }
      final start = selection.start.clamp(0, render.displayText.length);
      final end = selection.end.clamp(0, render.displayText.length);
      if (end <= start) {
        onSelectionChanged(null);
        return;
      }
      final canonicalSelection = render.canonicalSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      final canonicalStart = canonicalSelection.start.clamp(
        0,
        render.sourceText.length,
      );
      final canonicalEnd = canonicalSelection.end.clamp(
        0,
        render.sourceText.length,
      );
      final pageStart = sourceStart == null
          ? null
          : sourceStart! + canonicalStart;
      final pageEnd = sourceStart == null ? null : sourceStart! + canonicalEnd;
      onSelectionChanged(
        ReaderSelection(
          canonicalContext: render.sourceText,
          selection: TextSelection(
            baseOffset: canonicalStart,
            extentOffset: canonicalEnd,
          ),
          cause: cause,
          sourceStart: pageStart,
          sourceEnd: pageEnd,
        ),
      );
    }

    if (!render.overlayEnabled) {
      return SelectableText(
        render.displayText,
        key: const Key('brrk-reader-paragraph-selectable'),
        onSelectionChanged: handleSelection,
        textAlign: render.textAlign,
        style: render.style,
      );
    }

    return AcademicSelectableText(
      key: const Key('brrk-reader-paragraph-academic'),
      spec: render.toReaderTextLayoutSpec()!,
      sourceText: render.sourceText,
      onSelectionChanged: handleSelection,
    );
  }
}

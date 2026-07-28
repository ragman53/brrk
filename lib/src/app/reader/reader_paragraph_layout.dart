import 'package:flutter/material.dart';

import '../reading_appearance.dart';
import 'emergency_word_breaker.dart';
import 'hyphenation/academic_selectable_text.dart';
import 'hyphenation/hyphenated_text.dart';
import 'hyphenation/reader_text_layout_spec.dart';
import 'reader_selection.dart';

/// Text-dependent paragraph preparation cached by the paragraph widget.
class ReaderParagraphPreparation {
  const ReaderParagraphPreparation({
    required this.mapping,
    required this.overlayEnabled,
  });

  final HyphenatedText mapping;
  final bool overlayEnabled;
}

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

  ReaderParagraphPreparation prepare({
    required String canonicalText,
    required ReaderLayoutMode layoutMode,
  }) {
    final isAcademic = layoutMode == ReaderLayoutMode.academic;
    final mapping = isAcademic
        ? breaker.breakText(canonicalText)
        : HyphenatedText.fromInsertionOffsets(
            canonicalText,
            insertBeforeSourceBoundary: const <int>[],
          );
    return ReaderParagraphPreparation(
      mapping: mapping,
      overlayEnabled: isAcademic && mapping.sourceText != mapping.displayText,
    );
  }

  ReaderParagraphRender present({
    required ReaderParagraphPreparation preparation,
    required ReadingAppearance appearance,
  }) {
    final mapping = preparation.mapping;
    return ReaderParagraphRender(
      sourceText: mapping.sourceText,
      displayText: mapping.displayText,
      mapping: mapping,
      overlayEnabled: preparation.overlayEnabled,
      textAlign: appearance.bodyTextAlign,
      style: appearance.bodyStyle,
    );
  }

  ReaderParagraphRender render({
    required String canonicalText,
    required ReadingAppearance appearance,
  }) {
    return present(
      preparation: prepare(
        canonicalText: canonicalText,
        layoutMode: appearance.layoutMode,
      ),
      appearance: appearance,
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
class BrrkReaderParagraph extends StatefulWidget {
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
  State<BrrkReaderParagraph> createState() => _BrrkReaderParagraphState();
}

class _BrrkReaderParagraphState extends State<BrrkReaderParagraph> {
  late ReaderParagraphPreparation _preparation;

  ReaderParagraphPreparation _prepare() => widget.layout.prepare(
    canonicalText: widget.text,
    layoutMode: widget.appearance.layoutMode,
  );

  @override
  void initState() {
    super.initState();
    _preparation = _prepare();
  }

  @override
  void didUpdateWidget(covariant BrrkReaderParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.appearance.layoutMode != widget.appearance.layoutMode ||
        oldWidget.layout != widget.layout) {
      _preparation = _prepare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final render = widget.layout.present(
      preparation: _preparation,
      appearance: widget.appearance,
    );

    void handleSelection(
      TextSelection selection,
      SelectionChangedCause? cause,
    ) {
      if (!selection.isValid || selection.isCollapsed) {
        widget.onSelectionChanged(null);
        return;
      }
      final start = selection.start.clamp(0, render.displayText.length);
      final end = selection.end.clamp(0, render.displayText.length);
      if (end <= start) {
        widget.onSelectionChanged(null);
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
      final pageStart = widget.sourceStart == null
          ? null
          : widget.sourceStart! + canonicalStart;
      final pageEnd = widget.sourceStart == null
          ? null
          : widget.sourceStart! + canonicalEnd;
      widget.onSelectionChanged(
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
        onSelectionChanged: handleSelection,
        textAlign: render.textAlign,
        style: render.style,
      );
    }

    return AcademicSelectableText(
      spec: render.toReaderTextLayoutSpec()!,
      sourceText: render.sourceText,
      onSelectionChanged: handleSelection,
    );
  }
}

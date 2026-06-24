import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../reading_appearance.dart';
import 'reader_markdown_plan.dart';
import 'reader_paragraph_layout.dart';
import 'reader_selection.dart';
import 'reader_surface.dart';

/// Shared page renderer for Paper and PDF.
///
/// Owns the renderer strategy choice (FEAT-SPEC §3.1, §8). Screens pass
/// canonical page Markdown; this widget emits canonical
/// [ReaderSelection] events with exact page-source offsets only when the
/// native planner can prove them.
class BrrkReaderPage extends StatelessWidget {
  const BrrkReaderPage({
    super.key,
    required this.markdown,
    required this.appearance,
    required this.onSelectionChanged,
    this.planOverride,
    this.scrollController,
  });

  /// Canonical page Markdown (manual override if present).
  final String markdown;

  final ReadingAppearance appearance;
  final ReaderSelectionChanged onSelectionChanged;

  /// Test seam that lets tests inject a precomputed plan and inspect the
  /// resolved strategy. Production callers leave this null so this widget
  /// owns the strategy decision.
  @visibleForTesting
  final ReaderMarkdownPlan? planOverride;

  /// Optional scroll controller. When null, the page owns its own
  /// [SingleChildScrollView] for parity with the previous Paper screen and
  /// to keep PDF from inheriting `flutter_markdown`'s scroll ownership.
  final ScrollController? scrollController;

  /// The plan selected for [markdown] (or [planOverride] when supplied).
  ReaderMarkdownPlan get plan => planOverride ?? planReaderMarkdown(markdown);

  /// Convenience: the strategy chosen for [markdown].
  ReaderRenderStrategy get strategy => plan.strategy;

  @override
  Widget build(BuildContext context) {
    final resolvedPlan = plan;
    final Widget body = switch (resolvedPlan) {
      NativeReaderPlan(:final blocks) => _NativeReaderBody(
        blocks: blocks,
        appearance: appearance,
        onSelectionChanged: onSelectionChanged,
      ),
      LegacyMarkdownPlan() => _LegacyMarkdownBody(
        markdown: markdown,
        appearance: appearance,
        onSelectionChanged: onSelectionChanged,
      ),
    };

    final scrollable = scrollController != null
        ? SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(
              vertical: appearance.density.paragraphSpacing + 4,
            ),
            child: body,
          )
        : SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: appearance.density.paragraphSpacing + 4,
            ),
            child: body,
          );

    return ReaderSurface(child: scrollable);
  }
}

class _NativeReaderBody extends StatelessWidget {
  const _NativeReaderBody({
    required this.blocks,
    required this.appearance,
    required this.onSelectionChanged,
  });

  final List<ReaderBlock> blocks;
  final ReadingAppearance appearance;
  final ReaderSelectionChanged onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final block in blocks) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: appearance.density.paragraphSpacing));
      }
      children.add(_buildBlock(block));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildBlock(ReaderBlock block) {
    return switch (block) {
      ReaderParagraphBlock(:final text, :final sourceStart) =>
        BrrkReaderParagraph(
          text: text,
          sourceStart: sourceStart,
          appearance: appearance,
          onSelectionChanged: onSelectionChanged,
        ),
      ReaderHeadingBlock(:final level, :final text, :final sourceStart) =>
        _ReaderHeading(
          level: level,
          text: text,
          sourceStart: sourceStart,
          appearance: appearance,
          onSelectionChanged: onSelectionChanged,
        ),
      ReaderHorizontalRuleBlock() => Divider(
        height: 1,
        thickness: 1,
        color: appearance.palette.muted,
      ),
    };
  }
}

class _ReaderHeading extends StatelessWidget {
  const _ReaderHeading({
    required this.level,
    required this.text,
    required this.sourceStart,
    required this.appearance,
    required this.onSelectionChanged,
  });

  final int level;
  final String text;
  final int sourceStart;
  final ReadingAppearance appearance;
  final ReaderSelectionChanged onSelectionChanged;

  TextStyle get _style {
    if (level <= 1) return appearance.heading1Style();
    if (level == 2) return appearance.heading2Style();
    if (level == 3) return appearance.heading3Style();
    return appearance.heading3Style().copyWith(
      fontSize: (appearance.heading3Size - (level - 3)).clamp(12.0, 28.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      key: Key('brrk-reader-heading-$level'),
      textAlign: TextAlign.start,
      style: _style,
      onSelectionChanged: (selection, cause) {
        if (!selection.isValid || selection.isCollapsed) {
          onSelectionChanged(null);
          return;
        }
        final start = selection.start.clamp(0, text.length);
        final end = selection.end.clamp(0, text.length);
        if (end <= start) {
          onSelectionChanged(null);
          return;
        }
        onSelectionChanged(
          ReaderSelection(
            canonicalContext: text,
            selection: TextSelection(baseOffset: start, extentOffset: end),
            cause: cause,
            sourceStart: sourceStart + start,
            sourceEnd: sourceStart + end,
          ),
        );
      },
    );
  }
}

class _LegacyMarkdownBody extends StatelessWidget {
  const _LegacyMarkdownBody({
    required this.markdown,
    required this.appearance,
    required this.onSelectionChanged,
  });

  final String markdown;
  final ReadingAppearance appearance;
  final ReaderSelectionChanged onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdown,
      selectable: true,
      shrinkWrap: true,
      onSelectionChanged: (text, selection, cause) {
        final contextText = text ?? '';
        if (!selection.isValid || selection.isCollapsed) {
          onSelectionChanged(null);
          return;
        }
        final start = selection.start.clamp(0, contextText.length);
        final end = selection.end.clamp(0, contextText.length);
        if (end <= start) {
          onSelectionChanged(null);
          return;
        }
        // Fallback: `flutter_markdown` does not expose exact page-source
        // offsets through its public API. Per FEAT-SPEC §10, emit null.
        onSelectionChanged(
          ReaderSelection(
            canonicalContext: contextText,
            selection: TextSelection(baseOffset: start, extentOffset: end),
            cause: cause,
          ),
        );
      },
      styleSheet: MarkdownStyleSheet(
        textAlign: appearance.layoutMode == ReaderLayoutMode.academic
            ? WrapAlignment.spaceBetween
            : WrapAlignment.start,
        h1: appearance.heading1Style(),
        h2: appearance.heading2Style(),
        h3: appearance.heading3Style(),
        p: appearance.paragraphStyle(),
        blockSpacing: appearance.density.paragraphSpacing,
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: appearance.palette.muted)),
        ),
      ),
    );
  }
}

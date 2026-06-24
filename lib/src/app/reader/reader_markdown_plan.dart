/// Strategy chosen by the shared reader page for a given canonical page
/// Markdown string.
enum ReaderRenderStrategy { nativeProse, legacyMarkdown }

/// Plan chosen by [planReaderMarkdown].
sealed class ReaderMarkdownPlan {
  const ReaderMarkdownPlan();

  ReaderRenderStrategy get strategy;
}

/// Plan for native prose rendering using the strict subset accepted by the
/// Paper production stack.
final class NativeReaderPlan extends ReaderMarkdownPlan {
  const NativeReaderPlan(this.blocks);

  final List<ReaderBlock> blocks;

  @override
  ReaderRenderStrategy get strategy => ReaderRenderStrategy.nativeProse;
}

/// Plan for fallback rendering through the shared `flutter_markdown` widget.
///
/// [reason] documents the fallback trigger for tests and debug visibility.
final class LegacyMarkdownPlan extends ReaderMarkdownPlan {
  const LegacyMarkdownPlan(this.reason);

  final String reason;

  @override
  ReaderRenderStrategy get strategy => ReaderRenderStrategy.legacyMarkdown;
}

/// A single block in a [NativeReaderPlan].
sealed class ReaderBlock {
  const ReaderBlock();
}

final class ReaderHeadingBlock extends ReaderBlock {
  const ReaderHeadingBlock({
    required this.level,
    required this.text,
    required this.sourceStart,
    required this.sourceEnd,
  });

  final int level;
  final String text;
  final int sourceStart;
  final int sourceEnd;
}

final class ReaderParagraphBlock extends ReaderBlock {
  const ReaderParagraphBlock({
    required this.text,
    this.sourceStart,
    this.sourceEnd,
  });

  final String text;

  /// Page-source code-unit start offset, or null for multi-line paragraphs
  /// whose exact offsets cannot be proven across source-newline joins.
  final int? sourceStart;

  /// Page-source code-unit end offset.
  final int? sourceEnd;
}

final class ReaderHorizontalRuleBlock extends ReaderBlock {
  const ReaderHorizontalRuleBlock();
}

/// Conservative source-aware Markdown planner.
///
/// The native subset is deliberately strict (FEAT-SPEC §7.1):
/// - blank lines,
/// - ignorable HTML comments,
/// - plain ATX headings (`#`–`######`) with plain text only,
/// - plain prose paragraphs,
/// - horizontal rules.
///
/// Any unsupported or ambiguous syntax forces a [LegacyMarkdownPlan]; the
/// planner prefers false negatives over false positives (FEAT-SPEC §7.2).
ReaderMarkdownPlan planReaderMarkdown(String markdown) {
  if (markdown.isEmpty) return const NativeReaderPlan(<ReaderBlock>[]);

  final blocks = <ReaderBlock>[];
  var previousWasNonBlank = false;
  final proseBuffer = <_SourceLine>[];

  void flushProseBuffer() {
    if (proseBuffer.isEmpty) return;
    if (proseBuffer.length == 1) {
      final line = proseBuffer.single;
      blocks.add(
        ReaderParagraphBlock(
          text: line.text,
          sourceStart: line.startOffset,
          sourceEnd: line.startOffset + line.text.length,
        ),
      );
    } else {
      final visible = proseBuffer.map((l) => l.text).join(' ');
      blocks.add(ReaderParagraphBlock(text: visible));
    }
    proseBuffer.clear();
  }

  for (final line in _sourceLines(markdown)) {
    final raw = line.text;
    final trimmed = raw.trim();
    final leading = raw.length - raw.trimLeft().length;

    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      return const LegacyMarkdownPlan('fenced code');
    }

    if (trimmed.isEmpty) {
      flushProseBuffer();
      previousWasNonBlank = false;
      continue;
    }

    if (leading > 0) {
      return const LegacyMarkdownPlan('indented block');
    }

    if (_isIgnorableHtmlComment(trimmed)) {
      flushProseBuffer();
      previousWasNonBlank = false;
      continue;
    }

    if (_isHorizontalRule(trimmed)) {
      if (previousWasNonBlank) {
        return const LegacyMarkdownPlan('possible setext heading');
      }
      flushProseBuffer();
      blocks.add(const ReaderHorizontalRuleBlock());
      previousWasNonBlank = false;
      continue;
    }

    final heading = _headingMatch(trimmed);
    if (heading != null) {
      flushProseBuffer();
      final marker = heading.group(1)!;
      final body = heading.group(2)!;
      if (body.trimRight().endsWith('#')) {
        return const LegacyMarkdownPlan('unsupported heading close marker');
      }
      if (_containsUnsupportedInline(body)) {
        return const LegacyMarkdownPlan('unsupported heading inline syntax');
      }
      final start = line.startOffset + leading + marker.length + 1;
      blocks.add(
        ReaderHeadingBlock(
          level: marker.length,
          text: body,
          sourceStart: start,
          sourceEnd: start + body.length,
        ),
      );
      previousWasNonBlank = true;
      continue;
    }
    if (trimmed.startsWith('#')) {
      return const LegacyMarkdownPlan('unsupported heading syntax');
    }

    if (_isUnsupportedBlock(trimmed)) {
      return const LegacyMarkdownPlan('unsupported block syntax');
    }
    if (_containsUnsupportedInline(trimmed)) {
      return const LegacyMarkdownPlan('unsupported inline syntax');
    }

    proseBuffer.add(line);
    previousWasNonBlank = true;
  }

  flushProseBuffer();
  return NativeReaderPlan(blocks);
}

RegExpMatch? _headingMatch(String trimmed) {
  // ATX headings: `#` through `######`, followed by a space, and plain text
  // only. The strict subset rejects any trailing `#` heading close, inline
  // constructs, or escapes.
  return RegExp(r'^(#{1,6}) ([^#\s].*)$').firstMatch(trimmed);
}

bool _isHorizontalRule(String trimmed) {
  return RegExp(r'^(?:-{3,}|\*{3,}|_{3,})$').hasMatch(trimmed);
}

bool _isIgnorableHtmlComment(String trimmed) {
  // Per CommonMark, a fully self-contained HTML comment with no `--` inside
  // its body is the only raw HTML we silently ignore.
  if (!trimmed.startsWith('<!--') || !trimmed.endsWith('-->')) return false;
  final inner = trimmed.substring(4, trimmed.length - 3);
  return !inner.contains('--');
}

bool _isUnsupportedBlock(String trimmed) {
  if (trimmed.startsWith('>')) return true;
  if (trimmed.startsWith('|') || trimmed.endsWith('|')) return true;
  if (RegExp(r'^[-+*] ').hasMatch(trimmed)) return true;
  if (RegExp(r'^\d+[.)] ').hasMatch(trimmed)) return true;
  if (RegExp(r'^\[[^\]]+\]:\s*\S+').hasMatch(trimmed)) return true;
  if (trimmed.startsWith('<')) return true;
  return false;
}

bool _containsUnsupportedInline(String text) {
  if (text.contains('\\')) return true;
  if (text.contains('`')) return true;
  if (text.contains('![')) return true;
  if (RegExp(r'\[[^\]]+\]\([^\)]+\)').hasMatch(text)) return true;
  if (RegExp(r'\[[^\]]+\]\[[^\]]*\]').hasMatch(text)) return true;
  // Emphasis / strong markers.
  if (RegExp(r'(^|[^A-Za-z0-9])(?:\*\*|__|\*|_)(?=\S)').hasMatch(text)) {
    return true;
  }
  // Bare `<` or `>` outside of plain text.
  if (text.contains('<') || text.contains('>')) return true;
  return false;
}

Iterable<_SourceLine> _sourceLines(String source) sync* {
  var start = 0;
  while (true) {
    final newline = source.indexOf('\n', start);
    if (newline == -1) {
      yield _SourceLine(source.substring(start), start, source.length);
      break;
    }
    final hasCarriageReturn =
        newline > start && source.codeUnitAt(newline - 1) == 0x0d;
    final lineEnd = hasCarriageReturn ? newline - 1 : newline;
    yield _SourceLine(source.substring(start, lineEnd), start, newline + 1);
    start = newline + 1;
    if (start > source.length) break;
    if (start == source.length) {
      yield _SourceLine('', start, start);
      break;
    }
  }
}

class _SourceLine {
  const _SourceLine(this.text, this.startOffset, this.nextOffset);

  final String text;
  final int startOffset;
  final int nextOffset;
}

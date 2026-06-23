// SPDX-License-Identifier: MIT
//
// SPEC §15.3.2 — Emergency word breaking.
//
// Pure deterministic text transformation for Academic reader layout.
// Emergency word breaking is NOT dictionary-based, pattern-based,
// syllable-aware, linguistically correct English hyphenation,
// syllabification, or morphological analysis. Break positions may
// not match formal English hyphenation rules. This tradeoff is
// accepted in exchange for a smaller and more maintainable
// implementation.
//
// Per SPEC §15.3.2:
// - Eligible base token: `[A-Za-z]+`.
// - Minimum word length: 7.
// - Preserve at least 3 visible letters before a break and 3 after.
// - For a word of length `n`, eligible insertion offsets are
//   `3 <= offset <= n - 3`.
// - Insert `U+00AD SOFT HYPHEN` at every eligible internal
//   ASCII-letter boundary.
// - Let Flutter choose the actual break position according to the
//   available width.
// - Strip any existing `U+00AD` before applying the transformation so
//   it is idempotent.
// - Do not modify URLs, emails, file paths, Markdown link / image
//   destinations, inline code, fenced code, identifiers containing
//   `_`, `/`, `\`, `@`, `:`, numeric tokens, apostrophe words, hard
//   -hyphen compounds, Japanese, or mixed-script tokens.

import 'hyphenation/hyphenated_text.dart';

/// Default minimum ASCII word length eligible for Emergency word
/// breaking.
const int kEmergencyWordBreakerMinWordLength = 7;

/// Default minimum number of visible letters preserved before a
/// break opportunity.
const int kEmergencyWordBreakerMinLeftFragment = 3;

/// Default minimum number of visible letters preserved after a break
/// opportunity.
const int kEmergencyWordBreakerMinRightFragment = 3;

/// Pure Emergency word breaker. Stateless and deterministic.
class EmergencyWordBreaker {
  const EmergencyWordBreaker({
    this.minWordLength = kEmergencyWordBreakerMinWordLength,
    this.minLeftFragment = kEmergencyWordBreakerMinLeftFragment,
    this.minRightFragment = kEmergencyWordBreakerMinRightFragment,
  });

  /// Minimum word length eligible for insertion.
  final int minWordLength;

  /// Minimum number of visible letters preserved before the break.
  final int minLeftFragment;

  /// Minimum number of visible letters preserved after the break.
  final int minRightFragment;

  /// Detects Japanese / CJK runs as `U+3000`–`U+9FFF` or
  /// `U+FF00`–`U+FFEF` / `U+3040`–`U+30FF` Hiragana/Katakana.
  static final RegExp _cjk = RegExp(
    r'[\u3000-\u9FFF\u3040-\u30FF\uFF00-\uFFEF]',
  );

  /// Eligible ASCII word pattern.
  static final RegExp _asciiWord = RegExp(r'[A-Za-z]+');

  /// Whole-token spans for identifiers, paths, and similar
  /// structured tokens that must never receive Emergency word
  /// breaking opportunities, even when they contain a long
  /// ASCII-letter segment.
  ///
  /// Each pattern captures the full token; long ASCII spans inside
  /// the match are disqualified by overlap with the protected range.
  static final List<RegExp> _protectedPatterns = <RegExp>[
    // URLs.
    RegExp(r'https?://\S+', caseSensitive: false),
    RegExp(r'\bwww\.\S+', caseSensitive: false),
    // Email addresses.
    RegExp(r'\b[\w.+-]+@[\w-]+(?:\.[\w-]+)+\b'),
    // Windows-style paths: drive letter + backslash separators.
    RegExp(r'[A-Za-z]:\\[^\s,;]+'),
    // POSIX / URL-style paths starting with a slash.
    RegExp(r'(?:[A-Za-z]:)?/[/\w.\-]+'),
    // Identifier or path segments separated by forward slashes.
    RegExp(r'[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)+'),
    // Identifiers containing underscore (snake_case) or mixed
    // underscore/colon segments. This protects long ASCII spans
    // such as `philosophical_token` or `name:philosophical`.
    RegExp(r'[A-Za-z0-9_]+(?::[A-Za-z0-9_]+)+'),
    RegExp(r'[A-Za-z0-9]+_[A-Za-z0-9_]+'),
    RegExp(r'[A-Za-z0-9_]+:[A-Za-z][A-Za-z0-9_]*'),
    // Common file extensions and dotted identifier tails.
    RegExp(r'\.[A-Za-z0-9]{2,4}\b'),
    // Numeric tokens (digits).
    RegExp(r'\d'),
    // Hard-hyphen compounds (e.g. self-conscious).
    RegExp(r'[A-Za-z]-[A-Za-z]'),
    // Apostrophe words (e.g. don't).
    RegExp(r"[A-Za-z]'[A-Za-z]"),
    // Mixed-script token: a run of ASCII letters joined (no
    // whitespace) to one or more non-Latin characters on either
    // side. The non-greedy letter-only segments force the match to
    // start and end on an ASCII-letter boundary so the protected
    // range overlaps the candidate ASCII span.
    RegExp(r'[A-Za-z]+(?:[A-Za-z]*[^\x00-\x7F][^\s]*)+'),
    RegExp(r'[^\s\w]*[^\x00-\x7F][^\s]*[A-Za-z][A-Za-z0-9]*'),
  ];

  /// Conservative Markdown fence / inline-code regions.
  static final List<RegExp> _markdownProtected = <RegExp>[
    // Fenced code blocks.
    RegExp(r'```[\s\S]*?```'),
    // Inline code spans.
    RegExp(r'`[^`\n]+`'),
    // Markdown link / image destinations in `[label](destination)`.
    RegExp(r'\]\(\S+\)'),
  ];

  /// Returns `true` when [word] qualifies for Emergency word breaking.
  bool _isEligible(String word) {
    if (word.length < minWordLength) return false;
    if (_cjk.hasMatch(word)) return false;
    for (final p in _protectedPatterns) {
      if (p.hasMatch(word)) return false;
    }
    return true;
  }

  bool _isInsideProtected(int start, int end, List<_Range> ranges) {
    for (final r in ranges) {
      // Any overlap between the word span and a protected range
      // disqualifies the word from Emergency word breaking. This
      // catches the common case where the ASCII-word regex matched a
      // sub-span of a URL, email, file path, or numeric identifier.
      if (start < r.end && end > r.start) return true;
    }
    return false;
  }

  /// Returns the smallest range that includes [start..end) and any
  /// adjacent non-whitespace characters that would form a
  /// continuous token with the candidate span. Stops at whitespace
  /// boundaries.
  ///
  /// This protects whole identifier/path tokens such as
  /// `philosophical_token`, `name:philosophical`, or
  /// `path/to/philosophical` even when the explicit protected
  /// regexes only matched a shorter sub-span.
  _Range _expandToToken(String source, int start, int end) {
    var s = start;
    var e = end;
    while (s > 0 && !_isTokenBoundary(source.codeUnitAt(s - 1))) {
      s--;
    }
    while (e < source.length && !_isTokenBoundary(source.codeUnitAt(e))) {
      e++;
    }
    return _Range(s, e);
  }

  /// Returns `true` when [c] would split an identifier/path token
  /// for the purpose of Emergency word breaking. Whitespace and the
  /// usual ASCII sentence punctuation break tokens. CJK / non-ASCII
  /// characters do NOT break tokens: a continuous run like
  /// `philosophical世界` is one token.
  static bool _isTokenBoundary(int c) {
    if (c <= 0x20) return true; // whitespace + control
    // Common ASCII sentence punctuation that ends a token.
    if (c == 0x2C /* , */ ||
        c == 0x2E /* . */ ||
        c == 0x3B /* ; */ ||
        c == 0x21 /* ! */ ||
        c == 0x3F /* ? */ ||
        c == 0x29 /* ) */ ||
        c == 0x5D /* ] */ ||
        c == 0x7D /* } */ ||
        c == 0x22 /* " */ ||
        c == 0x27 /* ' */ ) {
      return true;
    }
    return false;
  }

  List<_Range> _findProtectedRanges(String source) {
    final ranges = <_Range>[];
    for (final pattern in _protectedPatterns) {
      for (final m in pattern.allMatches(source)) {
        ranges.add(_Range(m.start, m.end));
      }
    }
    for (final pattern in _markdownProtected) {
      for (final m in pattern.allMatches(source)) {
        ranges.add(_Range(m.start, m.end));
      }
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Range>[];
    for (final r in ranges) {
      if (merged.isNotEmpty && r.start <= merged.last.end) {
        merged.last = _Range(merged.last.start, r.end);
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  /// Computes the Emergency word breaking result for [source].
  ///
  /// The returned [HyphenatedText] preserves the canonical source
  /// string unchanged and exposes a UTF-16 display-to-source
  /// boundary map suitable for routing Add Note / Vocabulary / copy
  /// / Rust offsets through canonical coordinates.
  HyphenatedText breakText(String source) {
    // Step 1: strip any existing `U+00AD` so the transformation is
    // idempotent. The mapping below operates on the clean source.
    final cleanSource = source.replaceAll('\u00AD', '');

    if (cleanSource.isEmpty) {
      return HyphenatedText.fromInsertionOffsets(
        cleanSource,
        insertBeforeSourceBoundary: const <int>[],
      );
    }

    final protectedRanges = _findProtectedRanges(cleanSource);
    final insertions = <int>{};
    for (final match in _asciiWord.allMatches(cleanSource)) {
      // Expand the candidate ASCII span to the surrounding
      // non-whitespace token so that mixed-script tokens and
      // identifier/path tokens are disqualified as a whole, not
      // just their ASCII sub-span.
      final token = _expandToToken(cleanSource, match.start, match.end);
      if (token.start != match.start || token.end != match.end) {
        // Token extends beyond the ASCII span. The whole token is
        // either mixed-script or contains an identifier separator.
        // Treat the entire extended range as protected so no
        // markers are inserted anywhere inside it.
        protectedRanges.add(token);
      }
      if (_isInsideProtected(match.start, match.end, protectedRanges)) {
        continue;
      }
      final word = match.group(0)!;
      if (!_isEligible(word)) continue;
      // Insert `U+00AD` at every internal ASCII-letter boundary
      // `minLeftFragment <= offset <= word.length - minRightFragment`.
      // For a word of length `n`, that is offsets
      // `3 <= offset <= n - 3` at the default thresholds.
      for (
        var offset = minLeftFragment;
        offset <= word.length - minRightFragment;
        offset++
      ) {
        insertions.add(match.start + offset);
      }
    }

    return HyphenatedText.fromInsertionOffsets(
      cleanSource,
      insertBeforeSourceBoundary: insertions.toList()..sort(),
    );
  }
}

class _Range {
  const _Range(this.start, this.end);
  final int start;
  final int end;
}

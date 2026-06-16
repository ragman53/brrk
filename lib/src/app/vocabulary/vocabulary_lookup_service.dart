import 'dart:convert' show utf8;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_key.dart';
import 'vocab_provider.dart';
import '../../rust/api/models.dart';
import '../../rust/api/storage.dart' as storage;

/// Per-lookup UI state used by the definition bottom sheet.
class LookupState {
  final bool loading;
  final String?
  errorKey; // 'no_key' | 'rate_limit' | 'parse' | 'network' | null
  final VocabLookupResult? result;
  final String selectedText;

  const LookupState({
    this.loading = false,
    this.errorKey,
    this.result,
    this.selectedText = '',
  });

  LookupState copyWith({
    bool? loading,
    String? errorKey,
    VocabLookupResult? result,
    String? selectedText,
  }) => LookupState(
    loading: loading ?? this.loading,
    errorKey: errorKey,
    result: result,
    selectedText: selectedText ?? this.selectedText,
  );

  static const initial = LookupState();
}

/// Provider that exposes the in-flight lookup result for the definition sheet.
final lookupStateProvider = StateProvider<LookupState>(
  (ref) => LookupState.initial,
);

/// In-flight dedupe map keyed by `source + selected + offsets`.
final _inFlight = <String, Future<VocabLookupResult>>{};

String _dedupeKey({
  required String selectedText,
  required int? start,
  required int? end,
  required VocabSource source,
}) {
  final src = source.when(paper: (b, p) => 'p:$b:$p', pdf: (d, i) => 'd:$d:$i');
  return '$src|${start ?? -1}|${end ?? -1}|$selectedText';
}

bool isValidVocabularySelection(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return false;
  final hasLatin = s.runes.any(
    (r) => (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A),
  );
  final hasJapanese = s.runes.any(
    (r) =>
        (r >= 0x3040 && r <= 0x309F) ||
        (r >= 0x30A0 && r <= 0x30FF) ||
        (r >= 0x4E00 && r <= 0x9FFF),
  );
  if (hasLatin && hasJapanese) return false;
  if (hasJapanese) {
    if (s.runes.length > 20) return false;
    if (s.runes.any((r) => String.fromCharCode(r).trim().isEmpty)) {
      return false;
    }
    return true;
  }
  if (!hasLatin || s.runes.length > 40) return false;
  return RegExp(r"^[A-Za-z][A-Za-z'’\-]*$").hasMatch(s);
}

/// Converts a Flutter/Dart UTF-16 code-unit offset into a Rust UTF-8 byte
/// offset for the same [text].
int? utf8ByteOffsetForCodeUnitOffset(String text, int? codeUnitOffset) {
  if (codeUnitOffset == null) return null;
  if (codeUnitOffset <= 0) return 0;
  if (codeUnitOffset >= text.length) return utf8.encode(text).length;
  return utf8.encode(text.substring(0, codeUnitOffset)).length;
}

/// A normalized lookup candidate derived from a raw user selection.
///
/// Used by the paper/PDF readers to drive `Look up` without disturbing the
/// raw selection (which is still used for `Add Note`).
class VocabularySelectionCandidate {
  /// The candidate text in UTF-16 code units, taken from [context].
  final String text;

  /// UTF-16 code-unit offset into [context] where [text] starts.
  final int start;

  /// UTF-16 code-unit offset into [context] where [text] ends (exclusive).
  final int end;

  const VocabularySelectionCandidate({
    required this.text,
    required this.start,
    required this.end,
  });
}

/// Compute a vocabulary lookup candidate for a raw user selection.
///
/// Bounded long-press heuristic: the helper never invents content the user
/// did not select, and only narrows down an over-selection. Double-tap and
/// other valid raw selections are returned unchanged. For invalid
/// long-press selections it trims surrounding punctuation and, for small
/// Latin over-selections, returns the single word span containing the
/// selection midpoint.
///
/// Offsets are in UTF-16 code units, matching `String.substring` and
/// Flutter's `TextSelection`/`RenderEditable` coordinates.
VocabularySelectionCandidate? vocabularyCandidateFromSelection({
  required String context,
  required TextSelection selection,
  SelectionChangedCause? cause,
}) {
  if (context.isEmpty) return null;
  if (!selection.isValid || selection.isCollapsed) return null;

  final length = context.length;
  var start = selection.start.clamp(0, length);
  var end = selection.end.clamp(0, length);
  if (end <= start) return null;

  // Step 1: whitespace-trim the raw range. Keep the adjusted offsets so
  // sentence extraction in Rust still sees the right span.
  while (start < end && _isWhitespaceCodeUnit(context.codeUnitAt(start))) {
    start++;
  }
  while (end > start && _isWhitespaceCodeUnit(context.codeUnitAt(end - 1))) {
    end--;
  }
  if (end <= start) return null;

  final trimmedRaw = context.substring(start, end);
  if (isValidVocabularySelection(trimmedRaw)) {
    return VocabularySelectionCandidate(
      text: trimmedRaw,
      start: start,
      end: end,
    );
  }

  // Step 2: only the long-press path attempts over-selection recovery.
  // Double-tap/drag/toolbar behavior is preserved.
  if (cause != SelectionChangedCause.longPress) return null;

  // Step 3: try trimming surrounding punctuation / quotes from the
  // whitespace-trimmed range. If that becomes valid, return it.
  var puncStart = start;
  var puncEnd = end;
  while (puncStart < puncEnd &&
      _isPunctuationCodeUnit(context.codeUnitAt(puncStart))) {
    puncStart++;
  }
  while (puncEnd > puncStart &&
      _isPunctuationCodeUnit(context.codeUnitAt(puncEnd - 1))) {
    puncEnd--;
  }
  // The string we will consider for multi-word inference: the
  // punctuation-trimmed slice if we trimmed anything, otherwise the
  // whitespace-trimmed raw.
  final candidateBase = (puncEnd > puncStart)
      ? context.substring(puncStart, puncEnd)
      : trimmedRaw;
  if (puncEnd > puncStart) {
    if (isValidVocabularySelection(candidateBase)) {
      return VocabularySelectionCandidate(
        text: candidateBase,
        start: puncStart,
        end: puncEnd,
      );
    }
  }

  // Step 4: bounded Latin multi-word inference. Only when the range is
  // small, has no mixed script, no sentence terminator, no newline, and
  // 1-2 Latin word spans.
  if (!_containsLatin(candidateBase)) {
    // No Latin content to infer from; CJK is intentionally not segmented.
    return null;
  }
  if (_containsMixedScript(candidateBase)) return null;
  if (_containsSentenceTerminator(trimmedRaw)) return null;
  if (trimmedRaw.length > 32) return null;

  final spans = _latinWordSpans(trimmedRaw);
  if (spans.length > 2) return null;
  if (spans.isEmpty) return null;

  // Return only the span containing the selection midpoint. If the midpoint
  // is whitespace, punctuation, a digit, or outside every word span, refuse
  // to infer. This keeps long-press recovery bounded instead of choosing a
  // random word from a broader selection.
  final midpoint = (start + end) ~/ 2;
  for (final span in spans) {
    final absStart = start + span.start;
    final absEnd = start + span.end;
    if (midpoint >= absStart && midpoint < absEnd) {
      final text = context.substring(absStart, absEnd);
      if (isValidVocabularySelection(text)) {
        return VocabularySelectionCandidate(
          text: text,
          start: absStart,
          end: absEnd,
        );
      }
    }
  }
  return null;
}

bool _isWhitespaceCodeUnit(int r) {
  // Matches Dart's String.trim() whitespace: space, tab, CR, LF, FF, VT.
  return r == 0x20 ||
      r == 0x09 ||
      r == 0x0A ||
      r == 0x0D ||
      r == 0x0B ||
      r == 0x0C;
}

bool _isPunctuationCodeUnit(int r) {
  // Trim punctuation/quotes, not digits or whitespace. Digits make a
  // selection invalid; treating them as trimmable punctuation would let
  // broad selections like `being 123...` collapse to a random word.
  if (_isWhitespaceCodeUnit(r)) return false;
  if (r >= 0x30 && r <= 0x39) return false;
  return !_isVocabularyContentCodeUnit(r);
}

bool _isVocabularyContentCodeUnit(int r) {
  if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return true;
  if (r == 0x27 || r == 0x2019 || r == 0x2D) return true; // ' ’ -
  if (r >= 0x3040 && r <= 0x309F) return true; // Hiragana
  if (r >= 0x30A0 && r <= 0x30FF) return true; // Katakana
  if (r >= 0x4E00 && r <= 0x9FFF) return true; // CJK Unified Ideographs
  return false;
}

bool _containsLatin(String s) {
  for (final r in s.runes) {
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return true;
  }
  return false;
}

bool _containsMixedScript(String s) {
  var hasLatin = false;
  var hasCjk = false;
  for (final r in s.runes) {
    final isLatin = (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);
    final isCjk =
        (r >= 0x3040 && r <= 0x309F) ||
        (r >= 0x30A0 && r <= 0x30FF) ||
        (r >= 0x4E00 && r <= 0x9FFF);
    if (isLatin) hasLatin = true;
    if (isCjk) hasCjk = true;
    if (hasLatin && hasCjk) return true;
  }
  return false;
}

bool _containsSentenceTerminator(String s) {
  // Reject newlines and sentence-ending marks inside the selection.
  for (final r in s.runes) {
    if (r == 0x0A || r == 0x0D) return true;
    if (r == 0x2E || r == 0x21 || r == 0x3F) return true; // . ! ?
    if (r == 0x3002 || r == 0xFF01 || r == 0xFF1F) return true; // 。 ！ ？
  }
  return false;
}

/// Returns the [start, end) UTF-16 offsets of Latin word spans inside
/// [s]. A span is a maximal run of Latin letters, internal apostrophes
/// (U+0027 and U+2019), and hyphens (U+002D).
List<_Span> _latinWordSpans(String s) {
  final spans = <_Span>[];
  var i = 0;
  while (i < s.length) {
    final r = s.codeUnitAt(i);
    final isLatinStart = (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);
    if (!isLatinStart) {
      i++;
      continue;
    }
    var j = i;
    while (j < s.length) {
      final r2 = s.codeUnitAt(j);
      final isLatin = (r2 >= 0x41 && r2 <= 0x5A) || (r2 >= 0x61 && r2 <= 0x7A);
      final isInner = r2 == 0x27 || r2 == 0x2019 || r2 == 0x2D;
      if (isLatin || isInner) {
        j++;
        continue;
      }
      break;
    }
    // Reject spans that contain an internal whitespace code unit (e.g.
    // because the regex above was too permissive for stray inner chars).
    final slice = s.substring(i, j);
    if (slice.runes.any((rr) => _isWhitespaceCodeUnit(rr))) {
      i++;
      continue;
    }
    spans.add(_Span(i, j));
    i = j;
  }
  return spans;
}

class _Span {
  final int start;
  final int end;
  const _Span(this.start, this.end);

  int get length => end - start;
}

/// Trigger a vocabulary lookup. Returns the result, or null if the lookup
/// was dismissed/cancelled/errored. Cached lookups skip the network call.
Future<VocabLookupResult?> performLookup({
  required WidgetRef ref,
  required String selectedText,
  required String pageContext,
  required int? startOffset,
  required int? endOffset,
  required VocabSource source,
}) async {
  ref.read(lookupStateProvider.notifier).state = LookupState(
    loading: true,
    selectedText: selectedText,
  );

  final startByteOffset = utf8ByteOffsetForCodeUnitOffset(
    pageContext,
    startOffset,
  );
  final endByteOffset = utf8ByteOffsetForCodeUnitOffset(pageContext, endOffset);
  final key = _dedupeKey(
    selectedText: selectedText,
    start: startByteOffset,
    end: endByteOffset,
    source: source,
  );
  if (_inFlight.containsKey(key)) {
    final result = await _inFlight[key]!;
    ref.read(lookupStateProvider.notifier).state = LookupState(
      result: result,
      selectedText: selectedText,
    );
    return result;
  }

  final apiKey = await ref.read(apiKeyProvider.notifier).getRawKey();
  if (apiKey.isEmpty) {
    ref.read(lookupStateProvider.notifier).state = LookupState(
      errorKey: 'no_key',
      selectedText: selectedText,
    );
    return null;
  }

  final fut = storage.lookupVocabulary(
    apiKey: apiKey,
    selectedText: selectedText,
    pageContext: pageContext,
    selectionStart: startByteOffset,
    selectionEnd: endByteOffset,
    source: source,
  );
  _inFlight[key] = fut;
  try {
    final result = await fut;
    ref.read(lookupStateProvider.notifier).state = LookupState(
      result: result,
      selectedText: selectedText,
    );
    await ref.read(vocabProvider.notifier).refresh();
    return result;
  } catch (e) {
    final msg = e.toString();
    String errKey = 'unknown';
    if (msg.contains('ApiKeyError')) {
      errKey = 'no_key';
    } else if (msg.contains('RateLimitError')) {
      errKey = 'rate_limit';
    } else if (msg.contains('ParseError')) {
      errKey = 'parse';
    } else if (msg.contains('NetworkError') || msg.contains('TimeoutError')) {
      errKey = 'network';
    }
    ref.read(lookupStateProvider.notifier).state = LookupState(
      errorKey: errKey,
      selectedText: selectedText,
    );
    return null;
  } finally {
    _inFlight.remove(key);
  }
}

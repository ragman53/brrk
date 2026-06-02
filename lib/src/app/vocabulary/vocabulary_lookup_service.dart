import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_key.dart';
import '../../rust/api/models.dart';
import '../../rust/api/storage.dart' as storage;

/// Per-lookup UI state used by the definition bottom sheet.
class LookupState {
  final bool loading;
  final String? errorKey; // 'no_key' | 'rate_limit' | 'parse' | 'network' | null
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
  }) =>
      LookupState(
        loading: loading ?? this.loading,
        errorKey: errorKey,
        result: result,
        selectedText: selectedText ?? this.selectedText,
      );

  static const initial = LookupState();
}

/// Provider that exposes the in-flight lookup result for the definition sheet.
final lookupStateProvider =
    StateProvider<LookupState>((ref) => LookupState.initial);

/// In-flight dedupe map keyed by `source + selected + offsets`.
final _inFlight = <String, Future<VocabLookupResult>>{};

String _dedupeKey({
  required String selectedText,
  required int? start,
  required int? end,
  required VocabSource source,
}) {
  final src = source.when(
    paper: (b, p) => 'p:$b:$p',
    pdf: (d, i) => 'd:$d:$i',
  );
  return '$src|${start ?? -1}|${end ?? -1}|$selectedText';
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

  final key = _dedupeKey(
    selectedText: selectedText,
    start: startOffset,
    end: endOffset,
    source: source,
  );
  if (_inFlight.containsKey(key)) {
    final result = await _inFlight[key]!;
    ref.read(lookupStateProvider.notifier).state =
        LookupState(result: result, selectedText: selectedText);
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
    selectionStart: startOffset,
    selectionEnd: endOffset,
    source: source,
  );
  _inFlight[key] = fut;
  try {
    final result = await fut;
    ref.read(lookupStateProvider.notifier).state =
        LookupState(result: result, selectedText: selectedText);
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

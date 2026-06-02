import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../rust/api/models.dart';
import '../../rust/api/storage.dart' as storage;

class VocabNotifier extends StateNotifier<AsyncValue<List<VocabEntry>>> {
  VocabNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final entries = await storage.listVocabulary(
        sourceFilter: const VocabSourceFilter.all(),
      );
      if (!mounted) return;
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String language, String lemma) async {
    await storage.deleteVocabularyEntry(
      language: language,
      lemma: lemma,
    );
    await refresh();
  }

  Future<void> updateDefinition(
    String language,
    String lemma,
    String definition,
  ) async {
    await storage.updateVocabularyDefinition(
      language: language,
      lemma: lemma,
      definition: definition,
    );
    await refresh();
  }

  Future<void> deleteEncounter(
    String language,
    String lemma,
    String encounterId,
  ) async {
    await storage.deleteVocabularyEncounter(
      language: language,
      lemma: lemma,
      encounterId: encounterId,
    );
    await refresh();
  }
}

final vocabProvider =
    StateNotifierProvider<VocabNotifier, AsyncValue<List<VocabEntry>>>(
  (ref) => VocabNotifier(),
);

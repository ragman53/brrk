import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vocab_provider.dart';
import 'vocabulary_detail_screen.dart';
import '../../rust/api/models.dart';

class VocabularyScreen extends ConsumerStatefulWidget {
  final VocabSourceFilter? initialFilter;
  const VocabularyScreen({super.key, this.initialFilter});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  String _query = '';
  String? _languageFilter; // null = all, 'en', 'ja'

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(vocabProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search words or definitions',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('English', 'en'),
                const SizedBox(width: 8),
                _filterChip('Japanese', 'ja'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entriesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                final filtered = entries.where((e) {
                  if (_languageFilter != null && e.language != _languageFilter) {
                    return false;
                  }
                  if (_query.isEmpty) return true;
                  return e.lemma.toLowerCase().contains(_query) ||
                      e.definition.toLowerCase().contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No entries yet.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final e = filtered[i];
                    final seen = e.encounters
                        .fold<int>(0, (s, en) => s + en.lookupCount);
                    return ListTile(
                      leading: _LangBadge(lang: e.language),
                      title: Text(e.lemma),
                      subtitle: Text(
                        e.definition.split('\n').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text('×$seen'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                VocabularyDetailScreen(lemma: e.lemma, language: e.language),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _languageFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _languageFilter = value),
    );
  }
}

class _LangBadge extends StatelessWidget {
  final String lang;
  const _LangBadge({required this.lang});
  @override
  Widget build(BuildContext context) {
    final tag = lang.toUpperCase() == 'JA' ? 'JA' : 'EN';
    return CircleAvatar(
      radius: 14,
      child: Text(tag, style: const TextStyle(fontSize: 10)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vocabulary_lookup_service.dart';
import '../../rust/api/models.dart';
import '../../rust/api/storage.dart' as storage;

/// Compact definition bottom sheet driven by `lookupStateProvider`.
class DefinitionSheet extends ConsumerWidget {
  final String selectedText;
  final VoidCallback onRemoveWord;
  final VoidCallback onOpenVocabulary;

  const DefinitionSheet({
    super.key,
    required this.selectedText,
    required this.onRemoveWord,
    required this.onOpenVocabulary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lookupStateProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LanguageChip(language: _resultLanguage(state)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedText,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _body(context, ref, state),
            const SizedBox(height: 12),
            _actions(context, state),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, LookupState state) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Looking up definition...'),
          ],
        ),
      );
    }
    if (state.errorKey != null) {
      return _ErrorView(errorKey: state.errorKey!);
    }
    final r = state.result;
    if (r == null) {
      return const SizedBox.shrink();
    }
    final entry = r.entry;
    final count = entry.encounters.fold<int>(
      0,
      (sum, e) => sum + e.lookupCount,
    );
    final encounter = _currentEncounter(r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seen $count time${count == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(entry.definition, style: Theme.of(context).textTheme.bodyMedium),
        if (encounter != null && encounter.sentence.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Example', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            encounter.sentence,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  VocabEncounter? _currentEncounter(VocabLookupResult result) {
    for (final encounter in result.entry.encounters) {
      if (encounter.id == result.encounterId) return encounter;
    }
    return result.entry.encounters.isNotEmpty
        ? result.entry.encounters.last
        : null;
  }

  Widget _actions(BuildContext context, LookupState state) {
    if (state.result == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remove word?'),
                content: Text(
                  'Remove "${state.result!.entry.lemma}" from vocabulary?\n'
                  'This removes its definition and all saved examples.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await storage.deleteVocabularyEntry(
                language: state.result!.entry.language,
                lemma: state.result!.entry.lemma,
              );
              onRemoveWord();
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove word'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () {
            onOpenVocabulary();
          },
          icon: const Icon(Icons.menu_book),
          label: const Text('Open Vocabulary'),
        ),
      ],
    );
  }

  String? _resultLanguage(LookupState state) {
    final r = state.result;
    if (r == null) return null;
    return r.entry.language;
  }
}

class _LanguageChip extends StatelessWidget {
  final String? language;
  const _LanguageChip({this.language});
  @override
  Widget build(BuildContext context) {
    final tag = language == null
        ? '—'
        : (language!.toUpperCase() == 'JA' ? 'JA' : 'EN');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tag, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String errorKey;
  const _ErrorView({required this.errorKey});

  @override
  Widget build(BuildContext context) {
    final (title, detail) = switch (errorKey) {
      'no_key' => (
        'Mistral API key required',
        'Set up your Mistral API key in Settings.',
      ),
      'rate_limit' => (
        'Mistral rate limit reached',
        'Wait a moment and retry.',
      ),
      'parse' => (
        'Could not parse the definition',
        'Try again with a different word.',
      ),
      'network' => ('Network error', 'Check your connection and retry.'),
      _ => ('Lookup failed', 'Please try again.'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vocab_provider.dart';
import '../../rust/api/models.dart';
class VocabularyDetailScreen extends ConsumerStatefulWidget {
  final String lemma;
  final String language;
  const VocabularyDetailScreen({
    super.key,
    required this.lemma,
    required this.language,
  });

  @override
  ConsumerState<VocabularyDetailScreen> createState() =>
      _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState
    extends ConsumerState<VocabularyDetailScreen> {
  late TextEditingController _definitionController;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _definitionController = TextEditingController();
    final entry = _currentEntry(ref);
    if (entry != null) {
      _definitionController.text = entry.definition;
    }
    _definitionController.addListener(() {
      final entry = _currentEntry(ref);
      if (entry == null) return;
      if (_definitionController.text != entry.definition && !_dirty) {
        setState(() => _dirty = true);
      }
    });
  }

  @override
  void dispose() {
    _definitionController.dispose();
    super.dispose();
  }

  VocabEntry? _currentEntry(WidgetRef ref) {
    final list = ref.read(vocabProvider).valueOrNull;
    if (list == null) return null;
    try {
      return list.firstWhere(
        (e) => e.lemma == widget.lemma && e.language == widget.language,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(vocabProvider.notifier).updateDefinition(
            widget.language,
            widget.lemma,
            _definitionController.text,
          );
      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Definition saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEncounter(String encounterId) async {
    try {
      await ref.read(vocabProvider.notifier).deleteEncounter(
            widget.language,
            widget.lemma,
            encounterId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Delete "${widget.lemma}" and all its encounters?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(vocabProvider.notifier).deleteEntry(
            widget.language,
            widget.lemma,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _currentEntry(ref);
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.lemma)),
        body: const Center(child: Text('Entry not found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lemma}  [${widget.language.toUpperCase()}]'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete entry',
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _definitionController,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Definition',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_dirty)
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Encounters (${entry.encounters.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (entry.encounters.isEmpty)
            const Text('No encounters yet.')
          else
            ...entry.encounters.map(
              (e) => Card(
                child: ListTile(
                  title: Text(e.selectedText),
                  subtitle: Text(
                    e.sentence.isEmpty ? '(no sentence)' : e.sentence,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      Text('×${e.lookupCount}'),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEncounter(e.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

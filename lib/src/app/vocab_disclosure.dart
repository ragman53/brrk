import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used for the vocabulary lookup data-transfer acknowledgement.
const _kVocabAcknowledgedKey = 'vocab_acknowledged';

/// Whether the user has already acknowledged the Mistral Chat data-transfer
/// notice for vocabulary lookups.
final vocabDisclosureAcknowledgedProvider =
    StateProvider<bool>((ref) => false);

/// Load the acknowledgement state from persistent storage.
Future<void> loadVocabDisclosureAcknowledgement(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  ref.read(vocabDisclosureAcknowledgedProvider.notifier).state =
      prefs.getBool(_kVocabAcknowledgedKey) ?? false;
}

/// Persist the acknowledgement locally.
Future<void> persistVocabDisclosureAcknowledgement(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kVocabAcknowledgedKey, true);
  ref.read(vocabDisclosureAcknowledgedProvider.notifier).state = true;
}

/// One-time acknowledgement dialog. Returns `true` if the user tapped
/// "I understand" and acknowledged.
Future<bool> showVocabDisclosureIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final acknowledged = ref.read(vocabDisclosureAcknowledgedProvider);
  if (acknowledged) return true;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Vocabulary lookup uses Mistral'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When you look up a word, Brrk sends the selected word and its '
              'containing sentence to Mistral\u2019s chat API to generate a '
              'definition. Brrk does not send the full page or document.',
            ),
            SizedBox(height: 12),
            Text(
              'Definition lookups are small, but usage is subject to '
              'Mistral\u2019s current limits and pricing. Check your Mistral '
              'dashboard for details.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('I understand'),
        ),
      ],
    ),
  );
  if (result == true) {
    await persistVocabDisclosureAcknowledgement(ref);
    return true;
  }
  return false;
}

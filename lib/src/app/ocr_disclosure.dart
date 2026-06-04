import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used for the OCR data-transfer acknowledgement preference.
const _kOcrAcknowledgedKey = 'ocr_acknowledged';

/// Whether the user has already acknowledged the Mistral data-transfer notice.
final ocrDisclosureAcknowledgedProvider = StateProvider<bool>((ref) => false);

/// Load the acknowledgement state from persistent storage.
/// Call once at app startup after Rust init.
Future<void> loadOcrDisclosureAcknowledgement(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  ref.read(ocrDisclosureAcknowledgedProvider.notifier).state =
      prefs.getBool(_kOcrAcknowledgedKey) ?? false;
}

/// Persist the acknowledgement locally.
Future<void> persistOcrDisclosureAcknowledgement(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOcrAcknowledgedKey, true);
  ref.read(ocrDisclosureAcknowledgedProvider.notifier).state = true;
}

/// One-time prominent disclosure for OCR data transfer to Mistral.
/// Returns true only after affirmative acknowledgement.
Future<bool> showOcrDisclosureIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final acknowledged = ref.read(ocrDisclosureAcknowledgedProvider);
  if (acknowledged) return true;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('OCR sends content to Mistral'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brrk will send the selected image or PDF content to Mistral '
              'using your own API key to perform OCR.',
            ),
            SizedBox(height: 12),
            Text(
              'Brrk does not send this content to the Brrk developer and '
              'does not operate a Brrk OCR server.',
            ),
            SizedBox(height: 12),
            Text(
              'Mistral usage may be billed to your Mistral account. Only '
              'continue if you understand and want to run OCR.',
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
          child: const Text('I understand and run OCR'),
        ),
      ],
    ),
  );

  if (result == true) {
    await persistOcrDisclosureAcknowledgement(ref);
    return true;
  }
  return false;
}

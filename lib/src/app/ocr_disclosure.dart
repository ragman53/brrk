import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used for the OCR data-transfer acknowledgement preference.
const _kOcrAcknowledgedKey = 'ocr_acknowledged';

/// Whether the user has already acknowledged the Mistral data-transfer notice.
final ocrDisclosureAcknowledgedProvider =
    StateProvider<bool>((ref) => false);

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
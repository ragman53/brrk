import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Name of the key used in Flutter Secure Storage for the Mistral API key.
const _kApiKeyStorageKey = 'mistral_api_key';

/// Value-based API key state with loading indicator.
sealed class ApiKeyState {
  const ApiKeyState();
}

/// Secure storage is being read — do not show form yet.
class ApiKeyLoading extends ApiKeyState {
  const ApiKeyLoading();
}

/// API key is stored and non-empty.
class ApiKeySet extends ApiKeyState {
  final String masked;
  const ApiKeySet(this.masked);
}

/// API key was cleared or never set.
class ApiKeyUnset extends ApiKeyState {
  const ApiKeyUnset();
}

/// Error reading from secure storage.
class ApiKeyLoadError extends ApiKeyState {
  final String message;
  const ApiKeyLoadError(this.message);
}

/// Notifier that loads, validates, and saves the Mistral API key.
///
/// The raw key is never stored in Riverpod state — only a masked form
/// or error message. Actual key is kept in Flutter Secure Storage.
class ApiKeyNotifier extends StateNotifier<ApiKeyState> {
  ApiKeyNotifier() : super(const ApiKeyLoading()) {
    _load();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Load the API key from secure storage on startup.
  Future<void> _load() async {
    try {
      final key = await _storage.read(key: _kApiKeyStorageKey);
      if (key == null || key.trim().isEmpty) {
        state = const ApiKeyUnset();
      } else {
        state = ApiKeySet(_mask(key));
      }
    } catch (e) {
      state = ApiKeyLoadError(e.toString());
    }
  }

  /// Save a new API key. Returns an error message on validation failure.
  ///
  /// Defensively rejects inputs that look like masked credentials (P0-1)
  /// to prevent accidental overwrite of the real key when the user opens
  /// Settings without intending to replace the key.
  Future<String?> save(String rawKey) async {
    final trimmed = rawKey.trim();
    final validationError = _validate(trimmed);
    if (validationError != null) return validationError;

    // Defensive check: reject strings that consist entirely of mask characters.
    // This guards against accidentally saving the masked display string "●●●..."
    // if a future regression puts it back into an editable field.
    if (!_looksLikeRealCredential(trimmed)) {
      return 'Invalid API key format. Please paste your actual Mistral API key.';
    }

    try {
      await _storage.write(key: _kApiKeyStorageKey, value: trimmed);
      state = ApiKeySet(_mask(trimmed));
      return null;
    } catch (e) {
      return 'Failed to save: ${e.toString()}';
    }
  }

  /// Returns false if the string consists only of mask dots and/or whitespace.
  bool _looksLikeRealCredential(String key) {
    return key.isNotEmpty && !RegExp(r'^[\s\u25CF]+$').hasMatch(key);
  }

  /// Clear the stored API key.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _kApiKeyStorageKey);
      state = const ApiKeyUnset();
    } catch (e) {
      state = ApiKeyLoadError(e.toString());
    }
  }

  /// Returns true only when a valid, non-empty key is stored.
  bool get hasKey => state is ApiKeySet;

  /// Re-read the key from storage (e.g., after navigating back from Settings).
  Future<void> reload() => _load();

  /// Returns the raw (unmasked) API key from secure storage, or throws if not set.
  Future<String> getRawKey() async {
    final key = await _storage.read(key: _kApiKeyStorageKey);
    if (key == null || key.trim().isEmpty) {
      throw Exception('API key not configured');
    }
    return key.trim();
  }

  /// Light validation: non-empty, no whitespace/control chars, minimum length.
  /// Does NOT require "sk-" prefix per SPEC.md §3.3.
  String? _validate(String key) {
    if (key.isEmpty) return 'API key cannot be empty.';
    if (key.length < 10) return 'API key seems too short.';
    if (key.contains(RegExp(r'\s|[\x00-\x1F\x7F]'))) {
      return 'API key must not contain whitespace or control characters.';
    }
    return null;
  }

  String _mask(String key) {
    if (key.length <= 8) return '●●●●●●●●';
    return '${key.substring(0, 4)}●●●●●●●●${key.substring(key.length - 4)}';
  }
}

/// Provider for the API key state.
final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, ApiKeyState>(
  (ref) => ApiKeyNotifier(),
);
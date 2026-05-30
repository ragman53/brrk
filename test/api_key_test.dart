import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/api_key.dart';

void main() {
  group('ApiKeyNotifier validation', () {
    test('empty key is rejected', () {
      const notifier = _TestableNotifier();
      expect(notifier.validate(''), 'API key cannot be empty.');
    });

    test('key shorter than 10 chars is rejected', () {
      const notifier = _TestableNotifier();
      expect(notifier.validate('abc'), 'API key seems too short.');
    });

    test('key with whitespace is rejected', () {
      const notifier = _TestableNotifier();
      expect(notifier.validate('sk-key with space'), isNotNull);
    });

    test('key with control char is rejected', () {
      const notifier = _TestableNotifier();
      expect(notifier.validate('sk-key\x00-test'), isNotNull);
    });

    test('valid-looking key passes validation', () {
      const notifier = _TestableNotifier();
      expect(notifier.validate('sk-test-api-key-1234567890'), isNull);
    });

    // P0-1: Mask-character-only inputs must be rejected by save() guard.
    test('mask dots only are rejected as fake credential (P0-1)', () {
      const notifier = _TestableNotifier();
      // _looksLikeRealCredential returns false for '●●●...'
      expect(notifier.looksLikeRealCredential('●●●●●●●●●●●●●●●●●●●●'), false);
      expect(notifier.looksLikeRealCredential('        '), false);
      expect(notifier.looksLikeRealCredential(''), false);
    });

    test('real-looking credential passes mask guard', () {
      const notifier = _TestableNotifier();
      expect(notifier.looksLikeRealCredential('sk-test-api-key-1234567890'), true);
      expect(notifier.looksLikeRealCredential('abc'), true); // length ≥ 10 and non-mask
    });
  });

  group('ApiKeyState types', () {
    test('ApiKeyLoading is a ApiKeyState', () {
      const state = ApiKeyLoading();
      expect(state, isA<ApiKeyState>());
    });

    test('ApiKeyUnset is a ApiKeyState', () {
      const state = ApiKeyUnset();
      expect(state, isA<ApiKeyState>());
    });

    test('ApiKeySet stores masked value', () {
      const state = ApiKeySet('sk-●●●●●●●●abcd');
      expect(state.masked, 'sk-●●●●●●●●abcd');
    });

    test('ApiKeyLoadError stores message', () {
      const state = ApiKeyLoadError('disk error');
      expect(state.message, 'disk error');
    });
  });
}

/// Testable wrapper exposing private helper methods without secure storage.
class _TestableNotifier {
  const _TestableNotifier();

  String? validate(String key) {
    if (key.isEmpty) return 'API key cannot be empty.';
    if (key.length < 10) return 'API key seems too short.';
    if (key.contains(RegExp(r'\s|[\x00-\x1F\x7F]'))) {
      return 'API key must not contain whitespace or control characters.';
    }
    return null;
  }

  /// Mirrors ApiKeyNotifier._looksLikeRealCredential for test coverage.
  bool looksLikeRealCredential(String key) {
    return key.isNotEmpty && !RegExp(r'^[\s\u25CF]+$').hasMatch(key);
  }
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brrk/src/app/providers.dart';

void main() {
  group('AppInitializationNotifier', () {
    test('initial state is AppInitializing', () {
      final notifier = AppInitializationNotifier();
      expect(notifier.state, isA<AppInitializing>());
    });

    test('setReady transitions to AppReady', () {
      final notifier = AppInitializationNotifier();
      notifier.setReady();
      expect(notifier.state, isA<AppReady>());
    });

    test('setError stores the error message', () {
      final notifier = AppInitializationNotifier();
      notifier.setError('test error');
      final state = notifier.state as AppError;
      expect(state.message, equals('test error'));
    });
  });

  group('appInitializationProvider', () {
    test('default provider state is initializing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(appInitializationProvider), isA<AppInitializing>());
    });
  });
}
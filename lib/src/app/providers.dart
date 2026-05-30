import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App initialization states.
sealed class AppInitializationState {
  const AppInitializationState();
}

/// App is initializing — show loading indicator.
class AppInitializing extends AppInitializationState {
  const AppInitializing();
}

/// App is ready — show HomeScreen.
class AppReady extends AppInitializationState {
  const AppReady();
}

/// App initialization failed — show error message and retry button.
class AppError extends AppInitializationState {
  final String message;
  const AppError(this.message);
}

/// Notifier that drives the app initialization flow.
class AppInitializationNotifier extends StateNotifier<AppInitializationState> {
  AppInitializationNotifier() : super(const AppInitializing());

  /// Called when Rust init succeeds.
  void setReady() {
    state = const AppReady();
  }

  /// Called when Rust init fails with an error message.
  void setError(String message) {
    state = AppError(message);
  }
}

/// Provider for the app initialization state.
final appInitializationProvider =
    StateNotifierProvider<AppInitializationNotifier, AppInitializationState>(
  (ref) => AppInitializationNotifier(),
);
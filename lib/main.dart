import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:brrk/src/rust/frb_generated.dart';
import 'package:brrk/src/rust/api/storage.dart';
import 'package:brrk/src/app/providers.dart';
import 'package:brrk/src/app/home_screen.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/app/ocr_disclosure.dart';
import 'package:brrk/src/app/vocab_disclosure.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Bootstrap the app with Riverpod; init state drives the UI.
  runApp(const ProviderScope(child: BrrkBootstrap()));
}

/// Root widget that drives initialization before showing the main app.
class BrrkBootstrap extends ConsumerStatefulWidget {
  const BrrkBootstrap({super.key});

  @override
  ConsumerState<BrrkBootstrap> createState() => _BrrkBootstrapState();
}

class _BrrkBootstrapState extends ConsumerState<BrrkBootstrap> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final dataDir = await getApplicationDocumentsDirectory();
      // initApp is synchronous (Rust #[frb(sync)]), returns void.
      initApp(dataDir: dataDir.path);
      // B3: load persisted OCR disclosure acknowledgement so the dialog only
      // appears once, not on every app restart.
      await loadOcrDisclosureAcknowledgement(ref);
      await loadVocabDisclosureAcknowledgement(ref);
      ref.read(appInitializationProvider.notifier).setReady();
    } catch (e) {
      ref.read(appInitializationProvider.notifier).setError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(appInitializationProvider);
    final readingAppearance = ref.watch(readingAppearanceProvider);

    return MaterialApp(
      title: 'Brrk',
      theme: ThemeData(
        colorScheme: readingAppearance.palette.materialScheme,
        useMaterial3: true,
      ),
      home: switch (initState) {
        AppInitializing() => const _LoadingScreen(),
        AppReady() => const HomeScreen(),
        AppError(:final message) => _ErrorScreen(
          message: message,
          onRetry: _initializeApp,
        ),
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing…'),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Initialization failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

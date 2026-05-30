import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brrk/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts and shows loading then home', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BrrkBootstrap(),
      ),
    );

    // Shows loading indicator during init.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // After init completes (Rust init_app), shows HomeScreen.
    await tester.pumpAndSettle();

    expect(find.text('Brrk — Ready'), findsOneWidget);
  });
}
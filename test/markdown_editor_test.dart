import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/markdown_editor.dart';

void main() {
  group('MarkdownEditorScreen', () {
    testWidgets('shows initial text in field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownEditorScreen(
            title: 'Edit page Markdown',
            initialText: 'OCR text',
            hasManualEdit: false,
            onSave: (_) async => true,
            onReset: () async => true,
          ),
        ),
      );
      expect(find.text('Edit page Markdown'), findsOneWidget);
      expect(find.text('OCR text'), findsOneWidget);
    });

    testWidgets('save with dirty text returns saved result', (tester) async {
      String? savedText;
      MarkdownEditorResult? popped;
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(ctx).push<MarkdownEditorResult>(
                    MaterialPageRoute<MarkdownEditorResult>(
                      builder: (_) => MarkdownEditorScreen(
                        title: 'Edit page Markdown',
                        initialText: 'original',
                        hasManualEdit: true,
                        onSave: (t) async {
                          savedText = t;
                          return true;
                        },
                        onReset: () async => true,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Edit the text.
      await tester.enterText(find.byType(TextField), 'edited content');
      await tester.pumpAndSettle();

      // Tap Save.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedText, 'edited content');
      expect(popped, isNotNull);
      expect(popped!.saved, isTrue);
      expect(popped!.text, 'edited content');
      expect(popped!.reset, isFalse);
    });

    testWidgets('save with unchanged text returns not-saved result', (tester) async {
      bool saveCalled = false;
      MarkdownEditorResult? popped;
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(ctx).push<MarkdownEditorResult>(
                    MaterialPageRoute<MarkdownEditorResult>(
                      builder: (_) => MarkdownEditorScreen(
                        title: 'Edit page Markdown',
                        initialText: 'original',
                        hasManualEdit: false,
                        onSave: (t) async {
                          saveCalled = true;
                          return true;
                        },
                        onReset: () async => true,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Don't change text; tap Save directly.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saveCalled, isFalse, reason: 'no-op save should not invoke onSave');
      expect(popped, isNotNull);
      expect(popped!.saved, isFalse);
    });

    testWidgets('cancel returns saved false', (tester) async {
      MarkdownEditorResult? popped;
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(ctx).push<MarkdownEditorResult>(
                    MaterialPageRoute<MarkdownEditorResult>(
                      builder: (_) => MarkdownEditorScreen(
                        title: 'Edit page Markdown',
                        initialText: 'original',
                        hasManualEdit: false,
                        onSave: (_) async => true,
                        onReset: () async => true,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.saved, isFalse);
    });

    testWidgets('reset button is hidden when no existing edit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownEditorScreen(
            title: 'Edit page Markdown',
            initialText: 'original',
            hasManualEdit: false,
            onSave: (_) async => true,
            onReset: () async => true,
          ),
        ),
      );
      expect(find.text('Reset to OCR'), findsNothing);
    });

    testWidgets('reset button is visible when existing edit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownEditorScreen(
            title: 'Edit page Markdown',
            initialText: 'edited',
            hasManualEdit: true,
            onSave: (_) async => true,
            onReset: () async => true,
          ),
        ),
      );
      expect(find.text('Reset to OCR'), findsOneWidget);
    });

    testWidgets('reset confirm calls onReset and pops with reset', (tester) async {
      bool resetCalled = false;
      MarkdownEditorResult? popped;
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(ctx).push<MarkdownEditorResult>(
                    MaterialPageRoute<MarkdownEditorResult>(
                      builder: (_) => MarkdownEditorScreen(
                        title: 'Edit page Markdown',
                        initialText: 'edited',
                        hasManualEdit: true,
                        onSave: (_) async => true,
                        onReset: () async {
                          resetCalled = true;
                          return true;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset to OCR'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Reset to OCR?'), findsOneWidget);
      // Tap the second instance (in dialog confirm button)
      await tester.tap(find.text('Reset').last);
      await tester.pumpAndSettle();

      expect(resetCalled, isTrue);
      expect(popped, isNotNull);
      expect(popped!.reset, isTrue);
    });

    testWidgets('text field has maxLength of 10_000', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownEditorScreen(
            title: 'Edit page Markdown',
            initialText: '',
            hasManualEdit: false,
            onSave: (_) async => true,
            onReset: () async => true,
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, MarkdownEditorScreen.maxLength);
      expect(MarkdownEditorScreen.maxLength, 10_000);
    });

    testWidgets('PopScope.canPop is true when not dirty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownEditorScreen(
            title: 'Edit page Markdown',
            initialText: 'foo',
            hasManualEdit: false,
            onSave: (_) async => true,
            onReset: () async => true,
          ),
        ),
      );
      // The editor's PopScope is the innermost; popScopeScaffoldGuard is
      // added by MaterialApp/Navigator. Use byWidgetPredicate to disambiguate.
      final popScope = tester.widget<PopScope>(
        find.byWidgetPredicate(
          (w) => w is PopScope && w.child is Scaffold,
        ),
      );
      expect(popScope.canPop, isTrue);
    });

    testWidgets('PopScope.canPop becomes false when dirty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownEditorScreen(
            title: 'Edit page Markdown',
            initialText: 'foo',
            hasManualEdit: false,
            onSave: (_) async => true,
            onReset: () async => true,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'bar');
      await tester.pumpAndSettle();
      final popScope = tester.widget<PopScope>(
        find.byWidgetPredicate(
          (w) => w is PopScope && w.child is Scaffold,
        ),
      );
      expect(popScope.canPop, isFalse);
    });

    testWidgets('cancel with dirty text shows discard confirm dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownEditorScreen(
            title: 'Edit page Markdown',
            initialText: 'foo',
            hasManualEdit: false,
            onSave: (_) async => true,
            onReset: () async => true,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'bar');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('save failure keeps editor open and shows snackbar', (tester) async {
      MarkdownEditorResult? popped;
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(ctx).push<MarkdownEditorResult>(
                    MaterialPageRoute<MarkdownEditorResult>(
                      builder: (_) => MarkdownEditorScreen(
                        title: 'Edit page Markdown',
                        initialText: 'original',
                        hasManualEdit: true,
                        onSave: (_) async => false,
                        onReset: () async => true,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'changed');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Editor should still be on top
      expect(find.text('Edit page Markdown'), findsOneWidget);
      expect(find.text('Failed to save edit.'), findsOneWidget);
      expect(popped, isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/note_draft.dart';
import 'package:brrk/src/app/note_editor.dart';

void main() {
  group('NoteEditorScreen', () {
    testWidgets('shows Add Note title when no existing notes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(title: 'Add Note')),
      );
      expect(find.text('Add Note'), findsOneWidget);
    });

    testWidgets('shows Edit Note title when editing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoteEditorScreen(
            title: 'Edit Note',
            initialContent: 'My existing note',
            initialTags: ['important'],
          ),
        ),
      );
      expect(find.text('Edit Note'), findsOneWidget);
    });

    testWidgets('shows selected text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoteEditorScreen(
            title: 'Add Note',
            selectedText: 'This is the selected text',
          ),
        ),
      );
      expect(find.text('This is the selected text'), findsOneWidget);
      expect(find.text('Selected text'), findsOneWidget);
    });

    testWidgets('shows validation error on empty save', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(title: 'Add Note')),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Note cannot be empty'), findsOneWidget);
    });

    testWidgets('tag chips appear and toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(title: 'Add Note')),
      );
      expect(find.text('important'), findsOneWidget);
      expect(find.text('question'), findsOneWidget);

      await tester.tap(find.text('important'));
      await tester.pumpAndSettle();
      // FilterChip toggles — check the checkmark is visible.
      final chip = tester.widget<FilterChip>(
        find
            .ancestor(
              of: find.text('important'),
              matching: find.byType(FilterChip),
            )
            .first,
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('custom tag can be created and selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(title: 'Add Note')),
      );

      await tester.enterText(find.byType(TextField).last, 'my-tag');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(
        find
            .ancestor(
              of: find.text('my-tag'),
              matching: find.byType(FilterChip),
            )
            .first,
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('max 5 tags enforced', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(title: 'Add Note')),
      );
      // Select all 5 tags.
      for (final tag in ['important', 'question', 'quote', 'summary', 'todo']) {
        await tester.tap(find.text(tag));
        await tester.pumpAndSettle();
      }
      // After 5 tags selected, the 'todo' FilterChip should still be visible but disabled.
      final chips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(chips.length, equals(5));
      // All 5 selected.
      expect(chips.every((c) => c.selected), isTrue);
    });

    testWidgets('note and tag length limits are visible in fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(title: 'Add Note')),
      );

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.maxLength, 10000);
      expect(fields.last.maxLength, 50);
    });

    testWidgets('overlong note content is rejected before returning draft', (
      tester,
    ) async {
      // The TextField's maxLength prevents typing past 10,000 chars in
      // practice; this test verifies the editor's defensive validation
      // path by stuffing text directly via the controller.
      await tester.pumpWidget(
        const MaterialApp(
          home: NoteEditorScreen(
            title: 'Edit Note',
            initialContent: 'placeholder',
          ),
        ),
      );

      // Replace the TextField controller with overlong content
      // (simulating an existing note that was migrated with a bug).
      final fieldFinder = find.byType(TextField).first;
      final field = tester.widget<TextField>(fieldFinder);
      field.controller!.text = List.filled(10001, 'x').join();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Note must be 10,000 characters or fewer'),
        findsOneWidget,
      );
    });

    testWidgets('returns NoteDraft on save with selected text and offsets', (
      tester,
    ) async {
      NoteDraft? popped;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(ctx).push<NoteDraft>(
                    MaterialPageRoute(
                      builder: (_) => const NoteEditorScreen(
                        title: 'Add Note',
                        selectedText: 'hello world',
                        startOffset: 5,
                        endOffset: 11,
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
      await tester.enterText(find.byType(TextField).first, 'my note');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(popped, isNotNull);
      expect(popped!.content, 'my note');
      expect(popped!.selectedText, 'hello world');
      expect(popped!.startOffset, 5);
      expect(popped!.endOffset, 11);
    });
  });
}

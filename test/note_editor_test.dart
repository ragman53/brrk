import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/note_editor.dart';
import 'package:brrk/src/rust/api/models.dart';

void main() {
  group('NoteEditorScreen', () {
    testWidgets('shows Add Note title when no existing notes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(pageId: 'page-1')),
      );
      expect(find.text('Add Note'), findsOneWidget);
    });

    testWidgets('shows Edit Note title when editing', (tester) async {
      final now = DateTime.now().toUtc().toIso8601String();
      await tester.pumpWidget(
        MaterialApp(
          home: NoteEditorScreen(
            pageId: 'page-1',
            existingNote: Note(
              id: 'n1',
              pageId: 'page-1',
              selectedText: '',
              startOffset: 0,
              endOffset: 0,
              content: 'My existing note',
              tags: const ['important'],
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ),
      );
      expect(find.text('Edit Note'), findsOneWidget);
    });

    testWidgets('shows selected text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoteEditorScreen(
            pageId: 'page-1',
            selectedText: 'This is the selected text',
          ),
        ),
      );
      expect(find.text('This is the selected text'), findsOneWidget);
      expect(find.text('Selected text'), findsOneWidget);
    });

    testWidgets('shows validation error on empty save', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(pageId: 'page-1')),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Note cannot be empty'), findsOneWidget);
    });

    testWidgets('tag chips appear and toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NoteEditorScreen(pageId: 'page-1')),
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
        const MaterialApp(home: NoteEditorScreen(pageId: 'page-1')),
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
        const MaterialApp(home: NoteEditorScreen(pageId: 'page-1')),
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
        const MaterialApp(home: NoteEditorScreen(pageId: 'page-1')),
      );

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.maxLength, 10000);
      expect(fields.last.maxLength, 50);
    });

    testWidgets('overlong note content is rejected before returning note', (
      tester,
    ) async {
      final now = DateTime.now().toUtc().toIso8601String();
      await tester.pumpWidget(
        MaterialApp(
          home: NoteEditorScreen(
            pageId: 'page-1',
            existingNote: Note(
              id: 'n1',
              pageId: 'page-1',
              selectedText: '',
              startOffset: 0,
              endOffset: 0,
              content: List.filled(10001, 'x').join(),
              tags: const [],
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Note must be 10,000 characters or fewer'),
        findsOneWidget,
      );
    });
  });
}

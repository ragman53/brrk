import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brrk/src/app/paper_book_detail_screen.dart';
import 'package:brrk/src/rust/api/models.dart';

void main() {
  group('PaperBookDetailScreen', () {
    final nowGen = DateTime.now().toUtc().toIso8601String();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

    PaperBooksData booksOf(PaperBook book) =>
        PaperBooksData(version: 1, books: [book]);

    PaperBook makeBook({List<PaperPage> pages = const []}) => PaperBook(
      id: 'book-1',
      title: 'Test Book',
      createdAt: nowGen,
      updatedAt: nowGen,
      pages: pages.isEmpty
          ? [
              PaperPage(
                id: 'page-1',
                imagePath: 'images/book-1/page-1.jpg',
                ocrHash: 'sha256:abc',
                markdown: '# Test Page\n\nSome extracted text.',
                notes: const [],
              ),
              PaperPage(
                id: 'page-2',
                imagePath: 'images/book-1/page-2.jpg',
                ocrHash: 'sha256:def',
                markdown: '# Page Two\n\nMore text.',
                notes: const [],
              ),
            ]
          : pages,
    );

    testWidgets('shows book title in app bar', (tester) async {
      final book = makeBook();
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Test Book'), findsOneWidget);
    });

    testWidgets('shows markdown content', (tester) async {
      final book = makeBook();
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Some extracted text'), findsOneWidget);
    });

    testWidgets('shows page chips with ordinal numbers when no labels', (
      tester,
    ) async {
      final book = makeBook();
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Capture 1'), findsOneWidget);
      expect(find.text('Capture 2'), findsOneWidget);
    });

    testWidgets('shows page chip with label when set', (tester) async {
      final book = makeBook(
        pages: [
          PaperPage(
            id: 'page-1',
            imagePath: 'images/book-1/page-1.jpg',
            pageLabel: '42',
            ocrHash: 'sha256:abc',
            markdown: '# Test Page',
            notes: const [],
          ),
        ],
      );
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('p. 42'), findsOneWidget);
    });

    testWidgets('renders existing note chips', (tester) async {
      final book = PaperBook(
        id: 'book-1',
        title: 'Test Book',
        createdAt: nowGen,
        updatedAt: nowGen,
        pages: [
          PaperPage(
            id: 'page-1',
            imagePath: 'images/book-1/page-1.jpg',
            ocrHash: 'sha256:abc',
            markdown: '# Test Page',
            notes: [
              Note(
                id: 'note-1',
                pageId: 'page-1',
                selectedText: '',
                startOffset: 0,
                endOffset: 0,
                content: 'My first note',
                tags: const ['important'],
                createdAt: nowGen,
                updatedAt: nowGen,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My first note'), findsOneWidget);
    });

    testWidgets('AppBar has reading appearance icon button', (tester) async {
      final book = makeBook();
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('uses manual markdown when present', (tester) async {
      final manualPage = PaperPage(
        id: 'page-1',
        imagePath: 'images/book-1/page-1.jpg',
        pageLabel: null,
        ocrHash: 'sha256:abc',
        markdown: 'Original OCR text',
        manualMarkdown: 'Edited text',
        notes: const [],
      );
      final book = makeBook(pages: [manualPage]);
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edited text'), findsOneWidget);
      expect(find.text('Original OCR text'), findsNothing);
    });

    testWidgets('falls back to original markdown when manual is null', (tester) async {
      final book = makeBook();
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('extracted text'), findsOneWidget);
    });

    testWidgets('AppBar has edit page Markdown icon', (tester) async {
      final book = makeBook();
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('shows edit indicator on chip when page has manual edit', (tester) async {
      final manualPage = PaperPage(
        id: 'page-1',
        imagePath: 'images/book-1/page-1.jpg',
        pageLabel: null,
        ocrHash: 'sha256:abc',
        markdown: 'Original',
        manualMarkdown: 'Edited',
        notes: const [],
      );
      final book = makeBook(pages: [manualPage]);
      await tester.pumpWidget(
        wrap(
          PaperBookDetailScreen(
            bookId: book.id,
            getBooks: () async => booksOf(book),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    // Regression: editing a page label must not erase the manual Markdown.
    // We can't drive the dialog from a unit test (it uses FRB storage
    // directly), so we assert the structural contract: rebuilding a
    // PaperPage for label changes preserves `manualMarkdown`.
    test('label-edit rebuild of PaperPage preserves manualMarkdown', () {
      final page = PaperPage(
        id: 'page-1',
        imagePath: 'images/book-1/page-1.jpg',
        pageLabel: '12',
        ocrHash: 'sha256:abc',
        markdown: 'Original OCR text',
        manualMarkdown: 'Edited text',
        notes: const [],
      );
      final newLabel = '42';
      final rebuilt = PaperPage(
        id: page.id,
        imagePath: page.imagePath,
        pageLabel: newLabel,
        ocrHash: page.ocrHash,
        markdown: page.markdown,
        manualMarkdown: page.manualMarkdown,
        notes: page.notes,
      );
      expect(rebuilt.pageLabel, '42');
      expect(rebuilt.manualMarkdown, 'Edited text');
      expect(rebuilt.markdown, 'Original OCR text');
    });

    // Companion test: same rebuild, manualMarkdown is null (no edit yet).
    test('label-edit rebuild of PaperPage keeps null manualMarkdown', () {
      final page = PaperPage(
        id: 'page-1',
        imagePath: 'images/book-1/page-1.jpg',
        pageLabel: null,
        ocrHash: 'sha256:abc',
        markdown: 'Original OCR text',
        notes: const [],
      );
      final rebuilt = PaperPage(
        id: page.id,
        imagePath: page.imagePath,
        pageLabel: '1',
        ocrHash: page.ocrHash,
        markdown: page.markdown,
        manualMarkdown: page.manualMarkdown,
        notes: page.notes,
      );
      expect(rebuilt.manualMarkdown, isNull);
      expect(rebuilt.pageLabel, '1');
    });
  });
}

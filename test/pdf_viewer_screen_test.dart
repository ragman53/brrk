import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brrk/src/app/pdf_viewer_screen.dart';
import 'package:brrk/src/app/reader/brrk_reader_page.dart';
import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/rust/api/models.dart';

void main() {
  group('PdfViewerScreen', () {
    final now = DateTime.now().toUtc().toIso8601String();
    final doc = PdfDoc(
      id: 'doc-1',
      title: 'Test PDF',
      originalFileName: 'test.pdf',
      pdfPath: 'pdfs/doc-1.pdf',
      markdownPath: 'markdowns/doc-1.md',
      ocrHash: 'sha256:test',
      pageCount: 3,
      lastReadPageIndex: 0,
      tags: const [],
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows book title in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: PdfViewerScreen(doc: doc)),
        ),
      );
      expect(find.text('Test PDF'), findsOneWidget);
    });

    testWidgets('AppBar has reading appearance icon button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: PdfViewerScreen(doc: doc)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('AppBar has edit page Markdown icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: PdfViewerScreen(doc: doc)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    // Verify the manual override is used when present in the loaded data.
    testWidgets('uses manual page override when present', (tester) async {
      const ocrMarkdown =
          '<!-- page: 1 -->\n# Original\n\nOriginal OCR paragraph.';
      const manualText = 'Edited paragraph body.';
      final manual = PdfManualMarkdownData(
        version: 1,
        pages: {'0': manualText},
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async => manual,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Edited paragraph body.'), findsOneWidget);
      // The original OCR text should be replaced, not present.
      expect(find.textContaining('Original OCR paragraph.'), findsNothing);
    });

    testWidgets('falls back to OCR markdown when no manual override', (
      tester,
    ) async {
      const ocrMarkdown =
          '<!-- page: 1 -->\n# Original\n\nOriginal OCR paragraph.';
      final manual = PdfManualMarkdownData(version: 1, pages: const {});
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async => manual,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Original OCR paragraph.'), findsOneWidget);
    });

    testWidgets('uses shared reader page for natural native body text', (
      tester,
    ) async {
      const ocrMarkdown = '<!-- page: 1 -->\n# Page\n\nSome body text.';
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async =>
                  PdfManualMarkdownData(version: 1, pages: const {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrrkReaderPage), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
      final readerText = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .last;
      expect(readerText.textAlign, TextAlign.start);
    });

    testWidgets('native Academic PDF page uses shared Academic paragraph', (
      tester,
    ) async {
      const ocrMarkdown = '<!-- page: 1 -->\nA philosophical investigation.';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingAppearanceProvider.overrideWith((ref) {
              final notifier = ReadingAppearanceNotifier();
              notifier.setLayoutMode(ReaderLayoutMode.academic);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async =>
                  PdfManualMarkdownData(version: 1, pages: const {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrrkReaderPage), findsOneWidget);
      expect(find.byType(AcademicSelectableText), findsOneWidget);
      final academic = tester.widget<AcademicSelectableText>(
        find.byType(AcademicSelectableText),
      );
      expect(academic.spec.displayText.contains('\u00AD'), isTrue);
    });

    testWidgets('unsupported PDF Markdown uses shared fallback', (
      tester,
    ) async {
      const ocrMarkdown =
          '<!-- page: 1 -->\nThis has [a link](https://example.com).';
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async =>
                  PdfManualMarkdownData(version: 1, pages: const {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrrkReaderPage), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.byType(AcademicSelectableText), findsNothing);
    });

    testWidgets('fallback PDF selection enables Look up and Add Note', (
      tester,
    ) async {
      var readerBuilds = 0;
      const ocrMarkdown =
          '<!-- page: 1 -->\n'
          'This is *philosophical* text with a '
          '[reference](https://example.com).';
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async =>
                  PdfManualMarkdownData(version: 1, pages: const {}),
              onReaderBuild: () => readerBuilds++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrrkReaderPage), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
      final initialReaderBuilds = readerBuilds;
      final selectable = tester.widget<SelectableText>(
        find.descendant(
          of: find.byType(MarkdownBody),
          matching: find.byType(SelectableText),
        ),
      );
      final renderedText = selectable.textSpan!.toPlainText(
        includeSemanticsLabels: false,
      );
      final start = renderedText.indexOf('philosophical');
      selectable.onSelectionChanged!(
        TextSelection(
          baseOffset: start,
          extentOffset: start + 'philosophical'.length,
        ),
        SelectionChangedCause.longPress,
      );
      await tester.pump();

      expect(readerBuilds, initialReaderBuilds);
      expect(find.text('philosophical'), findsOneWidget);
      final lookUp = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Look up'),
      );
      expect(lookUp.onPressed, isNotNull);
      final addNote = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add Note'),
      );
      expect(addNote.onPressed, isNotNull);

      selectable.onSelectionChanged!(
        const TextSelection.collapsed(offset: 0),
        SelectionChangedCause.tap,
      );
      await tester.pump();

      expect(readerBuilds, initialReaderBuilds);
      expect(find.text('philosophical'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Look up'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Add Note'), findsNothing);
    });

    testWidgets('note load completion does not rebuild the reader', (
      tester,
    ) async {
      final notes = Completer<List<PdfNote>>();
      var readerBuilds = 0;
      const ocrMarkdown = '<!-- page: 1 -->\nPlain PDF text.';
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async =>
                  PdfManualMarkdownData(version: 1, pages: const {}),
              getPdfNotesOverride: (_, _) => notes.future,
              onReaderBuild: () => readerBuilds++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrrkReaderPage), findsOneWidget);
      final initialReaderBuilds = readerBuilds;
      final now = DateTime.now().toUtc().toIso8601String();
      notes.complete([
        PdfNote(
          id: 'note-1',
          docId: doc.id,
          pageIndex: 0,
          selectedText: 'Plain',
          selectedSentence: 'Plain PDF text.',
          content: 'Loaded note',
          tags: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Loaded note'), findsOneWidget);
      expect(readerBuilds, initialReaderBuilds);
    });

    testWidgets('TOC button remains available for PDF headings', (
      tester,
    ) async {
      const ocrMarkdown = '<!-- page: 1 -->\n# Chapter\n\nBody.';
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async =>
                  PdfManualMarkdownData(version: 1, pages: const {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byType(BrrkReaderPage), findsOneWidget);
    });

    testWidgets('realistic multiline OCR PDF uses native Academic path', (
      tester,
    ) async {
      const ocrMarkdown =
          '<!-- page: 1 -->\n'
          'This is an OCR text line\n'
          'continued on the next visual line\n'
          'and a philosophical investigation continues.';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingAppearanceProvider.overrideWith((ref) {
              final notifier = ReadingAppearanceNotifier();
              notifier.setLayoutMode(ReaderLayoutMode.academic);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: PdfViewerScreen(
              doc: doc,
              getPdfMarkdownOverride: (_) async => ocrMarkdown,
              getPdfManualMarkdownOverride: (_) async =>
                  PdfManualMarkdownData(version: 1, pages: const {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrrkReaderPage), findsOneWidget);
      // Multiline plain OCR should select native prose, not legacy fallback.
      expect(find.byType(AcademicSelectableText), findsOneWidget);
      final academic = tester.widget<AcademicSelectableText>(
        find.byType(AcademicSelectableText),
      );
      expect(academic.spec.displayText.contains('\u00AD'), isTrue);
      expect(academic.spec.displayText.contains('philosophical'), isFalse);
      expect(academic.sourceText, contains('philosophical'));
      expect(find.byType(MarkdownBody), findsNothing);
    });

    testWidgets(
      'page indicator shows edit icon when current page has override',
      (tester) async {
        const ocrMarkdown = '<!-- page: 1 -->\n# Page\n\nSome body text.';
        final manual = PdfManualMarkdownData(
          version: 1,
          pages: const {'0': 'edited'},
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: PdfViewerScreen(
                doc: doc,
                getPdfMarkdownOverride: (_) async => ocrMarkdown,
                getPdfManualMarkdownOverride: (_) async => manual,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Page indicator is "Page 1 / 3" + edit icon when override exists.
        expect(find.textContaining('Page 1 / 3'), findsOneWidget);
        // Edit icon in the indicator area (chip) should be present.
        expect(find.byIcon(Icons.edit), findsOneWidget);
      },
    );
  });
}

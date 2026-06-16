import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brrk/src/app/pdf_viewer_screen.dart';
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

    testWidgets('justifies Markdown body text for book-like layout', (
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

      final markdown = tester.widget<Markdown>(find.byType(Markdown));
      expect(markdown.styleSheet?.textAlign, WrapAlignment.spaceBetween);
      expect(markdown.styleSheet?.h1Align, WrapAlignment.start);
      expect(markdown.styleSheet?.unorderedListAlign, WrapAlignment.start);
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

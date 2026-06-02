import 'package:flutter/material.dart';
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
  });
}

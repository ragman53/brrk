import 'package:brrk/src/app/reader/brrk_reader_page.dart';
import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reader/reader_markdown_plan.dart';
import 'package:brrk/src/app/reader/reader_paragraph_layout.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nativeMarkdown = '# Heading\n\nA philosophical investigation.';
  const fallbackMarkdown = 'A paragraph with [a link](https://example.com).';
  const academic = ReadingAppearance(layoutMode: ReaderLayoutMode.academic);

  Widget harness(
    String sourceName,
    String markdown,
    ReadingAppearance appearance,
  ) {
    return MaterialApp(
      home: Scaffold(
        body: KeyedSubtree(
          key: Key(sourceName),
          child: BrrkReaderPage(
            markdown: markdown,
            appearance: appearance,
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
  }

  group('Paper/PDF renderer parity', () {
    test('identical native markdown chooses the same strategy and blocks', () {
      final paperPlan = planReaderMarkdown(nativeMarkdown);
      final pdfPlan = planReaderMarkdown(nativeMarkdown);

      expect(paperPlan.strategy, pdfPlan.strategy);
      expect(paperPlan.strategy, ReaderRenderStrategy.nativeProse);
      final paperBlocks = (paperPlan as NativeReaderPlan).blocks;
      final pdfBlocks = (pdfPlan as NativeReaderPlan).blocks;
      expect(paperBlocks.length, pdfBlocks.length);
      expect(
        paperBlocks.map((b) => b.runtimeType),
        pdfBlocks.map((b) => b.runtimeType),
      );
      expect(
        (paperBlocks.first as ReaderHeadingBlock).text,
        (pdfBlocks.first as ReaderHeadingBlock).text,
      );
    });

    testWidgets(
      'identical native Academic markdown produces same paragraph output',
      (tester) async {
        await tester.pumpWidget(harness('paper', nativeMarkdown, academic));
        final paperParagraph = tester.widget<BrrkReaderParagraph>(
          find.byType(BrrkReaderParagraph),
        );
        final paperRender = const ReaderParagraphLayout().render(
          canonicalText: paperParagraph.text,
          appearance: academic,
        );
        final paperOverlay = tester.widget<AcademicSelectableText>(
          find.byType(AcademicSelectableText),
        );

        await tester.pumpWidget(harness('pdf', nativeMarkdown, academic));
        final pdfParagraph = tester.widget<BrrkReaderParagraph>(
          find.byType(BrrkReaderParagraph),
        );
        final pdfRender = const ReaderParagraphLayout().render(
          canonicalText: pdfParagraph.text,
          appearance: academic,
        );
        final pdfOverlay = tester.widget<AcademicSelectableText>(
          find.byType(AcademicSelectableText),
        );

        expect(pdfParagraph.text, paperParagraph.text);
        expect(pdfRender.displayText, paperRender.displayText);
        expect(
          _softHyphenOffsets(pdfRender.displayText),
          _softHyphenOffsets(paperRender.displayText),
        );
        expect(pdfOverlay.spec.displayText, paperOverlay.spec.displayText);
      },
    );

    test('identical unsupported markdown chooses shared fallback', () {
      final paperPlan = planReaderMarkdown(fallbackMarkdown);
      final pdfPlan = planReaderMarkdown(fallbackMarkdown);

      expect(paperPlan.strategy, pdfPlan.strategy);
      expect(paperPlan.strategy, ReaderRenderStrategy.legacyMarkdown);
    });

    testWidgets(
      'identical fallback markdown uses MarkdownBody for both sources',
      (tester) async {
        await tester.pumpWidget(harness('paper', fallbackMarkdown, academic));
        expect(find.byType(MarkdownBody), findsOneWidget);
        expect(find.byType(AcademicSelectableText), findsNothing);

        await tester.pumpWidget(harness('pdf', fallbackMarkdown, academic));
        expect(find.byType(MarkdownBody), findsOneWidget);
        expect(find.byType(AcademicSelectableText), findsNothing);
      },
    );
  });
}

List<int> _softHyphenOffsets(String text) {
  final offsets = <int>[];
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x00AD) offsets.add(i);
  }
  return offsets;
}

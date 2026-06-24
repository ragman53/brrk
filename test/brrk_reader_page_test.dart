import 'package:brrk/src/app/reader/brrk_reader_page.dart';
import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reader/reader_paragraph_layout.dart';
import 'package:brrk/src/app/reader/reader_selection.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_lookup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const natural = ReadingAppearance(layoutMode: ReaderLayoutMode.natural);
  const academic = ReadingAppearance(layoutMode: ReaderLayoutMode.academic);

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('BrrkReaderPage', () {
    testWidgets('native plan renders heading without raw marker', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          BrrkReaderPage(
            markdown: '# Heading\n\nPlain paragraph.',
            appearance: natural,
            onSelectionChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Heading'), findsOneWidget);
      expect(find.text('# Heading'), findsNothing);
      expect(find.byType(BrrkReaderParagraph), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
    });

    testWidgets('unsupported markdown uses shared flutter_markdown fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          BrrkReaderPage(
            markdown: 'This has *emphasis*.',
            appearance: natural,
            onSelectionChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.byType(BrrkReaderParagraph), findsNothing);
    });

    testWidgets(
      'Academic fallback is justified and has no decorative overlay',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            BrrkReaderPage(
              markdown: 'This has *emphasis*.',
              appearance: academic,
              onSelectionChanged: (_) {},
            ),
          ),
        );

        final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
        expect(markdown.styleSheet?.textAlign, WrapAlignment.spaceBetween);
        expect(find.byType(AcademicSelectableText), findsNothing);
      },
    );

    testWidgets('native paragraph selection emits exact source offsets', (
      tester,
    ) async {
      ReaderSelection? captured;
      await tester.pumpWidget(
        wrap(
          BrrkReaderPage(
            markdown: '# H\n\nAlpha paragraph.',
            appearance: natural,
            onSelectionChanged: (event) => captured = event,
          ),
        ),
      );

      final selectable = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .last;
      selectable.onSelectionChanged!(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        SelectionChangedCause.longPress,
      );

      expect(captured, isNotNull);
      expect(captured!.canonicalContext, 'Alpha paragraph.');
      expect(
        captured!.selection.textInside(captured!.canonicalContext),
        'Alpha',
      );
      expect(captured!.sourceStart, '# H\n\n'.length);
      expect(captured!.sourceEnd, '# H\n\nAlpha'.length);
      expect(captured!.cause, SelectionChangedCause.longPress);
    });

    testWidgets(
      'native source offsets convert to UTF-8 bytes for note fields',
      (tester) async {
        ReaderSelection? captured;
        await tester.pumpWidget(
          wrap(
            BrrkReaderPage(
              markdown: 'あAlpha paragraph.',
              appearance: natural,
              onSelectionChanged: (event) => captured = event,
            ),
          ),
        );

        final selectable = tester.widget<SelectableText>(
          find.byType(SelectableText),
        );
        selectable.onSelectionChanged!(
          const TextSelection(baseOffset: 0, extentOffset: 1),
          SelectionChangedCause.longPress,
        );

        expect(captured!.sourceStart, 0);
        expect(captured!.sourceEnd, 1);
        expect(
          utf8ByteOffsetForCodeUnitOffset(
            'あAlpha paragraph.',
            captured!.sourceEnd,
          ),
          3,
          reason: 'Paper Note.startOffset/endOffset fields are byte offsets',
        );
      },
    );

    testWidgets('fallback selection leaves source offsets null', (
      tester,
    ) async {
      ReaderSelection? captured;
      await tester.pumpWidget(
        wrap(
          BrrkReaderPage(
            markdown: 'This has *emphasis*.',
            appearance: natural,
            onSelectionChanged: (event) => captured = event,
          ),
        ),
      );

      final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      markdown.onSelectionChanged!(
        'This has emphasis.',
        const TextSelection(baseOffset: 0, extentOffset: 4),
        SelectionChangedCause.tap,
      );

      expect(captured, isNotNull);
      expect(captured!.sourceStart, isNull);
      expect(captured!.sourceEnd, isNull);
      expect(captured!.canonicalContext.contains('\u00AD'), isFalse);
    });

    testWidgets('cleared selection emits null', (tester) async {
      ReaderSelection? captured = const ReaderSelection(
        canonicalContext: 'old',
        selection: TextSelection(baseOffset: 0, extentOffset: 3),
        cause: SelectionChangedCause.tap,
      );
      await tester.pumpWidget(
        wrap(
          BrrkReaderPage(
            markdown: 'Plain paragraph.',
            appearance: natural,
            onSelectionChanged: (event) => captured = event,
          ),
        ),
      );

      final selectable = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      selectable.onSelectionChanged!(
        const TextSelection.collapsed(offset: 0),
        SelectionChangedCause.tap,
      );

      expect(captured, isNull);
    });
  });
}

import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reader/reader_paragraph_layout.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const natural = ReadingAppearance(
    fontSize: 17,
    layoutMode: ReaderLayoutMode.natural,
  );
  const academic = ReadingAppearance(
    fontSize: 17,
    layoutMode: ReaderLayoutMode.academic,
  );

  group('ReaderParagraphLayout', () {
    test('Natural produces identity and no overlay', () {
      final layout = ReaderParagraphLayout();
      final render = layout.render(
        canonicalText: 'philosophical',
        appearance: natural,
      );
      expect(render.sourceText, 'philosophical');
      expect(render.displayText, 'philosophical');
      expect(render.overlayEnabled, isFalse);
      expect(render.textAlign, TextAlign.start);
      expect(render.toReaderTextLayoutSpec(), isNull);
    });

    test('Academic runs EmergencyWordBreaker and enables overlay', () {
      final layout = ReaderParagraphLayout();
      final render = layout.render(
        canonicalText: 'philosophical',
        appearance: academic,
      );
      expect(render.sourceText, 'philosophical');
      expect(render.displayText.contains('\u00AD'), isTrue);
      expect(render.overlayEnabled, isTrue);
      expect(render.textAlign, TextAlign.justify);
      expect(render.toReaderTextLayoutSpec(), isNotNull);
    });

    test('Academic with ineligible text is identity and justify', () {
      final layout = ReaderParagraphLayout();
      final render = layout.render(
        canonicalText: 'short cat dog',
        appearance: academic,
      );
      expect(render.displayText, 'short cat dog');
      expect(render.overlayEnabled, isFalse);
      expect(render.textAlign, TextAlign.justify);
    });

    test('Canonical selection strips U+00AD markers', () {
      final layout = ReaderParagraphLayout();
      final render = layout.render(
        canonicalText: 'philosophical',
        appearance: academic,
      );
      final sub = render.canonicalSubstring(
        TextSelection(baseOffset: 0, extentOffset: render.displayText.length),
      );
      expect(sub, 'philosophical');
      expect(sub.contains('\u00AD'), isFalse);
    });

    test('Display-to-source mapping preserves selection shape', () {
      final layout = ReaderParagraphLayout();
      final render = layout.render(
        canonicalText: 'philosophical',
        appearance: academic,
      );
      final canonical = render.canonicalSelection(
        TextSelection(baseOffset: 0, extentOffset: 7),
      );
      expect(
        render.sourceText.substring(canonical.start, canonical.end),
        'philo',
      );
    });

    test('Japanese and protected tokens are not broken', () {
      final layout = ReaderParagraphLayout();
      final render = layout.render(
        canonicalText: '日本語 philosophical 世界philosophical path_token',
        appearance: academic,
      );
      // Pure Japanese segments stay marker-free.
      expect(render.displayText, isNot(contains('日\u00AD本')));
      expect(render.displayText, isNot(contains('本\u00AD語')));
      // Isolated eligible Latin words may receive Emergency word breaking.
      expect(render.displayText, contains('phi\u00AD'));
      // CJK-adjacent mixed-script and identifier-like tokens remain protected.
      expect(render.displayText, contains('世界philosophical'));
      expect(render.displayText, contains('path_token'));
    });
  });

  group('BrrkReaderParagraph', () {
    testWidgets('Natural renders one SelectableText with canonical text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrrkReaderParagraph(
              text: 'A philosophical sentence.',
              appearance: natural,
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.byType(AcademicSelectableText), findsNothing);
    });

    testWidgets('Academic renders one AcademicSelectableText with markers', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrrkReaderParagraph(
              text: 'philosophical',
              appearance: academic,
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(AcademicSelectableText), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      final overlay = tester.widget<AcademicSelectableText>(
        find.byType(AcademicSelectableText),
      );
      expect(overlay.sourceText, 'philosophical');
      expect(overlay.spec.displayText.contains('\u00AD'), isTrue);
    });

    testWidgets('collapsed selection emits null and never U+00AD', (
      tester,
    ) async {
      String? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrrkReaderParagraph(
              text: 'philosophical',
              appearance: academic,
              onSelectionChanged: (event) => last = event?.canonicalContext,
            ),
          ),
        ),
      );
      final selectable = tester.widget<AcademicSelectableText>(
        find.byType(AcademicSelectableText),
      );
      selectable.onSelectionChanged(
        const TextSelection.collapsed(offset: 2),
        SelectionChangedCause.tap,
      );
      expect(last, isNull);
    });
  });
}

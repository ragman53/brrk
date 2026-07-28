import 'package:brrk/src/app/reader/emergency_word_breaker.dart';
import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reader/hyphenation/hyphenated_text.dart';
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

    testWidgets('caches text preparation across presentation rebuilds', (
      tester,
    ) async {
      final breaker = _CountingBreaker();
      final layout = ReaderParagraphLayout(breaker: breaker);

      Widget paragraph({
        required String text,
        required ReadingAppearance appearance,
        double width = 300,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: BrrkReaderParagraph(
                text: text,
                appearance: appearance,
                layout: layout,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        paragraph(text: 'philosophical', appearance: academic),
      );
      expect(breaker.calls, 1);

      await tester.pumpWidget(
        paragraph(
          text: 'philosophical',
          appearance: const ReadingAppearance(
            fontSize: 24,
            density: ReadingDensity.spacious,
            palette: ReadingPalette.nord,
            layoutMode: ReaderLayoutMode.academic,
          ),
          width: 200,
        ),
      );
      expect(
        breaker.calls,
        1,
        reason: 'appearance and width do not change break opportunities',
      );

      await tester.pumpWidget(
        paragraph(text: 'investigation', appearance: academic),
      );
      expect(breaker.calls, 2);

      await tester.pumpWidget(
        paragraph(text: 'investigation', appearance: natural),
      );
      expect(breaker.calls, 2, reason: 'Natural never invokes the breaker');

      await tester.pumpWidget(
        paragraph(text: 'investigation', appearance: academic),
      );
      expect(breaker.calls, 3);
    });

    testWidgets('Natural mode never invokes the breaker', (tester) async {
      final breaker = _CountingBreaker();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrrkReaderParagraph(
              text: 'philosophical',
              appearance: natural,
              layout: ReaderParagraphLayout(breaker: breaker),
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );

      expect(breaker.calls, 0);
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

class _CountingBreaker extends EmergencyWordBreaker {
  int calls = 0;

  @override
  HyphenatedText breakText(String source) {
    calls++;
    return super.breakText(source);
  }
}

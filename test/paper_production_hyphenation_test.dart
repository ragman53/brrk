// SPDX-License-Identifier: MIT
//
// Tests for the Paper academic rendering seam (SPEC §15.3).
//
// These tests verify that:
// - Natural mode renders canonical text via a single `SelectableText`
//   with no overlay.
// - Academic mode renders the canonical source text with Emergency
//   word breaking applied (default `EmergencyWordBreaker`), and the
//   display text contains inserted `U+00AD` markers. The
//   `AcademicSelectableText` surface is rendered with the decorative
//   overlay.
// - Selections map from display offsets to canonical source offsets
//   before Add Note / Look up. The persisted/lookup text contains
//   no U+00AD.

import 'package:brrk/src/app/paper_book_detail_screen.dart';
import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reader/hyphenation/paper_academic_hyphenation.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brrk/src/rust/api/models.dart';

Widget _wrapWithLayoutMode(Widget child, ReaderLayoutMode mode) {
  return ProviderScope(
    overrides: [
      readingAppearanceProvider.overrideWith((ref) {
        final notifier = ReadingAppearanceNotifier();
        notifier.setLayoutMode(mode);
        return notifier;
      }),
    ],
    child: MaterialApp(home: child),
  );
}

const _sampleMarkdown = 'A philosophical investigation into nature.';

PaperBooksData _books() {
  final now = DateTime.now().toUtc().toIso8601String();
  final book = PaperBook(
    id: 'book-1',
    title: 'Test Book',
    createdAt: now,
    updatedAt: now,
    pages: [
      PaperPage(
        id: 'page-1',
        imagePath: 'images/book-1/page-1.jpg',
        ocrHash: 'sha256:abc',
        markdown: _sampleMarkdown,
        notes: const [],
      ),
    ],
  );
  return PaperBooksData(version: 1, books: [book]);
}

ReadingAppearance _natural() =>
    const ReadingAppearance(fontSize: 17, layoutMode: ReaderLayoutMode.natural);

ReadingAppearance _academic() => const ReadingAppearance(
  fontSize: 17,
  layoutMode: ReaderLayoutMode.academic,
);

Future<void> _setUpPaperBook() async {
  SharedPreferences.setMockInitialValues({});
}

void main() {
  setUp(_setUpPaperBook);
  tearDown(() {
    clearPaperHyphenationOverrideForTest();
  });

  testWidgets(
    'Natural mode renders exactly one SelectableText with canonical text',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithLayoutMode(
          PaperBookDetailScreen(
            bookId: 'book-1',
            getBooks: () async => _books(),
          ),
          ReaderLayoutMode.natural,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.byType(AcademicSelectableText), findsNothing);
    },
  );

  testWidgets(
    'Academic mode renders AcademicSelectableText with Emergency word breaking markers',
    (tester) async {
      // No override: default PaperAcademicHyphenation + default
      // EmergencyWordBreaker applies. The sample contains
      // `philosophical` (eligible) and `investigation` (eligible),
      // so markers must appear.
      await tester.pumpWidget(
        _wrapWithLayoutMode(
          PaperBookDetailScreen(
            bookId: 'book-1',
            getBooks: () async => _books(),
          ),
          ReaderLayoutMode.academic,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AcademicSelectableText), findsOneWidget);
      // The AcademicSelectableText wraps exactly one primary
      // SelectableText (the FEAT-SPEC contract).
      expect(find.byType(SelectableText), findsOneWidget);
      final overlay = tester.widget<AcademicSelectableText>(
        find.byType(AcademicSelectableText),
      );
      expect(overlay.sourceText, _sampleMarkdown);
      expect(overlay.spec.displayText.contains('\u00AD'), isTrue);
    },
  );

  testWidgets('Academic uses TextAlign.justify on the primary SelectableText', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithLayoutMode(
        PaperBookDetailScreen(bookId: 'book-1', getBooks: () async => _books()),
        ReaderLayoutMode.academic,
      ),
    );
    await tester.pumpAndSettle();
    final selectable = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    expect(selectable.textAlign, TextAlign.justify);
  });

  testWidgets('Natural uses TextAlign.start on the primary SelectableText', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithLayoutMode(
        PaperBookDetailScreen(bookId: 'book-1', getBooks: () async => _books()),
        ReaderLayoutMode.natural,
      ),
    );
    await tester.pumpAndSettle();
    final selectable = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    expect(selectable.textAlign, TextAlign.start);
    // Natural must not contain U+00AD.
    expect(
      (selectable.data ?? selectable.textSpan!.toPlainText()).contains(
        '\u00AD',
      ),
      isFalse,
    );
  });

  test(
    'PaperAcademicHyphenation: Natural produces identity and no overlay',
    () {
      final seam = PaperAcademicHyphenation();
      final render = seam.render(
        canonicalSource: 'philosophical',
        appearance: _natural(),
      );
      expect(render.sourceText, 'philosophical');
      expect(render.displayText, 'philosophical');
      expect(render.overlayEnabled, isFalse);
      expect(render.textAlign, TextAlign.start);
    },
  );

  test(
    'PaperAcademicHyphenation: Academic applies Emergency word breaking',
    () {
      final seam = PaperAcademicHyphenation();
      final render = seam.render(
        canonicalSource: 'philosophical',
        appearance: _academic(),
      );
      expect(render.sourceText, 'philosophical');
      expect(render.displayText.contains('\u00AD'), isTrue);
      expect(render.overlayEnabled, isTrue);
      expect(render.textAlign, TextAlign.justify);
    },
  );

  test(
    'PaperAcademicHyphenation: Academic on ineligible text produces identity',
    () {
      final seam = PaperAcademicHyphenation();
      final render = seam.render(
        canonicalSource: 'short cat dog',
        appearance: _academic(),
      );
      // No word ≥ 7 chars → no markers → overlay disabled.
      expect(render.displayText, 'short cat dog');
      expect(render.overlayEnabled, isFalse);
      expect(render.textAlign, TextAlign.justify);
    },
  );

  test('PaperAcademicHyphenation: canonical selection strips U+00AD', () {
    final seam = PaperAcademicHyphenation();
    final render = seam.render(
      canonicalSource: 'philosophical',
      appearance: _academic(),
    );
    final sub = render.canonicalSubstring(
      TextSelection(baseOffset: 0, extentOffset: render.displayText.length),
    );
    expect(sub, 'philosophical');
    expect(sub.contains('\u00AD'), isFalse);
  });

  test(
    'PaperAcademicHyphenation: display-to-source mapping preserves selection',
    () {
      final seam = PaperAcademicHyphenation();
      final render = seam.render(
        canonicalSource: 'philosophical',
        appearance: _academic(),
      );
      // Display indices 0..7 cover `phi<­>l<­>o` which maps to
      // canonical source indices 0..5 = `philo`.
      final sel = TextSelection(baseOffset: 0, extentOffset: 7);
      final canonical = render.canonicalSelection(sel);
      expect(
        render.sourceText.substring(canonical.start, canonical.end),
        'philo',
      );
    },
  );

  test('PaperAcademicHyphenation: canonicalSubstring contains no U+00AD', () {
    final seam = PaperAcademicHyphenation();
    final render = seam.render(
      canonicalSource: 'philosophical and philosophical',
      appearance: _academic(),
    );
    // Any whole-string selection should still map cleanly.
    for (var i = 1; i < render.displayText.length; i++) {
      final sub = render.canonicalSubstring(
        TextSelection(baseOffset: 0, extentOffset: i),
      );
      expect(sub.contains('\u00AD'), isFalse);
    }
  });
}

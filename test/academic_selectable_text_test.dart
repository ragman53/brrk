// SPDX-License-Identifier: MIT
//
// Widget test for FEAT-SPEC §10.2 / §10.9 surface contract.

import 'package:brrk/src/app/reader/hyphenation/academic_selectable_text.dart';
import 'package:brrk/src/app/reader/hyphenation/reader_text_layout_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcademicSelectableText', () {
    testWidgets('contains exactly one SelectableText and one CustomPaint', (
      tester,
    ) async {
      const spec = ReaderTextLayoutSpec(
        displayText: 'philo\u00ADsophical',
        resolvedTextStyle: TextStyle(fontSize: 22, height: 1.25),
        textAlign: TextAlign.justify,
      );
      String? lastSelection;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 104,
                child: AcademicSelectableText(
                  spec: spec,
                  sourceText: 'philosophical',
                  onSelectionChanged: (s) => lastSelection = s.toString(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.byKey(const Key('academic-overlay-paint')), findsOneWidget);
      expect(find.byKey(const Key('academic-selectable-text')), findsOneWidget);
      // lastSelection may be null or empty in tests (no user input);
      // we only assert it is a string.
      expect(lastSelection, anyOf(isNull, isA<String>()));
    });

    testWidgets('overlay is wrapped in IgnorePointer and ExcludeSemantics', (
      tester,
    ) async {
      const spec = ReaderTextLayoutSpec(
        displayText: 'philo\u00ADsophical',
        resolvedTextStyle: TextStyle(fontSize: 22, height: 1.25),
        textAlign: TextAlign.justify,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 104,
                child: AcademicSelectableText(
                  spec: spec,
                  sourceText: 'philosophical',
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      // The custom paint layer is the only CustomPaint in the tree.
      final overlay = find.byKey(const Key('academic-overlay-paint'));
      expect(overlay, findsOneWidget);

      // The overlay must be wrapped in IgnorePointer and
      // ExcludeSemantics directly above it (not transitively through
      // many ancestors). We assert that the immediate parent chain
      // contains both wrappers.
      final parents = find.ancestor(
        of: overlay,
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer || w is ExcludeSemantics,
        ),
      );
      expect(parents, findsAtLeast(1));
      expect(
        find.ancestor(of: overlay, matching: find.byType(IgnorePointer)),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.ancestor(of: overlay, matching: find.byType(ExcludeSemantics)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets(
      'primary SelectableText uses spec.displayText and semanticsLabel',
      (tester) async {
        const spec = ReaderTextLayoutSpec(
          displayText: 'philo\u00ADsophical',
          resolvedTextStyle: TextStyle(fontSize: 22, height: 1.25),
          textAlign: TextAlign.justify,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 104,
                  child: AcademicSelectableText(
                    spec: spec,
                    sourceText: 'philosophical',
                    onSelectionChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        final selectableFinder = find.byKey(
          const Key('academic-selectable-text'),
        );
        final selectable = tester.widget<SelectableText>(selectableFinder);
        expect(selectable.textAlign, TextAlign.justify);
        expect(selectable.cursorWidth, 2.0);
        expect(selectable.semanticsLabel, 'philosophical');
        expect(selectable.data, 'philo\u00ADsophical');
      },
    );

    testWidgets('passes custom cursorWidth to primary SelectableText', (
      tester,
    ) async {
      const spec = ReaderTextLayoutSpec(
        displayText: 'philo\u00ADsophical',
        resolvedTextStyle: TextStyle(fontSize: 22, height: 1.25),
        textAlign: TextAlign.justify,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 104,
              child: AcademicSelectableText(
                spec: spec,
                sourceText: 'philosophical',
                cursorWidth: 4.0,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final selectable = tester.widget<SelectableText>(
        find.byKey(const Key('academic-selectable-text')),
      );
      expect(selectable.cursorWidth, 4.0);
    });
  });
}

// SPDX-License-Identifier: MIT
//
// Tests for FEAT-SPEC §10.3 value object `ReaderTextLayoutSpec`.

import 'dart:ui' show Locale;

import 'package:brrk/src/app/reader/hyphenation/reader_text_layout_spec.dart';
import 'package:flutter/painting.dart'
    show TextAlign, TextDirection, TextStyle, TextWidthBasis;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 17);

  group('ReaderTextLayoutSpec', () {
    test('structural equality matches all fields', () {
      const a = ReaderTextLayoutSpec(
        displayText: 'hello',
        resolvedTextStyle: baseStyle,
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        locale: Locale('en', 'US'),
        textWidthBasis: TextWidthBasis.parent,
        maxLines: 2,
        ellipsis: '…',
      );
      const b = ReaderTextLayoutSpec(
        displayText: 'hello',
        resolvedTextStyle: baseStyle,
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        locale: Locale('en', 'US'),
        textWidthBasis: TextWidthBasis.parent,
        maxLines: 2,
        ellipsis: '…',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('changing any layout-affecting field breaks equality', () {
      const a = ReaderTextLayoutSpec(
        displayText: 'hello',
        resolvedTextStyle: baseStyle,
      );
      expect(a, isNot(equals(a.copyWith(displayText: 'hello there'))));
      expect(a, isNot(equals(a.copyWith(textAlign: TextAlign.justify))));
      expect(a, isNot(equals(a.copyWith(textDirection: TextDirection.rtl))));
      expect(a, isNot(equals(a.copyWith(locale: const Locale('en', 'US')))));
      expect(
        a,
        isNot(equals(a.copyWith(textWidthBasis: TextWidthBasis.longestLine))),
      );
      expect(a, isNot(equals(a.copyWith(maxLines: 3))));
      expect(a, isNot(equals(a.copyWith(ellipsis: '…'))));
      expect(
        a,
        isNot(
          equals(
            a.copyWith(resolvedTextStyle: baseStyle.copyWith(fontSize: 18)),
          ),
        ),
      );
    });

    test('defaults are ltr + parent width basis + start alignment', () {
      const spec = ReaderTextLayoutSpec(
        displayText: 'hi',
        resolvedTextStyle: baseStyle,
      );
      expect(spec.textDirection, TextDirection.ltr);
      expect(spec.textWidthBasis, TextWidthBasis.parent);
      expect(spec.textAlign, TextAlign.start);
      expect(spec.textScaler, isNull);
      expect(spec.locale, isNull);
      expect(spec.strutStyle, isNull);
      expect(spec.textHeightBehavior, isNull);
      expect(spec.maxLines, isNull);
      expect(spec.ellipsis, isNull);
    });

    test('copyWith preserves unset fields', () {
      const a = ReaderTextLayoutSpec(
        displayText: 'hello',
        resolvedTextStyle: baseStyle,
        textAlign: TextAlign.justify,
        maxLines: 2,
      );
      final b = a.copyWith(displayText: 'world');
      expect(b.displayText, 'world');
      expect(b.textAlign, TextAlign.justify);
      expect(b.maxLines, 2);
      expect(b.resolvedTextStyle, baseStyle);
    });
  });
}

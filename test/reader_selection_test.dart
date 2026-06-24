import 'package:brrk/src/app/reader/reader_selection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderSelection', () {
    test('canonical context is preserved verbatim', () {
      const selection = ReaderSelection(
        canonicalContext: 'hello',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
        cause: SelectionChangedCause.longPress,
        sourceStart: 0,
        sourceEnd: 5,
      );
      expect(selection.canonicalContext, 'hello');
      expect(selection.cause, SelectionChangedCause.longPress);
      expect(selection.sourceStart, 0);
      expect(selection.sourceEnd, 5);
    });

    test('source offsets are nullable for fallback paths', () {
      const selection = ReaderSelection(
        canonicalContext: 'ctx',
        selection: TextSelection(baseOffset: 0, extentOffset: 3),
        cause: null,
      );
      expect(selection.sourceStart, isNull);
      expect(selection.sourceEnd, isNull);
      expect(selection.cause, isNull);
    });

    test('canonical context never contains U+00AD', () {
      // The renderer is responsible for stripping U+00AD from contexts;
      // the value object preserves whatever it is given.
      const selection = ReaderSelection(
        canonicalContext: 'canonical',
        selection: TextSelection(baseOffset: 0, extentOffset: 9),
        cause: SelectionChangedCause.tap,
      );
      expect(selection.canonicalContext.contains('\u00AD'), isFalse);
    });
  });
}

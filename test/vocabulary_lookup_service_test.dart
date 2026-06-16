import 'dart:convert' show utf8;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_lookup_service.dart';

/// Build a non-collapsed [TextSelection] in [context] from raw UTF-16
/// offsets. We use [TextSelection.collapsed] + an extent offset via
/// [TextSelection] to keep tests independent of how the platform normalizes
/// `baseOffset`/`extentOffset`.
TextSelection _sel(String context, int start, int end) {
  expect(
    start >= 0 && end <= context.length,
    isTrue,
    reason: 'selection out of range',
  );
  expect(start < end, isTrue, reason: 'collapsed selection');
  return TextSelection(baseOffset: start, extentOffset: end);
}

void main() {
  group('isValidVocabularySelection', () {
    test('accepts English words with hyphen or apostrophe', () {
      expect(isValidVocabularySelection('being'), isTrue);
      expect(isValidVocabularySelection("don't"), isTrue);
      expect(isValidVocabularySelection('self-conscious'), isTrue);
    });

    test('accepts short Japanese terms without whitespace', () {
      expect(isValidVocabularySelection('存在'), isTrue);
      expect(isValidVocabularySelection('差異と反復'), isTrue);
    });

    test('rejects invalid mixed or multi-word selections', () {
      expect(isValidVocabularySelection('common sense'), isFalse);
      expect(isValidVocabularySelection('差異 difference'), isFalse);
      expect(isValidVocabularySelection('123'), isFalse);
      expect(isValidVocabularySelection('   '), isFalse);
    });
  });

  group('utf8ByteOffsetForCodeUnitOffset', () {
    test('ASCII offsets are unchanged', () {
      const ctx = 'the being here';
      expect(utf8ByteOffsetForCodeUnitOffset(ctx, 4), 4);
      expect(utf8ByteOffsetForCodeUnitOffset(ctx, 9), 9);
    });

    test('Japanese code-unit offsets map to UTF-8 byte offsets', () {
      const ctx = 'これは最初の文です。対象語を含む二番目の文です。最後の文です。';
      final start = ctx.indexOf('対象語');
      final end = start + '対象語'.length;
      expect(start, 10);
      expect(end, 13);
      expect(utf8ByteOffsetForCodeUnitOffset(ctx, start), 30);
      expect(utf8ByteOffsetForCodeUnitOffset(ctx, end), 39);
    });

    test('handles null, zero, negative, and out-of-range offsets', () {
      const ctx = '存在 being';
      expect(utf8ByteOffsetForCodeUnitOffset(ctx, null), isNull);
      expect(utf8ByteOffsetForCodeUnitOffset(ctx, 0), 0);
      expect(utf8ByteOffsetForCodeUnitOffset(ctx, -4), 0);
      expect(
        utf8ByteOffsetForCodeUnitOffset(ctx, 999),
        utf8.encode(ctx).length,
      );
    });
  });

  group('vocabularyCandidateFromSelection', () {
    group('valid raw selection', () {
      test('returns exact word for any cause when raw is already valid', () {
        const ctx = 'the being of things';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 4, 9),
          cause: SelectionChangedCause.doubleTap,
        );
        expect(c, isNotNull);
        expect(c!.text, 'being');
        expect(c.start, 4);
        expect(c.end, 9);
      });

      test('preserves raw selection under long-press when valid', () {
        const ctx = 'the being of things';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 4, 9),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNotNull);
        expect(c!.text, 'being');
        expect(c.start, 4);
        expect(c.end, 9);
      });

      test('preserves CJK term under long-press when valid', () {
        const ctx = '私は存在を考える';
        // '存在' starts at index 2 (after '私は'), 2 chars long.
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 2, 4),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNotNull);
        expect(c!.text, '存在');
        expect(c.start, 2);
        expect(c.end, 4);
      });

      test('returns null for collapsed selection', () {
        const ctx = 'the being of things';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: const TextSelection.collapsed(offset: 4),
        );
        expect(c, isNull);
      });
    });

    group('long-press over-selection recovery', () {
      test('trims trailing period to recover "being" from "being."', () {
        const ctx = 'the being. more text';
        // 'being.' at indices 4..10
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 4, 10),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNotNull);
        expect(c!.text, 'being');
        expect(c.start, 4);
        expect(c.end, 9);
      });

      test(
        'trims smart quotes to recover "being" from "\u201Cbeing\u201D"',
        () {
          const ctx = 'the \u201Cbeing\u201D here';
          // "\u201Cbeing\u201D" at indices 4..12 ( \u201C b e i n g \u201D )
          final c = vocabularyCandidateFromSelection(
            context: ctx,
            selection: _sel(ctx, 4, 12),
            cause: SelectionChangedCause.longPress,
          );
          expect(c, isNotNull);
          expect(c!.text, 'being');
          expect(c.start, 5);
          expect(c.end, 10);
        },
      );

      test(
        'infers "being" from "the being" when midpoint falls in "being"',
        () {
          const ctx = 'the being here';
          // 'the being' at indices 0..9
          // midpoint = (0+9)~/2 = 4 -> substring index 4 is in 'being'
          final c = vocabularyCandidateFromSelection(
            context: ctx,
            selection: _sel(ctx, 0, 9),
            cause: SelectionChangedCause.longPress,
          );
          expect(c, isNotNull);
          expect(c!.text, 'being');
          expect(c.start, 4);
          expect(c.end, 9);
        },
      );

      test(
        'infers "being" from "the being," when midpoint falls in "being"',
        () {
          const ctx = 'the being,';
          // 'the being,' at indices 0..10
          // midpoint = (0+10)~/2 = 5 -> substring index 5 is in 'being'
          final c = vocabularyCandidateFromSelection(
            context: ctx,
            selection: _sel(ctx, 0, 10),
            cause: SelectionChangedCause.longPress,
          );
          expect(c, isNotNull);
          expect(c!.text, 'being');
          expect(c.start, 4);
          expect(c.end, 9);
        },
      );

      test('returns null for ambiguous midpoint between two words', () {
        const ctx = 'common sense here';
        // 'common sense' at indices 0..12
        // midpoint = (0+12)~/2 = 6 -> substring index 6 is the space
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, 12),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });

      test('returns null for one word plus broad unrelated trailing text', () {
        const ctx = 'being 12345678901234567890';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, ctx.length),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });

      test('returns null for full sentence selection', () {
        const ctx = 'The cat sat on the mat.';
        // 'The cat sat on the mat.' at indices 0..23
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, 23),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });

      test('returns null when selection crosses a sentence terminator', () {
        const ctx = 'first. second';
        // 'first. second' at indices 0..13
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, 13),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });

      test('returns null when selection contains a newline', () {
        const ctx = 'first\nsecond';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, ctx.length),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });

      test('returns null for mixed-script selection', () {
        const ctx = '差異 difference';
        // '差異 difference' is 9 code units: 差=0, 異=1, space=2,
        // d=3..n=10, e=11
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, ctx.length),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });

      test('trims whitespace and recovers CJK for over-long selection', () {
        // 21 CJK chars is rejected by the 20-char cap; punctuation trim
        // cannot recover, so it should remain null.
        const ctx = '存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在存在';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, ctx.length),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });
    });

    group('double-tap behavior preserved', () {
      test('returns valid raw selection unchanged for double-tap', () {
        const ctx = 'the being of things';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 4, 9),
          cause: SelectionChangedCause.doubleTap,
        );
        expect(c, isNotNull);
        expect(c!.text, 'being');
      });

      test(
        'returns null for invalid double-tap selection (no over-select recovery)',
        () {
          const ctx = 'the being. more';
          // 'being.' at 4..10 - invalid because of trailing period
          final c = vocabularyCandidateFromSelection(
            context: ctx,
            selection: _sel(ctx, 4, 10),
            cause: SelectionChangedCause.doubleTap,
          );
          expect(c, isNull);
        },
      );

      test('returns null for invalid double-tap multi-word selection', () {
        const ctx = 'the being here';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, 9),
          cause: SelectionChangedCause.doubleTap,
        );
        expect(c, isNull);
      });

      test('returns null for unknown cause (no inference)', () {
        const ctx = 'the being. more';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 4, 10),
          cause: null,
        );
        expect(c, isNull);
      });
    });

    group('edge cases', () {
      test('handles empty context', () {
        final c = vocabularyCandidateFromSelection(
          context: '',
          selection: const TextSelection(baseOffset: 0, extentOffset: 0),
        );
        expect(c, isNull);
      });

      test('clamps offsets that exceed the context length', () {
        const ctx = 'being';
        // extentOffset exceeds context length; should clamp to length.
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: TextSelection(baseOffset: 0, extentOffset: 100),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNotNull);
        expect(c!.text, 'being');
        expect(c.start, 0);
        expect(c.end, 5);
      });

      test('returns null when selection is only whitespace', () {
        const ctx = '   ';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, 3),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });

      test('returns null when selection is only punctuation', () {
        const ctx = '...';
        final c = vocabularyCandidateFromSelection(
          context: ctx,
          selection: _sel(ctx, 0, 3),
          cause: SelectionChangedCause.longPress,
        );
        expect(c, isNull);
      });
    });
  });
}

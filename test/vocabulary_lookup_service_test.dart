import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_lookup_service.dart';

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
}

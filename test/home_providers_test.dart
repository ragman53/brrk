import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/home_providers.dart';

void main() {
  group('PaperBooksState sealed class', () {
    test('PaperBooksLoading is a PaperBooksState', () {
      const state = PaperBooksLoading();
      expect(state, isA<PaperBooksState>());
    });

    test('PaperBooksError stores message', () {
      const state = PaperBooksError('disk error');
      expect(state.message, 'disk error');
    });
  });

  group('PdfDocsState sealed class', () {
    test('PdfDocsLoading is a PdfDocsState', () {
      const state = PdfDocsLoading();
      expect(state, isA<PdfDocsState>());
    });

    test('PdfDocsError stores message', () {
      const state = PdfDocsError('file not found');
      expect(state.message, 'file not found');
    });
  });
}
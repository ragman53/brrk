import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/camera_service.dart';

void main() {
  group('paperImageRelativePath', () {
    test('returns relative image path expected by Rust storage validation', () {
      expect(
        paperImageRelativePath('book-1', 'page-1'),
        'images/book-1/page-1.jpg',
      );
    });

    test('does not return an absolute path', () {
      final path = paperImageRelativePath('book-1', 'page-1');
      expect(path.startsWith('/'), isFalse);
    });
  });
}

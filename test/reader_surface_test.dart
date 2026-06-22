import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/reader/reader_surface.dart';

void main() {
  group('ReaderSurface', () {
    test('horizontal padding matches spec for phone widths', () {
      expect(ReaderSurface.horizontalPaddingFor(360.0), 18.0);
      expect(ReaderSurface.horizontalPaddingFor(400.0), 18.0);
      expect(ReaderSurface.horizontalPaddingFor(599.0), 18.0);
    });

    test('horizontal padding matches spec for wide-screen widths', () {
      expect(ReaderSurface.horizontalPaddingFor(600.0), 24.0);
      expect(ReaderSurface.horizontalPaddingFor(840.0), 24.0);
    });

    test('max body width is 640 dp', () {
      expect(ReaderSurface.maxBodyWidth, 640.0);
    });

    testWidgets('applies max width constraint to child', (tester) async {
      const innerKey = Key('reader-surface-child');
      const inner = SizedBox(key: innerKey, width: 2000, height: 20);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReaderSurface(child: inner)),
        ),
      );
      final childSize = tester.getSize(find.byKey(innerKey));
      expect(childSize.width, lessThan(ReaderSurface.maxBodyWidth));
    });
  });
}

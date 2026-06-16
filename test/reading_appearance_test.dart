import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brrk/src/app/reading_appearance.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  group('ReadingAppearanceControls', () {
    testWidgets('renders font size slider and density/palette buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const Scaffold(body: ReadingAppearanceControls())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Font size'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Density'), findsOneWidget);
      expect(find.text('Palette'), findsOneWidget);
    });

    testWidgets('shows current font size value', (tester) async {
      await tester.pumpWidget(
        wrap(const Scaffold(body: ReadingAppearanceControls())),
      );
      await tester.pumpAndSettle();

      expect(find.text('16sp'), findsOneWidget); // default
    });
  });

  group('ReadingAppearance text styles', () {
    test('use Noto Serif as primary and Noto Serif JP as fallback', () {
      const appearance = ReadingAppearance();

      expect(appearance.bodyStyle.fontFamily, brrkSerifFontFamily);
      expect(appearance.bodyStyle.fontFamilyFallback, brrkSerifFontFallback);
      expect(appearance.bodyStyle.fontWeight, FontWeight.normal);
      expect(appearance.paragraphStyle().fontFamily, brrkSerifFontFamily);
      expect(
        appearance.paragraphStyle().fontFamilyFallback,
        brrkSerifFontFallback,
      );
      expect(appearance.paragraphStyle().fontWeight, FontWeight.normal);
      expect(appearance.heading1Style().fontFamily, brrkSerifFontFamily);
      expect(
        appearance.heading1Style().fontFamilyFallback,
        brrkSerifFontFallback,
      );
    });
  });

  group('ReadingPalette.materialScheme', () {
    test('default palette brightness is light', () {
      final scheme = ReadingPalette.defaultPalette.materialScheme;
      expect(scheme.brightness, Brightness.light);
    });

    test('gruvbox palette brightness is dark', () {
      final scheme = ReadingPalette.gruvbox.materialScheme;
      expect(scheme.brightness, Brightness.dark);
    });

    test('solarized palette brightness is dark', () {
      final scheme = ReadingPalette.solarized.materialScheme;
      expect(scheme.brightness, Brightness.dark);
    });

    test('nord palette brightness is dark', () {
      final scheme = ReadingPalette.nord.materialScheme;
      expect(scheme.brightness, Brightness.dark);
    });
  });
}

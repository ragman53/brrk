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
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Palette'), findsOneWidget);
    });

    testWidgets('shows current font size value', (tester) async {
      await tester.pumpWidget(
        wrap(const Scaffold(body: ReadingAppearanceControls())),
      );
      await tester.pumpAndSettle();

      expect(find.text('17sp'), findsOneWidget); // default
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

    test('default font size is 17sp and range is preserved', () {
      const appearance = ReadingAppearance();
      expect(appearance.fontSize, ReadingAppearance.defaultFontSize);
      expect(ReadingAppearance.defaultFontSize, 17.0);
      expect(ReadingAppearance.minFontSize, 12.0);
      expect(ReadingAppearance.maxFontSize, 32.0);
    });

    test('all densities use letter spacing 0 and body word spacing is 0', () {
      for (final d in ReadingDensity.values) {
        expect(d.letterSpacing, 0.0, reason: 'density ${d.name}');
      }
      const appearance = ReadingAppearance();
      expect(appearance.bodyStyle.letterSpacing, 0.0);
      expect(appearance.bodyStyle.wordSpacing, 0.0);
      expect(appearance.paragraphStyle().letterSpacing, 0.0);
      expect(appearance.paragraphStyle().wordSpacing, 0.0);
    });

    test('density line heights match spec', () {
      expect(ReadingDensity.compact.lineHeight, 1.35);
      expect(ReadingDensity.standard.lineHeight, 1.50);
      expect(ReadingDensity.spacious.lineHeight, 1.65);
    });

    test('density paragraph spacings match spec', () {
      expect(ReadingDensity.compact.paragraphSpacing, 8);
      expect(ReadingDensity.standard.paragraphSpacing, 12);
      expect(ReadingDensity.spacious.paragraphSpacing, 18);
    });
  });

  group('ReaderLayoutMode', () {
    test('default is natural', () {
      const appearance = ReadingAppearance();
      expect(appearance.layoutMode, ReaderLayoutMode.natural);
    });

    test('bodyTextAlign returns start for natural', () {
      const appearance = ReadingAppearance(
        layoutMode: ReaderLayoutMode.natural,
      );
      expect(appearance.bodyTextAlign, TextAlign.start);
    });

    test('bodyTextAlign returns justify for academic', () {
      const appearance = ReadingAppearance(
        layoutMode: ReaderLayoutMode.academic,
      );
      expect(appearance.bodyTextAlign, TextAlign.justify);
    });

    test('layout mode persists across notifier reload', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reading_layout_mode': 'academic',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
        if (container.read(readingAppearanceProvider).layoutMode ==
            ReaderLayoutMode.academic) {
          break;
        }
      }

      final appearance = container.read(readingAppearanceProvider);
      expect(appearance.layoutMode, ReaderLayoutMode.academic);
    });
  });

  group('ReadingAppearanceNotifier font persistence', () {
    test(
      'previews multiple values and persists only the final value',
      () async {
        final notifier = ReadingAppearanceNotifier();
        addTearDown(notifier.dispose);
        await Future<void>.delayed(Duration.zero);

        notifier.previewFontSize(18);
        notifier.previewFontSize(19);
        notifier.previewFontSize(20);

        final prefs = await SharedPreferences.getInstance();
        expect(notifier.state.fontSize, 20);
        expect(prefs.getDouble('reading_font_size'), isNull);

        await notifier.persistFontSize(20);
        expect(prefs.getDouble('reading_font_size'), 20);
      },
    );

    test('reload restores the final persisted font size', () async {
      final notifier = ReadingAppearanceNotifier();
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      notifier.previewFontSize(23);
      await notifier.persistFontSize(23);

      final reloaded = ReadingAppearanceNotifier();
      addTearDown(reloaded.dispose);
      for (var i = 0; i < 10 && reloaded.state.fontSize != 23; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(reloaded.state.fontSize, 23);
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

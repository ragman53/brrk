import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bundled Noto Serif font used as the default app font for Latin text.
const brrkSerifFontFamily = 'NotoSerif';

/// Bundled Japanese Mincho-style Noto Serif font used for Japanese glyphs.
const brrkJapaneseSerifFontFamily = 'NotoSerifJP';

/// Uses Noto Serif for English/Latin text and Noto Serif JP for Japanese text.
const brrkSerifFontFallback = <String>[brrkJapaneseSerifFontFamily];

/// Density presets for reading content.
enum ReadingDensity {
  compact(1.25, 8, 0.0),
  standard(1.50, 12, 0.1),
  spacious(1.75, 18, 0.2);

  const ReadingDensity(
    this.lineHeight,
    this.paragraphSpacing,
    this.letterSpacing,
  );
  final double lineHeight;
  final double paragraphSpacing;
  final double letterSpacing;
}

/// Color palette for reading surfaces.
enum ReadingPalette {
  defaultPalette(
    Color(0xFFFFFCDC),
    Color(0xFF14281D),
    Color(0xFF9E9E9E),
    Color(0xFF1976D2),
  ),
  gruvbox(
    Color(0xFF282828),
    Color(0xFFEBDBB2),
    Color(0xFF928374),
    Color(0xFFFE8019),
  ),
  solarized(
    Color(0xFF002B36),
    Color(0xFF93A1A1),
    Color(0xFF586E75),
    Color(0xFF268BD2),
  ),
  nord(
    Color(0xFF2E3440),
    Color(0xFFE5E9F0),
    Color(0xFF4C566A),
    Color(0xFF81A1C1),
  );

  const ReadingPalette(
    this.background,
    this.foreground,
    this.muted,
    this.accent,
  );
  final Color background;
  final Color foreground;
  final Color muted;
  final Color accent;

  /// Full Material 3 `ColorScheme` for use as `ThemeData.colorScheme`.
  /// Uses `ColorScheme.fromSeed` for all palettes. Dark-background palettes
  /// (gruvbox, solarized, nord) include `brightness: Brightness.dark` so
  /// `fromSeed` correctly derives a dark scheme.
  ColorScheme get materialScheme {
    final brightness = _isDark ? Brightness.dark : Brightness.light;
    return ColorScheme.fromSeed(seedColor: background, brightness: brightness);
  }

  bool get _isDark {
    // Use perceived luminance; dark seeds produce dark schemes.
    return background.computeLuminance() < 0.5;
  }
}

/// Reusable controls widget for reading appearance settings.
/// Used in both Settings and in-reader bottom sheets.
class ReadingAppearanceControls extends ConsumerWidget {
  const ReadingAppearanceControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(readingAppearanceProvider);
    final notifier = ref.read(readingAppearanceProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font size.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Font size'),
              Text('${appearance.fontSize.round()}sp'),
            ],
          ),
          Slider(
            value: appearance.fontSize,
            min: 12,
            max: 32,
            divisions: 20,
            onChanged: (v) => notifier.setFontSize(v),
          ),
          const SizedBox(height: 16),

          // Density.
          const Text('Density'),
          const SizedBox(height: 8),
          SegmentedButton<ReadingDensity>(
            segments: const [
              ButtonSegment(
                value: ReadingDensity.compact,
                label: Text('Compact'),
              ),
              ButtonSegment(
                value: ReadingDensity.standard,
                label: Text('Standard'),
              ),
              ButtonSegment(
                value: ReadingDensity.spacious,
                label: Text('Spacious'),
              ),
            ],
            selected: {appearance.density},
            onSelectionChanged: (s) => notifier.setDensity(s.first),
          ),
          const SizedBox(height: 16),

          // Palette.
          const Text('Palette'),
          const SizedBox(height: 8),
          SegmentedButton<ReadingPalette>(
            segments: const [
              ButtonSegment(
                value: ReadingPalette.defaultPalette,
                label: Text('Default'),
              ),
              ButtonSegment(
                value: ReadingPalette.gruvbox,
                label: Text('Gruvbox'),
              ),
              ButtonSegment(
                value: ReadingPalette.solarized,
                label: Text('Solarized'),
              ),
              ButtonSegment(value: ReadingPalette.nord, label: Text('Nord')),
            ],
            selected: {appearance.palette},
            onSelectionChanged: (s) => notifier.setPalette(s.first),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Reading appearance configuration.
class ReadingAppearance {
  final double fontSize;
  final ReadingDensity density;
  final ReadingPalette palette;

  const ReadingAppearance({
    this.fontSize = 16.0,
    this.density = ReadingDensity.standard,
    this.palette = ReadingPalette.defaultPalette,
  });

  ReadingAppearance copyWith({
    double? fontSize,
    ReadingDensity? density,
    ReadingPalette? palette,
  }) => ReadingAppearance(
    fontSize: fontSize ?? this.fontSize,
    density: density ?? this.density,
    palette: palette ?? this.palette,
  );

  /// Heading sizes scaled from body fontSize.
  double get heading1Size => (fontSize + 8).clamp(12.0, 36.0);
  double get heading2Size => (fontSize + 5).clamp(12.0, 32.0);
  double get heading3Size => (fontSize + 3).clamp(12.0, 28.0);

  /// TextStyle for body text.
  TextStyle get bodyStyle => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.normal,
    height: density.lineHeight,
    letterSpacing: density.letterSpacing,
    color: palette.foreground,
    fontFamily: brrkSerifFontFamily,
    fontFamilyFallback: brrkSerifFontFallback,
  );

  TextStyle heading1Style([String? fontFamily]) => TextStyle(
    fontSize: heading1Size,
    fontWeight: FontWeight.bold,
    color: palette.foreground,
    fontFamily: fontFamily ?? brrkSerifFontFamily,
    fontFamilyFallback: brrkSerifFontFallback,
  );
  TextStyle heading2Style([String? fontFamily]) => TextStyle(
    fontSize: heading2Size,
    fontWeight: FontWeight.bold,
    color: palette.foreground,
    fontFamily: fontFamily ?? brrkSerifFontFamily,
    fontFamilyFallback: brrkSerifFontFallback,
  );
  TextStyle heading3Style([String? fontFamily]) => TextStyle(
    fontSize: heading3Size,
    fontWeight: FontWeight.bold,
    color: palette.foreground,
    fontFamily: fontFamily ?? brrkSerifFontFamily,
    fontFamilyFallback: brrkSerifFontFallback,
  );
  TextStyle paragraphStyle([String? fontFamily]) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.normal,
    height: density.lineHeight,
    letterSpacing: density.letterSpacing,
    color: palette.foreground,
    fontFamily: fontFamily ?? brrkSerifFontFamily,
    fontFamilyFallback: brrkSerifFontFallback,
  );
}

/// Provider for reading appearance state.
class ReadingAppearanceNotifier extends StateNotifier<ReadingAppearance> {
  ReadingAppearanceNotifier() : super(const ReadingAppearance()) {
    _load();
  }

  static const _fontSizeKey = 'reading_font_size';
  static const _densityKey = 'reading_density';
  static const _paletteKey = 'reading_palette';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_fontSizeKey) ?? 16.0;
    final densityStr = prefs.getString(_densityKey);
    final paletteStr = prefs.getString(_paletteKey);
    final density =
        ReadingDensity.values.where((d) => d.name == densityStr).firstOrNull ??
        ReadingDensity.standard;
    final palette =
        ReadingPalette.values.where((p) => p.name == paletteStr).firstOrNull ??
        ReadingPalette.defaultPalette;
    state = ReadingAppearance(
      fontSize: fontSize.clamp(12.0, 32.0),
      density: density,
      palette: palette,
    );
  }

  Future<void> setFontSize(double size) async {
    final clamped = size.clamp(12.0, 32.0);
    state = state.copyWith(fontSize: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, clamped);
  }

  Future<void> setDensity(ReadingDensity density) async {
    state = state.copyWith(density: density);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_densityKey, density.name);
  }

  Future<void> setPalette(ReadingPalette palette) async {
    state = state.copyWith(palette: palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.name);
  }
}

final readingAppearanceProvider =
    StateNotifierProvider<ReadingAppearanceNotifier, ReadingAppearance>(
      (ref) => ReadingAppearanceNotifier(),
    );

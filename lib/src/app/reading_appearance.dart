import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bundled Noto Serif font used as the default app font for Latin text.
const brrkSerifFontFamily = 'NotoSerif';

/// Bundled Japanese Mincho-style Noto Serif font used for Japanese glyphs.
const brrkJapaneseSerifFontFamily = 'NotoSerifJP';

/// Uses Noto Serif for English/Latin text and Noto Serif JP for Japanese text.
const brrkSerifFontFallback = <String>[brrkJapaneseSerifFontFamily];

/// Reader layout mode.
///
/// `natural` is the stable default and the reader's selection model is
/// guaranteed to operate on canonical text.
///
/// `academic` switches body alignment to `TextAlign.justify`. Justify
/// changes word spacing by line; it does not guarantee uniform word
/// spacing. English hyphenation is not yet wired up; when it is added
/// the UI copy and tests must be updated together.
enum ReaderLayoutMode { natural, academic }

/// Density presets for reading content.
enum ReadingDensity {
  compact(1.35, 8, 0.0),
  standard(1.50, 12, 0.0),
  spacious(1.65, 18, 0.0);

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
            onChanged: notifier.previewFontSize,
            onChangeEnd: notifier.persistFontSize,
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

          // Layout mode.
          const Text('Layout'),
          const SizedBox(height: 4),
          Text(
            appearance.layoutMode == ReaderLayoutMode.natural
                ? 'Left-aligned text with consistent word spacing'
                : 'Justified text where word spacing may vary by line',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ReaderLayoutMode>(
            segments: const [
              ButtonSegment(
                value: ReaderLayoutMode.natural,
                label: Text('Natural'),
              ),
              ButtonSegment(
                value: ReaderLayoutMode.academic,
                label: Text('Academic'),
              ),
            ],
            selected: {appearance.layoutMode},
            onSelectionChanged: (s) => notifier.setLayoutMode(s.first),
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
  /// Default font size in sp. The user can adjust within [minFontSize, maxFontSize].
  static const double defaultFontSize = 17.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;

  final double fontSize;
  final ReadingDensity density;
  final ReadingPalette palette;
  final ReaderLayoutMode layoutMode;

  const ReadingAppearance({
    this.fontSize = defaultFontSize,
    this.density = ReadingDensity.standard,
    this.palette = ReadingPalette.defaultPalette,
    this.layoutMode = ReaderLayoutMode.natural,
  });

  ReadingAppearance copyWith({
    double? fontSize,
    ReadingDensity? density,
    ReadingPalette? palette,
    ReaderLayoutMode? layoutMode,
  }) => ReadingAppearance(
    fontSize: fontSize ?? this.fontSize,
    density: density ?? this.density,
    palette: palette ?? this.palette,
    layoutMode: layoutMode ?? this.layoutMode,
  );

  /// Heading sizes scaled from body fontSize.
  double get heading1Size => (fontSize + 8).clamp(12.0, 36.0);
  double get heading2Size => (fontSize + 5).clamp(12.0, 32.0);
  double get heading3Size => (fontSize + 3).clamp(12.0, 28.0);

  /// Body `TextAlign` derived from the reader layout mode.
  ///
  /// `natural` → start; `academic` → justify. Headings, lists, and code
  /// always stay start-aligned and are not affected by this getter.
  TextAlign get bodyTextAlign => switch (layoutMode) {
    ReaderLayoutMode.natural => TextAlign.start,
    ReaderLayoutMode.academic => TextAlign.justify,
  };

  /// TextStyle for body text. Letter spacing is always 0; layout-mode-driven
  /// spacing changes are achieved through `bodyTextAlign` and Flutter's
  /// native justify behavior.
  TextStyle get bodyStyle => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.normal,
    height: density.lineHeight,
    letterSpacing: 0.0,
    wordSpacing: 0.0,
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
    letterSpacing: 0.0,
    wordSpacing: 0.0,
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
  static const _layoutModeKey = 'reading_layout_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize =
        prefs.getDouble(_fontSizeKey) ?? ReadingAppearance.defaultFontSize;
    final densityStr = prefs.getString(_densityKey);
    final paletteStr = prefs.getString(_paletteKey);
    final layoutModeStr = prefs.getString(_layoutModeKey);
    final density =
        ReadingDensity.values.where((d) => d.name == densityStr).firstOrNull ??
        ReadingDensity.standard;
    final palette =
        ReadingPalette.values.where((p) => p.name == paletteStr).firstOrNull ??
        ReadingPalette.defaultPalette;
    final layoutMode =
        ReaderLayoutMode.values
            .where((m) => m.name == layoutModeStr)
            .firstOrNull ??
        ReaderLayoutMode.natural;
    if (!mounted) return;
    state = ReadingAppearance(
      fontSize: fontSize.clamp(
        ReadingAppearance.minFontSize,
        ReadingAppearance.maxFontSize,
      ),
      density: density,
      palette: palette,
      layoutMode: layoutMode,
    );
  }

  double _clampFontSize(double size) =>
      size.clamp(ReadingAppearance.minFontSize, ReadingAppearance.maxFontSize);

  /// Updates the in-memory preview without performing persistence I/O.
  void previewFontSize(double size) {
    final clamped = _clampFontSize(size);
    if (state.fontSize == clamped) return;
    state = state.copyWith(fontSize: clamped);
  }

  /// Persists the final slider value once when the drag completes.
  Future<void> persistFontSize(double size) async {
    final clamped = _clampFontSize(size);
    if (state.fontSize != clamped) {
      state = state.copyWith(fontSize: clamped);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, clamped);
  }

  /// Programmatic update that preserves the existing update-and-save contract.
  Future<void> setFontSize(double size) async {
    previewFontSize(size);
    await persistFontSize(size);
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

  Future<void> setLayoutMode(ReaderLayoutMode mode) async {
    state = state.copyWith(layoutMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_layoutModeKey, mode.name);
  }
}

final readingAppearanceProvider =
    StateNotifierProvider<ReadingAppearanceNotifier, ReadingAppearance>(
      (ref) => ReadingAppearanceNotifier(),
    );

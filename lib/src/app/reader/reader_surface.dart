import 'package:flutter/material.dart';

/// Shared reader surface for the Paper and PDF readers.
///
/// The surface is intentionally small: it owns only the reader's
/// background, centered max width, and adaptive horizontal padding.
/// It does **not** know about OCR, storage, notes, vocabulary, Rust,
/// or page navigation.
///
/// Spec (FEAT-SPEC §6.3):
///   * Phone horizontal margin: 18 dp
///   * Wide-screen (>= 600 dp) horizontal margin: 24 dp
///   * Maximum body width: 640 dp
///   * Placement: centered
class ReaderSurface extends StatelessWidget {
  /// Maximum body width in logical pixels.
  static const double maxBodyWidth = 640.0;

  /// Threshold above which wide-screen padding is used.
  static const double wideScreenBreakpoint = 600.0;

  /// Phone horizontal padding in logical pixels.
  static const double phoneHorizontalPadding = 18.0;

  /// Wide-screen horizontal padding in logical pixels.
  static const double wideScreenHorizontalPadding = 24.0;

  /// Optional background color. When null, the surface is transparent.
  final Color? backgroundColor;

  /// The body to center and constrain.
  final Widget child;

  const ReaderSurface({super.key, required this.child, this.backgroundColor});

  /// Resolves the horizontal padding for the given viewport width.
  static double horizontalPaddingFor(double width) {
    if (width >= wideScreenBreakpoint) return wideScreenHorizontalPadding;
    return phoneHorizontalPadding;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = horizontalPaddingFor(width);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxBodyWidth),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: child,
      ),
    );
    if (backgroundColor == null) {
      return Align(alignment: Alignment.topCenter, child: content);
    }
    return Container(
      color: backgroundColor,
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}

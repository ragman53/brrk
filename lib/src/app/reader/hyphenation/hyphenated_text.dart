// SPDX-License-Identifier: MIT
//
// FEAT-SPEC §8 — production display-to-source mapping.
//
// `HyphenatedText` holds a canonical source string and a display
// string that may contain inserted `U+00AD SOFT HYPHEN` markers.
// It exposes a UTF-16 boundary map so display-side selections can be
// translated back to canonical source selections before Add Note /
// Vocabulary / copy / Rust calls.
//
// Invariants (enforced in `fromInsertionOffsets` / `fromDisplayText`):
// - `displayBoundaryToSourceBoundary.length == displayText.length + 1`
// - first element is `0`
// - last element is `sourceText.length`
// - values are non-decreasing
// - the substring for any mapped selection never contains `U+00AD`
// - both display boundaries surrounding an inserted soft hyphen map
//   to the same canonical source boundary
//
// The legacy Phase B debug-only helper remains in `soft_hyphen_mapping.dart`
// for the debug selection gate. Production reader code must import this
// file instead.

import 'package:flutter/services.dart';

/// Removes every `U+00AD SOFT HYPHEN` code unit.
///
/// String replacement alone is not sufficient when offsets are
/// required; use `HyphenatedText` for that case.
String removeSoftHyphens(String value) => value.replaceAll('\u00AD', '');

/// Production display-to-source mapping for Academic reader layout.
///
/// The mapping is purely a UTF-16 boundary lookup. It does not
/// select line breaks, decide where to insert soft hyphens, or
/// perform any layout. Break opportunity selection is the
/// responsibility of `EmergencyWordBreaker`.
class HyphenatedText {
  /// Canonical source text. Never contains `U+00AD`.
  final String sourceText;

  /// Display text shown to the renderer. May contain `U+00AD`.
  final String displayText;

  /// Map from display UTF-16 boundary → canonical source UTF-16
  /// boundary. Length is `displayText.length + 1`.
  final List<int> displayBoundaryToSourceBoundary;

  const HyphenatedText({
    required this.sourceText,
    required this.displayText,
    required this.displayBoundaryToSourceBoundary,
  });

  /// Builds a mapping from a canonical source string and a list of
  /// source UTF-16 boundary offsets where a soft hyphen should be
  /// inserted.
  ///
  /// Each offset `o` in [insertBeforeSourceBoundary] inserts one
  /// `U+00AD` immediately before source character at index `o`.
  /// Both display boundaries surrounding the inserted soft hyphen map
  /// to source boundary `o`.
  factory HyphenatedText.fromInsertionOffsets(
    String sourceText, {
    required List<int> insertBeforeSourceBoundary,
  }) {
    final insertions = <int>{};
    for (final raw in insertBeforeSourceBoundary) {
      if (raw <= 0 || raw > sourceText.length) continue;
      insertions.add(raw);
    }

    final display = StringBuffer();
    final map = <int>[0];
    for (var i = 0; i < sourceText.length; i++) {
      display.write(sourceText[i]);
      map.add(i + 1);
      if (insertions.contains(i + 1)) {
        display.write('\u00AD');
        map.add(i + 1);
      }
    }
    return HyphenatedText(
      sourceText: sourceText,
      displayText: display.toString(),
      displayBoundaryToSourceBoundary: List<int>.unmodifiable(map),
    );
  }

  /// Builds a mapping from a callback-visible display text containing
  /// already-inserted `U+00AD` markers.
  ///
  /// Canonical source is the display text with every `U+00AD`
  /// removed. The boundary map collapses each `U+00AD` into the
  /// surrounding source boundary.
  factory HyphenatedText.fromDisplayText(String displayText) {
    final source = StringBuffer();
    final map = <int>[0];
    var sourceBoundary = 0;
    for (var i = 0; i < displayText.length; i++) {
      final unit = displayText[i];
      if (unit == '\u00AD') {
        map.add(sourceBoundary);
      } else {
        source.write(unit);
        sourceBoundary += 1;
        map.add(sourceBoundary);
      }
    }
    return HyphenatedText(
      sourceText: source.toString(),
      displayText: displayText,
      displayBoundaryToSourceBoundary: List<int>.unmodifiable(map),
    );
  }

  /// Maps a display UTF-16 boundary to a canonical source UTF-16
  /// boundary, clamping into the valid range.
  int mapDisplayBoundaryToSource(int displayBoundary) {
    if (displayBoundary <= 0) return 0;
    if (displayBoundary >= displayBoundaryToSourceBoundary.length) {
      return sourceText.length;
    }
    return displayBoundaryToSourceBoundary[displayBoundary];
  }

  /// Maps a [TextSelection] in display coordinates to a [TextSelection]
  /// in canonical source coordinates. Reversed selections are
  /// preserved (baseOffset / extentOffset are mapped independently);
  /// invalid/collapsed selections are clamped.
  TextSelection toSourceSelection(TextSelection displaySelection) {
    if (displaySelection.isCollapsed) {
      final mapped = mapDisplayBoundaryToSource(displaySelection.baseOffset);
      return TextSelection.collapsed(offset: mapped);
    }
    final mappedBase = mapDisplayBoundaryToSource(displaySelection.baseOffset);
    final mappedExtent = mapDisplayBoundaryToSource(
      displaySelection.extentOffset,
    );
    return TextSelection(baseOffset: mappedBase, extentOffset: mappedExtent);
  }

  /// Returns the canonical substring for the given display selection.
  /// Guaranteed to contain no `U+00AD`.
  String sourceSubstring(TextSelection displaySelection) {
    final source = toSourceSelection(displaySelection);
    if (source.isCollapsed) return '';
    final start = source.start.clamp(0, sourceText.length);
    final end = source.end.clamp(start, sourceText.length);
    return sourceText.substring(start, end);
  }

  /// Returns `true` if this mapping has no inserted markers.
  bool get isIdentity => sourceText == displayText;
}

/// Builds a [TextEditingValue] from a string containing `U+00AD`
/// soft hyphens so the input is not silently dropped or
/// reinterpreted.
TextEditingValue softHyphenTextEditingValue(String text) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

/// Copies a string to the system clipboard, preserving `U+00AD`
/// characters. Flutter's `Clipboard.setData` already preserves them;
/// this helper exists for clarity at the call site.
Future<void> copyRawToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

// SPDX-License-Identifier: MIT
//
// Phase B soft-hyphen selection gate helper.
//
// THIS IS A SPIKE-ONLY HELPER, NOT PRODUCTION HYPHENATION.
// It is used solely by the debug selection gate screen
// (`lib/src/app/reader/hyphenation/selection_gate_screen.dart`) and its
// unit tests. It must not be integrated into the Paper/PDF readers,
// vocab/notes flows, or Rust/FRB storage in this phase.
//
// See FEAT-SPEC.md §11 for the mandatory selection gate that precedes
// any production hyphenation work.

import 'package:flutter/services.dart';

/// Removes all U+00AD SOFT HYPHEN code units.
///
/// A defensive helper to ensure no soft hyphens leak into canonical
/// substrings or copied output. String replacement alone is not
/// sufficient when offsets are required — see [mapDisplaySelectionToSource].
String removeSoftHyphens(String value) => value.replaceAll('\u00AD', '');

/// Maps a display text selection (which may span inserted U+00AD soft
/// hyphens) to a canonical source selection, and computes the
/// corresponding canonical substring.
///
/// The helper is intentionally minimal: it is a gate, not a feature.
class SoftHyphenMapping {
  /// The original canonical source text, without any soft hyphens.
  final String sourceText;

  /// The display text, which may contain U+00AD soft hyphens inserted
  /// between canonical source characters.
  final String displayText;

  /// For every display boundary index in `[0, displayText.length]`,
  /// stores the corresponding canonical boundary index in sourceText.
  ///
  /// Both boundaries of an inserted soft hyphen map to the same
  /// canonical boundary (i.e. the soft hyphen "sits" on a single
  /// canonical source position).
  ///
  /// Invariants:
  /// - length == displayText.length + 1
  /// - first element is 0
  /// - last element is sourceText.length
  /// - values are non-decreasing
  final List<int> displayBoundaryToSourceBoundary;

  const SoftHyphenMapping({
    required this.sourceText,
    required this.displayText,
    required this.displayBoundaryToSourceBoundary,
  });

  /// Builds a mapping from a source text and a list of source UTF-16
  /// boundary offsets where soft hyphens should be inserted.
  ///
  /// Each offset [o] in [insertBeforeSourceBoundary] means: a U+00AD
  /// will be inserted before source character at index [o], i.e.
  /// between source character [o - 1] and source character [o]. Both
  /// display boundaries surrounding the inserted soft hyphen map to
  /// source boundary [o] so callers can clamp display offsets
  /// spanning a soft hyphen without losing the canonical character.
  factory SoftHyphenMapping.fromInsertionOffsets(
    String sourceText, {
    required List<int> insertBeforeSourceBoundary,
  }) {
    final sorted = [...insertBeforeSourceBoundary]
      ..sort()
      ..removeWhere((o) => o <= 0 || o > sourceText.length);
    final insertions = <int>{...sorted};

    final display = StringBuffer();
    final map = <int>[0];
    for (var i = 0; i < sourceText.length; i++) {
      display.write(sourceText[i]);
      map.add(i + 1);
      if (insertions.contains(i + 1)) {
        display.write('\u00AD');
        // Both surrounding boundaries map to the same source boundary.
        map.add(i + 1);
      }
    }
    return SoftHyphenMapping(
      sourceText: sourceText,
      displayText: display.toString(),
      displayBoundaryToSourceBoundary: List<int>.unmodifiable(map),
    );
  }

  /// Builds a mapping directly from callback-visible display text.
  ///
  /// This is useful for `Markdown(selectable: true)`, whose selection
  /// callback returns the selected block's display text rather than the
  /// full raw Markdown source. The canonical source is simply the display
  /// text with U+00AD removed.
  factory SoftHyphenMapping.fromDisplayText(String displayText) {
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
    return SoftHyphenMapping(
      sourceText: source.toString(),
      displayText: displayText,
      displayBoundaryToSourceBoundary: List<int>.unmodifiable(map),
    );
  }

  /// Maps a display boundary to a canonical source boundary, clamping
  /// into the valid range.
  int mapDisplayBoundaryToSource(int displayBoundary) {
    if (displayBoundary <= 0) return 0;
    if (displayBoundary >= displayBoundaryToSourceBoundary.length) {
      return sourceText.length;
    }
    return displayBoundaryToSourceBoundary[displayBoundary];
  }

  /// Maps a [TextSelection] in display coordinates to a [TextSelection]
  /// in source coordinates, supporting reversed selections and clamping.
  TextSelection toSourceSelection(TextSelection displaySelection) {
    if (displaySelection.isCollapsed) {
      final mapped = mapDisplayBoundaryToSource(displaySelection.baseOffset);
      return TextSelection.collapsed(offset: mapped);
    }
    final start = displaySelection.start;
    final end = displaySelection.end;
    final mappedStart = mapDisplayBoundaryToSource(start);
    final mappedEnd = mapDisplayBoundaryToSource(end);
    if (mappedStart <= mappedEnd) {
      return TextSelection(baseOffset: mappedStart, extentOffset: mappedEnd);
    }
    return TextSelection(baseOffset: mappedEnd, extentOffset: mappedStart);
  }

  /// Returns the canonical substring for the given display selection.
  /// The result is guaranteed to contain no U+00AD.
  String sourceSubstring(TextSelection displaySelection) {
    final source = toSourceSelection(displaySelection);
    if (source.isCollapsed) return '';
    final start = source.start.clamp(0, sourceText.length);
    final end = source.end.clamp(start, sourceText.length);
    return sourceText.substring(start, end);
  }
}

/// Builds a [TextEditingValue] from a string containing U+00AD soft
/// hyphens so the input does not silently drop or reinterpret them.
TextEditingValue softHyphenTextEditingValue(String text) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

/// Copies a string to the system clipboard, preserving U+00AD
/// characters (Flutter's `Clipboard.setData` already preserves them;
/// this helper exists for clarity at the call site).
Future<void> copyRawToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

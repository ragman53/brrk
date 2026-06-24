import 'package:flutter/services.dart';

/// Canonical selection event emitted by the shared reader renderer.
///
/// [sourceStart] and [sourceEnd] are exact UTF-16 code-unit offsets into the
/// original page Markdown when the native planner can prove them. Callers
/// that persist into byte-offset fields (Paper `Note.startOffset/endOffset`
/// are documented byte offsets) must convert these to UTF-8 byte offsets
/// before saving; fallback paths leave them null.
class ReaderSelection {
  const ReaderSelection({
    required this.canonicalContext,
    required this.selection,
    required this.cause,
    this.sourceStart,
    this.sourceEnd,
  });

  /// Canonical selected block/context text. Never contains display-only
  /// soft hyphens.
  final String canonicalContext;

  /// Selection valid within [canonicalContext].
  final TextSelection selection;

  /// Original selection cause forwarded from the underlying selectable widget.
  final SelectionChangedCause? cause;

  /// Exact code-unit offsets into the page's original Markdown source when
  /// known. Null for fallback paths and any path that cannot prove exactness.
  final int? sourceStart;
  final int? sourceEnd;
}

typedef ReaderSelectionChanged = void Function(ReaderSelection? selection);

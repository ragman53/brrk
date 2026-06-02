import 'package:brrk/src/rust/api/models.dart';

/// Pre-save confirmed note data returned by [NoteEditorScreen].
///
/// `NoteEditorScreen` no longer creates a persisted [Note] / [PdfNote]
/// directly. It validates the user input and returns a [NoteDraft]; the
/// caller decides how to persist it.
///
/// This avoids duplicating the note editor UI for Paper vs. PDF and keeps
/// the two storage models separate (anti-spaghetti).
class NoteDraft {
  /// Currently selected surface text (may be empty when the user opens
  /// the editor via the `+ Add note` chip).
  final String selectedText;

  /// 0-based start offset in the displayed reader text. `null` when the
  /// editor was opened without a selection.
  final int? startOffset;

  /// 0-based end offset in the displayed reader text. `null` when the
  /// editor was opened without a selection.
  final int? endOffset;

  /// User-authored note content. Already validated: non-empty, trimmed,
  /// ≤ 10,000 characters, no null bytes.
  final String content;

  /// Tag list. Already validated: ≤ 5 tags, each ≤ 50 chars.
  final List<String> tags;

  const NoteDraft({
    required this.selectedText,
    this.startOffset,
    this.endOffset,
    required this.content,
    required this.tags,
  });
}

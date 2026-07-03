import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/rust/api/models.dart';
import 'package:flutter/material.dart';

class StickyNoteChip extends StatelessWidget {
  final Note note;
  final ReadingAppearance appearance;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const StickyNoteChip({
    super.key,
    required this.note,
    required this.appearance,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(
        note.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: appearance.palette.foreground, fontSize: 12),
      ),
      onPressed: onTap,
      deleteIcon: Icon(Icons.close, size: 16, color: appearance.palette.muted),
      onDeleted: onDelete,
      backgroundColor: Color.alphaBlend(
        appearance.palette.accent.withValues(alpha: 0.18),
        appearance.palette.background,
      ),
      side: BorderSide(color: appearance.palette.accent, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

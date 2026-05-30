import 'package:flutter/material.dart';
import 'package:brrk/src/rust/api/models.dart';
import 'package:uuid/uuid.dart';

/// Dialog/screen to add or edit a note for a page.
/// Returns the saved Note on confirm, null on cancel.
class NoteEditorScreen extends StatefulWidget {
  final String pageId;
  final String? selectedText;
  final int? startOffset;
  final int? endOffset;
  final Note? existingNote;

  const NoteEditorScreen({
    super.key,
    required this.pageId,
    this.selectedText,
    this.startOffset,
    this.endOffset,
    this.existingNote,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool get _isEditing => widget.existingNote != null;

  static const _maxNoteContentLength = 10_000;
  static const _maxTagLength = 50;
  static const _availableTags = [
    'important',
    'question',
    'quote',
    'summary',
    'todo',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingNote;
    if (existing != null) {
      _noteController.text = existing.content;
      _selectedTags.addAll(existing.tags.take(5));
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < 5) {
        _selectedTags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _selectedTags.contains(tag)) return;
    if (_selectedTags.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A note can have up to 5 tags')),
      );
      return;
    }
    if (tag.runes.length > _maxTagLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag must be 50 characters or fewer')),
      );
      return;
    }
    if (tag.contains('/') || tag.contains('\\') || tag.contains('\u0000')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag contains unsafe characters')),
      );
      return;
    }
    setState(() {
      _selectedTags.add(tag);
      _tagController.clear();
    });
  }

  void _save() {
    final content = _noteController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note cannot be empty')));
      return;
    }
    if (content.runes.length > _maxNoteContentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note must be 10,000 characters or fewer'),
        ),
      );
      return;
    }

    final existing = widget.existingNote;
    final now = DateTime.now().toUtc().toIso8601String();

    final note = Note(
      id: existing?.id ?? const Uuid().v4(),
      pageId: widget.pageId,
      selectedText: widget.selectedText ?? existing?.selectedText ?? '',
      startOffset: widget.startOffset ?? existing?.startOffset,
      endOffset: widget.endOffset ?? existing?.endOffset,
      content: content,
      tags: _selectedTags.toList(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final selectedText =
        widget.selectedText ?? widget.existingNote?.selectedText;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 72,
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedText != null && selectedText.isNotEmpty) ...[
              Text(
                'Selected text',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  border: Border.all(color: const Color(0xFFFFC107)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  selectedText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('Your note *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 6,
              maxLength: _maxNoteContentLength,
              decoration: const InputDecoration(
                hintText: 'Type your note here…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Tags (max 5)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: {..._availableTags, ..._selectedTags}.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (_) => _toggleTag(tag),
                  backgroundColor: const Color(0xFFE3F2FD),
                  selectedColor: const Color(0xFFBBDEFB),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF1976D2)
                        : Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF1976D2)
                        : Colors.grey.shade300,
                  ),
                  checkmarkColor: const Color(0xFF1976D2),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    maxLength: _maxTagLength,
                    decoration: const InputDecoration(
                      labelText: 'Create tag',
                      hintText: 'e.g. chapter-1',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addCustomTag(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addCustomTag,
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

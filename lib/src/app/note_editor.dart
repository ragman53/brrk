import 'package:flutter/material.dart';
import 'package:brrk/src/app/note_draft.dart';

/// Dialog/screen to add or edit a note for a page.
///
/// Returns a [NoteDraft] on confirm (which the caller persists as `Note`
/// for paper or `PdfNote` for PDF). Returns `null` on cancel.
///
/// The editor owns all note validation: content, tag count, and tag
/// length limits. Callers do not re-validate.
class NoteEditorScreen extends StatefulWidget {
  /// Free-form title shown in the AppBar.
  final String title;

  /// Selected surface text (paper or PDF block text).
  final String? selectedText;

  /// Optional offsets in the displayed reader text.
  final int? startOffset;
  final int? endOffset;

  /// Existing note content (edit mode).
  final String? initialContent;

  /// Existing tags (edit mode).
  final List<String> initialTags;

  const NoteEditorScreen({
    super.key,
    this.title = 'Add Note',
    this.selectedText,
    this.startOffset,
    this.endOffset,
    this.initialContent,
    this.initialTags = const [],
  });

  static const int maxNoteContentLength = 10_000;
  static const int maxTagLength = 50;
  static const int maxTags = 5;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();
  final Set<String> _selectedTags = {};

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
    if (widget.initialContent != null) {
      _noteController.text = widget.initialContent!;
    }
    _selectedTags.addAll(
      widget.initialTags.take(NoteEditorScreen.maxTags),
    );
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
      } else if (_selectedTags.length < NoteEditorScreen.maxTags) {
        _selectedTags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _selectedTags.contains(tag)) return;
    if (_selectedTags.length >= NoteEditorScreen.maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A note can have up to 5 tags')),
      );
      return;
    }
    if (tag.runes.length > NoteEditorScreen.maxTagLength) {
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
    if (content.runes.length > NoteEditorScreen.maxNoteContentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note must be 10,000 characters or fewer'),
        ),
      );
      return;
    }

    final draft = NoteDraft(
      selectedText: widget.selectedText ?? '',
      startOffset: widget.startOffset,
      endOffset: widget.endOffset,
      content: content,
      tags: _selectedTags.toList(),
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = widget.selectedText;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
              maxLength: NoteEditorScreen.maxNoteContentLength,
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
                    maxLength: NoteEditorScreen.maxTagLength,
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

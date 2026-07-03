import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/app/note_draft.dart';
import 'package:brrk/src/app/note_editor.dart';
import 'package:brrk/src/app/paper_book/paper_book_actions.dart';
import 'package:brrk/src/app/paper_book/paper_book_page_view.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/rust/api/models.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PaperBookPagesBody extends StatefulWidget {
  final PaperBook book;
  final ReadingAppearance readingAppearance;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final Future<void> Function(PaperPage page, int index) onDeletePage;
  final Future<void> Function(PaperPage page, int index) onEditPageLabel;
  final Future<bool> Function({
    required PaperPage page,
    required String selectedText,
    required String pageContext,
    required int? startOffset,
    required int? endOffset,
  })
  onLookUp;

  const PaperBookPagesBody({
    super.key,
    required this.book,
    required this.readingAppearance,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.onDeletePage,
    required this.onEditPageLabel,
    required this.onLookUp,
  });

  @override
  State<PaperBookPagesBody> createState() => _PaperBookPagesBodyState();
}

class _PaperBookPagesBodyState extends State<PaperBookPagesBody> {
  late int _selectedIndex;
  final Map<String, List<Note>> _pageNotes = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex.clamp(
      0,
      widget.book.pages.length - 1,
    );
    for (final page in widget.book.pages) {
      _pageNotes[page.id] = List.from(page.notes);
    }
  }

  @override
  void didUpdateWidget(covariant PaperBookPagesBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
    if (oldWidget.book.pages.length != widget.book.pages.length) {
      final clamped = _selectedIndex.clamp(
        0,
        widget.book.pages.isEmpty ? 0 : widget.book.pages.length - 1,
      );
      if (clamped != _selectedIndex) {
        _selectedIndex = clamped;
        widget.onSelectedIndexChanged(clamped);
      }
    }
  }

  String _chipLabel(PaperPage page, int index) =>
      page.pageLabel != null ? 'p. ${page.pageLabel}' : 'Capture ${index + 1}';

  Future<void> _openNoteEditor(
    PaperPage page, {
    Note? existingNote,
    String? selectedText,
    int? startOffset,
    int? endOffset,
  }) async {
    final draft = await Navigator.of(context).push<NoteDraft>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          title: existingNote != null ? 'Edit Note' : 'Add Note',
          selectedText: selectedText ?? existingNote?.selectedText,
          startOffset: startOffset ?? existingNote?.startOffset,
          endOffset: endOffset ?? existingNote?.endOffset,
          initialContent: existingNote?.content,
          initialTags: existingNote?.tags ?? const [],
        ),
      ),
    );
    if (draft == null) return;

    // Build the persisted Note. When editing, preserve id, createdAt,
    // pageId, and the original selection text/offsets even if the
    // editor was opened without a current selection.
    final now = DateTime.now().toUtc().toIso8601String();
    final note = Note(
      id: existingNote?.id ?? const Uuid().v4(),
      pageId: page.id,
      selectedText: draft.selectedText,
      startOffset: draft.startOffset,
      endOffset: draft.endOffset,
      content: draft.content,
      tags: draft.tags,
      createdAt: existingNote?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await storage.saveNote(pageId: page.id, note: note);
      setState(() {
        final notes = List<Note>.from(_pageNotes[page.id] ?? const []);
        notes.removeWhere((n) => n.id == note.id);
        notes.add(note);
        _pageNotes[page.id] = notes;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note saved')));
      }
    } catch (e) {
      if (mounted) showOcrError(context, OcrUserError.storage());
    }
  }

  Future<void> _deleteNote(Note note, String pageId) async {
    try {
      await storage.deleteNote(pageId: pageId, noteId: note.id);
      setState(() {
        _pageNotes[pageId] = (_pageNotes[pageId] ?? const [])
            .where((n) => n.id != note.id)
            .toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note deleted')));
      }
    } catch (e) {
      if (mounted) showOcrError(context, OcrUserError.storage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.book.pages;
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onLongPress: () => showPaperPageActions(
                    context,
                    page: pages[index],
                    index: index,
                    onEditPageLabel: widget.onEditPageLabel,
                    onDeletePage: widget.onDeletePage,
                  ),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_chipLabel(pages[index], index)),
                        if (pages[index].manualMarkdown != null &&
                            pages[index].manualMarkdown!.trim().isNotEmpty) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 12),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedIndex = index);
                      widget.onSelectedIndexChanged(index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: PaperBookPageView(
            page: pages[_selectedIndex],
            notes: _pageNotes[pages[_selectedIndex].id] ?? const [],
            readingAppearance: widget.readingAppearance,
            onAddNote: ({selectedText, startOffset, endOffset}) =>
                _openNoteEditor(
                  pages[_selectedIndex],
                  selectedText: selectedText,
                  startOffset: startOffset,
                  endOffset: endOffset,
                ),
            onEditNote: (note) =>
                _openNoteEditor(pages[_selectedIndex], existingNote: note),
            onDeleteNote: (note) => _deleteNote(note, pages[_selectedIndex].id),
            onLookUp:
                ({
                  required selectedText,
                  required pageContext,
                  required startOffset,
                  required endOffset,
                }) => widget.onLookUp(
                  page: pages[_selectedIndex],
                  selectedText: selectedText,
                  pageContext: pageContext,
                  startOffset: startOffset,
                  endOffset: endOffset,
                ),
          ),
        ),
      ],
    );
  }
}

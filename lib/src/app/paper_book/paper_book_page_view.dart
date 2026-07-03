import 'package:brrk/src/app/paper_book/paper_book_notes.dart';
import 'package:brrk/src/app/reader/brrk_reader_page.dart';
import 'package:brrk/src/app/reader/reader_selection.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_lookup_service.dart';
import 'package:brrk/src/rust/api/models.dart';
import 'package:flutter/material.dart';

class PaperBookPageView extends StatefulWidget {
  final PaperPage page;
  final List<Note> notes;
  final ReadingAppearance readingAppearance;
  final Future<void> Function({
    String? selectedText,
    int? startOffset,
    int? endOffset,
  })
  onAddNote;
  final void Function(Note note) onEditNote;
  final void Function(Note note) onDeleteNote;
  final Future<bool> Function({
    required String selectedText,
    required String pageContext,
    required int? startOffset,
    required int? endOffset,
  })
  onLookUp;

  const PaperBookPageView({
    super.key,
    required this.page,
    required this.notes,
    required this.readingAppearance,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onLookUp,
  });

  @override
  State<PaperBookPageView> createState() => _PaperBookPageViewState();
}

class _PaperBookPageViewState extends State<PaperBookPageView> {
  String? _selectedText;
  String? _selectedCanonical;
  int? _selectionStart;
  int? _selectionEnd;

  // Lookup candidate derived from the raw selection. Used only for the
  // `Look up` button so long-press over-selection can be recovered
  // without disturbing the raw selection (which feeds `Add Note`).
  String? _lookupText;
  int? _lookupStart;
  int? _lookupEnd;

  String get _displayedText =>
      widget.page.manualMarkdown != null &&
          widget.page.manualMarkdown!.trim().isNotEmpty
      ? widget.page.manualMarkdown!
      : widget.page.markdown;

  @override
  void didUpdateWidget(covariant PaperBookPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      _selectedText = null;
      _selectedCanonical = null;
      _selectionStart = null;
      _selectionEnd = null;
      _lookupText = null;
      _lookupStart = null;
      _lookupEnd = null;
    }
  }

  void _handleReaderSelection(ReaderSelection? event) {
    if (event == null) {
      setState(() {
        _selectedText = null;
        _selectedCanonical = null;
        _selectionStart = null;
        _selectionEnd = null;
        _lookupText = null;
        _lookupStart = null;
        _lookupEnd = null;
      });
      return;
    }
    final contextText = event.canonicalContext;
    final start = event.selection.start.clamp(0, contextText.length);
    final end = event.selection.end.clamp(0, contextText.length);
    if (end <= start) return;
    final selected = contextText.substring(start, end);
    final candidate = vocabularyCandidateFromSelection(
      context: contextText,
      selection: TextSelection(baseOffset: start, extentOffset: end),
      cause: event.cause,
    );
    // FEAT-SPEC §11.1: Paper note offsets are stored as UTF-8 byte offsets
    // (rust/src/api/models.rs:245-250). Convert exact native page-source
    // code-unit offsets now; fall back to null when exactness is not proven.
    final pageSource = _displayedText;
    final noteStart = event.sourceStart == null
        ? null
        : utf8ByteOffsetForCodeUnitOffset(pageSource, event.sourceStart);
    final noteEnd = event.sourceEnd == null
        ? null
        : utf8ByteOffsetForCodeUnitOffset(pageSource, event.sourceEnd);
    setState(() {
      _selectionStart = noteStart;
      _selectionEnd = noteEnd;
      _selectedText = selected.trim();
      _selectedCanonical = contextText;
      _lookupText = candidate?.text;
      _lookupStart = candidate?.start;
      _lookupEnd = candidate?.end;
    });
  }

  Future<void> _addSelectedNote() async {
    await widget.onAddNote(
      selectedText: _selectedText,
      startOffset: _selectionStart,
      endOffset: _selectionEnd,
    );
    if (!mounted) return;
    setState(() {
      _selectedText = null;
      _selectedCanonical = null;
      _selectionStart = null;
      _selectionEnd = null;
      _lookupText = null;
      _lookupStart = null;
      _lookupEnd = null;
    });
  }

  Future<void> _onLookUpPressed() async {
    final lookupText = _lookupText;
    if (lookupText == null || lookupText.isEmpty) return;
    // Always pass the canonical (no-marker) page context to vocabulary
    // lookup. Display text containing U+00AD must never reach Rust or the
    // Mistral Chat request.
    final started = await widget.onLookUp(
      selectedText: lookupText,
      pageContext: _selectedCanonical ?? _displayedText,
      startOffset: _lookupStart,
      endOffset: _lookupEnd,
    );
    if (!mounted || !started) return;
    setState(() {
      _selectedText = null;
      _selectedCanonical = null;
      _selectionStart = null;
      _selectionEnd = null;
      _lookupText = null;
      _lookupStart = null;
      _lookupEnd = null;
    });
  }

  Widget _buildSelectedStrip(ReadingAppearance appearance) {
    return Material(
      color: Color.alphaBlend(
        appearance.palette.accent.withValues(alpha: 0.16),
        appearance.palette.background,
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.sticky_note_2, color: Color(0xFFFFA000)),
        title: Text(
          _selectedText!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: (_lookupText != null && _lookupText!.isNotEmpty)
                  ? _onLookUpPressed
                  : null,
              icon: const Icon(Icons.menu_book_outlined, size: 16),
              label: const Text('Look up'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _addSelectedNote,
              child: const Text('Add Note'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.notes.where((n) => n.content.isNotEmpty).toList();
    final appearance = widget.readingAppearance;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Color.alphaBlend(
            appearance.palette.accent.withValues(alpha: 0.08),
            appearance.palette.background,
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...visible.map(
                (n) => StickyNoteChip(
                  note: n,
                  appearance: appearance,
                  onTap: () => widget.onEditNote(n),
                  onDelete: () => widget.onDeleteNote(n),
                ),
              ),
              ActionChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text('Add note'),
                  ],
                ),
                backgroundColor: Color.alphaBlend(
                  appearance.palette.accent.withValues(alpha: 0.12),
                  appearance.palette.background,
                ),
                onPressed: () => widget.onAddNote(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: appearance.palette.background,
                  child: BrrkReaderPage(
                    markdown: _displayedText,
                    appearance: appearance,
                    onSelectionChanged: _handleReaderSelection,
                  ),
                ),
              ),
              if (_selectedText != null && _selectedText!.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _buildSelectedStrip(appearance),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

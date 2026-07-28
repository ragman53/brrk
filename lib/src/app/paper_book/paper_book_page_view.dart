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

  @visibleForTesting
  final VoidCallback? onReaderBuild;

  const PaperBookPageView({
    super.key,
    required this.page,
    required this.notes,
    required this.readingAppearance,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onLookUp,
    this.onReaderBuild,
  });

  @override
  State<PaperBookPageView> createState() => _PaperBookPageViewState();
}

class _PaperBookPageViewState extends State<PaperBookPageView> {
  final ValueNotifier<_PaperReaderActionState?> _actionState =
      ValueNotifier<_PaperReaderActionState?>(null);
  late Widget _reader;

  String get _displayedText =>
      widget.page.manualMarkdown != null &&
          widget.page.manualMarkdown!.trim().isNotEmpty
      ? widget.page.manualMarkdown!
      : widget.page.markdown;

  Widget _buildReader() => BrrkReaderPage(
    markdown: _displayedText,
    appearance: widget.readingAppearance,
    onSelectionChanged: _handleReaderSelection,
    onBuild: widget.onReaderBuild,
  );

  bool _appearanceChanged(PaperBookPageView oldWidget) {
    final old = oldWidget.readingAppearance;
    final current = widget.readingAppearance;
    return old.fontSize != current.fontSize ||
        old.density != current.density ||
        old.palette != current.palette ||
        old.layoutMode != current.layoutMode;
  }

  String _displayedTextFor(PaperBookPageView value) =>
      value.page.manualMarkdown != null &&
          value.page.manualMarkdown!.trim().isNotEmpty
      ? value.page.manualMarkdown!
      : value.page.markdown;

  void _clearActionState() {
    if (_actionState.value != null) {
      _actionState.value = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _reader = _buildReader();
  }

  @override
  void didUpdateWidget(covariant PaperBookPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final textChanged = _displayedTextFor(oldWidget) != _displayedText;
    if (oldWidget.page.id != widget.page.id || textChanged) {
      _clearActionState();
    }
    if (oldWidget.page.id != widget.page.id ||
        textChanged ||
        _appearanceChanged(oldWidget) ||
        oldWidget.onReaderBuild != widget.onReaderBuild) {
      _reader = _buildReader();
    }
  }

  @override
  void dispose() {
    _actionState.dispose();
    super.dispose();
  }

  void _handleReaderSelection(ReaderSelection? event) {
    if (event == null) {
      _clearActionState();
      return;
    }
    final contextText = event.canonicalContext;
    final start = event.selection.start.clamp(0, contextText.length);
    final end = event.selection.end.clamp(0, contextText.length);
    if (end <= start) return;
    final candidate = vocabularyCandidateFromSelection(
      context: contextText,
      selection: TextSelection(baseOffset: start, extentOffset: end),
      cause: event.cause,
    );
    // FEAT-SPEC §11.1: Paper note offsets are stored as UTF-8 byte offsets.
    final pageSource = _displayedText;
    final next = _PaperReaderActionState(
      selectedText: contextText.substring(start, end).trim(),
      canonicalContext: contextText,
      noteStart: event.sourceStart == null
          ? null
          : utf8ByteOffsetForCodeUnitOffset(pageSource, event.sourceStart),
      noteEnd: event.sourceEnd == null
          ? null
          : utf8ByteOffsetForCodeUnitOffset(pageSource, event.sourceEnd),
      lookupText: candidate?.text,
      lookupStart: candidate?.start,
      lookupEnd: candidate?.end,
    );
    if (_actionState.value != next) {
      _actionState.value = next;
    }
  }

  Future<void> _addSelectedNote() async {
    final action = _actionState.value;
    if (action == null) return;
    await widget.onAddNote(
      selectedText: action.selectedText,
      startOffset: action.noteStart,
      endOffset: action.noteEnd,
    );
    if (!mounted) return;
    _clearActionState();
  }

  Future<void> _onLookUpPressed() async {
    final action = _actionState.value;
    final lookupText = action?.lookupText;
    if (action == null || lookupText == null || lookupText.isEmpty) return;
    // Always pass the canonical (no-marker) page context to vocabulary
    // lookup. Display text containing U+00AD must never reach Rust or the
    // Mistral Chat request.
    final started = await widget.onLookUp(
      selectedText: lookupText,
      pageContext: action.canonicalContext,
      startOffset: action.lookupStart,
      endOffset: action.lookupEnd,
    );
    if (!mounted || !started) return;
    _clearActionState();
  }

  Widget _buildSelectedStrip(
    ReadingAppearance appearance,
    _PaperReaderActionState action,
  ) {
    return Material(
      color: Color.alphaBlend(
        appearance.palette.accent.withValues(alpha: 0.16),
        appearance.palette.background,
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.sticky_note_2, color: Color(0xFFFFA000)),
        title: Text(
          action.selectedText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed:
                  action.lookupText != null && action.lookupText!.isNotEmpty
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
                  child: _reader,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: ValueListenableBuilder<_PaperReaderActionState?>(
                  valueListenable: _actionState,
                  builder: (context, action, child) {
                    if (action == null || action.selectedText.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildSelectedStrip(appearance, action);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaperReaderActionState {
  const _PaperReaderActionState({
    required this.selectedText,
    required this.canonicalContext,
    required this.noteStart,
    required this.noteEnd,
    required this.lookupText,
    required this.lookupStart,
    required this.lookupEnd,
  });

  final String selectedText;
  final String canonicalContext;
  final int? noteStart;
  final int? noteEnd;
  final String? lookupText;
  final int? lookupStart;
  final int? lookupEnd;

  @override
  bool operator ==(Object other) {
    return other is _PaperReaderActionState &&
        other.selectedText == selectedText &&
        other.canonicalContext == canonicalContext &&
        other.noteStart == noteStart &&
        other.noteEnd == noteEnd &&
        other.lookupText == lookupText &&
        other.lookupStart == lookupStart &&
        other.lookupEnd == lookupEnd;
  }

  @override
  int get hashCode => Object.hash(
    selectedText,
    canonicalContext,
    noteStart,
    noteEnd,
    lookupText,
    lookupStart,
    lookupEnd,
  );
}

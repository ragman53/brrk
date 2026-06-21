import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/app/home_providers.dart';
import 'package:brrk/src/app/markdown_editor.dart';
import 'package:brrk/src/app/note_draft.dart';
import 'package:brrk/src/app/note_editor.dart';
import 'package:brrk/src/app/vocab_disclosure.dart';
import 'package:brrk/src/app/vocabulary/definition_sheet.dart';
import 'package:brrk/src/app/vocabulary/vocab_provider.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_lookup_service.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_screen.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:brrk/src/rust/api/models.dart';

/// PDF markdown viewer with page navigation and last-read-page tracking.
/// Per SPEC.md §3.6: page markers, TOC, 2s debounce last-read-page save.
class PdfViewerScreen extends ConsumerStatefulWidget {
  final PdfDoc doc;

  /// Optional test seam: if provided, replaces the FRB markdown load
  /// (`getPdfMarkdown`). If null, FRB is used.
  final Future<String> Function(String docId)? getPdfMarkdownOverride;

  /// Optional test seam: if provided, replaces the FRB manual markdown
  /// load (`getPdfManualMarkdown`). If null, FRB is used.
  final Future<PdfManualMarkdownData> Function(String docId)?
  getPdfManualMarkdownOverride;

  const PdfViewerScreen({
    super.key,
    required this.doc,
    this.getPdfMarkdownOverride,
    this.getPdfManualMarkdownOverride,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  String _fullMarkdown = '';
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  late int _totalPages;
  PdfManualMarkdownData? _manual;

  // F17: PDF notes for the current page.
  List<PdfNote> _pageNotes = [];
  String? _selectedText;
  String? _selectedContext;
  int? _selectionStart;
  int? _selectionEnd;

  // Lookup candidate derived from the raw selection. Used only for the
  // `Look up` button so long-press over-selection can be recovered
  // without disturbing the raw selection (which feeds `Add Note`).
  String? _lookupText;
  int? _lookupStart;
  int? _lookupEnd;

  // Per-page content sections (split by <!-- page: N --> markers).
  List<String> _pageSections = [];
  // TOC entries: {level: int, text: String}.
  List<_TocEntry> _tocEntries = [];
  // Debounce timer for saving last read page.
  Timer? _saveDebounce;

  // Regex to find 1-based page markers in markdown.
  static final _pageMarkerRegex = RegExp(r'<!-- page:\s*(\d+)\s*-->');
  // Regex to find markdown headings.
  static final _headingRegex = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true);

  @override
  void initState() {
    super.initState();
    _totalPages = widget.doc.pageCount <= 0 ? 1 : widget.doc.pageCount;
    _loadMarkdown();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _saveLastReadPageImmediate();
    super.dispose();
  }

  Future<void> _loadMarkdown() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = widget.getPdfMarkdownOverride != null
          ? await widget.getPdfMarkdownOverride!(widget.doc.id)
          : await storage.getPdfMarkdown(docId: widget.doc.id);
      final manual = widget.getPdfManualMarkdownOverride != null
          ? await widget.getPdfManualMarkdownOverride!(widget.doc.id)
          : await storage.getPdfManualMarkdown(docId: widget.doc.id);
      final sections = _splitByPageMarkers(content);
      final toc = _extractToc(content);

      setState(() {
        _fullMarkdown = content;
        _pageSections = sections;
        _tocEntries = toc;
        _manual = manual;
        _loading = false;
        _currentPage = widget.doc.lastReadPageIndex.clamp(0, _totalPages - 1);
      });
      await _loadPdfNotes();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Splits markdown by 1-based `<!-- page: N -->` markers into sections.
  /// Returns a list where index N = content of page (N+1).
  List<String> _splitByPageMarkers(String markdown) {
    // Collect page marker positions.
    final matches = _pageMarkerRegex.allMatches(markdown).toList();
    final sections = <String>[];

    if (matches.isEmpty) {
      // No markers — treat as single-page.
      return [markdown.trim()];
    }

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].end;
      final end = i + 1 < matches.length
          ? matches[i + 1].start
          : markdown.length;
      sections.add(markdown.substring(start, end).trim());
    }
    return sections;
  }

  /// Extracts TOC entries (level + text + page index) from markdown headings.
  List<_TocEntry> _extractToc(String markdown) {
    final pageMarkers = _pageMarkerRegex.allMatches(markdown).toList();
    final entries = <_TocEntry>[];

    for (final match in _headingRegex.allMatches(markdown)) {
      final level = match.group(1)!.length;
      final text = match.group(2)!.trim();
      if (text.isEmpty) continue;

      entries.add(
        _TocEntry(
          level: level,
          text: text,
          pageIndex: _pageIndexForOffset(match.start, pageMarkers),
        ),
      );
    }
    return entries;
  }

  /// Returns the 0-based page index for a markdown byte offset using page markers.
  int _pageIndexForOffset(int offset, List<RegExpMatch> pageMarkers) {
    var pageIndex = 0;
    for (final marker in pageMarkers) {
      if (marker.start > offset) break;
      final pageNumber = int.tryParse(marker.group(1) ?? '');
      if (pageNumber != null && pageNumber > 0) {
        pageIndex = (pageNumber - 1).clamp(0, _totalPages - 1);
      }
    }
    return pageIndex;
  }

  /// Schedules a debounced save of the current page (2s per SPEC.md).
  void _scheduleLastReadPageSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), () {
      _saveLastReadPageImmediate();
    });
  }

  Future<void> _openMarkdownEditor() async {
    final displayed = _currentPageContent;
    final hasOverride = _manual?.pages[_currentPage.toString()] != null;
    final result = await Navigator.of(context).push<MarkdownEditorResult>(
      MaterialPageRoute<MarkdownEditorResult>(
        builder: (_) => MarkdownEditorScreen(
          title: 'Edit page Markdown',
          subtitle: 'PDF page ${_currentPage + 1} of $_totalPages',
          initialText: displayed,
          hasManualEdit: hasOverride,
          onSave: _savePdfManual,
          onReset: _clearPdfManual,
        ),
      ),
    );
    if (result == null) return;
    // Reload manual data so the reader reflects the new state.
    try {
      final fresh = await storage.getPdfManualMarkdown(docId: widget.doc.id);
      if (!mounted) return;
      setState(() {
        _manual = fresh;
      });
    } catch (_) {
      // Ignore; UI will re-fetch on next page change.
    }
  }

  Future<bool> _savePdfManual(String newText) async {
    try {
      await storage.savePdfPageManualMarkdown(
        docId: widget.doc.id,
        pageIndex: _currentPage,
        manualMarkdown: newText,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save edit.')));
      }
      return false;
    }
  }

  Future<bool> _clearPdfManual() async {
    try {
      await storage.savePdfPageManualMarkdown(
        docId: widget.doc.id,
        pageIndex: _currentPage,
        manualMarkdown: null,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to reset.')));
      }
      return false;
    }
  }

  // F17: PDF notes helpers ----------------------------------------------

  Future<void> _loadPdfNotes() async {
    try {
      final notes = await storage.getPdfNotes(
        docId: widget.doc.id,
        pageIndex: _currentPage,
      );
      if (!mounted) return;
      setState(() {
        _pageNotes = notes;
      });
    } catch (_) {
      // Silent: notes are best-effort; reader still works.
    }
  }

  Future<void> _openNoteEditorForCurrent({PdfNote? existing}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final draft = await Navigator.of(context).push<NoteDraft>(
      MaterialPageRoute(
        builder: (ctx) => NoteEditorScreen(
          title: existing != null ? 'Edit Note' : 'Add Note',
          selectedText: existing?.selectedText ?? _selectedText,
          startOffset: existing == null ? _selectionStart : null,
          endOffset: existing == null ? _selectionEnd : null,
          initialContent: existing?.content,
          initialTags: existing?.tags ?? const [],
        ),
      ),
    );
    if (draft == null) return;
    final note = existing == null
        ? PdfNote(
            id: _newNoteId(),
            docId: widget.doc.id,
            pageIndex: _currentPage,
            selectedText: draft.selectedText,
            selectedSentence: (_selectedContext ?? draft.selectedText).trim(),
            content: draft.content,
            tags: draft.tags,
            createdAt: now,
            updatedAt: now,
          )
        : PdfNote(
            id: existing.id,
            docId: existing.docId,
            pageIndex: existing.pageIndex,
            selectedText: existing.selectedText,
            selectedSentence: existing.selectedSentence,
            content: draft.content,
            tags: draft.tags,
            createdAt: existing.createdAt,
            updatedAt: now,
          );
    try {
      await storage.savePdfNote(note: note);
      if (!mounted) return;
      setState(() {
        _selectedText = null;
        _selectedContext = null;
        _selectionStart = null;
        _selectionEnd = null;
        _lookupText = null;
        _lookupStart = null;
        _lookupEnd = null;
      });
      await _loadPdfNotes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
    }
  }

  Future<void> _deletePdfNote(PdfNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This will permanently delete this note.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await storage.deletePdfNote(docId: note.docId, noteId: note.id);
      if (!mounted) return;
      await _loadPdfNotes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete note: $e')));
    }
  }

  String _newNoteId() {
    // Stable monotonic id; not security-sensitive.
    return 'pn-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  Future<void> _onPdfLookUpPressed() async {
    final lookupText = _lookupText;
    if (lookupText == null || lookupText.isEmpty) return;
    final acknowledged = await showVocabDisclosureIfNeeded(context, ref);
    if (!acknowledged || !mounted) return;

    final lookup = performLookup(
      ref: ref,
      selectedText: lookupText,
      pageContext: _selectedContext ?? _currentPageContent,
      startOffset: _lookupStart,
      endOffset: _lookupEnd,
      source: VocabSource.pdf(docId: widget.doc.id, pageIndex: _currentPage),
    );

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DefinitionSheet(
        selectedText: lookupText,
        onRemoveWord: () => ref.read(vocabProvider.notifier).refresh(),
        onOpenVocabulary: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VocabularyScreen(
                initialFilter: VocabSourceFilter.pdfDoc(docId: widget.doc.id),
              ),
            ),
          );
        },
      ),
    );
    setState(() {
      _selectedText = null;
      _selectedContext = null;
      _selectionStart = null;
      _selectionEnd = null;
      _lookupText = null;
      _lookupStart = null;
      _lookupEnd = null;
    });
    await lookup;
  }

  Future<void> _saveLastReadPageImmediate() async {
    final updatedDoc = PdfDoc(
      id: widget.doc.id,
      title: widget.doc.title,
      originalFileName: widget.doc.originalFileName,
      pdfPath: widget.doc.pdfPath,
      markdownPath: widget.doc.markdownPath,
      ocrHash: widget.doc.ocrHash,
      pageCount: widget.doc.pageCount,
      lastReadPageIndex: _currentPage,
      tags: widget.doc.tags,
      createdAt: widget.doc.createdAt,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    try {
      await storage.savePdfDoc(doc: updatedDoc);
    } catch (_) {
      // Silent — best effort.
    }
  }

  void _jumpToPage(int pageIndex) {
    setState(() {
      _currentPage = pageIndex.clamp(0, _totalPages - 1);
      _pageNotes = [];
      _selectedText = null;
      _selectedContext = null;
      _selectionStart = null;
      _selectionEnd = null;
      _lookupText = null;
      _lookupStart = null;
      _lookupEnd = null;
    });
    _scheduleLastReadPageSave();
    _loadPdfNotes();
  }

  String get _currentPageContent {
    final override = _manual?.pages[_currentPage.toString()];
    if (override != null && override.trim().isNotEmpty) {
      return override;
    }
    if (_pageSections.isEmpty) return _fullMarkdown;
    if (_currentPage < _pageSections.length) return _pageSections[_currentPage];
    return _pageSections.isNotEmpty ? _pageSections.last : _fullMarkdown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doc.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Vocabulary for this document',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VocabularyScreen(
                  initialFilter: VocabSourceFilter.pdfDoc(docId: widget.doc.id),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit page Markdown',
            onPressed: _loading ? null : _openMarkdownEditor,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Reading appearance',
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const ReadingAppearanceControls(),
            ),
          ),
          if (_tocEntries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'Table of Contents',
              onPressed: () => _showTocSheet(context),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDeletePdf(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete PDF', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_manual?.pages[_currentPage.toString()] != null &&
                      _manual!.pages[_currentPage.toString()]!
                          .trim()
                          .isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.edit, size: 14),
                    ),
                  Text(
                    'Page ${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _totalPages > 1
          ? _PageNavigationBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPrevious: () => _jumpToPage(_currentPage - 1),
              onNext: () => _jumpToPage(_currentPage + 1),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load markdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _loadMarkdown,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final appearance = ref.watch(readingAppearanceProvider);
    return Column(
      children: [
        _buildNoteChipRow(appearance),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: appearance.palette.background,
                  child: Markdown(
                    data: _currentPageContent,
                    selectable: true,
                    onSelectionChanged: (text, sel, cause) {
                      final str = text ?? '';
                      if (sel.isValid && !sel.isCollapsed) {
                        final start = sel.start.clamp(0, str.length);
                        final end = sel.end.clamp(0, str.length);
                        final candidate = vocabularyCandidateFromSelection(
                          context: str,
                          selection: sel,
                          cause: cause,
                        );
                        setState(() {
                          _selectedText = str.substring(start, end).trim();
                          _selectedContext = str;
                          _selectionStart = start;
                          _selectionEnd = end;
                          _lookupText = candidate?.text;
                          _lookupStart = candidate?.start;
                          _lookupEnd = candidate?.end;
                        });
                      } else {
                        if (_selectedText != null) {
                          setState(() {
                            _selectedText = null;
                            _selectedContext = null;
                            _selectionStart = null;
                            _selectionEnd = null;
                            _lookupText = null;
                            _lookupStart = null;
                            _lookupEnd = null;
                          });
                        }
                      }
                    },
                    styleSheet: MarkdownStyleSheet(
                      h1: appearance.heading1Style(),
                      h2: appearance.heading2Style(),
                      h3: appearance.heading3Style(),
                      p: appearance.paragraphStyle(),
                      blockSpacing: appearance.density.paragraphSpacing,
                      horizontalRuleDecoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: appearance.palette.muted),
                        ),
                      ),
                    ),
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

  Widget _buildNoteChipRow(ReadingAppearance appearance) {
    if (_pageNotes.isEmpty) {
      return SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add note'),
              onPressed: _selectedText == null || _selectedText!.isEmpty
                  ? () => _openNoteEditorForCurrent()
                  : null,
            ),
          ),
        ),
      );
    }
    return Container(
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
          ..._pageNotes.map(
            (n) => InputChip(
              label: Text(
                n.content.isEmpty ? '(empty)' : n.content.split('\n').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () => _openNoteEditorForCurrent(existing: n),
              onDeleted: () => _deletePdfNote(n),
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Add note'),
            onPressed: _selectedText == null || _selectedText!.isEmpty
                ? () => _openNoteEditorForCurrent()
                : null,
          ),
        ],
      ),
    );
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
                  ? _onPdfLookUpPressed
                  : null,
              icon: const Icon(Icons.menu_book_outlined, size: 16),
              label: const Text('Look up'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _openNoteEditorForCurrent(),
              child: const Text('Add Note'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePdf(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete PDF?'),
        content: const Text(
          'This will permanently delete this PDF, its extracted text, and OCR cache entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await storage.deletePdfDoc(docId: widget.doc.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF deleted')));
      ref.read(pdfDocsProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      final msg = switch (e) {
        StorageError_NotInitialized() =>
          'Result could not be saved. Check available storage and retry.',
        StorageError_NotFound() => 'PDF not found.',
        StorageError_IoError() =>
          'Failed to delete PDF. Check available storage.',
        StorageError_JsonError() =>
          'Failed to delete PDF. Check available storage.',
        StorageError_ValidationError() =>
          'Failed to delete PDF. Check available storage.',
        _ => 'Failed to delete PDF.',
      };
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showTocSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Table of Contents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _tocEntries.length,
                itemBuilder: (context, index) {
                  final entry = _tocEntries[index];
                  return ListTile(
                    contentPadding: EdgeInsets.only(
                      left: 12.0 + (entry.level - 1) * 16.0,
                      right: 12,
                    ),
                    dense: true,
                    title: Text(
                      entry.text,
                      style: TextStyle(
                        fontWeight: entry.level <= 2
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: entry.level <= 2 ? 15 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _jumpToPage(entry.pageIndex);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Table of contents entry parsed from markdown headings.
class _TocEntry {
  final int level;
  final String text;
  final int pageIndex;

  const _TocEntry({
    required this.level,
    required this.text,
    required this.pageIndex,
  });
}

/// Bottom navigation bar for page prev/next.
class _PageNavigationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PageNavigationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
          ),
          Text(
            '${currentPage + 1} / $totalPages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}

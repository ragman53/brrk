import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:brrk/src/app/api_key.dart';
import 'package:brrk/src/app/camera_screen.dart';
import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/app/home_providers.dart';
import 'package:brrk/src/app/note_draft.dart';
import 'package:brrk/src/app/vocab_disclosure.dart';
import 'package:brrk/src/app/vocabulary/definition_sheet.dart';
import 'package:brrk/src/app/vocabulary/vocab_provider.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_lookup_service.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_screen.dart';
import 'package:brrk/src/app/note_editor.dart';
import 'package:brrk/src/app/markdown_editor.dart';
import 'package:brrk/src/app/ocr_disclosure.dart';
import 'package:brrk/src/app/paper_book/paper_book_export.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/app/reader/brrk_reader_page.dart';
import 'package:brrk/src/app/reader/reader_selection.dart';
import 'package:brrk/src/app/settings_screen.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:brrk/src/rust/api/models.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays a paper book: list of pages, each showing OCR text + notes.
class PaperBookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  final Future<PaperBooksData> Function()? getBooks;

  const PaperBookDetailScreen({super.key, required this.bookId, this.getBooks});

  @override
  ConsumerState<PaperBookDetailScreen> createState() =>
      _PaperBookDetailScreenState();
}

class _PaperBookDetailScreenState extends ConsumerState<PaperBookDetailScreen> {
  PaperBook? _book;
  bool _loading = false;
  String? _loadError;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = widget.getBooks != null
          ? await widget.getBooks!()
          : await storage.getPaperBooks();
      final found = data.books.where((b) => b.id == widget.bookId).firstOrNull;
      if (found != null) {
        setState(() {
          _book = found;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _loadError = 'Book not found';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(paperBooksProvider.notifier).refresh();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_book?.title ?? 'Book')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_loading || _book == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_book?.title ?? 'Book')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pages = _book!.pages;
    final readingAppearance = ref.watch(readingAppearanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_book!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Vocabulary for this book',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VocabularyScreen(
                    initialFilter: VocabSourceFilter.paperBook(
                      bookId: _book!.id,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit page Markdown',
            onPressed: pages.isEmpty
                ? null
                : () => _openMarkdownEditor(
                    pages[_selectedIndex],
                    _selectedIndex,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Reading appearance',
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const ReadingAppearanceControls(),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename Book')),
              const PopupMenuItem(value: 'export', child: Text('Export JSON')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Book', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: pages.isEmpty
          ? _EmptyBookBody(onAddPage: _openCamera)
          : _PagesBody(
              book: _book!,
              readingAppearance: readingAppearance,
              selectedIndex: _selectedIndex,
              onSelectedIndexChanged: (i) => setState(() => _selectedIndex = i),
              onAddPage: _openCamera,
              onDeletePage: _deletePage,
              onEditPageLabel: _editPageLabel,
              onEditPageMarkdown: _openMarkdownEditor,
              onLookUp: _lookUpPaperSelection,
            ),
      floatingActionButton: pages.isNotEmpty
          ? FloatingActionButton(
              onPressed: _openCamera,
              tooltip: 'Add Page',
              child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'rename':
        _renameBook();
        break;
      case 'export':
        _exportJson();
        break;
      case 'delete':
        _deleteBook();
        break;
    }
  }

  Future<void> _renameBook() async {
    final controller = TextEditingController(text: _book!.title);
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Book'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == _book!.title) {
      controller.dispose();
      return;
    }
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final renamed = PaperBook(
        id: _book!.id,
        title: trimmed,
        createdAt: _book!.createdAt,
        updatedAt: now,
        pages: _book!.pages,
      );
      await storage.savePaperBook(book: renamed);
      if (!mounted) return;
      setState(() {
        _book = renamed;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book renamed')));
    } catch (e) {
      if (mounted) showOcrError(context, OcrUserError.storage());
    }
    controller.dispose();
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book?'),
        content: const Text(
          'This will permanently delete this book, all pages, images, and notes. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await storage.deletePaperBook(bookId: _book!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book deleted')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showOcrError(context, OcrUserError.storage());
    }
  }

  void _exportJson() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExportJsonSheet(book: _book!),
    );
  }

  Future<void> _openCamera() async {
    final apiKeyState = ref.read(apiKeyProvider);
    if (apiKeyState is! ApiKeySet) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('API Key Required'),
          content: const Text(
            'Adding a page requires a Mistral API key. Please set one in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                launchUrl(Uri.parse('https://console.mistral.ai/'));
              },
              child: const Text('Get API Key'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }
    if (!mounted) return;
    // Check OCR disclosure before first Paper OCR use.
    final acknowledged = await showOcrDisclosureIfNeeded(context, ref);
    if (!acknowledged || !mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CameraScreen(bookId: _book!.id)));
    _load();
  }

  Future<void> _deletePage(PaperPage page, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Page?'),
        content: const Text(
          'This will permanently delete this page, its image, and notes. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await storage.deletePaperPage(
        bookId: _book!.id,
        pageId: page.id,
        updatedAt: now,
      );
      if (!mounted) return;
      _load();
    } catch (e) {
      if (mounted) showOcrError(context, OcrUserError.storage());
    }
  }

  Future<void> _editPageLabel(PaperPage page, int index) async {
    final controller = TextEditingController(text: page.pageLabel ?? '');
    final label = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Page Label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'e.g. 42 or xii',
          ),
          maxLength: 32,
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    final trimmed = label?.trim() ?? '';
    final newLabel = trimmed.isEmpty ? null : trimmed;
    if (newLabel == page.pageLabel) {
      controller.dispose();
      return;
    }
    final newPage = PaperPage(
      id: page.id,
      imagePath: page.imagePath,
      pageLabel: newLabel,
      ocrHash: page.ocrHash,
      markdown: page.markdown,
      // Preserve any existing manual edit; label changes must not erase it.
      manualMarkdown: page.manualMarkdown,
      notes: page.notes,
    );
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await storage.upsertPaperPage(
        bookId: _book!.id,
        page: newPage,
        updatedAt: now,
      );
      if (!mounted) return;
      _load();
    } catch (e) {
      if (mounted) showOcrError(context, OcrUserError.storage());
    }
    controller.dispose();
  }

  Future<void> _openMarkdownEditor(PaperPage page, int index) async {
    final displayed =
        page.manualMarkdown != null && page.manualMarkdown!.trim().isNotEmpty
        ? page.manualMarkdown!
        : page.markdown;
    final result = await Navigator.of(context).push<MarkdownEditorResult>(
      MaterialPageRoute<MarkdownEditorResult>(
        builder: (_) => MarkdownEditorScreen(
          title: 'Edit page Markdown',
          subtitle: 'Paper page',
          initialText: displayed,
          hasManualEdit:
              page.manualMarkdown != null &&
              page.manualMarkdown!.trim().isNotEmpty,
          onSave: (t) => _saveManualMarkdown(page, t),
          onReset: () => _clearManualMarkdown(page),
        ),
      ),
    );
    if (result == null) return;
    await _load();
  }

  Future<bool> _saveManualMarkdown(PaperPage page, String newText) async {
    try {
      await storage.savePaperPageManualMarkdown(
        bookId: _book!.id,
        pageId: page.id,
        manualMarkdown: newText,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
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

  Future<bool> _clearManualMarkdown(PaperPage page) async {
    try {
      await storage.savePaperPageManualMarkdown(
        bookId: _book!.id,
        pageId: page.id,
        manualMarkdown: null,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
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

  Future<bool> _lookUpPaperSelection({
    required PaperPage page,
    required String selectedText,
    required String pageContext,
    required int? startOffset,
    required int? endOffset,
  }) async {
    final normalized = selectedText.trim();
    if (!isValidVocabularySelection(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select one word or short Japanese term.'),
        ),
      );
      return false;
    }
    final acknowledged = await showVocabDisclosureIfNeeded(context, ref);
    if (!acknowledged || !mounted || _book == null) return false;

    final lookup = performLookup(
      ref: ref,
      selectedText: normalized,
      pageContext: pageContext,
      startOffset: startOffset,
      endOffset: endOffset,
      source: VocabSource.paper(bookId: _book!.id, pageId: page.id),
    );

    if (!mounted) return true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DefinitionSheet(
        selectedText: normalized,
        onRemoveWord: () => ref.read(vocabProvider.notifier).refresh(),
        onOpenVocabulary: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VocabularyScreen(
                initialFilter: VocabSourceFilter.paperBook(bookId: _book!.id),
              ),
            ),
          );
        },
      ),
    );
    await lookup;
    return true;
  }
}

// ─── Empty book body ─────────────────────────────────────────────────────────

class _EmptyBookBody extends StatelessWidget {
  final VoidCallback onAddPage;
  const _EmptyBookBody({required this.onAddPage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No pages yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Capture pages to add them to this book.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddPage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Page'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pages body ───────────────────────────────────────────────────────────────

class _PagesBody extends StatefulWidget {
  final PaperBook book;
  final ReadingAppearance readingAppearance;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final VoidCallback onAddPage;
  final Future<void> Function(PaperPage page, int index) onDeletePage;
  final Future<void> Function(PaperPage page, int index) onEditPageLabel;
  final Future<void> Function(PaperPage page, int index) onEditPageMarkdown;
  final Future<bool> Function({
    required PaperPage page,
    required String selectedText,
    required String pageContext,
    required int? startOffset,
    required int? endOffset,
  })
  onLookUp;

  const _PagesBody({
    required this.book,
    required this.readingAppearance,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.onAddPage,
    required this.onDeletePage,
    required this.onEditPageLabel,
    required this.onEditPageMarkdown,
    required this.onLookUp,
  });

  @override
  State<_PagesBody> createState() => _PagesBodyState();
}

class _PagesBodyState extends State<_PagesBody> {
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
  void didUpdateWidget(covariant _PagesBody oldWidget) {
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

  void _showPageActions(BuildContext context, PaperPage page, int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Edit Page Label'),
              onTap: () {
                Navigator.pop(context);
                widget.onEditPageLabel(page, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Page',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDeletePage(page, index);
              },
            ),
          ],
        ),
      ),
    );
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
                  onLongPress: () =>
                      _showPageActions(context, pages[index], index),
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
          child: _PageView(
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

// ─── Page view ────────────────────────────────────────────────────────────────

class _PageView extends StatefulWidget {
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

  const _PageView({
    required this.page,
    required this.notes,
    required this.readingAppearance,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onLookUp,
  });

  @override
  State<_PageView> createState() => _PageViewState();
}

class _PageViewState extends State<_PageView> {
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
  void didUpdateWidget(covariant _PageView oldWidget) {
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
                (n) => _StickyNoteChip(
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

// ─── Sticky note chip ────────────────────────────────────────────────────────

class _StickyNoteChip extends StatelessWidget {
  final Note note;
  final ReadingAppearance appearance;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StickyNoteChip({
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

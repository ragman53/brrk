import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brrk/src/app/api_key.dart';
import 'package:brrk/src/app/camera_screen.dart';
import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/app/home_providers.dart';
import 'package:brrk/src/app/vocab_disclosure.dart';
import 'package:brrk/src/app/vocabulary/definition_sheet.dart';
import 'package:brrk/src/app/vocabulary/vocab_provider.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_lookup_service.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_screen.dart';
import 'package:brrk/src/app/markdown_editor.dart';
import 'package:brrk/src/app/ocr_disclosure.dart';
import 'package:brrk/src/app/paper_book/paper_book_dialogs.dart';
import 'package:brrk/src/app/paper_book/paper_book_empty_body.dart';
import 'package:brrk/src/app/paper_book/paper_book_export.dart';
import 'package:brrk/src/app/paper_book/paper_book_pages_body.dart';
import 'package:brrk/src/app/reading_appearance.dart';
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
          ? EmptyBookBody(onAddPage: _openCamera)
          : PaperBookPagesBody(
              book: _book!,
              readingAppearance: readingAppearance,
              selectedIndex: _selectedIndex,
              onSelectedIndexChanged: (i) => setState(() => _selectedIndex = i),
              onDeletePage: _deletePage,
              onEditPageLabel: _editPageLabel,
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
    final title = await showRenameBookDialog(
      context,
      initialTitle: _book!.title,
    );
    if (!mounted) return;
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == _book!.title) return;
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
  }

  Future<void> _deleteBook() async {
    final confirmed = await confirmDeleteBook(context);
    if (!confirmed || !mounted) return;
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
    final confirmed = await confirmDeletePage(context);
    if (!confirmed || !mounted) return;
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
    final label = await showEditPageLabelDialog(
      context,
      initialLabel: page.pageLabel,
    );
    if (!mounted) return;
    final trimmed = label?.trim() ?? '';
    final newLabel = trimmed.isEmpty ? null : trimmed;
    if (newLabel == page.pageLabel) return;
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

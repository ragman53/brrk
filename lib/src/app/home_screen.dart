import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brrk/src/app/api_key.dart';
import 'package:brrk/src/app/home_providers.dart';
import 'package:brrk/src/app/ocr_disclosure.dart';
import 'package:brrk/src/app/pdf_service.dart';
import 'package:brrk/src/app/pdf_viewer_screen.dart';
import 'package:brrk/src/app/settings_screen.dart';
import 'package:brrk/src/app/paper_book_detail_screen.dart';
import 'package:brrk/src/app/vocabulary/vocabulary_screen.dart';
import 'package:brrk/src/rust/api/models.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Home screen with Paper / PDF segmented control and list views.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyState = ref.watch(apiKeyProvider);
    final hasKey = apiKeyState is ApiKeySet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brrk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_tabController.index == 0) {
                ref.read(paperBooksProvider.notifier).refresh();
              } else {
                ref.read(pdfDocsProvider.notifier).refresh();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Vocabulary',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VocabularyScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Paper'),
            Tab(text: 'PDF'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PaperListView(onNewBook: () => _showNewBookDialog(context, ref)),
          _PdfListView(
            hasApiKey: hasKey,
            onAddPdf: () => _handleAddPdf(context, ref),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showNewBookDialog(context, ref),
              tooltip: 'New Book',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () => _handleAddPdf(context, ref),
              tooltip: 'Add PDF',
              child: const Icon(Icons.add),
            ),
    );
  }

  /// P0-4: handles PDF FAB tap with API-key check and OCR disclosure.
  Future<void> _handleAddPdf(BuildContext context, WidgetRef ref) async {
    if (ref.read(apiKeyProvider) is! ApiKeySet) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('API Key Required'),
          content: const Text('Adding a PDF requires a Mistral API key.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                launchUrl(Uri.parse('https://console.mistral.ai/'));
              },
              child: const Text('Get API Key'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      );
      if (go != true) return;
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }
    if (!ref.read(ocrDisclosureAcknowledgedProvider)) {
      final acknowledged = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Data sent to Mistral OCR'),
          content: const Text(
            'Brrk sends the selected PDF or captured page image '
            'directly to Mistral OCR using your credential. '
            'Brrk does not operate its own server for this MVP.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('I understand'),
            ),
          ],
        ),
      );
      if (acknowledged != true) return;
      await persistOcrDisclosureAcknowledgement(ref);
    }
    if (!context.mounted) return;
    startPdfOcr(context, ref);
  }

  Future<void> _showNewBookDialog(BuildContext context, WidgetRef ref) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const _NewBookDialog(),
    );
    if (title == null || !context.mounted) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final book = PaperBook(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
      pages: const [],
    );
    await storage.savePaperBook(book: book);
    ref.read(paperBooksProvider.notifier).refresh();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaperBookDetailScreen(bookId: book.id)),
    );
  }
}

/// Dialog for creating a new paper book — title only.
class _NewBookDialog extends StatefulWidget {
  const _NewBookDialog();

  @override
  State<_NewBookDialog> createState() => _NewBookDialogState();
}

class _NewBookDialogState extends State<_NewBookDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    final title = trimmed.isEmpty
        ? 'Book ${DateTime.now().toString().substring(0, 16)}'
        : trimmed;
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Book'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'e.g. My Notebook',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

// ─── Paper list ──────────────────────────────────────────────────────────────

class _PaperListView extends ConsumerWidget {
  final VoidCallback onNewBook;

  const _PaperListView({required this.onNewBook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paperBooksProvider);

    return switch (state) {
      PaperBooksLoading() => const Center(child: CircularProgressIndicator()),

      PaperBooksError(:final message) => _ErrorState(
        message: 'Failed to load paper books',
        detail: message,
        onRetry: () => ref.read(paperBooksProvider.notifier).refresh(),
      ),

      PaperBooksLoaded(:final data) =>
        data.books.isEmpty
            ? _PaperEmptyState(onNewBook: onNewBook)
            : _PaperListContent(books: data.books),
    };
  }
}

class _PaperEmptyState extends StatelessWidget {
  final VoidCallback onNewBook;

  const _PaperEmptyState({required this.onNewBook});

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
            Text(
              'No paper books yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a paper book and add pages to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onNewBook,
              icon: const Icon(Icons.add),
              label: const Text('New Book'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperListContent extends StatelessWidget {
  final List<PaperBook> books;

  const _PaperListContent({required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.book),
            title: Text(book.title),
            subtitle: Text('${book.pages.length} page(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaperBookDetailScreen(bookId: book.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── PDF list ───────────────────────────────────────────────────────────────

class _PdfListView extends ConsumerWidget {
  final bool hasApiKey;
  final VoidCallback onAddPdf;

  const _PdfListView({required this.hasApiKey, required this.onAddPdf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfDocsProvider);

    return switch (state) {
      PdfDocsLoading() => const Center(child: CircularProgressIndicator()),

      PdfDocsError(:final message) => _ErrorState(
        message: 'Failed to load PDFs',
        detail: message,
        onRetry: () => ref.read(pdfDocsProvider.notifier).refresh(),
      ),

      PdfDocsLoaded(:final data) =>
        data.docs.isEmpty
            ? _PdfEmptyState(onAddPdf: onAddPdf)
            : _PdfListContent(docs: data.docs),
    };
  }
}

// B4: receives a callback from _HomeScreenState so disclosure runs
// through _handleAddPdf, not directly to startPdfOcr.
class _PdfEmptyState extends StatelessWidget {
  final VoidCallback onAddPdf;

  const _PdfEmptyState({required this.onAddPdf});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No PDFs yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Select a PDF file to extract its text via OCR.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddPdf,
              icon: const Icon(Icons.add),
              label: const Text('Add PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfListContent extends ConsumerWidget {
  final List<PdfDoc> docs;

  const _PdfListContent({required this.docs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(doc.title),
            subtitle: Text('${doc.pageCount} page(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PdfViewerScreen(doc: doc)),
              );
            },
            onLongPress: () => _confirmDeletePdf(context, ref, doc),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletePdf(
    BuildContext context,
    WidgetRef ref,
    PdfDoc doc,
  ) async {
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
      await storage.deletePdfDoc(docId: doc.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF deleted')));
      ref.read(pdfDocsProvider.notifier).refresh();
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
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

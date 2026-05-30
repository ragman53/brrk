import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brrk/src/rust/api/storage.dart';
import 'package:brrk/src/rust/api/models.dart';

/// Paper books data state wrapper.
sealed class PaperBooksState {
  const PaperBooksState();
}

class PaperBooksLoading extends PaperBooksState {
  const PaperBooksLoading();
}

class PaperBooksLoaded extends PaperBooksState {
  final PaperBooksData data;
  const PaperBooksLoaded(this.data);
}

class PaperBooksError extends PaperBooksState {
  final String message;
  const PaperBooksError(this.message);
}

/// Notifier that loads paper books from Rust storage.
class PaperBooksNotifier extends StateNotifier<PaperBooksState> {
  PaperBooksNotifier() : super(const PaperBooksLoading()) {
    load();
  }

  Future<void> load() async {
    state = const PaperBooksLoading();
    try {
      final data = await getPaperBooks();
      state = PaperBooksLoaded(data);
    } catch (e) {
      state = PaperBooksError(e.toString());
    }
  }

  Future<void> refresh() => load();
}

/// Provider for paper books state.
final paperBooksProvider =
    StateNotifierProvider<PaperBooksNotifier, PaperBooksState>(
  (ref) => PaperBooksNotifier(),
);

/// PDF documents data state wrapper.
sealed class PdfDocsState {
  const PdfDocsState();
}

class PdfDocsLoading extends PdfDocsState {
  const PdfDocsLoading();
}

class PdfDocsLoaded extends PdfDocsState {
  final PdfDocsData data;
  const PdfDocsLoaded(this.data);
}

class PdfDocsError extends PdfDocsState {
  final String message;
  const PdfDocsError(this.message);
}

/// Notifier that loads PDF documents from Rust storage.
class PdfDocsNotifier extends StateNotifier<PdfDocsState> {
  PdfDocsNotifier() : super(const PdfDocsLoading()) {
    load();
  }

  Future<void> load() async {
    state = const PdfDocsLoading();
    try {
      final data = await getPdfDocs();
      state = PdfDocsLoaded(data);
    } catch (e) {
      state = PdfDocsError(e.toString());
    }
  }

  Future<void> refresh() => load();
}

/// Provider for PDF docs state.
final pdfDocsProvider =
    StateNotifierProvider<PdfDocsNotifier, PdfDocsState>(
  (ref) => PdfDocsNotifier(),
);
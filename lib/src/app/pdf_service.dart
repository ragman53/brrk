import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:brrk/src/app/api_key.dart';
import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/app/home_providers.dart';
import 'package:brrk/src/app/settings_screen.dart';
import 'package:brrk/src/app/pdf_viewer_screen.dart';
import 'package:brrk/src/rust/api/ocr.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:brrk/src/rust/api/models.dart';

const _maxPdfSizeBytes = 50 * 1024 * 1024; // 50MB

void _navigateToSettings(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
}

/// Best-effort cleanup of PDF file and markdown after a failed import.
/// P0-5: prevents untracked PDF files from accumulating on failure.
Future<void> _cleanupIncompletePdf(String docId) async {
  final appDir = await getApplicationDocumentsDirectory();
  final pdfFile = File('${appDir.path}/pdfs/$docId.pdf');
  final mdFile = File('${appDir.path}/markdowns/$docId.md');
  try {
    await pdfFile.delete();
  } catch (_) {}
  try {
    await mdFile.delete();
  } catch (_) {}
}

Future<void> startPdfOcr(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: false,
  );

  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  final sourcePath = file.path;
  if (sourcePath == null) {
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    showOcrError(
      context,
      const OcrUserError(message: 'Could not access the selected file.'),
    );
    return;
  }

  final sourceFile = File(sourcePath);
  final sizeBytes = await sourceFile.length();
  if (sizeBytes > _maxPdfSizeBytes) {
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    showOcrError(
      context,
      const OcrUserError(message: 'PDF must be 50MB or smaller.'),
    );
    return;
  }

  const uuid = Uuid();
  final docId = uuid.v4();
  final appDir = await getApplicationDocumentsDirectory();
  final pdfsDir = Directory('${appDir.path}/pdfs');
  if (!await pdfsDir.exists()) await pdfsDir.create(recursive: true);
  await sourceFile.copy('${pdfsDir.path}/$docId.pdf');

  if (!context.mounted) {
    // P0-5: clean up copied PDF since we never processed it
    _cleanupIncompletePdf(docId);
    return;
  }

  // B2: _processCopiedPdf returns true on success, false on any failure.
  // On failure, clean up the copied PDF so incomplete imports don't accumulate.
  final succeeded = await _processCopiedPdf(
    context: context,
    ref: ref,
    docId: docId,
    fileName: file.name,
  );
  if (!succeeded) {
    _cleanupIncompletePdf(docId);
  }
}

// Returns true on full success; false on any failure path.
Future<bool> _processCopiedPdf({
  required BuildContext context,
  required WidgetRef ref,
  required String docId,
  required String fileName,
}) async {
  if (!context.mounted) return false;
  _showLoading(context, 'Processing PDF…');

  String apiKey;
  try {
    apiKey = await ref.read(apiKeyProvider.notifier).getRawKey();
  } catch (e) {
    if (!context.mounted) return false;
    // ignore: use_build_context_synchronously
    _hideLoading(context);
    // ignore: use_build_context_synchronously
    showOcrError(
      context,
      exceptionToUser(
        e,
        onSettings: () => _navigateToSettings(context),
        onRetry: () => _processCopiedPdf(
          context: context,
          ref: ref,
          docId: docId,
          fileName: fileName,
        ),
      ),
    );
    return false;
  }

  OcrResult ocrResult;
  try {
    ocrResult = await processPdf(
      docId: docId,
      fileName: fileName,
      apiKey: apiKey,
      forceRefresh: false,
    );
  } on OcrError catch (e) {
    if (!context.mounted) return false;
    // ignore: use_build_context_synchronously
    _hideLoading(context);
    // ignore: use_build_context_synchronously
    showOcrError(
      context,
      ocrErrorToUser(
        e,
        () => _navigateToSettings(context),
        onRetry: () => _processCopiedPdf(
          context: context,
          ref: ref,
          docId: docId,
          fileName: fileName,
        ),
      ),
    );
    return false;
  } catch (e) {
    if (!context.mounted) return false;
    // ignore: use_build_context_synchronously
    _hideLoading(context);
    // ignore: use_build_context_synchronously
    showOcrError(
      context,
      exceptionToUser(
        e,
        onSettings: () => _navigateToSettings(context),
        onRetry: () => _processCopiedPdf(
          context: context,
          ref: ref,
          docId: docId,
          fileName: fileName,
        ),
      ),
    );
    return false;
  }

  final now = DateTime.now().toUtc().toIso8601String();
  final pdfDoc = PdfDoc(
    id: docId,
    title: fileName,
    originalFileName: fileName,
    pdfPath: 'pdfs/$docId.pdf',
    markdownPath: 'markdowns/$docId.md',
    ocrHash: ocrResult.sourceHash,
    pageCount: ocrResult.pages.length,
    lastReadPageIndex: 0,
    tags: const [],
    createdAt: now,
    updatedAt: now,
  );

  try {
    await storage.savePdfDoc(doc: pdfDoc);
  } catch (e) {
    // P1-1: use fixed message — do not show raw exception detail in release UI
    if (!context.mounted) return false;
    // ignore: use_build_context_synchronously
    _hideLoading(context);
    // ignore: use_build_context_synchronously
    showOcrError(
      context,
      const OcrUserError(
        message:
            'PDF metadata could not be saved. Check available storage and try again.',
      ),
    );
    return false;
  }

  if (!context.mounted) return false;
  // ignore: use_build_context_synchronously
  _hideLoading(context);
  // P1-8: refresh PDF list so the new PDF appears without manual refresh
  ref.read(pdfDocsProvider.notifier).refresh();
  if (!context.mounted) return false;
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => PdfViewerScreen(doc: pdfDoc)));
  return true; // success
}

void _showLoading(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Text(message),
        ],
      ),
      duration: const Duration(minutes: 5),
    ),
  );
}

void _hideLoading(BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
}

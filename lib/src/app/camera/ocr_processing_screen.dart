import 'dart:convert';

import 'package:brrk/src/app/api_key.dart';
import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/app/settings_screen.dart';
import 'package:brrk/src/rust/api/models.dart';
import 'package:brrk/src/rust/api/ocr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action requested after OCR processing.
enum OcrProcessingAction { save, cancel, adjustCrop, retake }

/// Outcome/action from OCR processing.
class OcrProcessingResult {
  final OcrProcessingAction type;
  final OcrResult? result;
  final String? label;

  const OcrProcessingResult(this.type, {this.result, this.label});
}

/// Shows OCR processing with optional page label entry.
/// Returns an action for save/cancel/adjust-crop/retake.
class OcrProcessingScreen extends ConsumerStatefulWidget {
  final String bookId;
  final List<int> imageBytes;
  final String? initialLabel;

  const OcrProcessingScreen({
    super.key,
    required this.bookId,
    required this.imageBytes,
    this.initialLabel,
  });

  @override
  ConsumerState<OcrProcessingScreen> createState() =>
      _OcrProcessingScreenState();
}

class _OcrProcessingScreenState extends ConsumerState<OcrProcessingScreen> {
  final _labelController = TextEditingController();
  OcrResult? _result;
  String? _error;
  bool _processing = false;
  bool _done = false;

  void _onSettings() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  String? get _currentLabel {
    final rawLabel = _labelController.text.trim();
    return rawLabel.isEmpty ? null : rawLabel;
  }

  @override
  void initState() {
    super.initState();
    _labelController.text = widget.initialLabel ?? '';
    _runOcr();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final apiKey = await ref.read(apiKeyProvider.notifier).getRawKey();
      final base64Data = base64Encode(widget.imageBytes);
      final result = await processImage(
        base64Data: base64Data,
        fileName: 'page.jpg',
        apiKey: apiKey,
        forceRefresh: false,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _processing = false;
          _done = true;
        });
      }
    } on OcrError catch (e) {
      if (mounted) {
        setState(() {
          _error = ocrErrorToUser(e, _onSettings, onRetry: _runOcr).message;
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final userErr = exceptionToUser(
          e,
          onSettings: _onSettings,
          onRetry: () {},
        );
        setState(() {
          _error = userErr.message;
          _processing = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_processing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cancel OCR?'),
          content: const Text(
            'The Mistral request may still finish and count toward your usage. '
            'Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return confirm ?? false;
    }

    if (_done) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Discard page?'),
          content: const Text(
            'OCR has completed, but this page is not saved yet. Discard it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return confirm ?? false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) {
          Navigator.of(context).pop(
            OcrProcessingResult(
              OcrProcessingAction.cancel,
              label: _currentLabel,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Processing'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && context.mounted) {
                Navigator.of(context).pop(
                  OcrProcessingResult(
                    OcrProcessingAction.cancel,
                    label: _currentLabel,
                  ),
                );
              }
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_processing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Extracting text…',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Page Label (optional)',
                  hintText: 'e.g. 42 or xii',
                ),
                maxLength: 32,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'This page was not saved.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _runOcr,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry OCR'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  OcrProcessingResult(
                    OcrProcessingAction.adjustCrop,
                    label: _currentLabel,
                  ),
                ),
                icon: const Icon(Icons.crop),
                label: const Text('Adjust crop'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  OcrProcessingResult(
                    OcrProcessingAction.retake,
                    label: _currentLabel,
                  ),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Retake'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(
                  OcrProcessingResult(
                    OcrProcessingAction.cancel,
                    label: _currentLabel,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }

    if (_done) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'OCR complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Page Label (optional)',
                  hintText: 'e.g. 42 or xii',
                ),
                maxLength: 32,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _savePage,
                child: const Text('Save Page'),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  void _savePage() {
    Navigator.of(context).pop(
      OcrProcessingResult(
        OcrProcessingAction.save,
        result: _result!,
        label: _currentLabel,
      ),
    );
  }
}

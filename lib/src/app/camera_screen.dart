import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:brrk/src/app/camera/capture_preview_screen.dart';
import 'package:brrk/src/app/camera/crop_screen.dart';
import 'package:brrk/src/app/camera/ocr_processing_screen.dart';
import 'package:brrk/src/app/camera_service.dart';
import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/app/settings_screen.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:brrk/src/rust/api/models.dart';

/// Screen that captures a page and adds it to an existing book.
class CameraScreen extends ConsumerStatefulWidget {
  final String bookId;

  const CameraScreen({super.key, required this.bookId});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _initialized = false;
  String? _error;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final granted = await _cameraService.requestPermission();
    if (!granted) {
      setState(() {
        _permissionDenied = true;
      });
      return;
    }
    try {
      await _cameraService.initialize();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  /// Two-phase capture:
  /// 1. Capture → resize in-memory → preview (shows normalized = what OCR sends)
  /// 2. Use → release camera → OCR → on success commit to disk
  Future<void> _captureAndPreview() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final xfile = await _cameraService.captureImage();
      if (!mounted) return;

      // Phase 1: normalize the raw capture; preview and OCR both use the same bytes.
      final tempFile = File(xfile.path);
      final rawBytes = await tempFile.readAsBytes();
      try {
        await tempFile.delete();
      } catch (_) {}
      if (!mounted) return;
      List<int> currentBytes = await resizeImageBytes(rawBytes);

      final previewResult = await navigator.push<List<int>?>(
        MaterialPageRoute(
          builder: (_) => CapturePreviewScreen(imageBytes: currentBytes),
        ),
      );
      if (!mounted) return;
      if (previewResult == null) return; // Retake: stay on live camera.
      currentBytes = previewResult;

      // Phase 2: release camera before OCR.
      await _cameraService.dispose();
      if (!mounted) return;
      setState(() {
        _initialized = false;
      });

      String? currentLabel;
      while (mounted) {
        final action = await navigator.push<OcrProcessingResult?>(
          MaterialPageRoute(
            builder: (_) => OcrProcessingScreen(
              bookId: widget.bookId,
              imageBytes: currentBytes,
              initialLabel: currentLabel,
            ),
          ),
        );
        if (!mounted) return;
        currentLabel = action?.label;

        if (action == null || action.type == OcrProcessingAction.cancel) {
          navigator.pop();
          return;
        }
        if (action.type == OcrProcessingAction.retake) {
          await _restartCamera();
          return;
        }
        if (action.type == OcrProcessingAction.adjustCrop) {
          final cropped = await navigator.push<List<int>?>(
            MaterialPageRoute(
              builder: (_) => CropScreen(imageBytes: currentBytes),
            ),
          );
          if (!mounted) return;
          if (cropped != null) currentBytes = cropped;
          continue;
        }

        final result = action.result!;
        final pageId = const Uuid().v4();
        await saveNormalizedImage(currentBytes, widget.bookId, pageId);
        final relPath = paperImageRelativePath(widget.bookId, pageId);
        final now = DateTime.now().toUtc().toIso8601String();
        final page = PaperPage(
          id: pageId,
          imagePath: relPath,
          pageLabel: action.label,
          ocrHash: result.sourceHash,
          markdown: result.pages.map((p) => p.markdown).join('\n'),
          notes: const [],
        );
        await storage.upsertPaperPage(
          bookId: widget.bookId,
          page: page,
          updatedAt: now,
        );
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Page saved')));
        navigator.pop();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      showOcrError(
        context,
        exceptionToUser(
          e,
          onSettings: () => navigator.push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          onRetry: _captureAndPreview,
        ),
      );
    }
  }

  Future<void> _restartCamera() async {
    setState(() {
      _initialized = false;
      _error = null;
    });
    await _cameraService.dispose();
    if (!mounted) return;
    await _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Page'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) return _deniedBody();
    if (_error != null) return _errorBody();
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Camera not ready'));
    }
    return Stack(
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize!.height,
              height: controller.value.previewSize!.width,
              child: CameraPreview(controller),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.large(
              onPressed: _captureAndPreview,
              child: const Icon(Icons.camera_alt, size: 36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deniedBody() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Camera permission denied',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable camera access in device settings.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ),
  );

  Widget _errorBody() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _initialized = false;
                  });
                  _initCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

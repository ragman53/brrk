import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:brrk/src/app/api_key.dart';
import 'package:brrk/src/app/camera_service.dart';
import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/app/settings_screen.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:brrk/src/rust/api/ocr.dart';
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
          builder: (_) => _PreviewScreen(imageBytes: currentBytes),
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
            builder: (_) => _OcrProcessingScreen(
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
              builder: (_) => _CropScreen(imageBytes: currentBytes),
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

// ─── Preview screen ─────────────────────────────────────────────────────────

/// Shows the captured & normalized image with Retake / Use / Adjust crop actions.
/// Returns null to retake, or normalized bytes to proceed to OCR.
class _PreviewScreen extends StatelessWidget {
  final List<int> imageBytes;
  const _PreviewScreen({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: _PreviewBody(imageBytes: imageBytes),
    );
  }
}

class _PreviewBody extends StatefulWidget {
  final List<int> imageBytes;
  const _PreviewBody({required this.imageBytes});

  @override
  State<_PreviewBody> createState() => _PreviewBodyState();
}

class _PreviewBodyState extends State<_PreviewBody> {
  late List<int> _currentBytes;

  @override
  void initState() {
    super.initState();
    _currentBytes = widget.imageBytes;
  }

  Future<List<int>?> _openCrop() async {
    final result = await Navigator.of(context).push<List<int>?>(
      MaterialPageRoute(builder: (_) => _CropScreen(imageBytes: _currentBytes)),
    );
    return result;
  }

  void _applyCrop(List<int> cropped) {
    setState(() {
      _currentBytes = cropped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Image.memory(
            Uint8List.fromList(_currentBytes),
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(null),
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final cropped = await _openCrop();
                  if (!mounted || cropped == null) return;
                  _applyCrop(cropped);
                },
                icon: const Icon(Icons.crop),
                label: const Text('Adjust crop'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_currentBytes),
                icon: const Icon(Icons.check),
                label: const Text('Use'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Crop overlay screen ───────────────────────────────────────────────────────

/// Custom rectangular crop UI. Returns cropped bytes or null on cancel.
class _CropScreen extends StatefulWidget {
  final List<int> imageBytes;
  const _CropScreen({required this.imageBytes});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  // Crop rect as fractions of image dimensions [left, top, right, bottom].
  late List<double> _rect; // [0.0, 0.0, 1.0, 1.0]

  @override
  void initState() {
    super.initState();
    _rect = [0.08, 0.08, 0.92, 0.92];
  }

  void _onCrop() {
    final decoded = img.decodeImage(Uint8List.fromList(widget.imageBytes));
    if (decoded == null) {
      Navigator.of(context).pop(null);
      return;
    }
    final iw = decoded.width.toDouble();
    final ih = decoded.height.toDouble();
    final x = (_rect[0] * iw).round().clamp(0, decoded.width - 1);
    final y = (_rect[1] * ih).round().clamp(0, decoded.height - 1);
    final w = ((_rect[2] - _rect[0]) * iw).round().clamp(1, decoded.width - x);
    final h = ((_rect[3] - _rect[1]) * ih).round().clamp(1, decoded.height - y);
    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    final jpeg = img.encodeJpg(cropped, quality: 85);
    Navigator.of(context).pop(List<int>.from(jpeg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Crop'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [TextButton(onPressed: _onCrop, child: const Text('Apply'))],
      ),
      body: _CropOverlayWidget(
        imageBytes: widget.imageBytes,
        rect: _rect,
        onRectChanged: (r) => setState(() => _rect = r),
      ),
    );
  }
}

/// Shows image with draggable/resizable crop overlay.
/// Uses a GlobalKey to measure actual image size in the Stack.
class _CropOverlayWidget extends StatefulWidget {
  final List<int> imageBytes;
  final List<double> rect;
  final void Function(List<double>) onRectChanged;

  const _CropOverlayWidget({
    required this.imageBytes,
    required this.rect,
    required this.onRectChanged,
  });

  @override
  State<_CropOverlayWidget> createState() => _CropOverlayWidgetState();
}

class _CropOverlayWidgetState extends State<_CropOverlayWidget> {
  int? _activeHandle; // -1=center drag, 0=TL, 1=TR, 2=BL, 3=BR
  final GlobalKey _imageKey = GlobalKey();
  double _imgDisplayW = 0, _imgDisplayH = 0;

  void _onImageMeasured() {
    final rb = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || !rb.hasSize) return;
    if (rb.size.width == _imgDisplayW && rb.size.height == _imgDisplayH) return;
    setState(() {
      _imgDisplayW = rb.size.width;
      _imgDisplayH = rb.size.height;
    });
  }

  void _clamp(double dx, double dy) {
    setState(() {
      final minW = 0.05, minH = 0.05;
      if (_activeHandle == -1) {
        final w = widget.rect[2] - widget.rect[0];
        final h = widget.rect[3] - widget.rect[1];
        final nx = (widget.rect[0] + dx).clamp(0.0, 1.0 - w);
        final ny = (widget.rect[1] + dy).clamp(0.0, 1.0 - h);
        widget.onRectChanged([nx, ny, nx + w, ny + h]);
      } else if (_activeHandle == 0) {
        final nx = (widget.rect[0] + dx).clamp(0.0, widget.rect[2] - minW);
        final ny = (widget.rect[1] + dy).clamp(0.0, widget.rect[3] - minH);
        widget.onRectChanged([nx, ny, widget.rect[2], widget.rect[3]]);
      } else if (_activeHandle == 1) {
        final nx = (widget.rect[2] + dx).clamp(widget.rect[0] + minW, 1.0);
        final ny = (widget.rect[1] + dy).clamp(0.0, widget.rect[3] - minH);
        widget.onRectChanged([widget.rect[0], ny, nx, widget.rect[3]]);
      } else if (_activeHandle == 2) {
        final nx = (widget.rect[0] + dx).clamp(0.0, widget.rect[2] - minW);
        final ny = (widget.rect[3] + dy).clamp(widget.rect[1] + minH, 1.0);
        widget.onRectChanged([nx, widget.rect[1], widget.rect[2], ny]);
      } else if (_activeHandle == 3) {
        final nx = (widget.rect[2] + dx).clamp(widget.rect[0] + minW, 1.0);
        final ny = (widget.rect[3] + dy).clamp(widget.rect[1] + minH, 1.0);
        widget.onRectChanged([widget.rect[0], widget.rect[1], nx, ny]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image — measure its displayed size with a key.
            Center(
              child: Image.memory(
                Uint8List.fromList(widget.imageBytes),
                fit: BoxFit.contain,
                key: _imageKey,
                frameBuilder: (context, child, frame, _) {
                  if (frame != null) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _onImageMeasured(),
                    );
                  }
                  return child;
                },
              ),
            ),
            // Crop rectangle + handles.
            Center(
              child: LayoutBuilder(
                builder: (context, imageConstraints) {
                  // After image key measurement, _imgDisplayW/H give the actual rendered size.
                  final imgW = _imgDisplayW > 0
                      ? _imgDisplayW
                      : imageConstraints.maxWidth;
                  final imgH = _imgDisplayH > 0
                      ? _imgDisplayH
                      : imageConstraints.maxHeight;
                  return SizedBox(
                    width: imgW,
                    height: imgH,
                    child: Stack(
                      children: [
                        // Semi-transparent overlay with cut-out aligned to the displayed image.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CropPainter(rect: widget.rect),
                            ),
                          ),
                        ),
                        // Crop box — drag to move entire rect.
                        Positioned(
                          left: widget.rect[0] * imgW,
                          top: widget.rect[1] * imgH,
                          width: (widget.rect[2] - widget.rect[0]) * imgW,
                          height: (widget.rect[3] - widget.rect[1]) * imgH,
                          child: GestureDetector(
                            onPanStart: (_) {
                              setState(() => _activeHandle = -1);
                            },
                            onPanUpdate: (d) =>
                                _clamp(d.delta.dx / imgW, d.delta.dy / imgH),
                            onPanEnd: (_) {
                              setState(() => _activeHandle = null);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 4 corner handles.
                        _cornerHandle(
                          0,
                          widget.rect[0] * imgW - 10,
                          widget.rect[1] * imgH - 10,
                        ),
                        _cornerHandle(
                          1,
                          widget.rect[2] * imgW - 10,
                          widget.rect[1] * imgH - 10,
                        ),
                        _cornerHandle(
                          2,
                          widget.rect[0] * imgW - 10,
                          widget.rect[3] * imgH - 10,
                        ),
                        _cornerHandle(
                          3,
                          widget.rect[2] * imgW - 10,
                          widget.rect[3] * imgH - 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cornerHandle(int index, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _activeHandle = index);
        },
        onPanUpdate: (d) {
          final box =
              _imageKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null || _imgDisplayW == 0) return;
          _clamp(d.delta.dx / _imgDisplayW, d.delta.dy / _imgDisplayH);
        },
        onPanEnd: (_) {
          setState(() => _activeHandle = null);
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final List<double> rect;
  _CropPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final r = Rect.fromLTRB(
      rect[0] * size.width,
      rect[1] * size.height,
      rect[2] * size.width,
      rect[3] * size.height,
    );
    final overlay = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRect(r),
    );
    canvas.drawPath(overlay, paint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => rect != old.rect;
}

// ─── OCR processing screen ───────────────────────────────────────────────────

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
class _OcrProcessingScreen extends ConsumerStatefulWidget {
  final String bookId;
  final List<int> imageBytes;
  final String? initialLabel;

  const _OcrProcessingScreen({
    required this.bookId,
    required this.imageBytes,
    this.initialLabel,
  });

  @override
  ConsumerState<_OcrProcessingScreen> createState() =>
      _OcrProcessingScreenState();
}

class _OcrProcessingScreenState extends ConsumerState<_OcrProcessingScreen> {
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

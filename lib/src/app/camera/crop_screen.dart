import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Custom rectangular crop UI. Returns cropped bytes or null on cancel.
class CropScreen extends StatefulWidget {
  final List<int> imageBytes;
  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
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

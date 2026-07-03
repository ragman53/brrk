import 'dart:typed_data';

import 'package:brrk/src/app/camera/crop_screen.dart';
import 'package:flutter/material.dart';

/// Shows the captured & normalized image with Retake / Use / Adjust crop actions.
/// Returns null to retake, or normalized bytes to proceed to OCR.
class CapturePreviewScreen extends StatelessWidget {
  final List<int> imageBytes;
  const CapturePreviewScreen({super.key, required this.imageBytes});

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
      MaterialPageRoute(builder: (_) => CropScreen(imageBytes: _currentBytes)),
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

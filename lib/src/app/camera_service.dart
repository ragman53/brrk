import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera service: manages lifecycle, permission, and image capture.
class CameraService {
  List<CameraDescription>? _cameras;
  CameraController? _controller;

  /// True when camera is currently initialized and ready.
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  CameraController? get controller => _controller;

  /// Request camera permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if camera permission is already granted.
  Future<bool> hasPermission() async {
    return Permission.camera.isGranted;
  }

  /// Initialize camera (front or back). Must be called on a widget build context.
  Future<void> initialize({bool preferBack = true}) async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw CameraException('no_cameras', 'No cameras available on this device.');
    }

    final target = preferBack
        ? _cameras!.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras!.first,
          )
        : _cameras!.first;

    _controller = CameraController(
      target,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
  }

  /// Capture a JPEG image and return the raw bytes.
  Future<XFile> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera not initialized.');
    }
    return _controller!.takePicture();
  }

  /// Dispose the camera controller and free resources.
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _cameras = null;
  }
}

/// Returns the relative storage path for a captured paper image.
String paperImageRelativePath(String bookId, String pageId) =>
    'images/$bookId/$pageId.jpg';

/// Resizes a source image file to maxWidth (preserving aspect ratio), saves as JPEG 85%.
/// Returns the absolute path of the resized image under app data directory.
Future<String> resizeAndSaveImage(
  File sourceFile,
  String bookId,
  String pageId, {
  int maxWidth = 2000,
  int quality = 85,
}) async {
  final bytes = await sourceFile.readAsBytes();

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('Could not decode image');
  }
  final resized = decoded.width > maxWidth
      ? img.copyResize(decoded, width: maxWidth)
      : decoded;
  final jpegBytes = img.encodeJpg(resized, quality: quality);

  // Save under <app_data>/images/{bookId}/{pageId}.jpg
  final appDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${appDir.path}/images/$bookId');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final outPath = '${appDir.path}/${paperImageRelativePath(bookId, pageId)}';
  final outFile = File(outPath);
  await outFile.writeAsBytes(Uint8List.fromList(jpegBytes));

  return outPath;
}

/// Resizes image bytes to a normalized JPEG (max width 2000, quality 85).
/// Returns resized bytes ready for OCR base64 encoding.
Future<Uint8List> resizeImageBytes(List<int> sourceBytes) async {
  final decoded = img.decodeImage(Uint8List.fromList(sourceBytes));
  if (decoded == null) {
    throw Exception('Could not decode image');
  }
  final resized = decoded.width > 2000 ? img.copyResize(decoded, width: 2000) : decoded;
  return img.encodeJpg(resized, quality: 85);
}

/// Saves already-normalized image bytes to the standard storage path.
/// Used after OCR succeeds so the stored file bytes match what was sent to the API.
Future<String> saveNormalizedImage(List<int> normalizedBytes, String bookId, String pageId) async {
  final appDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${appDir.path}/images/$bookId');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }
  final outPath = '${appDir.path}/${paperImageRelativePath(bookId, pageId)}';
  final outFile = File(outPath);
  await outFile.writeAsBytes(Uint8List.fromList(normalizedBytes));
  return outPath;
}

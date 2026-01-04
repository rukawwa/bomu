import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme.dart';
import 'analysis_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  // ignore: unused_field
  bool _isCameraInitialized = false;
  // ignore: unused_field
  bool _isProcessing = false;
  List<DetectedObject> _detectedObjects = [];
  ObjectDetector? _objectDetector;
  int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeDetector();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _objectDetector?.close();
    super.dispose();
  }

  // Handle App Lifecycle (Background/Resume)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _initializeDetector() {
    // Standard Object Detector
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // Medium is usually sufficient for detection
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      // Start Image Stream
      _controller!.startImageStream(_processImage);

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || _objectDetector == null) return;

    // Process every 3rd frame to optimize performance
    _frameCounter++;
    if (_frameCounter % 3 != 0) return;

    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final objects = await _objectDetector!.processImage(inputImage);
      if (mounted) {
        setState(() => _detectedObjects = objects);
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validate format for platform
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1 && Platform.isAndroid) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Get screen size for overlay scaling
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          CameraPreview(_controller!),

          // 2. Robotic Overlay (Corner Brackets)
          if (_objectDetector != null)
            CustomPaint(
              painter: _ObjectDetectorPainter(
                _detectedObjects,
                _controller!.value.previewSize!,
                size,
                _controller!.description.sensorOrientation,
                _controller!.description.lensDirection,
              ),
            ),

          // 3. UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              "SCANNING...",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance Spacer
                    ],
                  ),
                ),

                const Spacer(),

                // Capture Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: GestureDetector(
                    onTap: () async {
                      if (_controller == null ||
                          !_controller!.value.isInitialized ||
                          _isProcessing)
                        return;

                      try {
                        setState(() => _isProcessing = true);

                        // Stop stream to capture full res
                        // Note: Some devices might need stopImageStream first
                        await _controller!.stopImageStream();

                        final XFile image = await _controller!.takePicture();

                        if (!mounted) {
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AnalysisScreen(imagePath: image.path),
                          ),
                        ).then((_) {
                          // Restart stream when coming back
                          _controller!.startImageStream(_processImage);
                          setState(() => _isProcessing = false);
                        });
                      } catch (e) {
                        debugPrint("Capture error: $e");
                        setState(() => _isProcessing = false);
                      }
                    },
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 4,
                        ),
                        color: Colors.white10,
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for "Robotic" Overlay
class _ObjectDetectorPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final Size widgetSize;
  final int rotation;
  final CameraLensDirection cameraLensDirection;

  _ObjectDetectorPainter(
    this.objects,
    this.imageSize,
    this.widgetSize,
    this.rotation,
    this.cameraLensDirection,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = AppColors.primary;

    for (final object in objects) {
      final rect = object.boundingBox;

      // Coordinate Transformation
      // This is simplified. For production, align aspect ratios accurately.
      // Assuming Portrait Mode (height > width)

      // Note: Android imageSize is usually landscape (e.g. 1280x720), so width > height.
      // But screen is portrait.

      final double scaleX = widgetSize.width / imageSize.height;
      final double scaleY = widgetSize.height / imageSize.width;

      // Simple scaling for Portrait
      // Left = rect.left * scaleX
      // Top = rect.top * scaleY
      // Need to mirror if front camera (not used here) or adjust for sensor rotation

      // Correct rect
      final double left = rect.left * scaleX;
      final double top = rect.top * scaleY;
      final double right = rect.right * scaleX;
      final double bottom = rect.bottom * scaleY;

      final transformedRect = Rect.fromLTRB(left, top, right, bottom);

      _drawCornerBrackets(canvas, transformedRect, paint);

      // Optional: Draw Label "OBJECT DETECTED"
      // _drawLabel(canvas, transformedRect);
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint) {
    final double cornerLength = 25.0;

    // Top Left
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(0, cornerLength),
      paint,
    );

    // Top Right
    canvas.drawLine(
      rect.topRight,
      rect.topRight - Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(0, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - Offset(0, cornerLength),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(0, cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

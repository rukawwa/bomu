import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isProcessing = false;
  bool _permissionDenied = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _initError = null;
      });
    }

    try {
      final status = await Permission.camera.request();
      final hasAccess = status.isGranted || status.isLimited;
      if (!hasAccess) {
        if (mounted) {
          setState(() => _permissionDenied = true);
        }
        return;
      }

      _permissionDenied = false;

      await _controller?.dispose();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw 'Cihazda kamera bulunamadı';
      }

      final CameraDescription camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _permissionDenied = false;
        _initError = null;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _initError = 'Kamera başlatılamadı. Lütfen tekrar deneyin.';
          _permissionDenied = false;
        });
      }
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    try {
      setState(() => _isProcessing = true);
      final XFile image = await _controller!.takePicture();

      if (!mounted) return;

      // Navigate to AnalysisScreen and get results
      final results = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(imagePath: image.path),
        ),
      );

      // Return results to caller (home_screen)
      if (mounted && results != null) {
        Navigator.pop(context, results);
      } else if (mounted) {
        // User cancelled without adding, just go back
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fotoğraf çekilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Kamera izni gerekli',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ayarlar > Hakone > Kamera iznini açmalısın.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: openAppSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Ayarları Aç'),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(
                _initError!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Focus Overlay
          CustomPaint(painter: _FocusOverlayPainter(), child: Container()),

          // UI Controls
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildGuideText(),
                const SizedBox(height: 20),
                _buildCaptureButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _isProcessing ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _isProcessing ? 'ÇEKILIYOR...' : 'HAZIR',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildGuideText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text(
            'Tabağını çerçevenin içine yerleştir',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _captureAndAnalyze,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isProcessing
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.6),
            width: 4,
          ),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Center(
          child: _isProcessing
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                )
              : Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FocusOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final cutoutPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    final rect = Rect.fromLTWH(
      20,
      size.height * 0.20,
      size.width - 40,
      size.height * 0.50,
    );

    canvas.saveLayer(Rect.largest, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      cutoutPaint,
    );
    canvas.restore();

    // Draw border around focus area
    final borderPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      borderPaint,
    );

    // Draw corner accents
    _drawCornerAccents(canvas, rect);
  }

  void _drawCornerAccents(Canvas canvas, Rect rect) {
    final accentPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double accentLength = 30.0;
    const double offset = 1.5;

    // Top Left
    canvas.drawLine(
      Offset(rect.left + offset, rect.top + 24),
      Offset(rect.left + offset, rect.top + 24 + accentLength),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 24, rect.top + offset),
      Offset(rect.left + 24 + accentLength, rect.top + offset),
      accentPaint,
    );

    // Top Right
    canvas.drawLine(
      Offset(rect.right - offset, rect.top + 24),
      Offset(rect.right - offset, rect.top + 24 + accentLength),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right - 24, rect.top + offset),
      Offset(rect.right - 24 - accentLength, rect.top + offset),
      accentPaint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(rect.left + offset, rect.bottom - 24),
      Offset(rect.left + offset, rect.bottom - 24 - accentLength),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 24, rect.bottom - offset),
      Offset(rect.left + 24 + accentLength, rect.bottom - offset),
      accentPaint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(rect.right - offset, rect.bottom - 24),
      Offset(rect.right - offset, rect.bottom - 24 - accentLength),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right - 24, rect.bottom - offset),
      Offset(rect.right - 24 - accentLength, rect.bottom - offset),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

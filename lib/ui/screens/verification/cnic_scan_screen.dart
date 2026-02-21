import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/cnic_scanner_service.dart';
import '../../../ui/theme/color_palette.dart';
import '../../../ui/theme/spacing.dart';

/// Screen for scanning CNIC with camera
class CnicScanScreen extends StatefulWidget {
  const CnicScanScreen({super.key});

  @override
  State<CnicScanScreen> createState() => _CnicScanScreenState();
}

class _CnicScanScreenState extends State<CnicScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  final CnicScannerService _scannerService = CnicScannerService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission required')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No camera found')));
        }
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _captureAndScan() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Vibrate
      HapticFeedback.mediumImpact();

      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      // Show processing indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: Spacing.md),
                Text('Scanning CNIC...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Scan CNIC
      final cnicData = await _scannerService.scanCnic(imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        if (cnicData != null && cnicData.isValidFormat) {
          // Success - return CNIC data
          Navigator.pop(context, cnicData);
        } else {
          // Failed to extract valid data
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read CNIC. Please try again.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error capturing and scanning: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() async {
    // Properly dispose camera controller
    try {
      await _cameraController?.dispose();
    } catch (e) {
      print('Error disposing camera: $e');
    }

    _scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scan CNIC'),
        centerTitle: true,
      ),
      body: _isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                CameraPreview(_cameraController!),

                // Document Guide Overlay
                CustomPaint(
                  painter: DocumentOverlayPainter(),
                  child: Container(),
                ),

                // Instructions
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Position CNIC within the guide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Capture Button
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _captureAndScan,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isProcessing ? Colors.grey : Colors.white,
                          border: Border.all(
                            color: AppColors.primaryDark,
                            width: 4,
                          ),
                        ),
                        child: _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(Spacing.md),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primaryDark,
                                ),
                              )
                            : const Icon(
                                Icons.camera,
                                size: 35,
                                color: AppColors.primaryDark,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Custom painter for document guide overlay
class DocumentOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent black overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);

    // Document guide rectangle (credit card ratio: 1.586)
    final cardWidth = size.width * 0.85;
    final cardHeight = cardWidth / 1.586;
    final cardLeft = (size.width - cardWidth) / 2;
    final cardTop = (size.height - cardHeight) / 2;

    final cardRect = Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight);

    // Draw overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw guide border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(16)),
      borderPaint,
    );

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(cardLeft, cardTop + cornerLength),
      Offset(cardLeft, cardTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft, cardTop),
      Offset(cardLeft + cornerLength, cardTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cardLeft + cardWidth - cornerLength, cardTop),
      Offset(cardLeft + cardWidth, cardTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft + cardWidth, cardTop),
      Offset(cardLeft + cardWidth, cardTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cardLeft, cardTop + cardHeight - cornerLength),
      Offset(cardLeft, cardTop + cardHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft, cardTop + cardHeight),
      Offset(cardLeft + cornerLength, cardTop + cardHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cardLeft + cardWidth - cornerLength, cardTop + cardHeight),
      Offset(cardLeft + cardWidth, cardTop + cardHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft + cardWidth, cardTop + cardHeight - cornerLength),
      Offset(cardLeft + cardWidth, cardTop + cardHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

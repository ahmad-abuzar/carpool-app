import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../../../ui/theme/color_palette.dart';
import '../../../ui/theme/spacing.dart';

class FingerprintRealtimeScreen extends StatefulWidget {
  const FingerprintRealtimeScreen({super.key});

  @override
  State<FingerprintRealtimeScreen> createState() =>
      _FingerprintRealtimeScreenState();
}

class _FingerprintRealtimeScreenState extends State<FingerprintRealtimeScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool _isCapturingRightHand = true;
  File? _rightHandImage;
  File? _leftHandImage;

  // ML Kit Pose Detector
  late final PoseDetector _poseDetector;
  bool _isProcessing = false;
  Pose? _detectedPose;

  // Distance meter simulation (replace with real ML confidence)
  double _handDistance = 0.5;

  // Timer replaced by real-time stream, keeping variable for safety if legacy code references it
  Timer? _autoCaptureTimer;

  bool _isNavigating = false;
  bool _isCaptureInProgress = false;

  // Animation for scanning effect
  late AnimationController _scanAnimationController;

  void _safePop(Map<String, dynamic>? result) {
    if (_isNavigating) return;
    _isNavigating = true;
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, result);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize Pose Detector
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    _poseDetector = PoseDetector(options: options);

    // Initialize Scanner Animation
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission required')),
          );
          _safePop(null);
        }
        return;
      }

      _cameras = await availableCameras();
      final rearCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Start image stream for real-time detection
      await _cameraController!.startImageStream(_processImage);
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final wrist = _isCapturingRightHand
            ? pose.landmarks[PoseLandmarkType.rightWrist]
            : pose.landmarks[PoseLandmarkType.leftWrist];

        if (wrist != null && wrist.likelihood > 0.5) {
          final indexFinger = _isCapturingRightHand
              ? pose.landmarks[PoseLandmarkType.rightIndex]
              : pose.landmarks[PoseLandmarkType.leftIndex];

          double distanceScore = 0.5;

          if (indexFinger != null && indexFinger.likelihood > 0.5) {
            final dx = (wrist.x - indexFinger.x).abs();
            final dy = (wrist.y - indexFinger.y).abs();
            final size = dx + dy;

            const minSize = 100.0;
            const maxSize = 600.0; // Increased max size for closer hands

            if (size < minSize) {
              distanceScore = 0.8; // Too Far
            } else if (size > maxSize) {
              distanceScore = 0.2; // Too Close
            } else {
              distanceScore = 0.5; // Perfect
            }
          }

          if (mounted) {
            setState(() {
              _handDistance = distanceScore;
              _detectedPose = pose;
            });

            if (distanceScore >= 0.4 && distanceScore <= 0.6) {
              // Throttle capture to ensure stable detection
              _cameraController?.stopImageStream();
              await _captureHand();
            }
          }
        } else {
          if (mounted)
            setState(() {
              _handDistance = 1.0;
              _detectedPose = null;
            });
        }
      } else {
        if (mounted)
          setState(() {
            _handDistance = 1.0;
            _detectedPose = null;
          });
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      if (mounted) {
        _isProcessing = false;
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // For simplicity/robustness, assuming NV21/YUV420 standard handling or provided by library later.
    // Constructing bytes manualy is risky without precise plane logic, but usually required.
    // Concatenating planes for Android YUV420:
    final allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final size = Size(image.width.toDouble(), image.height.toDouble());

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: format ?? InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> _captureHand() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCaptureInProgress) {
      return;
    }

    _isCaptureInProgress = true;

    setState(() {
      // _isCapturing = true; // Removed
    });

    try {
      HapticFeedback.heavyImpact();
      final XFile image = await _cameraController!.takePicture();

      if (mounted) {
        setState(() {
          if (_isCapturingRightHand) {
            _rightHandImage = File(image.path);
          } else {
            _leftHandImage = File(image.path);
          }
          // _isCapturing = false; // Removed
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isCapturingRightHand
                  ? 'Right hand captured!'
                  : 'Left hand captured!',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );

        // Wait a short moment before switching hands
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          if (_isCapturingRightHand && _rightHandImage != null) {
            setState(() {
              _isCapturingRightHand = false;
              _detectedPose = null; // Reset pose for next hand
            });
            // Restart stream for left hand
            await _cameraController?.startImageStream(_processImage);
          } else if (_rightHandImage != null && _leftHandImage != null) {
            _safePop({
              'rightHand': _rightHandImage,
              'leftHand': _leftHandImage,
            });
          }
        }
      }
    } catch (e) {
      print('Error capturing hand: $e');
      if (mounted) {
        setState(() {
          // _isCapturing = false; // Removed
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _isCaptureInProgress = false;
    }
  }

  Future<void> _captureHandManually() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await _captureHand();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manual capture failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _autoCaptureTimer?.cancel();
    _poseDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Fingerprint Capture'),
        centerTitle: true,
      ),
      body: _isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),

                // Hand guide Animation
                _buildHandGuide(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ),

                // Skeleton Overlay
                if (_detectedPose != null && _cameraController != null)
                  CustomPaint(
                    painter: PosePainter(
                      pose: _detectedPose!,
                      imageSize: Size(
                        _cameraController!
                            .value
                            .previewSize!
                            .height, // Swap for portrait
                        _cameraController!.value.previewSize!.width,
                      ),
                      isRightHand: _isCapturingRightHand,
                    ),
                  ),

                // Distance meter
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Column(children: [_buildDistanceMeter()]),
                ),

                Positioned(
                  bottom: 36,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Text(
                        _isCapturingRightHand
                            ? 'Place RIGHT hand then tap Capture'
                            : 'Place LEFT hand then tap Capture',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCaptureInProgress
                              ? null
                              : _captureHandManually,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _isCaptureInProgress
                                ? 'Capturing...'
                                : 'Capture Hand Now',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildHandGuide(double screenWidth, double screenHeight) {
    // Determine color based on distance
    Color guideColor;
    String instruction;

    if (_handDistance < 0.3) {
      guideColor = Colors.red;
      instruction = "Too Close";
    } else if (_handDistance > 0.7) {
      guideColor = Colors.orange;
      instruction = "Too Far";
    } else if (_handDistance >= 0.4 && _handDistance <= 0.6) {
      guideColor = AppColors.success;
      instruction = "Perfect - Hold Steady";
    } else {
      guideColor = Colors.white.withOpacity(0.5);
      instruction = "Place ${_isCapturingRightHand ? 'Right' : 'Left'} Hand";
    }

    // Mirror for right hand if using front camera logic,
    // but typically 'back hand' icon is generic.
    // Let's just use "pan_tool" and maybe mirror for Left hand visually if needed.
    // Standard icon is right-handed usually.
    final bool flip = !_isCapturingRightHand;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Hand Icon
              Transform.scale(
                scaleX: flip ? -1 : 1,
                child: Icon(
                  Icons.pan_tool_rounded,
                  size: 280,
                  color: guideColor.withOpacity(0.3),
                ),
              ),

              // Guide Outline (Pulse)
              Transform.scale(
                scaleX: flip ? -1 : 1,
                child: Icon(
                  Icons.pan_tool_outlined,
                  size: 280,
                  color: guideColor,
                ),
              ),

              // Scanning Line Animation (Vertical)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scanAnimationController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      heightFactor: 0.1, // Line height
                      alignment: Alignment(
                        0,
                        _scanAnimationController.value * 2 - 1,
                      ), // Move -1 to 1
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              guideColor.withOpacity(0),
                              guideColor,
                              guideColor.withOpacity(0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: guideColor,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Text(
            instruction,
            style: TextStyle(
              color: guideColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceMeter() {
    // Kept for debug/precision if user wants,
    // but visual guide might supersede it.
    // Hiding it for cleaner look as per request "green box ki jagah..."
    return const SizedBox.shrink();
  }
}

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final bool isRightHand;

  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.isRightHand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final paintLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white;

    final wrist = isRightHand
        ? pose.landmarks[PoseLandmarkType.rightWrist]
        : pose.landmarks[PoseLandmarkType.leftWrist];

    final index = isRightHand
        ? pose.landmarks[PoseLandmarkType.rightIndex]
        : pose.landmarks[PoseLandmarkType.leftIndex];

    if (wrist != null) {
      canvas.drawCircle(
        _translate(wrist.x, wrist.y, size, imageSize),
        4,
        paint,
      );
    }

    if (index != null) {
      canvas.drawCircle(
        _translate(index.x, index.y, size, imageSize),
        4,
        paint,
      );
    }

    if (wrist != null && index != null) {
      final p1 = _translate(wrist.x, wrist.y, size, imageSize);
      final p2 = _translate(index.x, index.y, size, imageSize);
      canvas.drawLine(p1, p2, paintLine);
    }
  }

  Offset _translate(double x, double y, Size size, Size imageSize) {
    if (imageSize.width == 0 || imageSize.height == 0) return Offset.zero;

    // Scale to fit screen
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    return Offset(x * scaleX, y * scaleY);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.imageSize != imageSize;
  }
}

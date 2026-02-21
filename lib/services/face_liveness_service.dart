import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service for real-time face detection and liveness verification
class FaceLivenessService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      enableContours: true,
    ),
  );

  // Liveness tracking
  bool _hasDetectedFace = false;
  bool _hasBlinkDetected = false;
  bool _hasHeadTurnedLeft = false;
  bool _hasHeadTurnedRight = false;

  double? _previousLeftEyeOpenProbability;
  double? _previousRightEyeOpenProbability;

  /// Process camera image for face detection
  Future<FaceLivenessResult> processCameraImage(CameraImage image) async {
    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) return FaceLivenessResult.noFace();

      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceLivenessResult.noFace();
      }

      final face = faces.first;

      // Check if face is well positioned
      final faceQuality = _checkFaceQuality(face);
      if (!faceQuality.isGood) {
        return FaceLivenessResult(
          hasFace: true,
          isFaceWellPositioned: false,
          message: faceQuality.message,
        );
      }

      // Detect blink
      if (!_hasBlinkDetected) {
        _detectBlink(face);
      }

      // Detect head movement
      if (!_hasHeadTurnedLeft || !_hasHeadTurnedRight) {
        _detectHeadMovement(face);
      }

      // Check if all liveness checks passed
      final livenessComplete =
          _hasBlinkDetected && _hasHeadTurnedLeft && _hasHeadTurnedRight;

      return FaceLivenessResult(
        hasFace: true,
        isFaceWellPositioned: true,
        hasBlinkDetected: _hasBlinkDetected,
        hasHeadTurnedLeft: _hasHeadTurnedLeft,
        hasHeadTurnedRight: _hasHeadTurnedRight,
        livenessComplete: livenessComplete,
        message: _getLivenessMessage(),
      );
    } catch (e) {
      print('Error processing face: $e');
      return FaceLivenessResult.error(e.toString());
    }
  }

  /// Convert CameraImage to InputImage
  InputImage? _convertToInputImage(CameraImage image) {
    try {
      // Convert to NV21 format for ML Kit
      final allBytes = BytesBuilder();
      for (final Plane plane in image.planes) {
        allBytes.add(plane.bytes);
      }
      final bytes = allBytes.toBytes();

      // Get image format
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        print('Unsupported image format: ${image.format.raw}');
        return null;
      }

      // Front camera needs 270 degree rotation
      final rotation = InputImageRotation.rotation270deg;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  /// Check face quality (position, lighting, size)
  FaceQualityResult _checkFaceQuality(Face face) {
    // Check if face is too small (too far)
    final boundingBox = face.boundingBox;
    if (boundingBox.width < 200 || boundingBox.height < 200) {
      return FaceQualityResult(
        isGood: false,
        message: 'Move closer to the camera',
      );
    }

    // Check if face is too large (too close)
    if (boundingBox.width > 800 || boundingBox.height > 800) {
      return FaceQualityResult(
        isGood: false,
        message: 'Move away from the camera',
      );
    }

    // Check head angle (should be mostly straight)
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    if (headEulerAngleY.abs() > 20 &&
        !_hasHeadTurnedLeft &&
        !_hasHeadTurnedRight) {
      return FaceQualityResult(
        isGood: false,
        message: 'Face the camera directly',
      );
    }

    return FaceQualityResult(isGood: true, message: 'Good position');
  }

  /// Detect blink by eye open probability changes
  void _detectBlink(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;

    if (leftEyeOpen != null && rightEyeOpen != null) {
      // Blink detected if eyes were open and now closed
      if (_previousLeftEyeOpenProbability != null &&
          _previousRightEyeOpenProbability != null) {
        final wasOpen =
            _previousLeftEyeOpenProbability! > 0.8 &&
            _previousRightEyeOpenProbability! > 0.8;
        final nowClosed = leftEyeOpen < 0.3 && rightEyeOpen < 0.3;

        if (wasOpen && nowClosed) {
          _hasBlinkDetected = true;
          print('✅ Blink detected!');
        }
      }

      _previousLeftEyeOpenProbability = leftEyeOpen;
      _previousRightEyeOpenProbability = rightEyeOpen;
    }
  }

  /// Detect head movement (left/right turn)
  void _detectHeadMovement(Face face) {
    final headEulerAngleY = face.headEulerAngleY;

    if (headEulerAngleY != null) {
      // Head turned left (positive angle)
      if (headEulerAngleY > 20 && !_hasHeadTurnedLeft) {
        _hasHeadTurnedLeft = true;
        print('✅ Head turned left!');
      }

      // Head turned right (negative angle)
      if (headEulerAngleY < -20 && !_hasHeadTurnedRight) {
        _hasHeadTurnedRight = true;
        print('✅ Head turned right!');
      }
    }
  }

  /// Get current liveness instruction message
  String _getLivenessMessage() {
    if (!_hasBlinkDetected) {
      return 'Blink your eyes';
    }
    if (!_hasHeadTurnedLeft) {
      return 'Turn your head left';
    }
    if (!_hasHeadTurnedRight) {
      return 'Turn your head right';
    }
    return 'All checks complete!';
  }

  /// Reset liveness state
  void reset() {
    _hasDetectedFace = false;
    _hasBlinkDetected = false;
    _hasHeadTurnedLeft = false;
    _hasHeadTurnedRight = false;
    _previousLeftEyeOpenProbability = null;
    _previousRightEyeOpenProbability = null;
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.close();
  }
}

/// Result of face liveness detection
class FaceLivenessResult {
  final bool hasFace;
  final bool isFaceWellPositioned;
  final bool hasBlinkDetected;
  final bool hasHeadTurnedLeft;
  final bool hasHeadTurnedRight;
  final bool livenessComplete;
  final String message;

  FaceLivenessResult({
    this.hasFace = false,
    this.isFaceWellPositioned = false,
    this.hasBlinkDetected = false,
    this.hasHeadTurnedLeft = false,
    this.hasHeadTurnedRight = false,
    this.livenessComplete = false,
    this.message = '',
  });

  factory FaceLivenessResult.noFace() {
    return FaceLivenessResult(
      hasFace: false,
      message: 'Position your face in the frame',
    );
  }

  factory FaceLivenessResult.error(String error) {
    return FaceLivenessResult(message: 'Error: $error');
  }
}

/// Face quality check result
class FaceQualityResult {
  final bool isGood;
  final String message;

  FaceQualityResult({required this.isGood, required this.message});
}

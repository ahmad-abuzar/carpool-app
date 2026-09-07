import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../theme/color_palette.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';

/// Face verification screen - KYC style liveness check
/// One-time identity verification
class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  ConsumerState<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends ConsumerState<FaceVerificationScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _instruction = 'Position your face in the circle';
  int _step = 0;

  final List<String> _instructions = [
    'Position your face in the circle',
    'Blink your eyes',
    'Turn your head left',
    'Turn your head right',
    'Processing...',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _nextStep() async {
    if (_step < _instructions.length - 1) {
      setState(() {
        _step++;
        _instruction = _instructions[_step];
      });

      // Simulate processing time for each step
      await Future.delayed(const Duration(seconds: 2));

      if (_step == _instructions.length - 1) {
        // Final step - processing
        await _processVerification();
      } else {
        // Auto-advance for demo
        _nextStep();
      }
    }
  }

  Future<void> _processVerification() async {
    setState(() => _isProcessing = true);

    // Simulate backend processing
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.verified_user,
          color: AppColors.success,
          size: 64,
        ),
        title: Text(
          'Verification Complete!',
          style: AppTypography.headline(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your identity has been verified successfully.',
              style: AppTypography.body(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Verified User Badge Earned',
                    style: AppTypography.bodySmall(
                      context,
                      color: AppColors.success,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.pop(); // Close dialog
                context.go('/home'); // Go to home
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _cameraController != null)
              SizedBox.expand(child: CameraPreview(_cameraController!)),

            // Overlay with face circle
            if (_isInitialized)
              Center(
                child: Container(
                  width: 280,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _step == 0 ? Colors.white : AppColors.primaryDark,
                      width: 4,
                    ),
                  ),
                ),
              ),

            // Top instruction
            Positioned(
              top: Spacing.xl,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  children: [
                    Text(
                      'Face Verification',
                      style: AppTypography.headline(
                        context,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      _instruction,
                      style: AppTypography.body(context, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Positioned(
              bottom: Spacing.xl,
              left: Spacing.lg,
              right: Spacing.lg,
              child: Column(
                children: [
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _step
                              ? AppColors.primaryDark
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.lg),

                  // Start/Continue button
                  if (!_isProcessing && _step == 0)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        child: const Text('Start Verification'),
                      ),
                    ),

                  if (_isProcessing)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryDark,
                      ),
                    ),

                  const SizedBox(height: Spacing.md),

                  // Skip button
                  if (!_isProcessing)
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(
                        'Skip for now',
                        style: AppTypography.body(context, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Loading overlay
            if (!_isInitialized)
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

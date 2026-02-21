import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/face_verification_service.dart';
import '../../../services/verification_service.dart';
import '../../../state/providers.dart';
import '../../../ui/theme/color_palette.dart';
import '../../../ui/theme/spacing.dart';
import '../../../ui/theme/typography.dart';
import 'face_liveness_screen.dart';

/// Entry screen for face verification process
class FaceVerificationScreen extends ConsumerWidget {
  const FaceVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Verification'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.xxl),

              // Icon
              Container(
                padding: const EdgeInsets.all(Spacing.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.face, size: 80, color: Colors.white),
              ),

              const SizedBox(height: Spacing.xxl),

              // Title
              Text(
                'Liveness Verification',
                style: AppTypography.headline(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.md),

              // Subtitle
              Text(
                'We need to verify you\'re a real person',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxl),

              // Instructions
              _InstructionCard(
                icon: Icons.face,
                title: 'Automatic Detection',
                subtitle: 'App will detect your face automatically',
              ),

              const SizedBox(height: Spacing.md),

              _InstructionCard(
                icon: Icons.remove_red_eye,
                title: 'Blink Test',
                subtitle: 'Blink your eyes when prompted',
              ),

              const SizedBox(height: Spacing.md),

              _InstructionCard(
                icon: Icons.swap_horiz,
                title: 'Head Movement',
                subtitle: 'Turn your head left and right',
              ),

              const Spacer(),

              // Start button
              ElevatedButton.icon(
                onPressed: () async {
                  // Open live face scanner
                  final faceImage = await Navigator.push<File>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FaceLivenessScreen(),
                    ),
                  );

                  if (faceImage != null && context.mounted) {
                    // Process verification
                    await _processVerification(context, ref, faceImage);
                  }
                },
                icon: const Icon(Icons.camera_alt, size: 24),
                label: const Text(
                  'Start Verification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  backgroundColor: AppColors.primaryDark,
                ),
              ),

              const SizedBox(height: Spacing.md),

              TextButton(
                onPressed: () => context.push('/verification/fingerprint'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processVerification(
    BuildContext context,
    WidgetRef ref,
    File faceImage,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: Spacing.lg),
                Text('Processing verification...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final faceService = FaceVerificationService();
      final success = await faceService.submitFaceForVerification(
        faceImage,
        currentUser.id,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close dialog

        if (success) {
          // Mark as verified
          final verificationService = VerificationService();
          await verificationService.markFaceVerified(currentUser.id);

          // Navigate to fingerprint
          context.push('/verification/fingerprint');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification failed. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum LivenessStep { lookStraight, blink, turnLeft, turnRight }

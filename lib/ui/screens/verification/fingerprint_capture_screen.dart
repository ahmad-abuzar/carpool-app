import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/fingerprint_service.dart';
import '../../../services/verification_service.dart';
import '../../../state/providers.dart';
import '../../../ui/theme/color_palette.dart';
import '../../../ui/theme/spacing.dart';
import '../../../ui/theme/typography.dart';
import 'fingerprint_realtime_screen.dart';

/// Entry screen for fingerprint capture
class FingerprintCaptureScreen extends ConsumerWidget {
  const FingerprintCaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerprint Capture'),
        centerTitle: true,
      ),
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
                child: const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: Spacing.xxl),

              // Title
              Text(
                'Capture Fingerprints',
                style: AppTypography.headline(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.md),

              // Subtitle
              Text(
                'Camera will automatically capture both hands',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxl),

              // Instructions
              _InstructionCard(
                icon: Icons.back_hand,
                title: 'Place Hand Flat',
                subtitle: 'Position hand within camera guide',
              ),

              const SizedBox(height: Spacing.md),

              _InstructionCard(
                icon: Icons.timer,
                title: '3-Second Countdown',
                subtitle: 'Camera captures automatically',
              ),

              const SizedBox(height: Spacing.md),

              _InstructionCard(
                icon: Icons.swap_horiz,
                title: 'Both Hands',
                subtitle: 'Right hand first, then left hand',
              ),

              const Spacer(),

              // Start button
              ElevatedButton.icon(
                onPressed: () async {
                  // Open realtime scanner
                  final result = await Navigator.push<Map<String, File>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FingerprintRealtimeScreen(),
                    ),
                  );

                  if (result != null && context.mounted) {
                    // Process fingerprints
                    await _processFingerprints(context, ref, result);
                  }
                },
                icon: const Icon(Icons.camera_alt, size: 24),
                label: const Text(
                  'Start Capture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  backgroundColor: AppColors.primaryDark,
                ),
              ),

              const SizedBox(height: Spacing.md),

              TextButton(
                onPressed: () => context.push('/verification/complete'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processFingerprints(
    BuildContext context,
    WidgetRef ref,
    Map<String, File> result,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final rightHand = result['rightHand'];
    final leftHand = result['leftHand'];

    if (rightHand == null || leftHand == null) return;

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
                Text('Processing fingerprints...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final fingerprintService = FingerprintService();
      final success = await fingerprintService.submitFingerprints(
        rightHandImage: rightHand,
        leftHandImage: leftHand,
        uid: currentUser.id,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close dialog

        if (success) {
          // Mark as verified and complete
          final verificationService = VerificationService();
          await verificationService.markFingerprintsVerified(currentUser.id);
          await verificationService.completeVerification(currentUser.id);

          // Navigate to completion
          context.push('/verification/complete');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint submission failed. Please try again.'),
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

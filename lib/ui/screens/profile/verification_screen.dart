import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/user.dart';
import '../../../services/verification_service.dart';
import '../../../state/providers.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class VerificationIntroScreen extends ConsumerWidget {
  const VerificationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.xl),

              // Icon
              Container(
                padding: const EdgeInsets.all(Spacing.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: Spacing.xxl),

              // Title
              Text(
                'Verify your identity',
                style: AppTypography.headline(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.md),

              // Subtitle
              Text(
                'We use a verification flow similar to Saudi Visa Bio for maximum safety. Takes about 10 minutes.',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxl),

              // Steps
              _VerificationStep(
                icon: Icons.credit_card,
                title: 'Scan your ID',
                subtitle: 'CNIC or Student card',
                number: 1,
              ),

              const SizedBox(height: Spacing.lg),

              _VerificationStep(
                icon: Icons.face,
                title: 'Face liveness check',
                subtitle: 'Blink and head movement',
                number: 2,
              ),

              const SizedBox(height: Spacing.lg),

              _VerificationStep(
                icon: Icons.fingerprint,
                title: 'Fingerprint capture',
                subtitle: 'Camera capture of both hands',
                number: 3,
              ),

              const Spacer(),

              // Start button
              ElevatedButton(
                onPressed: () {
                  print('Start Verification button clicked');
                  if (currentUser != null) {
                    print('Current user: ${currentUser.id}');

                    // Set status to in progress (background)
                    final verificationService = VerificationService();
                    print('Setting verification status...');
                    verificationService.setVerificationStatus(
                      currentUser.id,
                      VerificationStatus.inProgress,
                    );

                    // Navigate to ID scan immediately
                    print('Navigating to /verification/id-scan');
                    context.push('/verification/id-scan');
                  } else {
                    print('Current user is null!');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  backgroundColor: AppColors.primaryDark,
                ),
                child: const Text(
                  'Start Verification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: Spacing.md),

              // Cancel button
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int number;

  const _VerificationStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Number badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: Spacing.md),

        // Icon
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 32),
        ),

        const SizedBox(width: Spacing.md),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(context, weight: FontWeight.bold),
              ),
              Text(subtitle, style: AppTypography.labelSmall(context)),
            ],
          ),
        ),
      ],
    );
  }
}

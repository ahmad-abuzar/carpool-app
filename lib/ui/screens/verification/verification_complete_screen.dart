import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class VerificationCompleteScreen extends ConsumerWidget {
  const VerificationCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(now);
    final formattedTime = DateFormat('hh:mm a').format(now);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Success icon
              Container(
                padding: const EdgeInsets.all(Spacing.xxl),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: Spacing.xxl),

              // Title
              Text(
                'You are now a Verified User',
                style: AppTypography.display(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.md),

              // Subtitle
              Text(
                'Your identity has been successfully verified',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxl),

              // Verification summary
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _VerificationItem(
                      icon: Icons.credit_card,
                      label: 'ID Verified',
                    ),
                    const Divider(height: Spacing.lg),
                    _VerificationItem(icon: Icons.face, label: 'Face Verified'),
                    const Divider(height: Spacing.lg),
                    _VerificationItem(
                      icon: Icons.fingerprint,
                      label: 'Fingerprints Verified',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Spacing.lg),

              // Verification date/time
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          formattedDate,
                          style: AppTypography.labelSmall(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          formattedTime,
                          style: AppTypography.labelSmall(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Back to profile button
              ElevatedButton(
                onPressed: () {
                  // Navigate back to profile, clearing the verification flow
                  context.go('/profile');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  backgroundColor: AppColors.primaryDark,
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _VerificationItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(Spacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.success, size: 24),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body(context, weight: FontWeight.bold),
          ),
        ),
        const Icon(Icons.check_circle, color: AppColors.success, size: 24),
      ],
    );
  }
}

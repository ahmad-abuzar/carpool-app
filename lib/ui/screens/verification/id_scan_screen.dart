import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/cnic_data.dart';
import '../../../ui/theme/color_palette.dart';
import '../../../ui/theme/spacing.dart';
import '../../../ui/theme/typography.dart';
import 'cnic_scan_screen.dart';
import 'cnic_confirmation_screen.dart';

/// ID Scan Screen - Entry point for CNIC verification
class IdScanScreen extends ConsumerWidget {
  const IdScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan CNIC'), centerTitle: true),
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
                  Icons.credit_card,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: Spacing.xxl),

              // Title
              Text(
                'Scan your CNIC',
                style: AppTypography.headline(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.md),

              // Subtitle
              Text(
                'We\'ll automatically extract your details using our smart scanner',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxl),

              // Instructions
              _InstructionStep(
                number: 1,
                title: 'Place CNIC flat',
                subtitle: 'On a dark surface with good lighting',
              ),

              const SizedBox(height: Spacing.lg),

              _InstructionStep(
                number: 2,
                title: 'Align with guide',
                subtitle: 'Position CNIC within the frame',
              ),

              const SizedBox(height: Spacing.lg),

              _InstructionStep(
                number: 3,
                title: 'Capture automatically',
                subtitle: 'Scanner will detect and capture',
              ),

              const Spacer(),

              // Start Scan Button
              ElevatedButton.icon(
                onPressed: () async {
                  // Open CNIC scanner
                  final cnicData = await Navigator.push<CnicData>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CnicScanScreen(),
                    ),
                  );

                  if (cnicData != null && context.mounted) {
                    // Show confirmation screen
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CnicConfirmationScreen(cnicData: cnicData),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.camera_alt, size: 24),
                label: const Text(
                  'Start Scanning',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  backgroundColor: AppColors.primaryDark,
                ),
              ),

              const SizedBox(height: Spacing.md),

              // Skip button (for testing)
              TextButton(
                onPressed: () => context.push('/verification/face'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;

  const _InstructionStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Number circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.secondaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: Spacing.md),

        // Text
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
    );
  }
}

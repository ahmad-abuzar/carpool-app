import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../theme/color_palette.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class DriverCard extends StatelessWidget {
  final User driver;
  final String? vehicleInfo;

  const DriverCard({super.key, required this.driver, this.vehicleInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    driver.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            driver.name,
                            style: AppTypography.body(
                              context,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: Spacing.xs),
                          if (driver.idVerified)
                            const Icon(
                              Icons.verified,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            driver.rating.toStringAsFixed(1),
                            style: AppTypography.bodySmall(
                              context,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            '${driver.totalRidesAsDriver} rides',
                            style: AppTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (vehicleInfo != null) ...[
              const SizedBox(height: Spacing.lg),
              const Divider(),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 20),
                  const SizedBox(width: Spacing.md),
                  Text(vehicleInfo!, style: AppTypography.bodySmall(context)),
                ],
              ),
            ],

            // Verification badges
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                if (driver.phoneVerified)
                  _VerificationBadge(icon: Icons.phone, label: 'Phone'),
                if (driver.emailVerified)
                  _VerificationBadge(icon: Icons.email, label: 'Email'),
                if (driver.idVerified)
                  _VerificationBadge(icon: Icons.badge, label: 'ID'),
                if (driver.vehicleVerified)
                  _VerificationBadge(
                    icon: Icons.directions_car,
                    label: 'Vehicle',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _VerificationBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14, color: AppColors.success),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12),
      backgroundColor: AppColors.success.withOpacity(0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

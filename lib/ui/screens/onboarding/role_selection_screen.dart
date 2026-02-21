import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/user.dart';
import '../../../state/auth_provider.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Spacing.xxxl),

              Text(
                'How do you want to use the app?',
                style: AppTypography.headline(context),
              ),

              const SizedBox(height: Spacing.md),

              Text(
                'You can change this later in settings',
                style: AppTypography.bodySmall(context),
              ),

              const SizedBox(height: Spacing.xxxl),

              // Passenger option
              _RoleCard(
                icon: Icons.person,
                title: 'I\'m a Passenger',
                subtitle: 'Find affordable rides for your daily commute',
                isSelected: _selectedRole == UserRole.passenger,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.passenger;
                  });
                },
              ),

              const SizedBox(height: Spacing.lg),

              // Driver option
              _RoleCard(
                icon: Icons.directions_car,
                title: 'I\'m a Driver',
                subtitle: 'Share your ride and earn money',
                isSelected: _selectedRole == UserRole.driver,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.driver;
                  });
                },
              ),

              const SizedBox(height: Spacing.lg),

              // Both option
              _RoleCard(
                icon: Icons.swap_horiz,
                title: 'Both',
                subtitle: 'Sometimes drive, sometimes ride',
                isSelected: _selectedRole == UserRole.both,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.both;
                  });
                },
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedRole == null
                      ? null
                      : () {
                          context.go('/welcome');
                        },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.dividerLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
          color: isSelected
              ? AppColors.primaryContainer
              : Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(Spacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                size: 28,
              ),
            ),
            const SizedBox(width: Spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body(context, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(subtitle, style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}

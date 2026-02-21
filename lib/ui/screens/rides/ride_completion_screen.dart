import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/ride.dart';
import '../../../state/providers.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class RideCompletionScreen extends ConsumerWidget {
  final Ride ride;

  const RideCompletionScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isDriver = currentUser?.id == ride.driver.id;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // ── Success Icon ──
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, size: 60, color: Colors.white),
              ),

              const SizedBox(height: Spacing.xxl),

              Text(
                'Ride Completed!',
                style: AppTypography.display(context, color: AppColors.success),
              ),

              const SizedBox(height: Spacing.sm),

              Text(
                isDriver
                    ? 'Your passengers have been dropped off safely'
                    : 'You\'ve arrived at your destination',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxxl),

              // ── Trip Summary Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.xl),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Spacing.radiusLg),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Summary',
                      style: AppTypography.body(
                        context,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Route
                    Row(
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 10,
                              color: AppColors.success,
                            ),
                            Container(
                              width: 2,
                              height: 24,
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.error,
                            ),
                          ],
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.origin.address,
                                style: AppTypography.bodySmall(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Spacing.lg),
                              Text(
                                ride.destination.address,
                                style: AppTypography.bodySmall(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Spacing.lg),
                    const Divider(),
                    const SizedBox(height: Spacing.md),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: ride.distanceKm != null
                              ? '${ride.distanceKm!.toStringAsFixed(1)} km'
                              : '— km',
                        ),
                        _SummaryItem(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: ride.durationMinutes != null
                              ? '${ride.durationMinutes} min'
                              : '— min',
                        ),
                        _SummaryItem(
                          icon: Icons.payments_outlined,
                          label: isDriver ? 'Earned' : 'Fare',
                          value: 'Rs ${ride.pricePerSeat.toStringAsFixed(0)}',
                        ),
                      ],
                    ),

                    if (isDriver && ride.passengers.isNotEmpty) ...[
                      const SizedBox(height: Spacing.md),
                      const Divider(),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Passengers: ${ride.passengers.length}',
                        style: AppTypography.bodySmall(context),
                      ),
                      Text(
                        'Total earned: Rs ${(ride.pricePerSeat * ride.passengers.length).toStringAsFixed(0)}',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Actions ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to rating screen
                    final ratedUserId = isDriver
                        ? (ride.passengers.isNotEmpty
                              ? ride.passengers.first.id
                              : '')
                        : ride.driver.id;

                    if (ratedUserId.isNotEmpty) {
                      context.push(
                        '/rating/${ride.id}',
                        extra: {
                          'isDriver': isDriver,
                          'ratedUserId': ratedUserId,
                        },
                      );
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.star, size: 24),
                  label: Text(
                    'Rate ${isDriver ? "Passenger" : "Driver"}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusMd),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: Spacing.md),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Go to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDark),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.bodySmall(context)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body(context, weight: FontWeight.bold),
        ),
      ],
    );
  }
}

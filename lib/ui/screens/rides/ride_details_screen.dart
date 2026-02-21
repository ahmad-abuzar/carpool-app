import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../models/user.dart';
import '../../../state/auth_provider.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/driver_card.dart';
import '../../widgets/route_map_widget.dart';

class RideDetailsScreen extends ConsumerWidget {
  final Ride ride;

  const RideDetailsScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    // Check if user can book (female-only eligibility)
    final canBook = !ride.femaleOnly || (currentUser?.gender == Gender.female);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Stub: Share ride link
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share link copied!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map view showing route
            SizedBox(
              height: 200,
              child: RouteMapWidget(
                origin: ride.origin,
                destination: ride.destination,
                distanceKm: ride.distanceKm,
                durationMinutes: ride.durationMinutes,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: Spacing.md),
                      Text(
                        dateFormat.format(ride.departureTime),
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: Spacing.md),
                      Text(
                        '${timeFormat.format(ride.departureTime)} - ${timeFormat.format(ride.estimatedArrivalTime)}',
                        style: AppTypography.body(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: Spacing.xl),
                  const Divider(),
                  const SizedBox(height: Spacing.xl),

                  // Route
                  Text('Route', style: AppTypography.headlineSmall(context)),
                  const SizedBox(height: Spacing.lg),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: AppColors.dividerLight,
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: Spacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup',
                              style: AppTypography.labelSmall(context),
                            ),
                            Text(
                              ride.origin.address,
                              style: AppTypography.body(
                                context,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (ride.meetupInstructions != null) ...[
                              const SizedBox(height: Spacing.xs),
                              Text(
                                ride.meetupInstructions!,
                                style: AppTypography.bodySmall(context),
                              ),
                            ],
                            const SizedBox(height: Spacing.xl),
                            Text(
                              'Drop-off',
                              style: AppTypography.labelSmall(context),
                            ),
                            Text(
                              ride.destination.address,
                              style: AppTypography.body(
                                context,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Spacing.xl),
                  const Divider(),
                  const SizedBox(height: Spacing.xl),

                  // Driver Info
                  Text('Driver', style: AppTypography.headlineSmall(context)),
                  const SizedBox(height: Spacing.md),
                  DriverCard(
                    driver: ride.driver,
                    vehicleInfo:
                        '${ride.vehicle.model} • ${ride.vehicle.color} • ${ride.vehicle.plateNumber}',
                  ),

                  const SizedBox(height: Spacing.xl),
                  const Divider(),
                  const SizedBox(height: Spacing.xl),

                  // Ride Info
                  Text(
                    'Ride Information',
                    style: AppTypography.headlineSmall(context),
                  ),
                  const SizedBox(height: Spacing.lg),

                  _InfoRow(
                    icon: Icons.event_seat,
                    label: 'Available Seats',
                    value: '${ride.availableSeats} of ${ride.totalSeats}',
                  ),
                  _InfoRow(
                    icon: Icons.payments,
                    label: 'Price per Seat',
                    value: 'Rs. ${ride.pricePerSeat.toInt()}',
                  ),

                  const SizedBox(height: Spacing.xl),

                  // Rules and Preferences
                  if (ride.rules.isNotEmpty || ride.femaleOnly) ...[
                    const Divider(),
                    const SizedBox(height: Spacing.xl),
                    Text(
                      'Rules & Preferences',
                      style: AppTypography.headlineSmall(context),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        if (ride.femaleOnly)
                          Chip(
                            avatar: const Icon(Icons.female, size: 16),
                            label: const Text('Female Only'),
                            backgroundColor: AppColors.femaleOnlyLight,
                            labelStyle: const TextStyle(
                              color: AppColors.femaleOnly,
                            ),
                          ),
                        ...ride.rules.map((rule) => Chip(label: Text(rule))),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              // Message driver
              IconButton.outlined(
                onPressed: () {
                  context.push('/chat/${ride.driver.id}', extra: ride.id);
                },
                icon: const Icon(Icons.message),
                iconSize: 24,
                padding: const EdgeInsets.all(16),
              ),
              const SizedBox(width: Spacing.md),
              // Book button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: canBook && ride.availableSeats > 0
                      ? () {
                          context.push('/booking', extra: ride);
                        }
                      : null,
                  child: Text(
                    !canBook
                        ? 'Not Eligible'
                        : ride.availableSeats == 0
                        ? 'Fully Booked'
                        : 'Book Seat',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: Spacing.md),
          Text(label, style: AppTypography.bodySmall(context)),
          const Spacer(),
          Text(
            value,
            style: AppTypography.body(context, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

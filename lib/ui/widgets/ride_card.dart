import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/ride.dart';
import '../theme/color_palette.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;

  const RideCard({super.key, required this.ride, this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');

    return Card(
      key: ValueKey(
        'ride_card_${ride.id}',
      ), // Unique key to prevent Hero errors
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        onTap:
            onTap ??
            () {
              context.push('/ride-details/${ride.id}', extra: ride);
            },
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      ride.driver.name[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ride.driver.name,
                              style: AppTypography.body(
                                context,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: Spacing.xs),
                            if (ride.driver.idVerified)
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.primaryDark,
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              '${ride.driver.rating.toStringAsFixed(1)} • ${ride.driver.totalRidesAsDriver} rides',
                              style: AppTypography.labelSmall(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs ${ride.pricePerSeat.toInt()}',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'per seat',
                        style: AppTypography.labelSmall(context),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: Spacing.lg),

              // Route
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 24,
                        color: AppColors.dividerLight,
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryDark,
                          shape: BoxShape.circle,
                        ),
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
                          style: AppTypography.body(
                            context,
                            weight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xl),
                        Text(
                          ride.destination.address,
                          style: AppTypography.body(
                            context,
                            weight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacing.lg),

              // Time and details
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${dateFormat.format(ride.departureTime)} • ${timeFormat.format(ride.departureTime)}',
                    style: AppTypography.bodySmall(context),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.event_seat,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${ride.availableSeats}/${ride.totalSeats} seats',
                    style: AppTypography.bodySmall(context),
                  ),
                ],
              ),

              // Badges
              if (ride.femaleOnly || ride.rules.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.md),
                  child: Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      if (ride.femaleOnly)
                        Chip(
                          label: const Text('Female Only'),
                          avatar: const Icon(Icons.female, size: 16),
                          backgroundColor: AppColors.femaleOnlyLight,
                          labelStyle: const TextStyle(
                            color: AppColors.femaleOnly,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ...ride.rules
                          .take(2)
                          .map(
                            (rule) => Chip(
                              label: Text(rule),
                              labelStyle: const TextStyle(fontSize: 12),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

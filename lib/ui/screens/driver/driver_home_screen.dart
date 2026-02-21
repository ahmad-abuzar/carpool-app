import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../../state/providers.dart';
import '../../../models/user.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final allRides = ref.watch(ridesProvider);

    // Filter rides where current user is the driver
    final myRides = allRides
        .where((ride) => ride.driver.id == currentUser?.id)
        .toList();

    // Active rides: scheduled, driverEnRoute, inProgress
    final upcomingRides = myRides
        .where(
          (ride) =>
              ride.status == RideStatus.scheduled ||
              ride.status == RideStatus.driverEnRoute ||
              ride.status == RideStatus.inProgress,
        )
        .toList();

    // Past rides: completed or cancelled
    final pastRides = myRides
        .where(
          (ride) =>
              ride.status == RideStatus.completed ||
              ride.status == RideStatus.cancelled,
        )
        .toList();

    final isDriver =
        currentUser?.role == UserRole.driver ||
        currentUser?.role == UserRole.both;

    if (!isDriver) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Rides')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_outlined, size: 64),
              const SizedBox(height: Spacing.lg),
              Text(
                'Driver Mode Not Enabled',
                style: AppTypography.body(context, weight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Enable driver mode in settings',
                style: AppTypography.bodySmall(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Post a Ride',
            onPressed: () => context.push('/post-ride'),
          ),
        ],
      ),
      body: upcomingRides.isEmpty && pastRides.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'No rides posted yet',
                    style: AppTypography.body(context, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Post your first ride to start earning',
                    style: AppTypography.bodySmall(context),
                  ),
                  const SizedBox(height: Spacing.xl),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/post-ride'),
                    icon: const Icon(Icons.add),
                    label: const Text('Post a Ride'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: [
                if (upcomingRides.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Rides',
                        style: AppTypography.headlineSmall(context),
                      ),
                      Text(
                        '${upcomingRides.length}',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  ...upcomingRides.map((ride) => _DriverRideCard(ride: ride)),
                  const SizedBox(height: Spacing.xl),
                ],

                if (pastRides.isNotEmpty) ...[
                  Text(
                    'Past Rides',
                    style: AppTypography.headlineSmall(context),
                  ),
                  const SizedBox(height: Spacing.md),
                  ...pastRides
                      .take(3)
                      .map((ride) => _DriverRideCard(ride: ride, isPast: true)),
                ],
              ],
            ),
    );
  }
}

class _DriverRideCard extends StatefulWidget {
  final Ride ride;
  final bool isPast;

  const _DriverRideCard({required this.ride, this.isPast = false});

  @override
  State<_DriverRideCard> createState() => _DriverRideCardState();
}

class _DriverRideCardState extends State<_DriverRideCard> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isPast = widget.isPast;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        onTap: () {
          if (isPast) {
            context.push('/ride-details/${ride.id}', extra: ride);
          } else {
            context.push('/upcoming-trip/${ride.id}', extra: ride);
          }
        },
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride.origin.address} → ${ride.destination.address}',
                          style: AppTypography.body(
                            context,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          '${dateFormat.format(ride.departureTime)} • ${timeFormat.format(ride.departureTime)}',
                          style: AppTypography.bodySmall(context),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${(ride.pricePerSeat * ride.bookedSeats).toInt()}',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'earnings',
                        style: AppTypography.labelSmall(context),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: Spacing.md),

              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${ride.bookedSeats}/${ride.totalSeats} seats booked',
                    style: AppTypography.bodySmall(context),
                  ),
                  const Spacer(),
                  if (!isPast)
                    TextButton(
                      onPressed: () {
                        context.push('/upcoming-trip/${ride.id}', extra: ride);
                      },
                      child: const Text('View Details'),
                    ),
                ],
              ),

              if (!isPast) ...[
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            '/upcoming-trip/${ride.id}',
                            extra: ride,
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isStarting
                            ? null
                            : () async {
                                setState(() => _isStarting = true);
                                try {
                                  // Navigate FIRST before the stream update
                                  // removes the ride from the list
                                  context.push(
                                    '/live-trip/${ride.id}',
                                    extra: ride,
                                  );
                                  // Then update status (fire-and-forget)
                                  RideService().updateRideStatus(
                                    ride.id,
                                    RideStatus.inProgress,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() => _isStarting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: _isStarting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow, size: 18),
                        label: Text(_isStarting ? 'Starting...' : 'Start Trip'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

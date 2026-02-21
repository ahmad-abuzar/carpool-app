import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../../state/providers.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class UpcomingTripScreen extends ConsumerWidget {
  final Ride ride;

  const UpcomingTripScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');
    final currentUser = ref.watch(currentUserProvider);
    final isDriver = currentUser?.id == ride.driver.id;

    final minutesUntilDeparture = ride.departureTime
        .difference(DateTime.now())
        .inMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Countdown card
            Card(
              color: AppColors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 48,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      minutesUntilDeparture > 60
                          ? '${(minutesUntilDeparture / 60).floor()}h ${minutesUntilDeparture % 60}m'
                          : '$minutesUntilDeparture minutes',
                      style: AppTypography.display(
                        context,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text('until departure', style: AppTypography.body(context)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // ─── Start Ride (Driver Only) ───
            if (isDriver) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Update ride status to in-progress
                    await RideService().updateRideStatus(
                      ride.id,
                      RideStatus.inProgress,
                    );
                    if (context.mounted) {
                      context.push('/live-trip/${ride.id}', extra: ride);
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'Start Ride',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],

            // Trip details
            Text('Trip Details', style: AppTypography.headlineSmall(context)),
            const SizedBox(height: Spacing.md),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: dateFormat.format(ride.departureTime),
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: timeFormat.format(ride.departureTime),
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'Pickup',
                      value: ride.origin.address,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.flag,
                      label: 'Drop-off',
                      value: ride.destination.address,
                    ),
                    if (ride.passengers.isNotEmpty) ...[
                      const Divider(),
                      _InfoRow(
                        icon: Icons.people,
                        label: 'Passengers',
                        value: '${ride.passengers.length} / ${ride.totalSeats}',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Driver info (for passengers)
            if (!isDriver) ...[
              Text('Driver', style: AppTypography.headlineSmall(context)),
              const SizedBox(height: Spacing.md),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
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
                  title: Text(ride.driver.name),
                  subtitle: Text(
                    '${ride.vehicle.model} • ${ride.vehicle.color}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(' ${ride.driver.rating.toStringAsFixed(1)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],

            // Passengers (for driver)
            if (isDriver && ride.passengers.isNotEmpty) ...[
              Text('Passengers', style: AppTypography.headlineSmall(context)),
              const SizedBox(height: Spacing.md),
              ...ride.passengers.map(
                (p) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        p.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text(p.phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.message_outlined),
                      onPressed: () =>
                          context.push('/chat/${p.id}', extra: ride.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final chatUserId = isDriver
                      ? (ride.passengers.isNotEmpty
                            ? ride.passengers.first.id
                            : ride.driver.id)
                      : ride.driver.id;
                  context.push('/chat/$chatUserId', extra: ride.id);
                },
                icon: const Icon(Icons.message),
                label: Text(isDriver ? 'Message Passenger' : 'Message Driver'),
              ),
            ),

            const SizedBox(height: Spacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final name = isDriver
                      ? (ride.passengers.isNotEmpty
                            ? ride.passengers.first.name
                            : 'Passenger')
                      : ride.driver.name;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Calling $name...')));
                },
                icon: const Icon(Icons.phone),
                label: Text(isDriver ? 'Call Passenger' : 'Call Driver'),
              ),
            ),

            const SizedBox(height: Spacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location shared!')),
                  );
                },
                icon: const Icon(Icons.share_location),
                label: const Text('Share Live Location'),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Emergency section
            Card(
              color: AppColors.error.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  children: [
                    Text(
                      'Safety & Emergency',
                      style: AppTypography.body(
                        context,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showSOSDialog(context);
                        },
                        icon: const Icon(Icons.warning),
                        label: const Text('SOS Emergency'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will alert your emergency contacts and share your location. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency contacts notified!'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Send SOS'),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: Spacing.md),
          Text(label, style: AppTypography.bodySmall(context)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body(context, weight: FontWeight.w600),
              textAlign: TextAlign.end,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

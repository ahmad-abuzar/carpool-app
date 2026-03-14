import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/ride.dart';
import '../../../state/providers.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final rides = ref.watch(ridesProvider);
    final ridesById = {for (final ride in rides) ride.id: ride};
    final now = DateTime.now();

    final grouped = bookingsAsync.maybeWhen(
      data: (bookings) {
        final upcoming = <Booking>[];
        final completed = <Booking>[];
        final cancelled = <Booking>[];

        for (final booking in bookings) {
          final liveRide = ridesById[booking.rideId] ?? booking.ride;

          final isCancelled =
              booking.status == BookingStatus.cancelled ||
              liveRide.status == RideStatus.cancelled;
          if (isCancelled) {
            cancelled.add(_copyWithRide(booking, liveRide));
            continue;
          }

          final isCompleted =
              booking.status == BookingStatus.completed ||
              liveRide.status == RideStatus.completed ||
              liveRide.departureTime.isBefore(now);
          if (isCompleted) {
            completed.add(_copyWithRide(booking, liveRide));
            continue;
          }

          final isUpcoming =
              (booking.status == BookingStatus.pending ||
                  booking.status == BookingStatus.confirmed) &&
              (liveRide.departureTime.isAfter(now) ||
                  liveRide.status == RideStatus.driverEnRoute ||
                  liveRide.status == RideStatus.inProgress);

          if (isUpcoming) {
            upcoming.add(_copyWithRide(booking, liveRide));
          }
        }

        upcoming.sort(
          (a, b) => a.ride.departureTime.compareTo(b.ride.departureTime),
        );
        completed.sort(
          (a, b) => b.ride.departureTime.compareTo(a.ride.departureTime),
        );
        cancelled.sort(
          (a, b) => b.ride.departureTime.compareTo(a.ride.departureTime),
        );

        return _RideHistoryGroups(
          upcoming: upcoming,
          completed: completed,
          cancelled: cancelled,
        );
      },
      orElse: _RideHistoryGroups.empty,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ride History'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming (${grouped.upcoming.length})'),
              Tab(text: 'Completed (${grouped.completed.length})'),
              Tab(text: 'Cancelled (${grouped.cancelled.length})'),
            ],
          ),
        ),
        body: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _HistoryErrorState(
            error: error,
            onRetry: () => ref.invalidate(userBookingsProvider),
          ),
          data: (_) => TabBarView(
            children: [
              _HistoryList(
                bookings: grouped.upcoming,
                emptyTitle: 'No upcoming rides',
                emptySubtitle: 'Booked rides will appear here',
                emptyIcon: Icons.event_available,
              ),
              _HistoryList(
                bookings: grouped.completed,
                emptyTitle: 'No completed rides',
                emptySubtitle: 'Completed trips will appear here',
                emptyIcon: Icons.check_circle_outline,
              ),
              _HistoryList(
                bookings: grouped.cancelled,
                emptyTitle: 'No cancelled rides',
                emptySubtitle: 'Cancelled bookings will appear here',
                emptyIcon: Icons.cancel_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Booking _copyWithRide(Booking booking, Ride ride) {
    return Booking(
      id: booking.id,
      rideId: booking.rideId,
      ride: ride,
      passenger: booking.passenger,
      seatsBooked: booking.seatsBooked,
      totalAmount: booking.totalAmount,
      status: booking.status,
      bookingTime: booking.bookingTime,
      cancellationReason: booking.cancellationReason,
    );
  }
}

class _RideHistoryGroups {
  final List<Booking> upcoming;
  final List<Booking> completed;
  final List<Booking> cancelled;

  const _RideHistoryGroups({
    required this.upcoming,
    required this.completed,
    required this.cancelled,
  });

  factory _RideHistoryGroups.empty() {
    return const _RideHistoryGroups(upcoming: [], completed: [], cancelled: []);
  }
}

class _HistoryList extends ConsumerWidget {
  final List<Booking> bookings;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  const _HistoryList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userBookingsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      },
      child: bookings.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.xl),
              children: [
                const SizedBox(height: Spacing.xxxl),
                Icon(
                  emptyIcon,
                  size: 56,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(height: Spacing.lg),
                Center(
                  child: Text(
                    emptyTitle,
                    style: AppTypography.body(context, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Center(
                  child: Text(
                    emptySubtitle,
                    style: AppTypography.bodySmall(context),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return _HistoryRideCard(booking: bookings[index]);
              },
            ),
    );
  }
}

class _HistoryRideCard extends StatelessWidget {
  final Booking booking;

  const _HistoryRideCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final ride = booking.ride;
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        onTap: () {
          final isPast =
              booking.status == BookingStatus.completed ||
              booking.status == BookingStatus.cancelled ||
              ride.status == RideStatus.completed ||
              ride.status == RideStatus.cancelled ||
              ride.departureTime.isBefore(DateTime.now());

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
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '${dateFormat.format(ride.departureTime)} • ${timeFormat.format(ride.departureTime)}',
                    style: AppTypography.bodySmall(context),
                  ),
                  const Spacer(),
                  _BookingStatusChip(booking: booking),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(
                '${ride.origin.address} → ${ride.destination.address}',
                style: AppTypography.body(context, weight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''}',
                    style: AppTypography.bodySmall(context),
                  ),
                  const Spacer(),
                  Text(
                    'Rs ${booking.totalAmount.toStringAsFixed(0)}',
                    style: AppTypography.body(
                      context,
                      weight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              if (booking.cancellationReason != null &&
                  booking.cancellationReason!.trim().isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  'Reason: ${booking.cancellationReason}',
                  style: AppTypography.labelSmall(
                    context,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingStatusChip extends StatelessWidget {
  final Booking booking;

  const _BookingStatusChip({required this.booking});

  @override
  Widget build(BuildContext context) {
    final ride = booking.ride;

    Color color = AppColors.info;
    String label = 'Upcoming';

    if (booking.status == BookingStatus.cancelled ||
        ride.status == RideStatus.cancelled) {
      color = AppColors.error;
      label = 'Cancelled';
    } else if (booking.status == BookingStatus.completed ||
        ride.status == RideStatus.completed ||
        ride.departureTime.isBefore(DateTime.now())) {
      color = AppColors.success;
      label = 'Completed';
    } else if (ride.status == RideStatus.inProgress) {
      color = AppColors.warning;
      label = 'In Progress';
    } else if (booking.status == BookingStatus.pending) {
      color = AppColors.warning;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(context, color: color),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _HistoryErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: Spacing.md),
            Text('Could not load ride history', style: AppTypography.body(context)),
            const SizedBox(height: Spacing.xs),
            Text(
              error.toString(),
              style: AppTypography.bodySmall(context),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

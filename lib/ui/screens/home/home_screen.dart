import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../models/ride.dart';
import '../../../state/providers.dart';

import '../../../models/user.dart';
import '../../../models/notification.dart';
import '../../../models/booking.dart';
import '../../../state/notification_provider.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

import '../../widgets/ride_card.dart';

final homeRefreshTickerProvider = StreamProvider.autoDispose<int>((ref) {
  // Force a lightweight rebuild so time-based ride filtering stays current.
  return Stream<int>.periodic(const Duration(seconds: 30), (tick) => tick);
});

final liveLocationProvider = StreamProvider.autoDispose<String?>((ref) async* {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    yield null;
    return;
  }

  if (!user.locationSharingEnabled) {
    yield user.homeAddress;
    return;
  }

  // Emit immediately on app open, then refresh every 2 minutes.
  yield await _resolveLiveLocation(user);
  yield* Stream.periodic(
    const Duration(minutes: 2),
  ).asyncMap((_) => _resolveLiveLocation(user));
});

Future<String?> _resolveLiveLocation(User user) async {
  try {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) return user.homeAddress;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return user.homeAddress;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final parts = [
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  } catch (_) {
    return user.homeAddress;
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeRefreshTickerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final currentUser = ref.watch(currentUserProvider);
    final liveLocationAsync = ref.watch(liveLocationProvider);
    final rides = ref.watch(ridesProvider);
    final unreadNotifications = ref.watch(unreadNotificationCountProvider).maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    // Auto-suggested rides (nearby/matching preferences)
    final now = DateTime.now();
    final twoHoursAgo = now.subtract(const Duration(hours: 2));

    final suggestedRides = rides
        .where((ride) {
          // Only show scheduled rides to passengers
          if (ride.status != RideStatus.scheduled) return false;
          // Don't show user's own rides in suggestions
          if (currentUser != null && ride.driver.id == currentUser.id) {
            return false;
          }
          if (currentUser?.preferFemaleOnlyRides == true && !ride.femaleOnly) {
            return false;
          }
          // Show rides from the past 2 hours (more lenient for testing)
          return ride.availableSeats > 0 &&
              ride.departureTime.isAfter(twoHoursAgo);
        })
        .take(5)
        .toList();

    // Next upcoming ride (if any bookings)
    final bookingsAsync = ref.watch(userBookingsProvider);
    final ridesById = {for (final ride in rides) ride.id: ride};
    final upcomingBookings = bookingsAsync.maybeWhen(
      data: (bookings) {
        final upcoming =
            bookings.where((b) {
              final liveRide = ridesById[b.rideId] ?? b.ride;
              final hasActiveBookingStatus =
                  b.status == BookingStatus.pending ||
                  b.status == BookingStatus.confirmed;
              final hasActiveRideStatus =
                  liveRide.status != RideStatus.completed &&
                  liveRide.status != RideStatus.cancelled;
              final isUpcomingOrOngoing =
                  liveRide.departureTime.isAfter(now) ||
                  liveRide.status == RideStatus.driverEnRoute ||
                  liveRide.status == RideStatus.inProgress;

              return hasActiveBookingStatus &&
                  hasActiveRideStatus &&
                  isUpcomingOrOngoing;
            }).toList()..sort(
              (a, b) {
                final aRide = ridesById[a.rideId] ?? a.ride;
                final bRide = ridesById[b.rideId] ?? b.ride;
                return aRide.departureTime.compareTo(bRide.departureTime);
              },
            );
        return upcoming;
      },
      orElse: () => <Booking>[],
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      endDrawer: const _NotificationSidebar(),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  backgroundImage:
                      (currentUser?.profileImageUrl ?? currentUser?.avatarUrl) !=
                          null
                      ? NetworkImage(
                          currentUser!.profileImageUrl ?? currentUser.avatarUrl!,
                        )
                      : null,
                  child:
                      (currentUser?.profileImageUrl ?? currentUser?.avatarUrl) ==
                          null
                      ? Text(
                          currentUser?.name[0].toUpperCase() ?? 'U',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${currentUser?.name.split(' ').first ?? 'User'}!',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              liveLocationAsync.maybeWhen(
                                data: (value) =>
                                    value?.trim().isNotEmpty == true
                                    ? value!
                                    : (currentUser?.homeAddress ?? 'Location unavailable'),
                                loading: () => 'Fetching live location...',
                                orElse: () =>
                                    currentUser?.homeAddress ?? 'Location unavailable',
                              ),
                              style: AppTypography.labelSmall(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.menu_open),
                      if (unreadNotifications > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Notifications',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(Spacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CurrentModeStatus(
                  currentRole: currentUser?.role ?? UserRole.passenger,
                ),

                const SizedBox(height: Spacing.lg),

                // Next Ride Card
                if (upcomingBookings.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Next Ride',
                        style: AppTypography.headlineSmall(context),
                      ),
                      TextButton(
                        onPressed: () => context.push('/ride-history'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  _NextRideCard(
                    booking: upcomingBookings.first,
                    ride:
                        ridesById[upcomingBookings.first.rideId] ??
                        upcomingBookings.first.ride,
                  ),
                  const SizedBox(height: Spacing.xl),
                ] else ...[
                  Card(
                    elevation: 0,
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusMd),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.directions_car_outlined,
                            size: 48,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'No upcoming rides',
                            style: AppTypography.body(
                              context,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Search for rides below',
                            style: AppTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                ],

                // Suggested Rides
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Suggested Rides Near You',
                      style: AppTypography.headlineSmall(context),
                    ),
                    TextButton(
                      onPressed: () => context.push('/ride-search'),
                      child: const Text('See All'),
                    ),
                  ],
                ),

                const SizedBox(height: Spacing.md),

                // Rides List
                if (suggestedRides.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'No rides available',
                            style: AppTypography.body(context),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...suggestedRides.map((ride) => RideCard(ride: ride)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

}

class _CurrentModeStatus extends StatelessWidget {
  final UserRole currentRole;

  const _CurrentModeStatus({required this.currentRole});

  @override
  Widget build(BuildContext context) {
    final isDriver =
        currentRole == UserRole.driver || currentRole == UserRole.both;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            isDriver ? Icons.directions_car : Icons.person,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Current Mode: ${isDriver ? 'Driver' : 'Passenger'}',
            style: AppTypography.body(context, weight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            'Profile > Switch',
            style: AppTypography.labelSmall(context),
          ),
        ],
      ),
    );
  }
}

class _NotificationSidebar extends ConsumerWidget {
  const _NotificationSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: AppTypography.headlineSmall(context),
                  ),
                  TextButton(
                    onPressed: () {
                      if (currentUser != null) {
                        notificationService.markAllAsRead(currentUser.id);
                      }
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Text(
                      'Failed to load notifications\n$error',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(context),
                    ),
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Text(
                        'No notifications yet',
                        style: AppTypography.body(context),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notif.read
                              ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                              : Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            _getNotificationIcon(notif.type),
                            color: notif.read
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notif.message),
                        trailing: Text(
                          _formatTime(notif.timestamp),
                          style: AppTypography.labelSmall(context),
                        ),
                        onTap: () {
                          notificationService.markAsRead(notif.id);
                          if (notif.rideId != null) {
                            context.pop();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
        return Icons.check_circle;
      case NotificationType.bookingCancelled:
        return Icons.cancel;
      case NotificationType.rideStarting:
        return Icons.directions_car;
      case NotificationType.driverArriving:
        return Icons.location_on;
      case NotificationType.rideCompleted:
        return Icons.flag;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.incomingCall:
        return Icons.call;
      case NotificationType.ratingRequest:
        return Icons.star;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

// ─── Mode Switcher Widget ───
class _NextRideCard extends StatelessWidget {
  final Booking booking;
  final Ride ride;

  const _NextRideCard({required this.booking, required this.ride});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          context.push('/upcoming-trip/${ride.id}', extra: ride);
        },
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: colorScheme.primary),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '${dateFormat.format(ride.departureTime)} • ${timeFormat.format(ride.departureTime)}',
                    style: AppTypography.body(
                      context,
                      weight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      '${ride.origin.address} → ${ride.destination.address}',
                      style: AppTypography.bodySmall(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      ride.driver.name[0],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    ride.driver.name,
                    style: AppTypography.bodySmall(context),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

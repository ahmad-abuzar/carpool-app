import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../state/providers.dart';

import '../../../models/user.dart';
import '../../../models/notification.dart';
import '../../../models/booking.dart';
import '../../../services/firestore_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/ai_chatbot_widget.dart';
import '../../widgets/ride_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final rides = ref.watch(ridesProvider);
    final unreadNotifications = ref
        .watch(notificationsProvider.notifier)
        .unreadCount;

    // Auto-suggested rides (nearby/matching preferences)
    final now = DateTime.now();
    final twoHoursAgo = now.subtract(const Duration(hours: 2));

    final suggestedRides = rides
        .where((ride) {
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
    final upcomingBookings = bookingsAsync.maybeWhen(
      data: (bookings) {
        print('🏠 HomeScreen: Total bookings received: ${bookings.length}');
        final upcoming =
            bookings.where((b) {
              final isUpcoming = b.ride.departureTime.isAfter(DateTime.now());
              print(
                '   - Booking ${b.id}: ${b.ride.departureTime} (upcoming: $isUpcoming, status: ${b.status.name})',
              );
              return isUpcoming;
            }).toList()..sort(
              (a, b) => a.ride.departureTime.compareTo(b.ride.departureTime),
            );
        print('🏠 HomeScreen: Filtered upcoming bookings: ${upcoming.length}');
        return upcoming;
      },
      orElse: () {
        print('🏠 HomeScreen: No booking data available');
        return <Booking>[];
      },
    );

    return Stack(
      children: [
        Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        currentUser?.name[0].toUpperCase() ?? 'U',
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
                          Text(
                            'Hello, ${currentUser?.name.split(' ').first ?? 'User'}!',
                            style: AppTypography.body(
                              context,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (currentUser?.homeAddress != null)
                            Text(
                              currentUser!.homeAddress!,
                              style: AppTypography.labelSmall(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Notifications
                  IconButton(
                    icon: Badge(
                      isLabelVisible: unreadNotifications > 0,
                      label: Text('$unreadNotifications'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () {
                      // Show notifications bottom sheet
                      _showNotifications(context, ref);
                    },
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(Spacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── Mode Switcher ───
                    _ModeSwitcher(
                      currentRole: currentUser?.role ?? UserRole.passenger,
                      onModeChanged: (role) {
                        if (currentUser != null) {
                          final updated = currentUser.copyWith(role: role);
                          ref.read(authProvider.notifier).updateUser(updated);
                          // Persist to Firestore
                          FirestoreService().updateDocument(
                            collection: 'users',
                            docId: currentUser.id,
                            data: {'role': role.name},
                          );
                        }
                      },
                    ),

                    const SizedBox(height: Spacing.lg),

                    // Search / Post Card (adapts to mode)
                    Card(
                      child: InkWell(
                        onTap: () => context.push(
                          (currentUser?.role == UserRole.driver)
                              ? '/post-ride'
                              : '/ride-search',
                        ),
                        borderRadius: BorderRadius.circular(Spacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    (currentUser?.role == UserRole.driver)
                                        ? Icons.add_circle_outline
                                        : Icons.search,
                                    size: 28,
                                  ),
                                  const SizedBox(width: Spacing.md),
                                  Text(
                                    (currentUser?.role == UserRole.driver)
                                        ? 'Offer a Ride'
                                        : 'Where are you going?',
                                    style: AppTypography.body(
                                      context,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.lg),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _QuickFilterChip(
                                      label: 'Today',
                                      icon: Icons.today,
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    _QuickFilterChip(
                                      label: 'Tomorrow',
                                      icon: Icons.calendar_today,
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    if (currentUser?.gender == Gender.female)
                                      _QuickFilterChip(
                                        label: 'Female Only',
                                        icon: Icons.female,
                                        color: AppColors.femaleOnly,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: Spacing.xl),

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
                      _NextRideCard(booking: upcomingBookings.first),
                      const SizedBox(height: Spacing.xl),
                    ] else ...[
                      Card(
                        color: AppColors.primaryContainer,
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
        ),

        // AI Chatbot Widget - Floating assistant
        const AIChatbotWidget(),
      ],
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final notifications = ref.read(notificationsProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
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
                      ref.read(notificationsProvider.notifier).markAllAsRead();
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif.read
                          ? Theme.of(context).colorScheme.surfaceVariant
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
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(notif.id);
                      if (notif.rideId != null) {
                        // Navigate to ride details
                        context.pop();
                      }
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
class _ModeSwitcher extends StatelessWidget {
  final UserRole currentRole;
  final ValueChanged<UserRole> onModeChanged;

  const _ModeSwitcher({required this.currentRole, required this.onModeChanged});

  bool get _isDriver =>
      currentRole == UserRole.driver || currentRole == UserRole.both;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDriver
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color:
                (_isDriver ? const Color(0xFF2E7D32) : const Color(0xFF1565C0))
                    .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  _isDriver ? Icons.directions_car : Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  _isDriver ? 'Driver Mode' : 'Passenger Mode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isDriver ? 'ACTIVE' : 'ACTIVE',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Spacing.md),

            // Toggle buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  // Passenger button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onModeChanged(UserRole.passenger),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isDriver ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isDriver
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hail,
                              size: 18,
                              color: !_isDriver
                                  ? const Color(0xFF0D47A1)
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Passenger',
                              style: TextStyle(
                                color: !_isDriver
                                    ? const Color(0xFF0D47A1)
                                    : Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Driver button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onModeChanged(UserRole.driver),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isDriver ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isDriver
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 18,
                              color: _isDriver
                                  ? const Color(0xFF1B5E20)
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Driver',
                              style: TextStyle(
                                color: _isDriver
                                    ? const Color(0xFF1B5E20)
                                    : Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _QuickFilterChip({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color),
      onPressed: () {
        // Apply filter and navigate to search
        context.push('/ride-search');
      },
    );
  }
}

class _NextRideCard extends StatelessWidget {
  final dynamic booking;

  const _NextRideCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final ride = booking.ride;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');

    return Card(
      color: AppColors.primaryContainer,
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
                  const Icon(Icons.schedule, color: AppColors.primaryDark),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '${dateFormat.format(ride.departureTime)} • ${timeFormat.format(ride.departureTime)}',
                    style: AppTypography.body(
                      context,
                      weight: FontWeight.w600,
                      color: AppColors.primaryDark,
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
                    backgroundColor: AppColors.primaryDark,
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

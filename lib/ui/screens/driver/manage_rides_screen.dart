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

class ManageRidesScreen extends ConsumerStatefulWidget {
  const ManageRidesScreen({super.key});

  @override
  ConsumerState<ManageRidesScreen> createState() => _ManageRidesScreenState();
}

class _ManageRidesScreenState extends ConsumerState<ManageRidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Please log in'))
          : TabBarView(
              controller: _tabController,
              children: [
                _RideListTab(
                  driverId: currentUser.id,
                  type: _RideListType.upcoming,
                ),
                _RideListTab(
                  driverId: currentUser.id,
                  type: _RideListType.active,
                ),
                _RideListTab(
                  driverId: currentUser.id,
                  type: _RideListType.past,
                ),
              ],
            ),
    );
  }
}

enum _RideListType { upcoming, active, past }

class _RideListTab extends StatefulWidget {
  final String driverId;
  final _RideListType type;

  const _RideListTab({required this.driverId, required this.type});

  @override
  State<_RideListTab> createState() => _RideListTabState();
}

class _RideListTabState extends State<_RideListTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Ride>> _ridesFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  void _loadRides() {
    final rideService = RideService();
    switch (widget.type) {
      case _RideListType.upcoming:
        _ridesFuture = rideService.getUpcomingRidesForDriver(widget.driverId);
        break;
      case _RideListType.active:
        _ridesFuture = rideService
            .getRidesByDriver(widget.driverId)
            .then(
              (rides) => rides
                  .where(
                    (r) =>
                        r.status == RideStatus.inProgress ||
                        r.status == RideStatus.driverEnRoute,
                  )
                  .toList(),
            );
        break;
      case _RideListType.past:
        _ridesFuture = rideService.getPastRidesForDriver(widget.driverId);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Ride>>(
      future: _ridesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: Spacing.md),
                Text('Error loading rides', style: AppTypography.body(context)),
                const SizedBox(height: Spacing.md),
                OutlinedButton(
                  onPressed: () => setState(() => _loadRides()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final rides = snapshot.data ?? [];

        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _emptyIcon,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: Spacing.lg),
                Text(_emptyMessage, style: AppTypography.body(context)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadRides());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(Spacing.lg),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              return _DriverRideCard(ride: rides[index], type: widget.type);
            },
          ),
        );
      },
    );
  }

  IconData get _emptyIcon {
    switch (widget.type) {
      case _RideListType.upcoming:
        return Icons.event_available;
      case _RideListType.active:
        return Icons.directions_car;
      case _RideListType.past:
        return Icons.history;
    }
  }

  String get _emptyMessage {
    switch (widget.type) {
      case _RideListType.upcoming:
        return 'No upcoming rides';
      case _RideListType.active:
        return 'No active rides';
      case _RideListType.past:
        return 'No past rides';
    }
  }
}

class _DriverRideCard extends StatelessWidget {
  final Ride ride;
  final _RideListType type;

  const _DriverRideCard({required this.ride, required this.type});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        onTap: () {
          switch (type) {
            case _RideListType.upcoming:
              context.push('/upcoming-trip/${ride.id}', extra: ride);
              break;
            case _RideListType.active:
              context.push('/live-trip/${ride.id}', extra: ride);
              break;
            case _RideListType.past:
              context.push('/ride-details/${ride.id}', extra: ride);
              break;
          }
        },
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row — date + status chip
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    dateFormat.format(ride.departureTime),
                    style: AppTypography.bodySmall(context),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text('•', style: AppTypography.bodySmall(context)),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    timeFormat.format(ride.departureTime),
                    style: AppTypography.bodySmall(context),
                  ),
                  const Spacer(),
                  _StatusChip(status: ride.status),
                ],
              ),

              const SizedBox(height: Spacing.md),

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
                        height: 20,
                        color: AppColors.primaryDark.withValues(alpha: 0.3),
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
                          style: AppTypography.body(
                            context,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.md),
                        Text(
                          ride.destination.address,
                          style: AppTypography.body(
                            context,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacing.md),
              const Divider(),
              const SizedBox(height: Spacing.sm),

              // Bottom row — passengers + price
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '${ride.bookedSeats}/${ride.totalSeats} seats',
                    style: AppTypography.bodySmall(context),
                  ),
                  const Spacer(),
                  Text(
                    'Rs ${ride.pricePerSeat.toStringAsFixed(0)}/seat',
                    style: AppTypography.body(
                      context,
                      weight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RideStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case RideStatus.scheduled:
        color = AppColors.info;
        label = 'Scheduled';
        break;
      case RideStatus.driverEnRoute:
        color = Colors.orange;
        label = 'En Route';
        break;
      case RideStatus.inProgress:
        color = AppColors.success;
        label = 'In Progress';
        break;
      case RideStatus.completed:
        color = AppColors.primaryDark;
        label = 'Completed';
        break;
      case RideStatus.cancelled:
        color = AppColors.error;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../../services/booking_service.dart';
import '../../../state/providers.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class LiveTripScreen extends ConsumerStatefulWidget {
  final Ride ride;

  const LiveTripScreen({super.key, required this.ride});

  @override
  ConsumerState<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends ConsumerState<LiveTripScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isDriver = currentUser?.id == widget.ride.driver.id;
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder with animated gradient
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryContainer,
                      Color.lerp(
                        AppColors.primaryContainer,
                        AppColors.primaryDark,
                        _pulseController.value * 0.15,
                      )!,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.navigation,
                        size: 80 + (_pulseController.value * 10),
                        color: AppColors.primaryDark.withValues(
                          alpha: 0.6 + _pulseController.value * 0.4,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        'Live Tracking',
                        style: AppTypography.headline(
                          context,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        'Trip in progress...',
                        style: AppTypography.body(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + Spacing.md,
            left: Spacing.lg,
            right: Spacing.lg,
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(Spacing.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'In Progress',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // SOS button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _showSOSDialog(context),
                  ),
                ),
              ],
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.18,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Spacing.radiusXl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Spacing.xl),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: Spacing.lg),

                    // Route info
                    Row(
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 12,
                              color: AppColors.success,
                            ),
                            Container(
                              width: 2,
                              height: 30,
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              size: 16,
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
                                widget.ride.origin.address,
                                style: AppTypography.body(
                                  context,
                                  weight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Spacing.lg),
                              Text(
                                widget.ride.destination.address,
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

                    const SizedBox(height: Spacing.lg),
                    const Divider(),
                    const SizedBox(height: Spacing.md),

                    // ETA & fare
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatChip(
                          icon: Icons.access_time,
                          label: 'ETA',
                          value: timeFormat.format(
                            widget.ride.estimatedArrivalTime,
                          ),
                        ),
                        _StatChip(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: widget.ride.distanceKm != null
                              ? '${widget.ride.distanceKm!.toStringAsFixed(1)} km'
                              : '— km',
                        ),
                        _StatChip(
                          icon: Icons.payments_outlined,
                          label: 'Fare',
                          value:
                              'Rs ${widget.ride.pricePerSeat.toStringAsFixed(0)}',
                        ),
                      ],
                    ),

                    const SizedBox(height: Spacing.lg),
                    const Divider(),
                    const SizedBox(height: Spacing.md),

                    // People section
                    if (isDriver) ...[
                      Text(
                        'Passengers',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      if (widget.ride.passengers.isEmpty)
                        Text(
                          'No passengers yet',
                          style: AppTypography.bodySmall(context),
                        )
                      else
                        ...widget.ride.passengers.map(
                          (p) => ListTile(
                            contentPadding: EdgeInsets.zero,
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.message_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => context.push(
                                    '/chat/${p.id}',
                                    extra: widget.ride.id,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Calling ${p.name}...'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      Text(
                        'Driver',
                        style: AppTypography.body(
                          context,
                          weight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Text(
                            widget.ride.driver.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(widget.ride.driver.name),
                        subtitle: Text(
                          '${widget.ride.vehicle.model} • ${widget.ride.vehicle.plateNumber}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.message_outlined,
                                size: 20,
                              ),
                              onPressed: () => context.push(
                                '/chat/${widget.ride.driver.id}',
                                extra: widget.ride.id,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined, size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Calling ${widget.ride.driver.name}...',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: Spacing.xl),

                    // Complete Ride button (driver only)
                    if (isDriver)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isCompleting ? null : _completeRide,
                          icon: _isCompleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 28),
                          label: Text(
                            _isCompleting ? 'Completing...' : 'Complete Ride',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Spacing.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _completeRide() async {
    setState(() => _isCompleting = true);

    try {
      // 1. Update ride status to completed
      await RideService().updateRideStatus(
        widget.ride.id,
        RideStatus.completed,
      );

      // 2. Complete all bookings for this ride
      final bookings = await BookingService().getBookingsByRide(widget.ride.id);
      for (final booking in bookings) {
        await BookingService().completeBooking(booking.id);
      }

      if (mounted) {
        context.pushReplacement(
          '/ride-complete/${widget.ride.id}',
          extra: widget.ride,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing ride: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will alert your emergency contacts and share your location. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primaryDark),
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

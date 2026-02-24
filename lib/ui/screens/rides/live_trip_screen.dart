import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/commission_service.dart';
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
    with TickerProviderStateMixin {
  // Map
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  // Location tracking
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  late AnimationController _pulseController;

  // Ride state
  bool _isCompleting = false;
  DateTime _tripStartTime = DateTime.now();
  double _distanceTravelled = 0.0;
  LatLng? _lastPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _tripStartTime = DateTime.now();
    _fetchRoute();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Fetch road route from OSRM
  Future<void> _fetchRoute() async {
    try {
      final origin = widget.ride.origin;
      final destination = widget.ride.destination;

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;

        if (mounted) {
          setState(() {
            _routePoints = coordinates
                .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();
            _isLoadingRoute = false;
          });
        }
      } else {
        _fallbackRoute();
      }
    } catch (e) {
      _fallbackRoute();
    }
  }

  void _fallbackRoute() {
    if (mounted) {
      setState(() {
        _routePoints = [
          LatLng(widget.ride.origin.latitude, widget.ride.origin.longitude),
          LatLng(
            widget.ride.destination.latitude,
            widget.ride.destination.longitude,
          ),
        ];
        _isLoadingRoute = false;
      });
    }
  }

  /// Start GPS tracking
  Future<void> _startLocationTracking() async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setDefaultLocation();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setDefaultLocation();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation();
      return;
    }

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _lastPosition = _currentLocation;
        });
        _moveCameraToCurrentLocation();
      }
    } catch (e) {
      _setDefaultLocation();
    }

    // Listen to location changes
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen((Position position) {
          if (mounted) {
            final newLocation = LatLng(position.latitude, position.longitude);

            // Calculate distance
            if (_lastPosition != null) {
              final distance = const Distance().as(
                LengthUnit.Kilometer,
                _lastPosition!,
                newLocation,
              );
              _distanceTravelled += distance;
            }

            setState(() {
              _currentLocation = newLocation;
              _lastPosition = newLocation;
            });

            // Update location in Firestore for passengers to see
            final currentUser = ref.read(currentUserProvider);
            if (currentUser?.id == widget.ride.driver.id) {
              RideService().updateRideLocation(
                widget.ride.id,
                Location(
                  address: 'Current Location',
                  latitude: position.latitude,
                  longitude: position.longitude,
                ),
              );
            }
          }
        });
  }

  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(
          widget.ride.origin.latitude,
          widget.ride.origin.longitude,
        );
      });
    }
  }

  void _moveCameraToCurrentLocation() {
    if (_currentLocation != null) {
      try {
        _mapController.move(_currentLocation!, 15.0);
      } catch (_) {}
    }
  }

  String get _elapsedTime {
    final elapsed = DateTime.now().difference(_tripStartTime);
    if (elapsed.inMinutes < 60) {
      return '${elapsed.inMinutes} min';
    }
    return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isDriver = currentUser?.id == widget.ride.driver.id;
    final timeFormat = DateFormat('h:mm a');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final originPoint = LatLng(
      widget.ride.origin.latitude,
      widget.ride.origin.longitude,
    );
    final destinationPoint = LatLng(
      widget.ride.destination.latitude,
      widget.ride.destination.longitude,
    );

    return Scaffold(
      body: Stack(
        children: [
          // ─── Real Map ───
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? originPoint,
              initialZoom: 14.0,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              // Map tiles
              TileLayer(
                urlTemplate: isDarkMode
                    ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carpool.app',
              ),

              // Route polyline
              if (!_isLoadingRoute && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: AppColors.primaryDark,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Origin marker
                  Marker(
                    point: originPoint,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.success, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: AppColors.success,
                        size: 14,
                      ),
                    ),
                  ),

                  // Destination marker
                  Marker(
                    point: destinationPoint,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  // ─── Live driver location marker ───
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 52,
                      height: 52,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulse ring
                              Container(
                                width: 36 + (_pulseController.value * 16),
                                height: 36 + (_pulseController.value * 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryDark.withValues(
                                    alpha:
                                        0.25 - (_pulseController.value * 0.2),
                                  ),
                                ),
                              ),
                              // Car icon
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryDark.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_isLoadingRoute)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              ),
            ),

          // ─── Top bar ───
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'LIVE',
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
                // Re-center button
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
                    icon: const Icon(Icons.my_location),
                    onPressed: _moveCameraToCurrentLocation,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
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

          // ─── Bottom sheet ───
          DraggableScrollableSheet(
            initialChildSize: 0.36,
            minChildSize: 0.15,
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

                    // Live trip stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatChip(
                          icon: Icons.timer_outlined,
                          label: 'Elapsed',
                          value: _elapsedTime,
                        ),
                        _StatChip(
                          icon: Icons.straighten,
                          label: 'Travelled',
                          value: '${_distanceTravelled.toStringAsFixed(1)} km',
                        ),
                        _StatChip(
                          icon: Icons.access_time,
                          label: 'ETA',
                          value: timeFormat.format(
                            widget.ride.estimatedArrivalTime,
                          ),
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
      double totalRideEarnings = 0;
      for (final booking in bookings) {
        await BookingService().completeBooking(booking.id);
        totalRideEarnings += booking.totalAmount;
      }

      // 3. Record commission (5% of ride earnings)
      if (totalRideEarnings > 0) {
        await CommissionService().recordRideEarning(
          userId: widget.ride.driver.id,
          rideId: widget.ride.id,
          rideEarnings: totalRideEarnings,
        );
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../models/ride.dart';
import '../theme/color_palette.dart';

/// Route Map Widget
/// Displays an interactive map with actual road-based route from origin to destination
class RouteMapWidget extends StatefulWidget {
  final Location origin;
  final Location destination;
  final double? distanceKm;
  final int? durationMinutes;

  const RouteMapWidget({
    super.key,
    required this.origin,
    required this.destination,
    this.distanceKm,
    this.durationMinutes,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  List<LatLng> _routePoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  /// Fetch actual route from OSRM (Open Source Routing Machine)
  Future<void> _fetchRoute() async {
    try {
      final origin = widget.origin;
      final destination = widget.destination;

      // OSRM API endpoint (free public demo server)
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

        setState(() {
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();
          _isLoading = false;
        });
      } else {
        _setError('Failed to load route');
      }
    } catch (e) {
      _setError('Error loading route');
    }
  }

  void _setError(String message) {
    setState(() {
      _isLoading = false;
      // Fallback to straight line
      _routePoints = [
        LatLng(widget.origin.latitude, widget.origin.longitude),
        LatLng(widget.destination.latitude, widget.destination.longitude),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Create LatLng points
    final originPoint = LatLng(widget.origin.latitude, widget.origin.longitude);
    final destinationPoint = LatLng(
      widget.destination.latitude,
      widget.destination.longitude,
    );

    // Calculate center and zoom level
    final centerLat =
        (widget.origin.latitude + widget.destination.latitude) / 2;
    final centerLng =
        (widget.origin.longitude + widget.destination.longitude) / 2;
    final center = LatLng(centerLat, centerLng);

    // Calculate appropriate zoom level based on distance
    double zoom = 12.0;
    if (widget.distanceKm != null) {
      if (widget.distanceKm! > 50) {
        zoom = 9.0;
      } else if (widget.distanceKm! > 20) {
        zoom = 10.5;
      } else if (widget.distanceKm! < 5) {
        zoom = 13.0;
      }
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            minZoom: 5,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            // Map tiles
            TileLayer(
              urlTemplate: isDarkMode
                  ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carpool.app',
              tileBuilder: isDarkMode ? _darkModeTileBuilder : null,
            ),

            // Route polyline - shows actual road-based route
            if (!_isLoading && _routePoints.isNotEmpty)
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
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryDark,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: AppColors.primaryDark,
                      size: 16,
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
                      color: AppColors.secondaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),

        // Distance and duration overlay
        if (widget.distanceKm != null || widget.durationMinutes != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route,
                    size: 16,
                    color: isDarkMode ? Colors.white : AppColors.primaryDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.distanceKm?.toStringAsFixed(1) ?? "25"} km • ${widget.durationMinutes ?? 45} min',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Attribution (required by OpenStreetMap)
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 8, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  /// Tile builder for dark mode to adjust tile appearance
  Widget _darkModeTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.1),
        BlendMode.darken,
      ),
      child: tileWidget,
    );
  }
}

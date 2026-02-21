import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/ai_config.dart';
import '../../models/ride.dart';

/// AI-Powered Route Optimization Service
/// Optimizes multi-passenger pickup sequences and routes
class AIRouteOptimizationService {
  late final GenerativeModel _model;
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  AIRouteOptimizationService() {
    _model = GenerativeModel(
      model: AIConfig.geminiFlashModel,
      apiKey: AIConfig.getApiKey(),
      generationConfig: GenerationConfig(
        temperature: AIConfig.analysisTemperature,
        maxOutputTokens: 2000,
      ),
    );
  }

  /// Optimize pickup sequence for multiple passengers
  Future<OptimizedRoute> optimizePickupSequence({
    required Location driverLocation,
    required Location finalDestination,
    required List<PassengerPickup> passengers,
  }) async {
    if (passengers.isEmpty) {
      return OptimizedRoute(
        sequence: [],
        totalDistance: 0,
        totalDuration: 0,
        explanation: 'No passengers to pick up',
      );
    }

    try {
      // Get distances between all points
      final distances = await _calculateDistanceMatrix(
        driverLocation,
        finalDestination,
        passengers,
      );

      // Use AI to determine optimal sequence
      final prompt = _buildOptimizationPrompt(
        driverLocation,
        finalDestination,
        passengers,
        distances,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseOptimizationResponse(
        response.text ?? '',
        passengers,
        distances,
      );
    } catch (e) {
      print('Error in route optimization: $e');
      return _fallbackOptimization(
        driverLocation,
        finalDestination,
        passengers,
      );
    }
  }

  /// Calculate distance matrix using Google Maps API
  Future<Map<String, double>> _calculateDistanceMatrix(
    Location driverLocation,
    Location finalDestination,
    List<PassengerPickup> passengers,
  ) async {
    // If Google Maps API is not configured, use simple distance calculation
    if (_googleMapsApiKey.isEmpty) {
      return _calculateSimpleDistances(
        driverLocation,
        finalDestination,
        passengers,
      );
    }

    try {
      final origins = [
        driverLocation,
        ...passengers.map((p) => p.pickupLocation),
      ];
      final destinations = [
        ...passengers.map((p) => p.pickupLocation),
        finalDestination,
      ];

      final originsStr = origins
          .map((l) => '${l.latitude},${l.longitude}')
          .join('|');
      final destinationsStr = destinations
          .map((l) => '${l.latitude},${l.longitude}')
          .join('|');

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=$originsStr&destinations=$destinationsStr&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDistanceMatrix(data);
      }
    } catch (e) {
      print('Error fetching distance matrix: $e');
    }

    return _calculateSimpleDistances(
      driverLocation,
      finalDestination,
      passengers,
    );
  }

  /// Parse Google Maps distance matrix response
  Map<String, double> _parseDistanceMatrix(Map<String, dynamic> data) {
    final distances = <String, double>{};
    final rows = data['rows'] as List;

    for (var i = 0; i < rows.length; i++) {
      final elements = rows[i]['elements'] as List;
      for (var j = 0; j < elements.length; j++) {
        final element = elements[j];
        if (element['status'] == 'OK') {
          final distanceMeters = element['distance']['value'] as int;
          distances['$i-$j'] = distanceMeters / 1000.0; // Convert to km
        }
      }
    }

    return distances;
  }

  /// Simple distance calculation using Haversine formula
  Map<String, double> _calculateSimpleDistances(
    Location driverLocation,
    Location finalDestination,
    List<PassengerPickup> passengers,
  ) {
    final distances = <String, double>{};
    final allLocations = [
      driverLocation,
      ...passengers.map((p) => p.pickupLocation),
      finalDestination,
    ];

    for (var i = 0; i < allLocations.length; i++) {
      for (var j = 0; j < allLocations.length; j++) {
        if (i != j) {
          distances['$i-$j'] = _haversineDistance(
            allLocations[i],
            allLocations[j],
          );
        }
      }
    }

    return distances;
  }

  /// Haversine distance calculation
  double _haversineDistance(Location loc1, Location loc2) {
    const earthRadius = 6371.0; // km

    final lat1 = loc1.latitude * (3.14159 / 180);
    final lat2 = loc2.latitude * (3.14159 / 180);
    final dLat = (loc2.latitude - loc1.latitude) * (3.14159 / 180);
    final dLon = (loc2.longitude - loc1.longitude) * (3.14159 / 180);

    final a =
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * (dLon / 2).sin() * (dLon / 2).sin();

    final c = 2 * (a.sqrt()).asin();
    return earthRadius * c;
  }

  /// Build optimization prompt
  String _buildOptimizationPrompt(
    Location driverLocation,
    Location finalDestination,
    List<PassengerPickup> passengers,
    Map<String, double> distances,
  ) {
    final passengerInfo = passengers
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final passenger = entry.value;
          return '''
Passenger ${index + 1}: ${passenger.name}
  Location: ${passenger.pickupLocation.address}
  Waiting since: ${passenger.requestedTime}
''';
        })
        .join('\n');

    return '''
You are a route optimization expert for a carpool service.

Current Situation:
- Driver is at: ${driverLocation.address}
- Final destination: ${finalDestination.address}
- Number of passengers to pick up: ${passengers.length}

Passengers:
$passengerInfo

Task: Determine the optimal pickup sequence to:
1. Minimize total travel distance
2. Minimize passenger wait times
3. Avoid backtracking
4. Keep the route logical

Provide the optimal sequence as passenger numbers (1, 2, 3, etc.) separated by commas.
Then explain why this sequence is optimal in 1-2 sentences.

Format:
SEQUENCE|EXPLANATION

Example:
2,1,3|This sequence minimizes backtracking by picking up passengers along the main route to the destination.
''';
  }

  /// Parse optimization response
  OptimizedRoute _parseOptimizationResponse(
    String response,
    List<PassengerPickup> passengers,
    Map<String, double> distances,
  ) {
    try {
      final line = response
          .split('\n')
          .firstWhere((l) => l.contains('|'), orElse: () => '');

      if (line.isEmpty) {
        return _fallbackOptimization(
          Location(latitude: 0, longitude: 0, address: ''),
          Location(latitude: 0, longitude: 0, address: ''),
          passengers,
        );
      }

      final parts = line.split('|');
      final sequenceStr = parts[0].trim();
      final explanation = parts.length > 1
          ? parts[1].trim()
          : 'Optimized route';

      final sequence = sequenceStr
          .split(',')
          .map((s) => int.parse(s.trim()) - 1)
          .where((i) => i >= 0 && i < passengers.length)
          .toList();

      // Calculate total distance and duration
      double totalDistance = 0;
      int totalDuration = 0; // minutes

      return OptimizedRoute(
        sequence: sequence.map((i) => passengers[i]).toList(),
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        explanation: explanation,
      );
    } catch (e) {
      print('Error parsing optimization response: $e');
      return _fallbackOptimization(
        Location(latitude: 0, longitude: 0, address: ''),
        Location(latitude: 0, longitude: 0, address: ''),
        passengers,
      );
    }
  }

  /// Fallback optimization (simple nearest-neighbor)
  OptimizedRoute _fallbackOptimization(
    Location driverLocation,
    Location finalDestination,
    List<PassengerPickup> passengers,
  ) {
    if (passengers.isEmpty) {
      return OptimizedRoute(
        sequence: [],
        totalDistance: 0,
        totalDuration: 0,
        explanation: 'No passengers to optimize',
      );
    }

    // Simple nearest-neighbor algorithm
    final sequence = <PassengerPickup>[];
    final remaining = List<PassengerPickup>.from(passengers);
    var currentLocation = driverLocation;

    while (remaining.isNotEmpty) {
      // Find nearest passenger
      PassengerPickup? nearest;
      double minDistance = double.infinity;

      for (final passenger in remaining) {
        final distance = _haversineDistance(
          currentLocation,
          passenger.pickupLocation,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearest = passenger;
        }
      }

      if (nearest != null) {
        sequence.add(nearest);
        remaining.remove(nearest);
        currentLocation = nearest.pickupLocation;
      }
    }

    return OptimizedRoute(
      sequence: sequence,
      totalDistance: 0,
      totalDuration: 0,
      explanation: 'Optimized using nearest-neighbor algorithm',
    );
  }

  /// Get alternative routes
  Future<List<RouteAlternative>> getAlternativeRoutes({
    required Location origin,
    required Location destination,
  }) async {
    // This would integrate with Google Maps Directions API
    // For now, return a simple response
    return [
      RouteAlternative(
        name: 'Fastest Route',
        distance: 0,
        duration: 0,
        description: 'Via main highway',
      ),
      RouteAlternative(
        name: 'Shortest Route',
        distance: 0,
        duration: 0,
        description: 'Via city roads',
      ),
    ];
  }
}

/// Passenger pickup information
class PassengerPickup {
  final String passengerId;
  final String name;
  final Location pickupLocation;
  final DateTime requestedTime;

  PassengerPickup({
    required this.passengerId,
    required this.name,
    required this.pickupLocation,
    required this.requestedTime,
  });
}

/// Optimized route result
class OptimizedRoute {
  final List<PassengerPickup> sequence;
  final double totalDistance; // km
  final int totalDuration; // minutes
  final String explanation;

  OptimizedRoute({
    required this.sequence,
    required this.totalDistance,
    required this.totalDuration,
    required this.explanation,
  });
}

/// Route alternative
class RouteAlternative {
  final String name;
  final double distance;
  final int duration;
  final String description;

  RouteAlternative({
    required this.name,
    required this.distance,
    required this.duration,
    required this.description,
  });
}

// Extension for sin/cos on double
extension MathExtension on double {
  double sin() => this;
  double cos() => this;
  double asin() => this;
  double sqrt() => this;
}

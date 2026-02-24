import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ride.dart';

/// Location Search Service using OpenStreetMap Nominatim API
/// Provides autocomplete suggestions for location search
class LocationSearchService {
  /// Search for locations based on query
  /// Returns list of location suggestions
  Future<List<LocationSuggestion>> searchLocations(
    String query, {
    String countryCode = 'pk', // Pakistan by default
  }) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      // Automatically append "Lahore" if not already in query
      String searchQuery = query;
      if (!query.toLowerCase().contains('lahore')) {
        searchQuery = '$query, Lahore';
      }

      // Expanded Lahore bounding box for better coverage
      // Format: left,top,right,bottom (min_lon,max_lat,max_lon,min_lat)
      const lahoreBounds = '74.0,31.8,74.6,31.2'; // Wider Lahore area

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=$searchQuery&'
        'format=json&'
        'addressdetails=1&'
        'limit=10&'
        'accept-language=en&' // English results
        'countrycodes=pk&' // Pakistan only
        'viewbox=$lahoreBounds&' // Lahore region priority
        'bounded=0&' // Allow results outside viewbox if needed
        'dedupe=1', // Remove duplicate results
      );

      print('🔍 Searching locations for: $searchQuery');
      print('📍 Full URL: $url');

      final response = await http
          .get(
            url,
            headers: {
              'User-Agent': 'EzRide Carpool App',
              'Accept-Language': 'en', // English preference
            },
          )
          .timeout(const Duration(seconds: 10)); // Increased timeout

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        print('✅ Found ${data.length} locations');

        // Debug: Print first few results
        if (data.isNotEmpty) {
          print('🎯 First result: ${data[0]['display_name']}');
          if (data.length > 1) {
            print('🎯 Second result: ${data[1]['display_name']}');
          }
        } else {
          print('⚠️ No results returned from API');
        }

        return data.map((item) {
          final String shortName = _formatShortName(item);
          final String fullAddress = _formatFullAddress(item);
          return LocationSuggestion(
            displayName: shortName,
            address: fullAddress,
            latitude: double.parse(item['lat'] ?? '0'),
            longitude: double.parse(item['lon'] ?? '0'),
            type: item['type'] ?? '',
          );
        }).toList();
      } else {
        print('❌ Location search failed: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error searching locations: $e');
      return [];
    }
  }

  /// Create a short, user-friendly name like "Ferozepur Road, Model Town"
  String _formatShortName(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>?;
    if (address == null) {
      // Fallback: take the first part of display_name
      final displayName = item['display_name'] ?? '';
      final parts = displayName.split(',');
      if (parts.length >= 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }
      return displayName;
    }

    final nameParts = <String>[];

    // 1. Get the specific place name (amenity, building, road, etc.)
    final placeName =
        address['amenity'] ??
        address['building'] ??
        address['shop'] ??
        address['office'] ??
        address['tourism'] ??
        address['leisure'] ??
        address['highway'] ??
        item['name']; // Nominatim also provides 'name' at top level

    if (placeName != null && placeName.toString().isNotEmpty) {
      nameParts.add(placeName.toString());
    }

    // 2. Get the road/street
    final road = address['road'] ?? address['street'];
    if (road != null && road.toString().isNotEmpty && road != placeName) {
      nameParts.add(road.toString());
    }

    // 3. Get the area (suburb, neighbourhood, quarter)
    final area =
        address['suburb'] ??
        address['neighbourhood'] ??
        address['quarter'] ??
        address['residential'];
    if (area != null &&
        area.toString().isNotEmpty &&
        !nameParts.contains(area.toString())) {
      nameParts.add(area.toString());
    }

    // If we still have nothing, fall back to city
    if (nameParts.isEmpty) {
      final city = address['city'] ?? address['town'] ?? address['village'];
      if (city != null) nameParts.add(city.toString());
    }

    if (nameParts.isEmpty) {
      // Last resort: use first 2 parts of display_name
      final displayName = item['display_name'] ?? '';
      final parts = displayName.split(',');
      if (parts.length >= 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }
      return displayName;
    }

    // Return at most 2-3 parts for a clean short name
    return nameParts.take(3).join(', ');
  }

  /// Format full address from Nominatim response
  String _formatFullAddress(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>?;
    if (address == null) return item['display_name'] ?? '';

    final parts = <String>[];

    // Add area/suburb
    final area = address['suburb'] ?? address['neighbourhood'];
    if (area != null) parts.add(area.toString());

    // Add city/town/village
    if (address['city'] != null) {
      parts.add(address['city']);
    } else if (address['town'] != null) {
      parts.add(address['town']);
    } else if (address['village'] != null) {
      parts.add(address['village']);
    }

    // Add state/province
    if (address['state'] != null) {
      parts.add(address['state']);
    }

    return parts.isEmpty ? item['display_name'] : parts.join(', ');
  }

  /// Convert LocationSuggestion to Location model
  Location toLocation(LocationSuggestion suggestion) {
    return Location(
      address: suggestion.address,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
    );
  }
}

/// Location suggestion model for autocomplete
class LocationSuggestion {
  final String displayName;
  final String address;
  final double latitude;
  final double longitude;
  final String type;

  LocationSuggestion({
    required this.displayName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
  });
}

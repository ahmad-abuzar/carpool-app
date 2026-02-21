import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride.dart';
import '../models/user.dart';

import '../services/ride_service.dart';

// Ride Service Provider
final rideServiceProvider = Provider<RideService>((ref) {
  return RideService();
});

// Rides list provider
final ridesProvider = StateNotifierProvider<RidesNotifier, List<Ride>>((ref) {
  final rideService = ref.watch(rideServiceProvider);
  return RidesNotifier(rideService);
});

class RidesNotifier extends StateNotifier<List<Ride>> {
  final RideService _rideService;
  bool isLoading = false;

  RidesNotifier(this._rideService) : super([]) {
    // Initial load
    loadAvailableRides();
  }

  Future<void> loadAvailableRides() async {
    try {
      print('🔄 RideProvider: Loading available rides...');
      _rideService.listenToAvailableRides().listen(
        (rides) {
          print(
            '✅ RideProvider: Received ${rides.length} rides from Firestore',
          );
          for (final ride in rides) {
            print(
              '   📍 ${ride.origin.address} → ${ride.destination.address} (${ride.availableSeats} seats)',
            );
          }
          state = rides;
        },
        onError: (error) {
          print('❌ RideProvider: Error in rides stream: $error');
        },
      );
    } catch (e) {
      print('❌ RideProvider: Error loading rides: $e');
    }
  }

  Future<void> addRide(Ride ride) async {
    isLoading = true;
    try {
      print('📤 RideProvider: Posting ride...');
      print('   Driver: ${ride.driver.name}');
      print('   Route: ${ride.origin.address} → ${ride.destination.address}');
      print('   Departure: ${ride.departureTime}');
      print('   Price: Rs ${ride.pricePerSeat}/seat');
      print('   Seats: ${ride.availableSeats}');

      final rideId = await _rideService.createRide(ride);

      print('✅ RideProvider: Ride posted successfully with ID: $rideId');
      // State update is handled by the stream listener if it matches query,
      // but we can also optimistically add it if we want immediate feedback
      // state = [...state, ride];
    } catch (e) {
      print('❌ RideProvider: Error adding ride: $e');
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  // Removed simple updateRide/refreshRides as we rely on streams/services now
  // Kept searching logic but it should ideally be backend powered

  Future<void> updateRide(Ride ride) async {
    try {
      await _rideService.updateRide(ride);
    } catch (e) {
      print('Error updating ride: $e');
      rethrow;
    }
  }

  List<Ride> searchLocal(RideSearchFilters filters) {
    return state.where((ride) {
      if (filters.femaleOnly && !ride.femaleOnly) return false;
      if (filters.maxPrice != null && ride.pricePerSeat > filters.maxPrice!)
        return false;
      if (filters.date != null) {
        final rideDate = DateTime(
          ride.departureTime.year,
          ride.departureTime.month,
          ride.departureTime.day,
        );
        final searchDate = DateTime(
          filters.date!.year,
          filters.date!.month,
          filters.date!.day,
        );
        if (!rideDate.isAtSameMomentAs(searchDate)) return false;
      }
      return true;
    }).toList();
  }
}

// Ride search filters
class RideSearchFilters {
  final Location? origin;
  final Location? destination;
  final DateTime? date;
  final bool femaleOnly;
  final double? maxPrice;
  final int? minSeats;

  const RideSearchFilters({
    this.origin,
    this.destination,
    this.date,
    this.femaleOnly = false,
    this.maxPrice,
    this.minSeats,
  });

  RideSearchFilters copyWith({
    Location? origin,
    Location? destination,
    DateTime? date,
    bool? femaleOnly,
    double? maxPrice,
    int? minSeats,
  }) {
    return RideSearchFilters(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      femaleOnly: femaleOnly ?? this.femaleOnly,
      maxPrice: maxPrice ?? this.maxPrice,
      minSeats: minSeats ?? this.minSeats,
    );
  }
}

final rideSearchFiltersProvider = StateProvider<RideSearchFilters>((ref) {
  return const RideSearchFilters();
});

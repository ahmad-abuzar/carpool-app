import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import 'firestore_service.dart';

/// Ride Management Service
/// Handles all ride-related operations
class RideService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'rides';

  /// Create a new ride
  Future<String> createRide(Ride ride) async {
    try {
      print('🚗 RideService: Creating ride in Firestore...');
      print('   Driver ID: ${ride.driver.id}');
      print('   Driver Name: ${ride.driver.name}');
      print('   Route: ${ride.origin.address} → ${ride.destination.address}');
      print('   Departure: ${ride.departureTime}');
      print('   Status: ${ride.status.name}');

      final rideData = ride.toMap();
      print('   Data keys: ${rideData.keys.join(', ')}');

      final rideId = await _firestoreService.createDocumentWithAutoId(
        collection: _collection,
        data: rideData,
      );

      print('✅ RideService: Ride created successfully with ID: $rideId');
      return rideId;
    } catch (e) {
      print('❌ RideService: ERROR creating ride: $e');

      if (e.toString().toLowerCase().contains('permission')) {
        throw 'Permission denied. Please check Firestore security rules.';
      }

      if (e.toString().toLowerCase().contains('network')) {
        throw 'Network error. Please check your internet connection.';
      }

      rethrow;
    }
  }

  /// Get ride by ID
  Future<Ride?> getRideById(String rideId) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: rideId,
    );

    if (data == null) return null;
    return Ride.fromMap(data);
  }

  /// Update ride
  Future<void> updateRide(Ride ride) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: ride.id,
      data: ride.toMap(),
      merge: true,
    );
  }

  /// Update ride status
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: rideId,
      data: {'status': status.name},
    );
  }

  /// Update available seats
  Future<void> updateAvailableSeats(String rideId, int seats) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: rideId,
      data: {'availableSeats': seats},
    );
  }

  /// Decrement available seats (for booking)
  Future<bool> decrementAvailableSeats(String rideId, int seatsToBook) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final rideDoc = await transaction.get(
          _firestore.collection(_collection).doc(rideId),
        );

        if (!rideDoc.exists) {
          throw Exception('Ride not found');
        }

        final currentSeats = rideDoc.data()?['availableSeats'] as int;
        if (currentSeats < seatsToBook) {
          throw Exception('Not enough seats available');
        }

        transaction.update(rideDoc.reference, {
          'availableSeats': currentSeats - seatsToBook,
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Increment available seats (for cancellation)
  Future<void> incrementAvailableSeats(String rideId, int seats) async {
    await _firestore.collection(_collection).doc(rideId).update({
      'availableSeats': FieldValue.increment(seats),
    });
  }

  /// Add passenger to ride
  Future<void> addPassenger(String rideId, User passenger) async {
    await _firestore.collection(_collection).doc(rideId).update({
      'passengers': FieldValue.arrayUnion([passenger.toMap()]),
      'passengerIds': FieldValue.arrayUnion([passenger.id]),
    });
  }

  /// Remove passenger from ride
  Future<void> removePassenger(String rideId, String passengerId) async {
    final ride = await getRideById(rideId);
    if (ride == null) return;

    final updatedPassengers = ride.passengers
        .where((p) => p.id != passengerId)
        .toList();

    await _firestoreService.updateDocument(
      collection: _collection,
      docId: rideId,
      data: {
        'passengers': updatedPassengers.map((p) => p.toMap()).toList(),
        'passengerIds': updatedPassengers.map((p) => p.id).toList(),
      },
    );
  }

  /// Cancel ride
  Future<void> cancelRide(String rideId) async {
    await updateRideStatus(rideId, RideStatus.cancelled);
  }

  /// Delete ride
  Future<void> deleteRide(String rideId) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: rideId,
    );
  }

  /// Search rides with filters
  Future<List<Ride>> searchRides({
    String? originAddress,
    String? destinationAddress,
    DateTime? date,
    bool? femaleOnly,
    double? maxPrice,
    int? minSeats,
  }) async {
    final conditions = <QueryCondition>[];

    // Filter by status (only show scheduled rides)
    conditions.add(
      QueryCondition(
        field: 'status',
        operator: '==',
        value: RideStatus.scheduled.name,
      ),
    );

    // Filter by female only
    if (femaleOnly == true) {
      conditions.add(
        QueryCondition(field: 'femaleOnly', operator: '==', value: true),
      );
    }

    // Filter by max price
    if (maxPrice != null) {
      conditions.add(
        QueryCondition(field: 'pricePerSeat', operator: '<=', value: maxPrice),
      );
    }

    // Filter by minimum available seats
    if (minSeats != null) {
      conditions.add(
        QueryCondition(
          field: 'availableSeats',
          operator: '>=',
          value: minSeats,
        ),
      );
    }

    // Filter by date (rides departing on or after the specified date)
    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      conditions.add(
        QueryCondition(
          field: 'departureTime',
          operator: '>=',
          value: startOfDay.millisecondsSinceEpoch,
        ),
      );
    }

    final docs = await _firestoreService.advancedQuery(
      collection: _collection,
      conditions: conditions,
      orderByField: 'departureTime',
      descending: false,
      limit: 50,
    );

    var rides = docs.map((doc) => Ride.fromMap(doc)).toList();

    // Additional filtering for origin/destination (since Firestore doesn't support text search)
    if (originAddress != null) {
      rides = rides
          .where(
            (ride) => ride.origin.address.toLowerCase().contains(
              originAddress.toLowerCase(),
            ),
          )
          .toList();
    }

    if (destinationAddress != null) {
      rides = rides
          .where(
            (ride) => ride.destination.address.toLowerCase().contains(
              destinationAddress.toLowerCase(),
            ),
          )
          .toList();
    }

    return rides;
  }

  /// Get rides by driver
  Future<List<Ride>> getRidesByDriver(String driverId) async {
    final docs = await _firestoreService.queryDocuments(
      collection: _collection,
      field: 'driverId',
      value: driverId,
    );

    return docs.map((doc) => Ride.fromMap(doc)).toList();
  }

  /// Get upcoming rides for driver
  Future<List<Ride>> getUpcomingRidesForDriver(String driverId) async {
    final now = DateTime.now();
    final rides = await getRidesByDriver(driverId);

    return rides
        .where(
          (ride) =>
              ride.departureTime.isAfter(now) &&
              (ride.status == RideStatus.scheduled ||
                  ride.status == RideStatus.driverEnRoute),
        )
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
  }

  /// Get past rides for driver
  Future<List<Ride>> getPastRidesForDriver(String driverId) async {
    final now = DateTime.now();
    final rides = await getRidesByDriver(driverId);

    return rides
        .where(
          (ride) =>
              ride.status == RideStatus.completed ||
              ride.status == RideStatus.cancelled ||
              ride.departureTime.isBefore(now),
        )
        .toList()
      ..sort((a, b) => b.departureTime.compareTo(a.departureTime));
  }

  /// Get rides where user is a passenger
  Future<List<Ride>> getRidesAsPassenger(String passengerId) async {
    final docs = await _firestoreService.queryDocuments(
      collection: _collection,
      field: 'passengerIds',
      value: passengerId,
      operator: 'array-contains',
    );

    return docs.map((doc) => Ride.fromMap(doc)).toList();
  }

  /// Update ride location (for live tracking)
  Future<void> updateRideLocation(String rideId, Location location) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: rideId,
      data: {'currentLocation': location.toMap()},
    );
  }

  /// Listen to ride changes
  Stream<Ride?> listenToRide(String rideId) {
    return _firestoreService
        .listenToDocument(collection: _collection, docId: rideId)
        .map((data) => data != null ? Ride.fromMap(data) : null);
  }

  /// Listen to available rides
  Stream<List<Ride>> listenToAvailableRides() {
    final now = DateTime.now();
    final yesterdayTimestamp = now
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch;

    print('🔍 RideService: Setting up rides listener...');
    print('   Current time: $now');
    print(
      '   Filtering rides from: ${DateTime.fromMillisecondsSinceEpoch(yesterdayTimestamp)}',
    );
    print('   ⚠️ Using simple query to avoid index requirement');

    // Simplified query - only filter by departureTime to avoid composite index
    // We'll filter by status in memory instead
    return _firestoreService
        .listenToQuery(
          collection: _collection,
          conditions: [
            // Only filter by time - no composite index needed
            QueryCondition(
              field: 'departureTime',
              operator: '>=',
              value: yesterdayTimestamp,
            ),
          ],
          orderByField: 'departureTime',
          descending: false,
          limit: 50,
        )
        .map((docs) {
          print(
            '📦 RideService: Received ${docs.length} documents from Firestore',
          );

          final rides = docs
              .map((doc) {
                try {
                  return Ride.fromMap(doc);
                } catch (e) {
                  print('⚠️ RideService: Error parsing ride document: $e');
                  print('   Document data: $doc');
                  return null;
                }
              })
              .whereType<Ride>()
              .toList();

          // Filter out completed/cancelled rides in memory (to avoid composite index)
          final activeRides = rides
              .where(
                (ride) =>
                    ride.status != RideStatus.completed &&
                    ride.status != RideStatus.cancelled,
              )
              .toList();

          print('✅ RideService: Successfully parsed ${rides.length} rides');
          print('   Filtered to ${activeRides.length} active rides');

          for (final ride in activeRides) {
            print(
              '   🚗 ${ride.id.substring(0, 8)}: ${ride.origin.address} → ${ride.destination.address} [${ride.status.name}]',
            );
            print(
              '      Seats: ${ride.availableSeats}/${ride.totalSeats}, Price: Rs${ride.pricePerSeat}',
            );
          }

          return activeRides;
        });
  }

  /// Get popular routes (for analytics)
  Future<Map<String, int>> getPopularRoutes() async {
    final rides = await _firestoreService.getCollection(_collection);
    final routeCounts = <String, int>{};

    for (final ride in rides) {
      final rideData = Ride.fromMap(ride);
      final route =
          '${rideData.origin.address} → ${rideData.destination.address}';
      routeCounts[route] = (routeCounts[route] ?? 0) + 1;
    }

    // Sort by count
    final sortedRoutes = Map.fromEntries(
      routeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sortedRoutes;
  }
}

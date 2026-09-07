import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import 'firestore_service.dart';

/// Booking Management Service
/// Handles all booking-related operations
class BookingService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'bookings';

  /// Create a new booking with retry logic
  Future<String?> createBooking(Booking booking) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print('📝 Creating booking (attempt ${retryCount + 1}/$maxRetries)...');

        // Use transaction to ensure seat availability
        final bookingId = await _firestore.runTransaction((transaction) async {
          // Check if seats are available
          final rideDoc = await transaction.get(
            _firestore.collection('rides').doc(booking.rideId),
          );

          if (!rideDoc.exists) {
            throw Exception('Ride not found');
          }

          final rideData = rideDoc.data()!;
          final availableSeats = rideData['availableSeats'] as int;

          if (availableSeats < booking.seatsBooked) {
            throw Exception('Not enough seats available');
          }

          // Create booking
          final bookingRef = _firestore.collection(_collection).doc();
          final bookingData = booking.toMap();
          bookingData['id'] = bookingRef.id;

          transaction.set(bookingRef, bookingData);

          // Update ride seats
          transaction.update(rideDoc.reference, {
            'availableSeats': availableSeats - booking.seatsBooked,
          });

          // Add passenger to ride
          transaction.update(rideDoc.reference, {
            'passengerIds': FieldValue.arrayUnion([booking.passenger.id]),
          });

          return bookingRef.id;
        });

        print('✅ Booking created successfully: $bookingId');
        return bookingId;
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable' && retryCount < maxRetries - 1) {
          // Exponential backoff: 1s, 2s, 4s
          final delaySeconds = (retryCount + 1) * 1;
          print('⚠️ Firestore unavailable, retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
          retryCount++;
          continue;
        }
        print('❌ Error creating booking: ${e.code} - ${e.message}');
        return null;
      } catch (e) {
        print('❌ Error creating booking: $e');
        return null;
      }
    }

    print('❌ Failed to create booking after $maxRetries attempts');
    return null;
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: bookingId,
    );

    if (data == null) return null;
    return Booking.fromMap(data);
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: bookingId,
      data: {'status': status.name},
    );
  }

  /// Confirm booking
  Future<void> confirmBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.confirmed);
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        // Update booking status
        final bookingRef = _firestore.collection(_collection).doc(bookingId);
        transaction.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          'cancellationReason': reason,
        });

        // Return seats to ride
        final rideRef = _firestore.collection('rides').doc(booking.rideId);
        transaction.update(rideRef, {
          'availableSeats': FieldValue.increment(booking.seatsBooked),
        });

        // Remove passenger from ride
        transaction.update(rideRef, {
          'passengerIds': FieldValue.arrayRemove([booking.passenger.id]),
        });
      });
    } catch (e) {
      print('Error cancelling booking: $e');
    }
  }

  /// Complete booking (after ride completion)
  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.completed);
  }

  /// Get bookings by passenger
  Future<List<Booking>> getBookingsByPassenger(String passengerId) async {
    final docs = await _firestoreService.queryDocuments(
      collection: _collection,
      field: 'passengerId',
      value: passengerId,
    );

    return docs.map((doc) => Booking.fromMap(doc)).toList();
  }

  /// Get bookings by ride
  Future<List<Booking>> getBookingsByRide(String rideId) async {
    final docs = await _firestoreService.queryDocuments(
      collection: _collection,
      field: 'rideId',
      value: rideId,
    );

    return docs.map((doc) => Booking.fromMap(doc)).toList();
  }

  /// Get upcoming bookings for passenger
  Future<List<Booking>> getUpcomingBookings(String passengerId) async {
    final now = DateTime.now();

    final allBookings = await getBookingsByPassenger(passengerId);

    return allBookings.where((booking) {
        return booking.status == BookingStatus.confirmed &&
            booking.ride.departureTime.isAfter(now);
      }).toList()
      ..sort((a, b) => a.ride.departureTime.compareTo(b.ride.departureTime));
  }

  /// Get past bookings for passenger
  Future<List<Booking>> getPastBookings(String passengerId) async {
    final now = DateTime.now();

    final allBookings = await getBookingsByPassenger(passengerId);

    return allBookings.where((booking) {
        return booking.status == BookingStatus.completed ||
            booking.ride.departureTime.isBefore(now);
      }).toList()
      ..sort((a, b) => b.ride.departureTime.compareTo(a.ride.departureTime));
  }

  /// Get pending bookings (awaiting confirmation)
  Future<List<Booking>> getPendingBookings(String passengerId) async {
    final docs = await _firestoreService.advancedQuery(
      collection: _collection,
      conditions: [
        QueryCondition(
          field: 'passengerId',
          operator: '==',
          value: passengerId,
        ),
        QueryCondition(
          field: 'status',
          operator: '==',
          value: BookingStatus.pending.name,
        ),
      ],
    );

    return docs.map((doc) => Booking.fromMap(doc)).toList();
  }

  /// Get cancelled bookings
  Future<List<Booking>> getCancelledBookings(String passengerId) async {
    final docs = await _firestoreService.advancedQuery(
      collection: _collection,
      conditions: [
        QueryCondition(
          field: 'passengerId',
          operator: '==',
          value: passengerId,
        ),
        QueryCondition(
          field: 'status',
          operator: '==',
          value: BookingStatus.cancelled.name,
        ),
      ],
    );

    return docs.map((doc) => Booking.fromMap(doc)).toList();
  }

  /// Listen to booking changes
  Stream<Booking?> listenToBooking(String bookingId) {
    return _firestoreService
        .listenToDocument(collection: _collection, docId: bookingId)
        .map((data) => data != null ? Booking.fromMap(data) : null);
  }

  /// Listen to user's bookings
  Stream<List<Booking>> listenToUserBookings(String passengerId) {
    return _firestoreService
        .listenToQuery(
          collection: _collection,
          conditions: [
            QueryCondition(
              field: 'passengerId',
              operator: '==',
              value: passengerId,
            ),
          ],
          orderByField: 'bookingTime',
          descending: true,
        )
        .map((docs) => docs.map((doc) => Booking.fromMap(doc)).toList());
  }

  /// Get booking statistics for user
  Future<Map<String, dynamic>> getBookingStatistics(String passengerId) async {
    final allBookings = await getBookingsByPassenger(passengerId);

    final totalBookings = allBookings.length;
    final completedBookings = allBookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final cancelledBookings = allBookings
        .where((b) => b.status == BookingStatus.cancelled)
        .length;
    final totalSpent = allBookings
        .where((b) => b.status == BookingStatus.completed)
        .fold<double>(0, (sum, b) => sum + b.totalAmount);

    return {
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'totalSpent': totalSpent,
      'cancellationRate': totalBookings > 0
          ? (cancelledBookings / totalBookings * 100)
          : 0,
    };
  }

  /// Delete booking
  Future<void> deleteBooking(String bookingId) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: bookingId,
    );
  }
}

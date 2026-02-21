import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ride_service.dart';
import '../services/booking_service.dart';

/// Ride Service Provider
final rideServiceProvider = Provider<RideService>((ref) {
  return RideService();
});

/// Booking Service Provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

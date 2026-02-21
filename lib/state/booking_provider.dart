import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'auth_provider.dart';

// Booking Service Provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// User Bookings Provider
final userBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final service = ref.watch(bookingServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    print('📋 userBookingsProvider: No user logged in');
    return Stream.value([]);
  }

  print('📋 userBookingsProvider: Listening to bookings for user ${user.id}');
  return service.listenToUserBookings(user.id).map((bookings) {
    print('📋 userBookingsProvider: Received ${bookings.length} bookings');
    for (var booking in bookings) {
      print(
        '   - Booking ${booking.id}: ${booking.ride.origin.address} → ${booking.ride.destination.address}, Status: ${booking.status.name}',
      );
    }
    return bookings;
  });
});

// Booking Controller for Actions
final bookingControllerProvider =
    StateNotifierProvider<BookingController, AsyncValue<String?>>((ref) {
      final service = ref.watch(bookingServiceProvider);
      return BookingController(service);
    });

class BookingController extends StateNotifier<AsyncValue<String?>> {
  final BookingService _service;

  BookingController(this._service) : super(const AsyncValue.data(null));

  Future<String?> createBooking(Booking booking) async {
    state = const AsyncValue.loading();
    final result = await _service.createBooking(booking);
    if (result != null) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error('Failed to create booking', StackTrace.current);
    }
    return result;
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _service.cancelBooking(bookingId, reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

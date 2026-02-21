import 'ride.dart';
import 'user.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }

class Booking {
  final String id;
  final String rideId;
  final Ride ride;
  final User passenger;
  final int seatsBooked;
  final double totalAmount;
  final BookingStatus status;
  final DateTime bookingTime;
  final String? cancellationReason;

  const Booking({
    required this.id,
    required this.rideId,
    required this.ride,
    required this.passenger,
    required this.seatsBooked,
    required this.totalAmount,
    this.status = BookingStatus.pending,
    required this.bookingTime,
    this.cancellationReason,
  });

  Booking copyWith({BookingStatus? status, String? cancellationReason}) {
    return Booking(
      id: id,
      rideId: rideId,
      ride: ride,
      passenger: passenger,
      seatsBooked: seatsBooked,
      totalAmount: totalAmount,
      status: status ?? this.status,
      bookingTime: bookingTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'ride': ride.toMap(),
      'passengerId': passenger.id,
      'passenger': passenger.toMap(),
      'seatsBooked': seatsBooked,
      'totalAmount': totalAmount,
      'status': status.name,
      'bookingTime': bookingTime.millisecondsSinceEpoch,
      'cancellationReason': cancellationReason,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      rideId: map['rideId'] as String,
      ride: Ride.fromMap(map['ride'] as Map<String, dynamic>),
      passenger: User.fromMap(map['passenger'] as Map<String, dynamic>),
      seatsBooked: map['seatsBooked'] as int,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      bookingTime: DateTime.fromMillisecondsSinceEpoch(
        map['bookingTime'] as int,
      ),
      cancellationReason: map['cancellationReason'] as String?,
    );
  }
}

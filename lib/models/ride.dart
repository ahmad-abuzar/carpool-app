import 'user.dart';
import 'vehicle.dart';

enum RideStatus { scheduled, driverEnRoute, inProgress, completed, cancelled }

class Location {
  final String address;
  final double latitude;
  final double longitude;

  const Location({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {'address': address, 'latitude': latitude, 'longitude': longitude};
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      address: map['address'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}

class Ride {
  final String id;
  final User driver;
  final Vehicle vehicle;
  final Location origin;
  final Location destination;
  final DateTime departureTime;
  final DateTime estimatedArrivalTime;
  final double pricePerSeat;
  final int totalSeats;
  final int availableSeats;
  final bool femaleOnly;
  final List<String> rules; // e.g., "No smoking", "Music allowed"
  final RideStatus status;
  final List<User> passengers;
  final String? meetupInstructions;

  // For tracking
  final Location? currentLocation;
  final double? distanceKm;
  final int? durationMinutes;

  const Ride({
    required this.id,
    required this.driver,
    required this.vehicle,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.estimatedArrivalTime,
    required this.pricePerSeat,
    required this.totalSeats,
    required this.availableSeats,
    this.femaleOnly = false,
    this.rules = const [],
    this.status = RideStatus.scheduled,
    this.passengers = const [],
    this.meetupInstructions,
    this.currentLocation,
    this.distanceKm,
    this.durationMinutes,
  });

  Ride copyWith({
    RideStatus? status,
    int? availableSeats,
    List<User>? passengers,
    Location? currentLocation,
  }) {
    return Ride(
      id: id,
      driver: driver,
      vehicle: vehicle,
      origin: origin,
      destination: destination,
      departureTime: departureTime,
      estimatedArrivalTime: estimatedArrivalTime,
      pricePerSeat: pricePerSeat,
      totalSeats: totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      femaleOnly: femaleOnly,
      rules: rules,
      status: status ?? this.status,
      passengers: passengers ?? this.passengers,
      meetupInstructions: meetupInstructions,
      currentLocation: currentLocation ?? this.currentLocation,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  bool get isFull => availableSeats == 0;
  int get bookedSeats => totalSeats - availableSeats;

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driver.id,
      'driver': driver.toMap(),
      'vehicle': vehicle.toMap(),
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'departureTime': departureTime.millisecondsSinceEpoch,
      'estimatedArrivalTime': estimatedArrivalTime.millisecondsSinceEpoch,
      'pricePerSeat': pricePerSeat,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'femaleOnly': femaleOnly,
      'rules': rules,
      'status': status.name,
      'passengers': passengers.map((p) => p.toMap()).toList(),
      'passengerIds': passengers.map((p) => p.id).toList(),
      'meetupInstructions': meetupInstructions,
      'currentLocation': currentLocation?.toMap(),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] as String,
      driver: User.fromMap(map['driver'] as Map<String, dynamic>),
      vehicle: Vehicle.fromMap(map['vehicle'] as Map<String, dynamic>),
      origin: Location.fromMap(map['origin'] as Map<String, dynamic>),
      destination: Location.fromMap(map['destination'] as Map<String, dynamic>),
      departureTime: DateTime.fromMillisecondsSinceEpoch(
        map['departureTime'] as int,
      ),
      estimatedArrivalTime: DateTime.fromMillisecondsSinceEpoch(
        map['estimatedArrivalTime'] as int,
      ),
      pricePerSeat: (map['pricePerSeat'] as num).toDouble(),
      totalSeats: map['totalSeats'] as int,
      availableSeats: map['availableSeats'] as int,
      femaleOnly: map['femaleOnly'] as bool? ?? false,
      rules: List<String>.from(map['rules'] ?? []),
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.scheduled,
      ),
      passengers:
          (map['passengers'] as List<dynamic>?)
              ?.map((p) => User.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      meetupInstructions: map['meetupInstructions'] as String?,
      currentLocation: map['currentLocation'] != null
          ? Location.fromMap(map['currentLocation'] as Map<String, dynamic>)
          : null,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      durationMinutes: map['durationMinutes'] as int?,
    );
  }
}

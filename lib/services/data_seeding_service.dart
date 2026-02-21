import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/ride.dart';
import '../models/vehicle.dart' as v;
import 'firestore_service.dart';

class DataSeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> seedData() async {
    print('🌱 DataSeedingService: Starting Data Seeding...');

    // 1. Seed Users (15 users total)
    final users = _getLocalizedUsers();
    print('   Seeding ${users.length} users...');
    for (var user in users) {
      await _firestoreService.setDocument(
        collection: 'users',
        docId: user.id,
        data: user.toMap(),
      );
    }
    print('✅ Seed: Users completed');

    // 2. Seed Rides
    final rides = _getLocalizedRides(users);
    print('   Seeding ${rides.length} rides...');
    for (var ride in rides) {
      await _firestoreService.createDocumentWithAutoId(
        collection: 'rides',
        data: ride.toMap(),
      );
    }
    print('✅ Seed: Rides completed');
    print('✅ Data Seeding Finished Successfully!');
  }

  /// Quick method to seed only rides (useful for testing)
  Future<void> seedRidesOnly() async {
    print('🌱 DataSeedingService: Seeding test rides...');

    // Check if rides already exist
    final snapshot = await _firestore.collection('rides').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      print('⚠️  Rides already exist in database. Skipping seed.');
      print('   To re-seed, delete existing rides first.');
      return;
    }

    final users = _getLocalizedUsers();
    final rides = _getLocalizedRides(users);

    print('   Creating ${rides.length} test rides...');
    for (var ride in rides) {
      final rideId = await _firestoreService.createDocumentWithAutoId(
        collection: 'rides',
        data: ride.toMap(),
      );
      print(
        '   ✅ Created ride: ${ride.origin.address} → ${ride.destination.address} (ID: ${rideId.substring(0, 8)}...)',
      );
    }

    print('✅ Test rides seeded successfully!');
  }

  List<User> _getLocalizedUsers() {
    return [
      _user('s1', 'Ayesha Khan', 'Lahore', UserRole.both, Gender.female),
      _user('s2', 'Ali Hassan', 'Karachi', UserRole.driver, Gender.male),
      _user(
        's3',
        'Fatima Malik',
        'Islamabad',
        UserRole.passenger,
        Gender.female,
      ),
      _user('s4', 'Usman Ahmed', 'Rawalpindi', UserRole.driver, Gender.male),
      _user('s5', 'Zainab Ali', 'Peshawar', UserRole.both, Gender.female),
      _user('s6', 'Hassan Raza', 'Faisalabad', UserRole.driver, Gender.male),
      _user('s7', 'Maryam Bibi', 'Multan', UserRole.passenger, Gender.female),
      _user('s8', 'Bilal Sheikh', 'Lahore', UserRole.driver, Gender.male),
      _user('s9', 'Sana Javed', 'Karachi', UserRole.both, Gender.female),
      _user('s10', 'Omer Farooq', 'Islamabad', UserRole.driver, Gender.male),
      _user('s11', 'Sara Ahmed', 'Lahore', UserRole.passenger, Gender.female),
      _user('s12', 'Hamza Butt', 'Sialkot', UserRole.driver, Gender.male),
      _user('s13', 'Zoya Khan', 'Quetta', UserRole.passenger, Gender.female),
      _user('s14', 'Raza Ali', 'Lahore', UserRole.both, Gender.male),
      _user(
        's15',
        'Nimra Shah',
        'Islamabad',
        UserRole.passenger,
        Gender.female,
      ),
    ];
  }

  User _user(
    String id,
    String name,
    String city,
    UserRole role,
    Gender gender,
  ) {
    return User(
      id: id,
      name: name,
      phone: '+92 300 ${id.padLeft(7, '0')}',
      email: '${name.toLowerCase().replaceAll(' ', '.')}@example.pk',
      gender: gender,
      role: role,
      rating: 4.5 + (id.length % 5) / 10,
      totalRides: 10 + id.length,
      idVerified: true,
      homeAddress: city,
    );
  }

  List<Ride> _getLocalizedRides(List<User> users) {
    final now = DateTime.now();
    final drivers = users.where((u) => u.role != UserRole.passenger).toList();

    return [
      _ride(
        'r_s1',
        drivers[0],
        'Gulberg',
        'DHA Phase 6',
        now.add(const Duration(hours: 3)),
      ),
      _ride(
        'r_s2',
        drivers[1],
        'Model Town',
        'Mall Road',
        now.add(const Duration(hours: 5)),
      ),
      _ride(
        'r_s3',
        drivers[2],
        'F-7',
        'Blue Area',
        now.add(const Duration(hours: 2)),
      ),
      _ride(
        'r_s4',
        drivers[3],
        'Bahria Phase 7',
        'Saddar',
        now.add(const Duration(days: 1, hours: 2)),
      ),
      _ride(
        'r_s5',
        drivers[4],
        'Cantt',
        'Johar Town',
        now.add(const Duration(hours: 4)),
      ),
    ];
  }

  Ride _ride(String id, User driver, String from, String to, DateTime time) {
    return Ride(
      id: '', // Auto-generated
      driver: driver,
      vehicle: const v.Vehicle(
        id: 'v1',
        model: 'Honda Civic',
        color: 'White',
        plateNumber: 'ABC-123',
        seats: 4,
        verified: true,
      ),
      origin: Location(
        address: '$from, Pakistan',
        latitude: 31.5,
        longitude: 74.3,
      ),
      destination: Location(
        address: '$to, Pakistan',
        latitude: 31.6,
        longitude: 74.4,
      ),
      departureTime: time,
      estimatedArrivalTime: time.add(const Duration(minutes: 45)),
      pricePerSeat: 150.0,
      totalSeats: 3,
      availableSeats: 3,
      femaleOnly: driver.gender == Gender.female,
      status: RideStatus.scheduled,
      rules: ['No smoking', 'Mask required'],
    );
  }
}

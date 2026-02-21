import '../models/user.dart';
import '../models/vehicle.dart';
import '../models/ride.dart';
import '../models/message.dart';
import '../models/rating.dart';
import '../models/payment_method.dart';
import '../models/booking.dart';
import '../models/notification.dart';

/// Mock data service for development - Pakistani version
class MockDataService {
  // Current logged in user (for demo)
  static User currentUser = _users[0];

  // Sample users with Pakistani names
  static final List<User> _users = [
    User(
      id: '1',
      name: 'Ayesha Khan',
      phone: '+92 300 1234567',
      email: 'ayesha.khan@email.com',
      gender: Gender.female,
      role: UserRole.both,
      rating: 4.8,
      totalRides: 45,
      totalRidesAsDriver: 23,
      phoneVerified: true,
      emailVerified: true,
      idVerified: true,
      vehicleVerified: true,
      homeAddress: 'Gulberg, Lahore',
      workAddress: 'DHA Phase 5, Lahore',
      preferFemaleOnlyRides: true,
      emergencyContacts: ['+92 300 1234568'],
    ),
    User(
      id: '2',
      name: 'Ali Hassan',
      phone: '+92 321 9876543',
      email: 'ali.hassan@email.com',
      gender: Gender.male,
      role: UserRole.driver,
      rating: 4.9,
      totalRides: 12,
      totalRidesAsDriver: 67,
      phoneVerified: true,
      emailVerified: true,
      idVerified: true,
      vehicleVerified: true,
      homeAddress: 'Model Town, Lahore',
      workAddress: 'Mall Road, Lahore',
    ),
    User(
      id: '3',
      name: 'Fatima Malik',
      phone: '+92 333 4567890',
      email: 'fatima.malik@email.com',
      gender: Gender.female,
      role: UserRole.passenger,
      rating: 4.7,
      totalRides: 34,
      totalRidesAsDriver: 0,
      phoneVerified: true,
      emailVerified: true,
      idVerified: false,
      homeAddress: 'Johar Town, Lahore',
      workAddress: 'Gulberg, Lahore',
      preferFemaleOnlyRides: true,
    ),
    User(
      id: '4',
      name: 'Usman Ahmed',
      phone: '+92 345 1122334',
      email: 'usman.ahmed@email.com',
      gender: Gender.male,
      role: UserRole.driver,
      rating: 4.6,
      totalRides: 8,
      totalRidesAsDriver: 42,
      phoneVerified: true,
      emailVerified: false,
      idVerified: true,
      vehicleVerified: true,
      homeAddress: 'Johar Town, Lahore',
      workAddress: 'Mall Road, Lahore',
    ),
    User(
      id: '5',
      name: 'Zainab Ali',
      phone: '+92 300 9988776',
      email: 'zainab.ali@email.com',
      gender: Gender.female,
      role: UserRole.both,
      rating: 4.9,
      totalRides: 56,
      totalRidesAsDriver: 31,
      phoneVerified: true,
      emailVerified: true,
      idVerified: true,
      vehicleVerified: true,
      homeAddress: 'Cantt, Lahore',
      workAddress: 'DHA Phase 5, Lahore',
    ),
    User(
      id: '6',
      name: 'Hassan Raza',
      phone: '+92 312 5566778',
      email: 'hassan.raza@email.com',
      gender: Gender.male,
      role: UserRole.driver,
      rating: 4.5,
      totalRides: 5,
      totalRidesAsDriver: 28,
      phoneVerified: true,
      emailVerified: true,
      idVerified: true,
      vehicleVerified: false,
      homeAddress: 'Wapda Town, Lahore',
      workAddress: 'Allama Iqbal Town, Lahore',
    ),
  ];

  // Sample vehicles
  static final List<Vehicle> _vehicles = [
    Vehicle(
      id: 'v1',
      model: 'Honda Civic 2020',
      color: 'Silver',
      plateNumber: 'LEA-1234',
      seats: 4,
      verified: true,
    ),
    Vehicle(
      id: 'v2',
      model: 'Toyota Corolla 2019',
      color: 'White',
      plateNumber: 'KHI-5678',
      seats: 4,
      verified: true,
    ),
    Vehicle(
      id: 'v3',
      model: 'Suzuki Alto 2021',
      color: 'Red',
      plateNumber: 'ISB-9012',
      seats: 3,
      verified: false,
    ),
  ];

  // Sample locations (Lahore only)
  static final List<Location> _locations = [
    Location(address: 'Gulberg, Lahore', latitude: 31.5204, longitude: 74.3587),
    Location(
      address: 'DHA Phase 5, Lahore',
      latitude: 31.4697,
      longitude: 74.4084,
    ),
    Location(
      address: 'Johar Town, Lahore',
      latitude: 31.4697,
      longitude: 74.2728,
    ),
    Location(
      address: 'Mall Road, Lahore',
      latitude: 31.5656,
      longitude: 74.3242,
    ),
    Location(
      address: 'Model Town, Lahore',
      latitude: 31.4814,
      longitude: 74.3436,
    ),
    Location(
      address: 'Bahria Town, Lahore',
      latitude: 31.3426,
      longitude: 74.1863,
    ),
    Location(address: 'Cantt, Lahore', latitude: 31.5497, longitude: 74.3436),
    Location(
      address: 'Faisal Town, Lahore',
      latitude: 31.4315,
      longitude: 74.2572,
    ),
    Location(
      address: 'Allama Iqbal Town, Lahore',
      latitude: 31.5081,
      longitude: 74.3031,
    ),
    Location(
      address: 'Wapda Town, Lahore',
      latitude: 31.4167,
      longitude: 74.2667,
    ),
  ];

  // Sample rides with Lahore locations and PKR currency
  static List<Ride> getMockRides() {
    final now = DateTime.now();

    return [
      Ride(
        id: 'r1',
        driver: _users[1], // Ali Hassan
        vehicle: _vehicles[0],
        origin: _locations[0], // Gulberg, Lahore
        destination: _locations[1], // DHA Phase 5, Lahore
        departureTime: now.add(const Duration(hours: 2)),
        estimatedArrivalTime: now.add(const Duration(hours: 2, minutes: 30)),
        pricePerSeat: 150, // PKR
        totalSeats: 3,
        availableSeats: 2,
        femaleOnly: false,
        rules: ['No smoking', 'AC on'],
        meetupInstructions: 'Main gate near Liberty Market',
        distanceKm: 12.5,
        durationMinutes: 30,
      ),
      Ride(
        id: 'r2',
        driver: _users[0], // Ayesha Khan (female driver)
        vehicle: _vehicles[1],
        origin: _locations[4], // F-7, Islamabad
        destination: _locations[5], // Blue Area, Islamabad
        departureTime: now.add(const Duration(hours: 1)),
        estimatedArrivalTime: now.add(const Duration(hours: 1, minutes: 20)),
        pricePerSeat: 100, // PKR
        totalSeats: 3,
        availableSeats: 3,
        femaleOnly: true, // Female only ride
        rules: ['Female passengers only', 'No smoking', 'Quiet ride'],
        meetupInstructions: 'Near Jinnah Super Market',
        distanceKm: 8.0,
        durationMinutes: 20,
      ),
      Ride(
        id: 'r3',
        driver: _users[3], // Usman Ahmed
        vehicle: _vehicles[0],
        origin: _locations[7], // Johar Town, Lahore
        destination: _locations[8], // Mall Road, Lahore
        departureTime: now.add(const Duration(hours: 3)),
        estimatedArrivalTime: now.add(const Duration(hours: 3, minutes: 25)),
        pricePerSeat: 120, // PKR
        totalSeats: 4,
        availableSeats: 1,
        femaleOnly: false,
        rules: ['Music allowed', 'AC on'],
        distanceKm: 10.0,
        durationMinutes: 25,
      ),
      Ride(
        id: 'r4',
        driver: _users[4], // Zainab Ali (female driver)
        vehicle: _vehicles[1],
        origin: _locations[6], // Bahria Town, Rawalpindi
        destination: _locations[9], // Saddar, Rawalpindi
        departureTime: now.add(const Duration(hours: 4)),
        estimatedArrivalTime: now.add(const Duration(hours: 4, minutes: 35)),
        pricePerSeat: 180, // PKR
        totalSeats: 3,
        availableSeats: 2,
        femaleOnly: true, // Female only ride
        rules: ['Female passengers only', 'No smoking'],
        meetupInstructions: 'Main entrance, Phase 4',
        distanceKm: 15.0,
        durationMinutes: 35,
      ),
      Ride(
        id: 'r5',
        driver: _users[1], // Ali Hassan
        vehicle: _vehicles[0],
        origin: _locations[2], // Clifton, Karachi
        destination: _locations[3], // I.I. Chundrigar Road, Karachi
        departureTime: now.add(const Duration(days: 1, hours: 8)),
        estimatedArrivalTime: now.add(
          const Duration(days: 1, hours: 8, minutes: 40),
        ),
        pricePerSeat: 200, // PKR
        totalSeats: 3,
        availableSeats: 3,
        femaleOnly: false,
        rules: ['No smoking', 'AC on', 'Luggage allowed'],
        distanceKm: 18.0,
        durationMinutes: 40,
      ),
    ];
  }

  // Payment methods with PKR
  static List<PaymentMethod> getPaymentMethods() {
    return [
      PaymentMethod(
        id: 'pm1',
        type: PaymentMethodType.cash,
        displayName: 'Cash (PKR)',
        isDefault: true,
      ),
      PaymentMethod(
        id: 'pm2',
        type: PaymentMethodType.card,
        displayName: 'Debit/Credit Card',
        isDefault: false,
      ),
      PaymentMethod(
        id: 'pm3',
        type: PaymentMethodType.wallet,
        displayName: 'JazzCash / Easypaisa',
        isDefault: false,
      ),
    ];
  }

  // Get all vehicles
  static List<Vehicle> getAllVehicles() => _vehicles;

  // Get all locations
  static List<Location> getAllLocations() => _locations;

  // Get user by ID
  static User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get sample conversations
  static List<Conversation> getConversations() {
    return [
      Conversation(
        id: 'c1',
        rideId: 'r1',
        otherUser: _users[1],
        lastMessage: Message(
          id: 'm1',
          conversationId: 'c1',
          senderId: _users[1].id,
          receiverId: currentUser.id,
          content: 'Main 5 minutes mein pohanchta hoon',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        unreadCount: 1,
      ),
    ];
  }

  // Get messages for a conversation
  static List<Message> getMessages(String userId) {
    return [
      Message(
        id: 'm1',
        conversationId: 'c1',
        senderId: userId,
        receiverId: currentUser.id,
        content: 'Assalam o Alaikum! Kya aap tayar hain?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Message(
        id: 'm2',
        conversationId: 'c1',
        senderId: currentUser.id,
        receiverId: userId,
        content: 'Walaikum Assalam! Haan, main tayar hoon',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      Message(
        id: 'm3',
        conversationId: 'c1',
        senderId: userId,
        receiverId: currentUser.id,
        content: 'Main 5 minutes mein pohanchta hoon',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  // Alias for compatibility
  static List<Message> getMessagesForConversation(
    String userId1,
    String userId2,
  ) {
    return getMessages(userId2);
  }

  // Get notifications
  static List<AppNotification> getNotifications() {
    return [
      AppNotification(
        id: 'n1',
        userId: currentUser.id,
        type: NotificationType.bookingConfirmed,
        title: 'Booking Confirmed',
        message: 'Aapki ride Gulberg se DHA Phase 5 tak confirm ho gayi hai',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        read: false,
        rideId: 'r1',
      ),
      AppNotification(
        id: 'n2',
        userId: currentUser.id,
        type: NotificationType.rideStarting,
        title: 'Ride Starting Soon',
        message: 'Aapki ride 30 minutes mein shuru hogi',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        read: true,
        rideId: 'r1',
      ),
    ];
  }
}

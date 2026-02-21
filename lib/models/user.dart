import 'user_preferences.dart';

enum Gender { male, female, preferNotToSay }

enum UserRole { passenger, driver, both }

enum VerificationStatus { none, inProgress, pending, verified }

enum VerificationLevel { none, partial, full }

/// Stores Cloudinary URLs for verification images
class VerificationImages {
  final String? cnicImageUrl;
  final String? faceImageUrl;
  final FingerprintImages? fingerprintImages;

  const VerificationImages({
    this.cnicImageUrl,
    this.faceImageUrl,
    this.fingerprintImages,
  });

  Map<String, dynamic> toMap() {
    return {
      'cnicImageUrl': cnicImageUrl,
      'faceImageUrl': faceImageUrl,
      'fingerprintImages': fingerprintImages?.toMap(),
    };
  }

  factory VerificationImages.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const VerificationImages();
    return VerificationImages(
      cnicImageUrl: map['cnicImageUrl'] as String?,
      faceImageUrl: map['faceImageUrl'] as String?,
      fingerprintImages: map['fingerprintImages'] != null
          ? FingerprintImages.fromMap(
              map['fingerprintImages'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  VerificationImages copyWith({
    String? cnicImageUrl,
    String? faceImageUrl,
    FingerprintImages? fingerprintImages,
  }) {
    return VerificationImages(
      cnicImageUrl: cnicImageUrl ?? this.cnicImageUrl,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      fingerprintImages: fingerprintImages ?? this.fingerprintImages,
    );
  }
}

/// Stores Cloudinary URLs for fingerprint images
class FingerprintImages {
  final String? leftHandUrl;
  final String? rightHandUrl;

  const FingerprintImages({this.leftHandUrl, this.rightHandUrl});

  Map<String, dynamic> toMap() {
    return {'leftHandUrl': leftHandUrl, 'rightHandUrl': rightHandUrl};
  }

  factory FingerprintImages.fromMap(Map<String, dynamic> map) {
    return FingerprintImages(
      leftHandUrl: map['leftHandUrl'] as String?,
      rightHandUrl: map['rightHandUrl'] as String?,
    );
  }

  FingerprintImages copyWith({String? leftHandUrl, String? rightHandUrl}) {
    return FingerprintImages(
      leftHandUrl: leftHandUrl ?? this.leftHandUrl,
      rightHandUrl: rightHandUrl ?? this.rightHandUrl,
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? profileImageUrl; // Cloudinary profile image URL
  final Gender gender;
  final double rating;
  final int totalRides;
  final int totalRidesAsDriver;
  final UserRole role;

  // Verification
  final bool phoneVerified;
  final bool emailVerified;
  final bool idVerified;
  final bool faceVerified;
  final bool fingerprintsVerified;
  final bool vehicleVerified;
  final VerificationStatus verificationStatus;
  final VerificationLevel verificationLevel;
  final DateTime? verificationDate;
  final VerificationImages?
  verificationImages; // Cloudinary verification image URLs

  // Preferences
  final String? homeAddress;
  final String? workAddress;
  final bool preferFemaleOnlyRides;
  final List<String> emergencyContacts;

  // Settings
  final bool notificationsEnabled;
  final bool locationSharingEnabled;

  // User Preferences (ride matching)
  final UserPreferences? preferences;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.profileImageUrl,
    required this.gender,
    this.rating = 0.0,
    this.totalRides = 0,
    this.totalRidesAsDriver = 0,
    this.role = UserRole.passenger,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.idVerified = false,
    this.faceVerified = false,
    this.fingerprintsVerified = false,
    this.vehicleVerified = false,
    this.verificationStatus = VerificationStatus.none,
    this.verificationLevel = VerificationLevel.none,
    this.verificationDate,
    this.verificationImages,
    this.homeAddress,
    this.workAddress,
    this.preferFemaleOnlyRides = false,
    this.emergencyContacts = const [],
    this.notificationsEnabled = true,
    this.locationSharingEnabled = true,
    this.preferences,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? profileImageUrl,
    Gender? gender,
    double? rating,
    int? totalRides,
    int? totalRidesAsDriver,
    UserRole? role,
    bool? phoneVerified,
    bool? emailVerified,
    bool? idVerified,
    bool? faceVerified,
    bool? fingerprintsVerified,
    bool? vehicleVerified,
    VerificationStatus? verificationStatus,
    VerificationLevel? verificationLevel,
    DateTime? verificationDate,
    VerificationImages? verificationImages,
    String? homeAddress,
    String? workAddress,
    bool? preferFemaleOnlyRides,
    List<String>? emergencyContacts,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
    UserPreferences? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      totalRidesAsDriver: totalRidesAsDriver ?? this.totalRidesAsDriver,
      role: role ?? this.role,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      idVerified: idVerified ?? this.idVerified,
      faceVerified: faceVerified ?? this.faceVerified,
      fingerprintsVerified: fingerprintsVerified ?? this.fingerprintsVerified,
      vehicleVerified: vehicleVerified ?? this.vehicleVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      verificationDate: verificationDate ?? this.verificationDate,
      verificationImages: verificationImages ?? this.verificationImages,
      homeAddress: homeAddress ?? this.homeAddress,
      workAddress: workAddress ?? this.workAddress,
      preferFemaleOnlyRides:
          preferFemaleOnlyRides ?? this.preferFemaleOnlyRides,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationSharingEnabled:
          locationSharingEnabled ?? this.locationSharingEnabled,
      preferences: preferences ?? this.preferences,
    );
  }

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'profileImageUrl': profileImageUrl,
      'gender': gender.name,
      'rating': rating,
      'totalRides': totalRides,
      'totalRidesAsDriver': totalRidesAsDriver,
      'role': role.name,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'idVerified': idVerified,
      'faceVerified': faceVerified,
      'fingerprintsVerified': fingerprintsVerified,
      'vehicleVerified': vehicleVerified,
      'verificationStatus': verificationStatus.name,
      'verificationLevel': verificationLevel.name,
      'verificationDate': verificationDate?.millisecondsSinceEpoch,
      'verificationImages': verificationImages?.toMap(),
      'homeAddress': homeAddress,
      'workAddress': workAddress,
      'preferFemaleOnlyRides': preferFemaleOnlyRides,
      'emergencyContacts': emergencyContacts,
      'notificationsEnabled': notificationsEnabled,
      'locationSharingEnabled': locationSharingEnabled,
      'preferences': preferences?.toMap(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      gender: Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.preferNotToSay,
      ),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalRides: map['totalRides'] as int? ?? 0,
      totalRidesAsDriver: map['totalRidesAsDriver'] as int? ?? 0,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.passenger,
      ),
      phoneVerified: map['phoneVerified'] as bool? ?? false,
      emailVerified: map['emailVerified'] as bool? ?? false,
      idVerified: map['idVerified'] as bool? ?? false,
      faceVerified: map['faceVerified'] as bool? ?? false,
      fingerprintsVerified: map['fingerprintsVerified'] as bool? ?? false,
      vehicleVerified: map['vehicleVerified'] as bool? ?? false,
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == map['verificationStatus'],
        orElse: () => VerificationStatus.none,
      ),
      verificationLevel: VerificationLevel.values.firstWhere(
        (e) => e.name == map['verificationLevel'],
        orElse: () => VerificationLevel.none,
      ),
      verificationDate: map['verificationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['verificationDate'] as int)
          : null,
      verificationImages: VerificationImages.fromMap(
        map['verificationImages'] as Map<String, dynamic>?,
      ),
      homeAddress: map['homeAddress'] as String?,
      workAddress: map['workAddress'] as String?,
      preferFemaleOnlyRides: map['preferFemaleOnlyRides'] as bool? ?? false,
      emergencyContacts: List<String>.from(map['emergencyContacts'] ?? []),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      locationSharingEnabled: map['locationSharingEnabled'] as bool? ?? true,
      preferences: map['preferences'] != null
          ? UserPreferences.fromMap(map['preferences'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Firestore compatibility - alias for fromMap
  factory User.fromFirestore(Map<String, dynamic> data) => User.fromMap(data);

  /// Firestore compatibility - alias for toMap
  Map<String, dynamic> toFirestore() => toMap();
}

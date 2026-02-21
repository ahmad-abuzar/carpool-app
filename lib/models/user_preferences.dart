import 'package:carpool_app/models/ride.dart';
import 'package:carpool_app/models/preferences_enums.dart';

/// Office/workplace information
class OfficeInfo {
  final String name;
  final Location location;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"

  const OfficeInfo({
    required this.name,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location.toMap(),
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory OfficeInfo.fromMap(Map<String, dynamic> map) {
    return OfficeInfo(
      name: map['name'] as String,
      location: Location.fromMap(map['location'] as Map<String, dynamic>),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
    );
  }

  OfficeInfo copyWith({
    String? name,
    Location? location,
    String? startTime,
    String? endTime,
  }) {
    return OfficeInfo(
      name: name ?? this.name,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// User behavioral preferences for smart matching
class UserPreferences {
  final OfficeInfo office;
  final MusicPreference musicPreference;
  final TalkPreference talkPreference;
  final GenderPreference genderPreference;
  final RideFrequency rideFrequency;
  final String? companyEmail;
  final bool emailVerified;

  const UserPreferences({
    required this.office,
    required this.musicPreference,
    required this.talkPreference,
    required this.genderPreference,
    required this.rideFrequency,
    this.companyEmail,
    this.emailVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'office': office.toMap(),
      'music_preference': musicPreference.name,
      'talk_preference': talkPreference.name,
      'gender_preference': genderPreference.name,
      'ride_frequency': rideFrequency.name,
      'company_email': companyEmail,
      'email_verified': emailVerified,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      office: OfficeInfo.fromMap(map['office'] as Map<String, dynamic>),
      musicPreference: MusicPreference.values.firstWhere(
        (e) => e.name == map['music_preference'],
        orElse: () => MusicPreference.none,
      ),
      talkPreference: TalkPreference.values.firstWhere(
        (e) => e.name == map['talk_preference'],
        orElse: () => TalkPreference.normal,
      ),
      genderPreference: GenderPreference.values.firstWhere(
        (e) => e.name == map['gender_preference'],
        orElse: () => GenderPreference.any,
      ),
      rideFrequency: RideFrequency.values.firstWhere(
        (e) => e.name == map['ride_frequency'],
        orElse: () => RideFrequency.occasional,
      ),
      companyEmail: map['company_email'] as String?,
      emailVerified: map['email_verified'] as bool? ?? false,
    );
  }

  UserPreferences copyWith({
    OfficeInfo? office,
    MusicPreference? musicPreference,
    TalkPreference? talkPreference,
    GenderPreference? genderPreference,
    RideFrequency? rideFrequency,
    String? companyEmail,
    bool? emailVerified,
  }) {
    return UserPreferences(
      office: office ?? this.office,
      musicPreference: musicPreference ?? this.musicPreference,
      talkPreference: talkPreference ?? this.talkPreference,
      genderPreference: genderPreference ?? this.genderPreference,
      rideFrequency: rideFrequency ?? this.rideFrequency,
      companyEmail: companyEmail ?? this.companyEmail,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

/// Auto-calculated behavioral scores
class BehavioralScores {
  final double punctualityScore; // 0-100
  final double completionRate; // 0-100
  final double averageRating; // 0-5

  const BehavioralScores({
    this.punctualityScore = 100.0,
    this.completionRate = 100.0,
    this.averageRating = 5.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'punctuality_score': punctualityScore,
      'completion_rate': completionRate,
      'average_rating': averageRating,
    };
  }

  factory BehavioralScores.fromMap(Map<String, dynamic> map) {
    return BehavioralScores(
      punctualityScore: (map['punctuality_score'] as num?)?.toDouble() ?? 100.0,
      completionRate: (map['completion_rate'] as num?)?.toDouble() ?? 100.0,
      averageRating: (map['average_rating'] as num?)?.toDouble() ?? 5.0,
    );
  }
}

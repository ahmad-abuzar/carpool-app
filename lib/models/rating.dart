import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String ratedUserId;
  final String raterUserId;
  final int stars; // 1-5
  final List<String> tags; // e.g., "On time", "Safe driving", "Friendly"
  final String? comment;
  final String rideId;
  final DateTime timestamp;

  const Rating({
    required this.id,
    required this.ratedUserId,
    required this.raterUserId,
    required this.stars,
    this.tags = const [],
    this.comment,
    required this.rideId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ratedUserId': ratedUserId,
      'raterUserId': raterUserId,
      'stars': stars,
      'tags': tags,
      'comment': comment,
      'rideId': rideId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      id: map['id'] ?? '',
      ratedUserId: map['ratedUserId'] ?? '',
      raterUserId: map['raterUserId'] ?? '',
      stars: map['stars'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      comment: map['comment'],
      rideId: map['rideId'] ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
                DateTime.now(),
    );
  }
}

// Common rating tags
class RatingTags {
  static const List<String> driverTags = [
    'Safe driving',
    'On time',
    'Friendly',
    'Clean car',
    'Good music',
    'Smooth ride',
  ];

  static const List<String> passengerTags = [
    'On time',
    'Friendly',
    'Respectful',
    'Good conversation',
    'Quiet',
  ];
}

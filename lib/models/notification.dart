import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  bookingConfirmed,
  bookingCancelled,
  rideStarting,
  driverArriving,
  rideCompleted,
  paymentReceived,
  newMessage,
  incomingCall,
  ratingRequest,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;
  final String? rideId;
  final String? actionUrl;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
    this.rideId,
    this.actionUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'rideId': rideId,
      'actionUrl': actionUrl,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.newMessage,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
                DateTime.now(),
      read: map['read'] ?? false,
      rideId: map['rideId'],
      actionUrl: map['actionUrl'],
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      read: read ?? this.read,
      rideId: rideId,
      actionUrl: actionUrl,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification.dart';

/// Notification Service
/// Handles all in-app notification operations via Firestore
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Create a notification
  Future<String> createNotification(AppNotification notification) async {
    try {
      final docRef = _firestore.collection(_collection).doc(notification.id);
      await docRef.set(notification.toMap());
      return notification.id;
    } catch (e) {
      print('❌ NotificationService: Error creating notification: $e');
      rethrow;
    }
  }

  /// Get notifications for a user (paginated)
  Future<List<AppNotification>> getNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AppNotification.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ NotificationService: Error getting notifications: $e');
      return [];
    }
  }

  /// Listen to notifications for a user (real-time)
  Stream<List<AppNotification>> listenToNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return AppNotification.fromMap(data);
          }).toList();
        });
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('❌ NotificationService: Error marking as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ NotificationService: Error marking all as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ NotificationService: Error getting unread count: $e');
      return 0;
    }
  }

  /// Stream of unread count
  Stream<int> listenToUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('❌ NotificationService: Error deleting notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('❌ NotificationService: Error deleting all notifications: $e');
    }
  }

  // ─── Helper methods for creating specific notification types ───

  /// Create a booking notification
  Future<void> createBookingNotification({
    required String userId,
    required String rideId,
    required NotificationType type,
    required String title,
    required String message,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      rideId: rideId,
    );
    await createNotification(notification);
  }

  /// Create a ride-related notification
  Future<void> createRideNotification({
    required String userId,
    required String rideId,
    required String title,
    required String message,
    NotificationType type = NotificationType.rideStarting,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      rideId: rideId,
    );
    await createNotification(notification);
  }

  /// Create a payment notification
  Future<void> createPaymentNotification({
    required String userId,
    required String rideId,
    required double amount,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      userId: userId,
      type: NotificationType.paymentReceived,
      title: 'Payment Received',
      message: 'You received Rs ${amount.toStringAsFixed(0)} for your ride.',
      timestamp: DateTime.now(),
      rideId: rideId,
    );
    await createNotification(notification);
  }

  /// Create a rating request notification
  Future<void> createRatingRequestNotification({
    required String userId,
    required String rideId,
    required String driverName,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      userId: userId,
      type: NotificationType.ratingRequest,
      title: 'Rate Your Ride',
      message: 'How was your ride with $driverName? Rate now!',
      timestamp: DateTime.now(),
      rideId: rideId,
    );
    await createNotification(notification);
  }
}

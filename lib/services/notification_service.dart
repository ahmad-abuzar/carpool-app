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
      print(
        '❌ NotificationService: Error creating notification for user ${notification.userId}: $e',
      );
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
          .get();

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AppNotification.fromMap(data);
      }).toList();

      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications.take(limit).toList();
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
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return AppNotification.fromMap(data);
          }).toList();

          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return notifications.take(50).toList();
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
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final isRead = doc.data()['read'] == true;
        if (!isRead) {
          batch.update(doc.reference, {'read': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('❌ NotificationService: Error marking all as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final notifications = await getNotifications(userId, limit: 200);
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      print('❌ NotificationService: Error getting unread count: $e');
      return 0;
    }
  }

  /// Stream of unread count
  Stream<int> listenToUnreadCount(String userId) {
    return listenToNotifications(userId).map(
      (notifications) => notifications.where((n) => !n.read).length,
    );
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

  /// Create a new message notification
  Future<void> createMessageNotification({
    required String userId,
    required String senderName,
    required String messagePreview,
    String? rideId,
  }) async {
    final preview = messagePreview.trim();
    final truncated = preview.length > 80
        ? '${preview.substring(0, 80)}...'
        : preview;

    final notification = AppNotification(
      id: const Uuid().v4(),
      userId: userId,
      type: NotificationType.newMessage,
      title: 'New message from $senderName',
      message: truncated,
      timestamp: DateTime.now(),
      rideId: rideId,
      actionUrl: '/messages',
    );
    await createNotification(notification);
  }

  /// Create an incoming call notification
  Future<void> createIncomingCallNotification({
    required String userId,
    required String callerName,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      userId: userId,
      type: NotificationType.incomingCall,
      title: 'Incoming call',
      message: '$callerName is calling you',
      timestamp: DateTime.now(),
      actionUrl: '/messages',
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

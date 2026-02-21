import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

/// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// User Notifications Provider (real-time stream)
final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return service.listenToNotifications(user.id);
});

/// Unread Notification Count Provider (real-time)
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value(0);
  }

  return service.listenToUnreadCount(user.id);
});

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

  return (() async* {
    try {
      await for (final notifications in service.listenToNotifications(user.id)) {
        yield notifications;
      }
    } catch (e) {
      print('❌ userNotificationsProvider stream error: $e');
      yield <AppNotification>[];
    }
  })();
});

/// Unread Notification Count Provider (real-time)
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value(0);
  }

  return (() async* {
    try {
      await for (final count in service.listenToUnreadCount(user.id)) {
        yield count;
      }
    } catch (e) {
      print('❌ unreadNotificationCountProvider stream error: $e');
      yield 0;
    }
  })();
});

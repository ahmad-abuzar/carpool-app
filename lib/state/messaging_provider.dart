import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../services/messaging_service.dart';
import '../services/mock_data_service.dart';
import 'auth_provider.dart'; // Contains firestoreServiceProvider

// Messaging Service Provider
final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService();
});

// Conversations stream provider
final conversationsProvider = StreamProvider<List<Conversation>>((ref) async* {
  final messagingService = ref.watch(messagingServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  print('💬 ConversationsProvider: Initializing...');

  if (currentUser == null) {
    print('⚠️ ConversationsProvider: No current user, returning empty list');
    yield [];
    return;
  }

  print('💬 ConversationsProvider: Listening for user ${currentUser.id}');

  await for (final conversationsList in messagingService.listenToConversations(
    currentUser.id,
  )) {
    print(
      '💬 ConversationsProvider: Received ${conversationsList.length} raw conversations',
    );

    final conversations = <Conversation>[];

    for (final convMap in conversationsList) {
      try {
        // Get participants list
        final participants = List<String>.from(convMap['participants'] ?? []);
        print('   Processing conversation with participants: $participants');

        // Find the other user ID
        final otherUserId = participants.firstWhere(
          (id) => id != currentUser.id,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) {
          print('   ⚠️ No other user found, skipping');
          continue;
        }

        print('   Fetching user data for: $otherUserId');

        // Fetch other user data
        final otherUserData = await ref
            .read(firestoreServiceProvider)
            .getDocument(collection: 'users', docId: otherUserId);

        if (otherUserData == null) {
          print('   ⚠️ User data not found for $otherUserId, skipping');
          continue;
        }

        // Create conversation with proper user data
        final conversation = Conversation(
          id: convMap['id'] as String,
          otherUser: User.fromMap({...otherUserData, 'id': otherUserId}),
          lastMessage: convMap['lastMessage'] != null
              ? Message.fromMap(convMap['lastMessage'] as Map<String, dynamic>)
              : null,
          unreadCount: convMap['unreadCount'] as int? ?? 0,
          rideId: convMap['rideId'] as String?,
        );

        print('   ✅ Added conversation with ${conversation.otherUser.name}');
        conversations.add(conversation);
      } catch (e, stack) {
        print('❌ ConversationsProvider: Error processing conversation: $e');
        print('   Stack: $stack');
        continue;
      }
    }

    print(
      '✅ ConversationsProvider: Yielding ${conversations.length} conversations',
    );
    yield conversations;
  }
});

// Messages stream provider for a specific chat
final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  otherUserId,
) {
  final messagingService = ref.watch(messagingServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) return Stream.value([]);

  return messagingService.listenToMessages(currentUser.id, otherUserId);
});

// Notifications provider
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
      return NotificationsNotifier();
    });

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(MockDataService.getNotifications());

  void refreshNotifications() {
    state = MockDataService.getNotifications();
  }

  void markAsRead(String notificationId) {
    state = [
      for (final notif in state)
        if (notif.id == notificationId) notif.copyWith(read: true) else notif,
    ];
  }

  void markAllAsRead() {
    state = [for (final notif in state) notif.copyWith(read: true)];
  }

  int get unreadCount {
    return state.where((notif) => !notif.read).length;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Test Data Helper for Messaging
/// Use this to create sample conversations and messages for testing
class MessagingTestHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a test conversation between two users
  Future<void> createTestConversation({
    required String userId1,
    required String userId2,
    String? rideId,
  }) async {
    final conversationId = _getConversationId(userId1, userId2);

    // Create a test message
    final testMessage = {
      'id': 'test_msg_${DateTime.now().millisecondsSinceEpoch}',
      'conversationId': conversationId,
      'senderId': userId1,
      'receiverId': userId2,
      'content': 'Hello! This is a test message.',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'read': false,
      'rideId': rideId,
    };

    // Create conversation
    await _firestore.collection('conversations').doc(conversationId).set({
      'id': conversationId,
      'participants': [userId1, userId2],
      'lastMessage': testMessage,
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': FieldValue.serverTimestamp(),
      'rideId': rideId,
    });

    // Create message document
    await _firestore.collection('messages').add(testMessage);

    // Set unread count for receiver
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('metadata')
        .doc(userId2)
        .set({'unreadCount': 1});

    print('✅ Test conversation created: $conversationId');
  }

  /// Create multiple test messages in an existing conversation
  Future<void> createTestMessages({
    required String userId1,
    required String userId2,
    int count = 5,
  }) async {
    final conversationId = _getConversationId(userId1, userId2);

    final messages = [
      'Hey, are you available for a ride tomorrow?',
      'Yes! What time?',
      'Around 9 AM, is that okay?',
      'Perfect! See you then.',
      'Great, thanks!',
    ];

    for (int i = 0; i < count && i < messages.length; i++) {
      final isFromUser1 = i % 2 == 0;
      final message = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_$i',
        'conversationId': conversationId,
        'senderId': isFromUser1 ? userId1 : userId2,
        'receiverId': isFromUser1 ? userId2 : userId1,
        'content': messages[i],
        'timestamp': DateTime.now()
            .subtract(Duration(hours: count - i))
            .millisecondsSinceEpoch,
        'read': i < count - 1, // Last message is unread
      };

      await _firestore.collection('messages').add(message);

      // Update conversation with last message
      if (i == count - 1) {
        await _firestore
            .collection('conversations')
            .doc(conversationId)
            .update({
              'lastMessage': message,
              'lastMessageTime': message['timestamp'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    }

    print('✅ Created $count test messages in conversation: $conversationId');
  }

  /// Check if user has any conversations
  Future<void> checkUserConversations(String userId) async {
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    print('📊 User $userId has ${conversations.docs.length} conversations:');

    for (final doc in conversations.docs) {
      final data = doc.data();
      print('  - Conversation ID: ${doc.id}');
      print('    Participants: ${data['participants']}');
      print('    Last Message: ${data['lastMessage']?['content'] ?? 'None'}');
      print('    Last Message Time: ${data['lastMessageTime']}');
      print('');
    }
  }

  /// Check messages in a conversation
  Future<void> checkConversationMessages(String userId1, String userId2) async {
    final conversationId = _getConversationId(userId1, userId2);

    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .get();

    print(
      '📨 Conversation $conversationId has ${messages.docs.length} messages:',
    );

    for (final doc in messages.docs) {
      final data = doc.data();
      print('  - ${data['senderId']}: ${data['content']}');
      print(
        '    Time: ${DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)}',
      );
      print('');
    }
  }

  /// Delete all test data for a user
  Future<void> cleanupTestData(String userId) async {
    // Delete conversations
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    final batch = _firestore.batch();

    for (final doc in conversations.docs) {
      batch.delete(doc.reference);

      // Delete messages in this conversation
      final messages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: doc.id)
          .get();

      for (final msgDoc in messages.docs) {
        batch.delete(msgDoc.reference);
      }
    }

    await batch.commit();
    print('🗑️ Cleaned up test data for user: $userId');
  }

  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}

/// How to use this helper:
/// 
/// 1. Create test conversation:
/// ```dart
/// final helper = MessagingTestHelper();
/// await helper.createTestConversation(
///   userId1: 'current_user_id',
///   userId2: 'other_user_id',
/// );
/// ```
/// 
/// 2. Add more messages:
/// ```dart
/// await helper.createTestMessages(
///   userId1: 'current_user_id',
///   userId2: 'other_user_id',
///   count: 5,
/// );
/// ```
/// 
/// 3. Check what's in Firestore:
/// ```dart
/// await helper.checkUserConversations('current_user_id');
/// await helper.checkConversationMessages('user1', 'user2');
/// ```
/// 
/// 4. Clean up:
/// ```dart
/// await helper.cleanupTestData('current_user_id');
/// ```

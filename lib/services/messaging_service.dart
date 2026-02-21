import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'firestore_service.dart';

/// Messaging Service
/// Handles all messaging and conversation operations
class MessagingService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _messagesCollection = 'messages';
  static const String _conversationsCollection = 'conversations';

  /// Send a message
  Future<String> sendMessage(Message message) async {
    final messageId = await _firestoreService.createDocumentWithAutoId(
      collection: _messagesCollection,
      data: message.toMap(),
    );

    // Update or create conversation
    await _updateConversation(message);

    return messageId;
  }

  /// Update conversation with latest message
  Future<void> _updateConversation(Message message) async {
    final conversationId = _getConversationId(
      message.senderId,
      message.receiverId,
    );

    await _firestoreService.setDocument(
      collection: _conversationsCollection,
      docId: conversationId,
      data: {
        'id': conversationId,
        'participants': [message.senderId, message.receiverId],
        'lastMessage': message.toMap(),
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      merge: true,
    );

    // Increment unread count for receiver
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection('metadata')
        .doc(message.receiverId)
        .set({'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  /// Get conversation ID from two user IDs
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Get messages between two users
  Future<List<Message>> getMessages(String userId1, String userId2) async {
    final conversationId = _getConversationId(userId1, userId2);

    final docs = await _firestoreService.advancedQuery(
      collection: _messagesCollection,
      conditions: [
        QueryCondition(
          field: 'senderId',
          operator: 'in',
          value: [userId1, userId2],
        ),
      ],
      orderByField: 'timestamp',
      descending: false,
      limit: 100,
    );

    // Filter messages between these two users
    final messages = docs
        .map((doc) => Message.fromMap(doc))
        .where(
          (msg) =>
              (msg.senderId == userId1 && msg.receiverId == userId2) ||
              (msg.senderId == userId2 && msg.receiverId == userId1),
        )
        .toList();

    return messages;
  }

  /// Get conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    final docs = await _firestoreService.queryDocuments(
      collection: _conversationsCollection,
      field: 'participants',
      value: userId,
      operator: 'array-contains',
    );

    // Get unread counts
    for (final doc in docs) {
      final conversationId = doc['id'] as String;
      final metadataDoc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection('metadata')
          .doc(userId)
          .get();

      doc['unreadCount'] = metadataDoc.data()?['unreadCount'] ?? 0;
    }

    // Sort by last message time
    docs.sort((a, b) {
      final aTime = a['lastMessageTime'] as int? ?? 0;
      final bTime = b['lastMessageTime'] as int? ?? 0;
      return bTime.compareTo(aTime);
    });

    return docs;
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String userId1, String userId2) async {
    final conversationId = _getConversationId(userId1, userId2);

    // Reset unread count
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection('metadata')
        .doc(userId1)
        .set({'unreadCount': 0}, SetOptions(merge: true));

    // Mark individual messages as read
    final unreadMessages = await _firestoreService.advancedQuery(
      collection: _messagesCollection,
      conditions: [
        QueryCondition(field: 'senderId', operator: '==', value: userId2),
        QueryCondition(field: 'receiverId', operator: '==', value: userId1),
        QueryCondition(field: 'read', operator: '==', value: false),
      ],
    );

    final batch = _firestore.batch();
    for (final msg in unreadMessages) {
      final msgRef = _firestore
          .collection(_messagesCollection)
          .doc(msg['id'] as String);
      batch.update(msgRef, {'read': true});
    }
    await batch.commit();
  }

  /// Get unread message count for user
  Future<int> getUnreadCount(String userId) async {
    final conversations = await getConversations(userId);
    return conversations.fold<int>(
      0,
      (sum, conv) => sum + (conv['unreadCount'] as int? ?? 0),
    );
  }

  /// Delete conversation
  Future<void> deleteConversation(String userId1, String userId2) async {
    final conversationId = _getConversationId(userId1, userId2);

    // Delete conversation document
    await _firestoreService.deleteDocument(
      collection: _conversationsCollection,
      docId: conversationId,
    );

    // Delete all messages
    final messages = await getMessages(userId1, userId2);
    final batch = _firestore.batch();
    for (final msg in messages) {
      final msgRef = _firestore.collection(_messagesCollection).doc(msg.id);
      batch.delete(msgRef);
    }
    await batch.commit();
  }

  /// Delete a single message
  Future<void> deleteMessage(String messageId) async {
    await _firestoreService.deleteDocument(
      collection: _messagesCollection,
      docId: messageId,
    );
  }

  /// Listen to messages between two users
  Stream<List<Message>> listenToMessages(String userId1, String userId2) {
    final conversationId = _getConversationId(userId1, userId2);

    print(
      '💬 MessagingService: Listening to messages for conversation: $conversationId',
    );

    return _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        // Removed orderBy to avoid composite index requirement
        .limit(100)
        .snapshots()
        .map((snapshot) {
          print(
            '💬 MessagingService: Received ${snapshot.docs.length} messages',
          );

          final messages = snapshot.docs
              .map((doc) => Message.fromMap({...doc.data(), 'id': doc.id}))
              .toList();

          // Sort by timestamp in memory (ascending - oldest first)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          return messages;
        });
  }

  /// Listen to conversations for a user
  Stream<List<Map<String, dynamic>>> listenToConversations(String userId) {
    return _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: userId)
        // Removed orderBy to avoid composite index requirement
        .snapshots()
        .map((snapshot) {
          // Get all conversations
          final conversations = snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();

          // Sort by lastMessageTime in memory
          conversations.sort((a, b) {
            final aTime = a['lastMessageTime'] as int? ?? 0;
            final bTime = b['lastMessageTime'] as int? ?? 0;
            return bTime.compareTo(aTime); // Descending order
          });

          return conversations;
        });
  }

  /// Search messages by content
  Future<List<Message>> searchMessages(String userId, String query) async {
    final allMessages = await _firestoreService.queryDocuments(
      collection: _messagesCollection,
      field: 'senderId',
      value: userId,
    );

    final receivedMessages = await _firestoreService.queryDocuments(
      collection: _messagesCollection,
      field: 'receiverId',
      value: userId,
    );

    final combined = [...allMessages, ...receivedMessages];

    // Filter by query
    final filtered = combined
        .map((doc) => Message.fromMap(doc))
        .where((msg) => msg.content.toLowerCase().contains(query.toLowerCase()))
        .toList();

    // Sort by timestamp
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }
}

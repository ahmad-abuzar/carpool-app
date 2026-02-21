import 'user.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool read;
  final String? rideId; // Associated ride if any

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.read = false,
    this.rideId,
  });

  Message copyWith({bool? read}) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      read: read ?? this.read,
      rideId: rideId,
    );
  }

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'read': read,
      'rideId': rideId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String? ?? '',
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      read: map['read'] as bool? ?? false,
      rideId: map['rideId'] as String?,
    );
  }
}

class Conversation {
  final String id;
  final User otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final String? rideId;

  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.rideId,
  });

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'otherUser': otherUser.toMap(),
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'rideId': rideId,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      otherUser: User.fromMap(map['otherUser'] as Map<String, dynamic>),
      lastMessage: map['lastMessage'] != null
          ? Message.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: map['unreadCount'] as int? ?? 0,
      rideId: map['rideId'] as String?,
    );
  }
}

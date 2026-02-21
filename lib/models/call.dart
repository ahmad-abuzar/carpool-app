enum CallType {
  audio,
  video;

  String get displayName {
    switch (this) {
      case CallType.audio:
        return 'Audio Call';
      case CallType.video:
        return 'Video Call';
    }
  }

  String get icon {
    switch (this) {
      case CallType.audio:
        return '📞';
      case CallType.video:
        return '📹';
    }
  }
}

enum CallStatus {
  ringing,
  connecting,
  connected,
  ended,
  rejected,
  missed,
  failed;

  String get displayName {
    switch (this) {
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
      case CallStatus.rejected:
        return 'Call Rejected';
      case CallStatus.missed:
        return 'Missed Call';
      case CallStatus.failed:
        return 'Call Failed';
    }
  }

  bool get isActive => this == CallStatus.connected;
  bool get isEnded => [
    CallStatus.ended,
    CallStatus.rejected,
    CallStatus.missed,
    CallStatus.failed,
  ].contains(this);
}

class Call {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? channelName;
  final int? agoraUid;

  const Call({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.channelName,
    this.agoraUid,
  });

  // Get duration in seconds
  int? get durationInSeconds {
    if (startedAt == null || endedAt == null) return null;
    return endedAt!.difference(startedAt!).inSeconds;
  }

  // Format duration as MM:SS
  String get formattedDuration {
    final duration = durationInSeconds;
    if (duration == null) return '00:00';

    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Call copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverId,
    String? receiverName,
    String? receiverPhotoUrl,
    CallType? type,
    CallStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    String? channelName,
    int? agoraUid,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      channelName: channelName ?? this.channelName,
      agoraUid: agoraUid ?? this.agoraUid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'channelName': channelName,
      'agoraUid': agoraUid,
    };
  }

  factory Call.fromMap(Map<String, dynamic> map) {
    return Call(
      id: map['id'] as String,
      callerId: map['callerId'] as String,
      callerName: map['callerName'] as String,
      callerPhotoUrl: map['callerPhotoUrl'] as String?,
      receiverId: map['receiverId'] as String,
      receiverName: map['receiverName'] as String,
      receiverPhotoUrl: map['receiverPhotoUrl'] as String?,
      type: CallType.values.firstWhere((e) => e.name == map['type']),
      status: CallStatus.values.firstWhere((e) => e.name == map['status']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int)
          : null,
      endedAt: map['endedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endedAt'] as int)
          : null,
      channelName: map['channelName'] as String?,
      agoraUid: map['agoraUid'] as int?,
    );
  }
}

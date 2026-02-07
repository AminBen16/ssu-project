import 'dart:convert';

enum DeliveryStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
}

enum MessageType {
  text,
  image,
  audio,
  emergency,
  system,
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final int timestamp;
  final DeliveryStatus status;
  final MessageType type;
  final bool isEncrypted;
  final String? metadata;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.status = DeliveryStatus.pending,
    this.type = MessageType.text,
    this.isEncrypted = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'status': status.index,
      'type': type.index,
      'isEncrypted': isEncrypted ? 1 : 0,
      'metadata': metadata,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      timestamp: map['timestamp'] as int,
      status: DeliveryStatus.values[map['status'] as int],
      type: MessageType.values[map['type'] as int],
      isEncrypted: (map['isEncrypted'] as int) == 1,
      metadata: map['metadata'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source) as Map<String, dynamic>);

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    int? timestamp,
    DeliveryStatus? status,
    MessageType? type,
    bool? isEncrypted,
    String? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Peer {
  final String id;
  final String deviceId;
  final String name;
  final bool isOnline;
  final int lastSeen;
  final String? publicKey;

  const Peer({
    required this.id,
    required this.deviceId,
    required this.name,
    this.isOnline = false,
    required this.lastSeen,
    this.publicKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'name': name,
      'isOnline': isOnline ? 1 : 0,
      'lastSeen': lastSeen,
      'publicKey': publicKey,
    };
  }

  factory Peer.fromMap(Map<String, dynamic> map) {
    return Peer(
      id: map['id'] as String,
      deviceId: map['deviceId'] as String,
      name: map['name'] as String,
      isOnline: (map['isOnline'] as int) == 1,
      lastSeen: map['lastSeen'] as int,
      publicKey: map['publicKey'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Peer.fromJson(String source) =>
      Peer.fromMap(json.decode(source) as Map<String, dynamic>);

  Peer copyWith({
    String? id,
    String? deviceId,
    String? name,
    bool? isOnline,
    int? lastSeen,
    String? publicKey,
  }) {
    return Peer(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      publicKey: publicKey ?? this.publicKey,
    );
  }
}

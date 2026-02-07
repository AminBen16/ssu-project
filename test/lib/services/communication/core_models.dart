import 'dart:convert';

/// Core domain models for the communication system

/// Key pair for asymmetric encryption
class KeyPair {
  final String publicKey;
  final String privateKey;

  KeyPair({
    required this.publicKey,
    required this.privateKey,
  });
}

/// Status of the mesh network
class MeshStatus {
  final bool isEnabled;
  final bool isConnected;
  final int connectedPeersCount;

  MeshStatus({
    this.isEnabled = false,
    this.isConnected = false,
    this.connectedPeersCount = 0,
  });
}

/// Core message data model for offline-first communication
class Message {
  final String id;
  final String fromDeviceId;
  final String toUserId;
  final MessageType type;
  final DateTime timestamp;
  final int ttlHours;
  final int hopCount;
  final String encryptedPayload;
  final DeliveryStatus status;
  final String? fileName;
  final int? fileSize;
  final String? checksum;
  final bool isEmergency;
  final String? groupId;

  Message({
    required this.id,
    required this.fromDeviceId,
    required this.toUserId,
    required this.type,
    required this.timestamp,
    required this.encryptedPayload,
    this.ttlHours = 48,
    this.hopCount = 0,
    this.status = DeliveryStatus.sending,
    this.fileName,
    this.fileSize,
    this.checksum,
    this.isEmergency = false,
    this.groupId,
  });

  /// Check if message is expired
  bool get isExpired {
    return DateTime.now().difference(timestamp).inHours > ttlHours;
  }

  /// Check if message can be relayed (hop limit)
  bool get canRelay {
    return hopCount < 10; // Max 10 hops
  }

  /// Create a relayed copy with incremented hop count
  Message relay() {
    return Message(
      id: id,
      fromDeviceId: fromDeviceId,
      toUserId: toUserId,
      type: type,
      timestamp: timestamp,
      encryptedPayload: encryptedPayload,
      ttlHours: ttlHours,
      hopCount: hopCount + 1,
      status: status,
      fileName: fileName,
      fileSize: fileSize,
      checksum: checksum,
      isEmergency: isEmergency,
      groupId: groupId,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromDeviceId': fromDeviceId,
      'toUserId': toUserId,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'ttlHours': ttlHours,
      'hopCount': hopCount,
      'encryptedPayload': encryptedPayload,
      'status': status.toString().split('.').last,
      'fileName': fileName,
      'fileSize': fileSize,
      'checksum': checksum,
      'isEmergency': isEmergency,
      'groupId': groupId,
    };
  }

  /// Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      fromDeviceId: json['fromDeviceId'],
      toUserId: json['toUserId'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      ttlHours: json['ttlHours'] ?? 48,
      hopCount: json['hopCount'] ?? 0,
      encryptedPayload: json['encryptedPayload'],
      status: DeliveryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DeliveryStatus.sending,
      ),
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      checksum: json['checksum'],
      isEmergency: json['isEmergency'] ?? false,
      groupId: json['groupId'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, type: $type, status: $status, from: $fromDeviceId)';
  }
}

/// Peer device representation
class Peer {
  final String deviceId;
  final String userId;
  final String displayName;
  final String publicKey;
  final NetworkStatus status;
  final TransportType transportType;
  final DateTime lastSeen;
  final Map<String, dynamic> capabilities;

  Peer({
    required this.deviceId,
    required this.userId,
    required this.displayName,
    required this.publicKey,
    required this.status,
    this.transportType = TransportType.bluetooth,
    required this.lastSeen,
    this.capabilities = const {},
  });

  // Backward compatibility
  String get deviceName => displayName;

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'userId': userId,
      'displayName': displayName,
      'publicKey': publicKey,
      'status': status.toString().split('.').last,
      'transportType': transportType.toString().split('.').last,
      'lastSeen': lastSeen.toIso8601String(),
      'capabilities': capabilities,
    };
  }

  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      deviceId: json['deviceId'],
      userId: json['userId'],
      displayName: json['displayName'],
      publicKey: json['publicKey'],
      status: NetworkStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => NetworkStatus.offline,
      ),
      transportType: TransportType.values.firstWhere(
        (e) => e.toString().split('.').last == json['transportType'],
        orElse: () => TransportType.bluetooth,
      ),
      lastSeen: DateTime.parse(json['lastSeen']),
      capabilities: Map<String, dynamic>.from(json['capabilities'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Peer && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() {
    return 'Peer(id: $deviceId, name: $displayName, status: $status)';
  }
}

/// Network status enumeration
enum NetworkStatus {
  online,
  offline,
  connecting,
  error,
  connected,
  mesh,
  lan,
  internet,
}

/// Transport type enumeration
enum TransportType {
  bluetooth,
  wifiDirect,
  wifiInfrastructure,
  cellular,
  websocket,
  usb,
  mesh,
  lan,
  internet,
}

/// Message type enumeration
enum MessageType {
  text,
  file,
  audio,
  emergency,
}

/// Delivery status enumeration
enum DeliveryStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Emergency alert message
class EmergencyAlert {
  final String id;
  final String senderId;
  final String title;
  final String message;
  final AlertPriority priority;
  final DateTime timestamp;
  final bool broadcastToAll;
  final String? targetGroupId;

  EmergencyAlert({
    required this.id,
    required this.senderId,
    required this.title,
    required this.message,
    required this.priority,
    required this.timestamp,
    this.broadcastToAll = false,
    this.targetGroupId,
  });

  Message toMessage() {
    return Message(
      id: id,
      fromDeviceId: senderId,
      toUserId: broadcastToAll ? 'all' : (targetGroupId ?? ''),
      type: MessageType.emergency,
      timestamp: timestamp,
      encryptedPayload: jsonEncode({
        'title': title,
        'message': message,
        'priority': priority.toString().split('.').last,
        'broadcastToAll': broadcastToAll,
        'targetGroupId': targetGroupId,
      }),
      isEmergency: true,
      groupId: targetGroupId,
    );
  }

  factory EmergencyAlert.fromMessage(Message message) {
    final payload = jsonDecode(message.encryptedPayload);
    return EmergencyAlert(
      id: message.id,
      senderId: message.fromDeviceId,
      title: payload['title'],
      message: payload['message'],
      priority: AlertPriority.values.firstWhere(
        (e) => e.toString().split('.').last == payload['priority'],
      ),
      timestamp: message.timestamp,
      broadcastToAll: payload['broadcastToAll'] ?? false,
      targetGroupId: payload['targetGroupId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'title': title,
      'message': message,
      'priority': priority.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'broadcastToAll': broadcastToAll,
      'targetGroupId': targetGroupId,
    };
  }

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'],
      senderId: json['senderId'],
      title: json['title'],
      message: json['message'],
      priority: AlertPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      broadcastToAll: json['broadcastToAll'] ?? false,
      targetGroupId: json['targetGroupId'],
    );
  }
}

/// Alert priority enumeration
enum AlertPriority {
  low,
  medium,
  high,
  critical,
}

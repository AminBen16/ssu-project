import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/services/communication/core_models.dart';
import 'package:test/services/communication/messaging_interface.dart'
    as msg_interface;
import 'package:uuid/uuid.dart';

/// Main communication service implementing the unified messaging API
class CommunicationService implements msg_interface.CommunicationService {
  final msg_interface.TransportManager _transportManager;
  final msg_interface.MessageStorage _messageStorage;
  final msg_interface.MessageEncryption _encryption;
  final msg_interface.PeerDiscovery _peerDiscovery;
  final String _currentUserId;
  final String _currentDeviceId;

  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<String> _publicMessageStream =
      StreamController<String>.broadcast();

  final Map<String, Message> _pendingMessages = {};
  final Map<String, Timer> _retryTimers = {};
  final Map<String, int> _retryCounts = {};

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 30);

  CommunicationService({
    required msg_interface.TransportManager transportManager,
    required msg_interface.MessageStorage messageStorage,
    required msg_interface.MessageEncryption encryption,
    required msg_interface.PeerDiscovery peerDiscovery,
    required String currentUserId,
    required String currentDeviceId,
  })  : _transportManager = transportManager,
        _messageStorage = messageStorage,
        _encryption = encryption,
        _peerDiscovery = peerDiscovery,
        _currentUserId = currentUserId,
        _currentDeviceId = currentDeviceId;

  @override
  Stream<String> get messageStream => _publicMessageStream.stream;

  /// Stream of full Message objects for internal app usage
  Stream<Message> get richMessageStream => _messageController.stream;

  @override
  Future<void> initialize() async {
    // Start transport layers
    await _transportManager.start();

    // Listen for incoming data from all transports
    _transportManager.dataStream.listen(_handleIncomingData);

    // Start peer discovery
    await _peerDiscovery.startDiscovery();
    _peerDiscovery.peerStream.listen((event) {
      _handlePeerDiscovery(event);
    });

    // Load existing messages
    await _loadExistingMessages();

    // Start periodic cleanup
    Timer.periodic(const Duration(hours: 1), (_) => _cleanupExpiredMessages());
  }

  Future<void> dispose() async {
    await _transportManager.stop();
    await _peerDiscovery.stopDiscovery();

    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();

    await _messageController.close();
    await _publicMessageStream.close();
  }

  @override
  Future<void> sendMessage(String message, String recipientId) async {
    final msg = await createTextMessage(message, recipientId);
    await sendRichMessage(msg);
  }

  @override
  Future<void> broadcastMessage(String message) async {
    final msg = await createTextMessage(message, 'all');
    await sendRichMessage(msg);
  }

  Future<void> sendRichMessage(Message message) async {
    try {
      final encryptedMessage = Message(
        id: message.id,
        fromDeviceId: _currentDeviceId,
        toUserId: message.toUserId,
        type: message.type,
        timestamp: message.timestamp,
        ttlHours: message.ttlHours,
        hopCount: message.hopCount,
        encryptedPayload: message.encryptedPayload,
        status: DeliveryStatus.sending,
        fileName: message.fileName,
        fileSize: message.fileSize,
        checksum: message.checksum,
        isEmergency: message.isEmergency,
        groupId: message.groupId,
      );

      // Store locally first
      await _messageStorage.storeMessage(
          encryptedMessage.id, encryptedMessage.toJson());
      _pendingMessages[message.id] = encryptedMessage;

      // Send via transport
      final messageJson = jsonEncode(encryptedMessage.toJson());
      await _transportManager.sendData(messageJson);

      // Update status
      await _updateMessageStatus(message.id, DeliveryStatus.sent);
    } catch (e) {
      await _updateMessageStatus(message.id, DeliveryStatus.failed);
      rethrow;
    }
  }

  Future<DeliveryStatus> getDeliveryStatus(String messageId) async {
    final message = await _messageStorage.getMessage(messageId);
    if (message == null) return DeliveryStatus.failed;
    return DeliveryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == message['status'],
        orElse: () => DeliveryStatus.failed);
  }

  @override
  Future<List<Peer>> getConnectedPeers() async {
    return await _peerDiscovery.getDiscoveredPeers();
  }

  @override
  Future<NetworkStatus> getNetworkStatus() async {
    // Assuming TransportManager has this method or we derive it
    return NetworkStatus.online; // Placeholder if not in interface
  }

  void _handleIncomingData(String data) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      final message = Message.fromJson(jsonData);

      // Skip our own messages
      if (message.fromDeviceId == _currentDeviceId) return;

      // Check if message is for us or should be relayed
      if (message.toUserId == _currentUserId ||
          message.toUserId == 'all' ||
          message.groupId != null) {
        _handleIncomingMessage(message);
      } else if (message.canRelay && !message.isExpired) {
        // Relay the message
        _relayMessage(message);
      }
    } catch (e) {
      // Invalid message format, ignore
    }
  }

  Future<void> _handleIncomingMessage(Message message) async {
    try {
      String decryptedPayload = message.encryptedPayload;
      if (message.type == MessageType.audio ||
          message.type == MessageType.file) {
        // Keep encrypted for binary types, UI handles decryption
      } else {
        decryptedPayload = await _encryption.decrypt(message.encryptedPayload);
        _publicMessageStream.add(decryptedPayload);
      }

      final decryptedMessage = Message(
        id: message.id,
        fromDeviceId: message.fromDeviceId,
        toUserId: message.toUserId,
        type: message.type,
        timestamp: message.timestamp,
        ttlHours: message.ttlHours,
        hopCount: message.hopCount,
        encryptedPayload: decryptedPayload,
        status: DeliveryStatus.delivered,
        fileName: message.fileName,
        fileSize: message.fileSize,
        checksum: message.checksum,
        isEmergency: message.isEmergency,
        groupId: message.groupId,
      );

      // Store the message
      await _messageStorage.storeMessage(
          decryptedMessage.id, decryptedMessage.toJson());

      // Emit to listeners
      _messageController.add(decryptedMessage);

      // If it's an emergency, handle specially
      if (message.isEmergency) {
        _handleEmergencyMessage(decryptedMessage);
      }
    } catch (e) {
      // Failed to decrypt, ignore message
    }
  }

  Future<void> _relayMessage(Message message) async {
    final relayedMessage = message.relay();
    final messageJson = jsonEncode(relayedMessage.toJson());

    try {
      await _transportManager.sendData(messageJson);
    } catch (e) {
      // Relay failed, but don't mark as error since we received it
    }
  }

  void _handlePeerDiscovery(List<Peer> peers) {
    // Handle new peers discovered
    // Could trigger message exchange or inventory sync
  }

  Future<void> _handleEmergencyMessage(Message message) async {
    // Special handling for emergency messages
    // Could trigger notifications, UI alerts, etc.
  }

  Future<void> _updateMessageStatus(
      String messageId, DeliveryStatus status) async {
    // MessageStorage interface only has markMessageDelivered, so we might need to extend it or use storeMessage
    final msgMap = await _messageStorage.getMessage(messageId);
    if (msgMap != null) {
      msgMap['status'] = status.toString().split('.').last;
      await _messageStorage.storeMessage(messageId, msgMap);
    }

    if (status == DeliveryStatus.sent || status == DeliveryStatus.delivered) {
      _pendingMessages.remove(messageId);
      _retryTimers[messageId]?.cancel();
      _retryTimers.remove(messageId);
      _retryCounts.remove(messageId);
    } else if (status == DeliveryStatus.failed) {
      _scheduleRetry(messageId);
    }
  }

  void _scheduleRetry(String messageId) {
    if ((_retryCounts[messageId] ?? 0) >= _maxRetries) {
      return;
    }

    _retryCounts[messageId] = (_retryCounts[messageId] ?? 0) + 1;

    _retryTimers[messageId] = Timer(_retryDelay, () async {
      final message = _pendingMessages[messageId];
      if (message != null) {
        try {
          final messageJson = jsonEncode(message.toJson());
          await _transportManager.sendData(messageJson);
          await _updateMessageStatus(messageId, DeliveryStatus.sent);
        } catch (e) {
          await _updateMessageStatus(messageId, DeliveryStatus.failed);
        }
      }
    });
  }

  Future<void> _loadExistingMessages() async {
    final pending = await _messageStorage.getPendingMessages();
    for (final msgMap in pending) {
      final message = Message.fromJson(msgMap);
      _pendingMessages[message.id] = message;
      _scheduleRetry(message.id);
    }
  }

  Future<void> _cleanupExpiredMessages() async {
    // Implementation depends on storage capabilities
  }

  /// Send emergency alert
  Future<void> sendEmergencyAlert(EmergencyAlert alert) async {
    final message = alert.toMessage();
    await sendRichMessage(message);
  }

  /// Create a new text message
  Future<Message> createTextMessage(String content, String recipientId) async {
    final messageId = const Uuid().v4();
    final encrypted = await _encryption.encrypt(content, recipientId);

    return Message(
      id: messageId,
      fromDeviceId: _currentDeviceId,
      toUserId: recipientId,
      type: MessageType.text,
      timestamp: DateTime.now(),
      encryptedPayload: encrypted,
    );
  }

  /// Create a new file message
  Future<Message> createFileMessage(String fileName, int fileSize,
      String checksum, String recipientId) async {
    final messageId = const Uuid().v4();
    return Message(
      id: messageId,
      fromDeviceId: _currentDeviceId,
      toUserId: recipientId,
      type: MessageType.file,
      timestamp: DateTime.now(),
      encryptedPayload: '', // Payload set by caller
      fileName: fileName,
      fileSize: fileSize,
      checksum: checksum,
    );
  }

  /// Create a new audio message (voice note)
  Future<Message> createAudioMessage(
      Uint8List audioData, String recipientId) async {
    final messageId = const Uuid().v4();
    final encryptedAudioData =
        await _encryption.encryptVoiceNote(audioData, recipientId);

    return Message(
      id: messageId,
      fromDeviceId: _currentDeviceId,
      toUserId: recipientId,
      type: MessageType.audio,
      timestamp: DateTime.now(),
      encryptedPayload: encryptedAudioData,
    );
  }
}

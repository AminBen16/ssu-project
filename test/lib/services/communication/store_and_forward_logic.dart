import 'dart:async';
import 'dart:convert';

import 'package:test/services/communication/messaging_interface.dart';

/// Service to handle store-and-forward logic for mesh networking
class StoreAndForwardService implements StoreAndForward {
  final MessageStorage _messageStorage;
  final TransportManager _transportManager;
  final String _currentDeviceId;

  static const int _maxHopCount = 10;
  static const Duration _defaultTtl = Duration(hours: 48);

  StoreAndForwardService(
    this._messageStorage,
    this._transportManager,
    this._currentDeviceId,
  );

  @override
  Future<void> initialize() async {
    // Start periodic processing of stored messages
    Timer.periodic(const Duration(minutes: 15), (_) => processStoredMessages());
    Timer.periodic(
        const Duration(hours: 1), (_) => clearOldMessages(_defaultTtl));
  }

  @override
  Future<void> storeMessageForLater(
      String messageJson, String targetDeviceId) async {
    try {
      final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;
      final message = Message.fromJson(messageMap);

      // Only store if not expired and hop count is within limits
      if (!message.isExpired && message.hopCount < _maxHopCount) {
        // Store with 'forwarding' status
        final forwardingMessage = {
          ...messageMap,
          'status': 'forwarding',
          'storedAt': DateTime.now().toIso8601String(),
        };

        await _messageStorage.storeMessage(message.id, forwardingMessage);
      }
    } catch (e) {
      // Invalid message format
    }
  }

  @override
  Future<void> processStoredMessages() async {
    final storedMessages = await _getMessagesToForward();

    for (final messageMap in storedMessages) {
      try {
        final message = Message.fromJson(messageMap);

        // Check if we can deliver directly now
        if (await _canReachDevice(message.toUserId)) {
          await _forwardMessage(message);
        } else {
          // Check if we should relay to other peers
          await _relayToPeers(message);
        }
      } catch (e) {
        // Error processing message
      }
    }
  }

  @override
  Future<int> getStoredMessageCount() async {
    final messages = await _getMessagesToForward();
    return messages.length;
  }

  @override
  Future<void> clearOldMessages(Duration maxAge) async {
    final messages = await _getAllStoredMessages();
    final now = DateTime.now();

    for (final messageMap in messages) {
      final storedAtStr = messageMap['storedAt'] as String?;
      if (storedAtStr != null) {
        final storedAt = DateTime.parse(storedAtStr);
        if (now.difference(storedAt) > maxAge) {
          await _messageStorage.deleteMessage(messageMap['id']);
        }
      } else {
        // If no storedAt, check message timestamp
        final timestampStr = messageMap['timestamp'] as String;
        final timestamp = DateTime.parse(timestampStr);
        if (now.difference(timestamp) > maxAge) {
          await _messageStorage.deleteMessage(messageMap['id']);
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getMessagesToForward() async {
    // This would ideally be a specific query on the storage
    // For now, we fetch all and filter
    final allMessages = await _getAllStoredMessages();
    return allMessages.where((m) => m['status'] == 'forwarding').toList();
  }

  Future<List<Map<String, dynamic>>> _getAllStoredMessages() async {
    // Placeholder: In a real DB implementation, this would query all messages
    // Since the interface only has getMessagesForDevice, we might need to extend it
    // or assume we can iterate keys.
    // For this implementation, we'll assume getPendingMessages returns what we need
    // or we'd need to add a method to MessageStorage.
    // Using getPendingMessages as a proxy for now, though semantically different.
    return await _messageStorage.getPendingMessages();
  }

  Future<bool> _canReachDevice(String deviceId) async {
    // Check if device is directly connected via any transport
    // This requires TransportManager to expose connected devices or routing table
    // For now, we'll assume we can try sending and see if it fails
    return true;
  }

  Future<void> _forwardMessage(Message message) async {
    try {
      await _transportManager.sendData(jsonEncode(message.toJson()));

      // If successful, mark as delivered/sent and remove from forwarding queue
      await _messageStorage.markMessageDelivered(message.id);
    } catch (e) {
      // Forwarding failed, keep for later
    }
  }

  Future<void> _relayToPeers(Message message) async {
    // If we can't reach the destination, broadcast to connected peers
    // who might be closer to the destination (epidemic routing / flooding)

    if (message.canRelay) {
      final relayedMessage = message.relay();

      // Update stored message with new hop count
      final messageMap = relayedMessage.toJson();
      messageMap['status'] = 'forwarding';
      messageMap['storedAt'] = DateTime.now().toIso8601String();

      await _messageStorage.storeMessage(message.id, messageMap);

      // Broadcast to neighbors
      try {
        await _transportManager.sendData(jsonEncode(relayedMessage.toJson()));
      } catch (e) {
        // Ignore broadcast errors
      }
    } else {
      // Hop limit reached, drop message
      await _messageStorage.deleteMessage(message.id);
    }
  }

  /// Handle incoming message for store-and-forward
  Future<void> handleIncomingMessage(String messageJson) async {
    try {
      final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;
      final message = Message.fromJson(messageMap);

      if (message.toUserId == _currentDeviceId) {
        // Message is for us, process it
        // (This logic is usually in CommunicationService, but S&F might intercept)
      } else {
        // Message is for someone else
        await storeMessageForLater(messageJson, message.toUserId);
      }
    } catch (e) {
      // Invalid message
    }
  }
}

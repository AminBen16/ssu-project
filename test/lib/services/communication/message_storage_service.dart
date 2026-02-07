import 'dart:async';

import 'package:test/services/communication/messaging_interface.dart';

/// In-memory implementation of MessageStorage for offline-first messaging.
/// This satisfies the MessageStorage interface using a Map-based store.
class MessageStorageService implements MessageStorage {
  final Map<String, Map<String, dynamic>> _messages = {};

  @override
  Future<void> storeMessage(
      String messageId, Map<String, dynamic> message) async {
    _messages[messageId] = Map<String, dynamic>.from(message);
  }

  @override
  Future<Map<String, dynamic>?> getMessage(String messageId) async {
    final message = _messages[messageId];
    return message != null ? Map<String, dynamic>.from(message) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getMessagesForDevice(
      String deviceId) async {
    // Matches messages where toUserId equals the requested ID (deviceId/userId)
    return _messages.values
        .where((m) => m['toUserId'] == deviceId)
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    _messages.remove(messageId);
  }

  @override
  Future<void> markMessageDelivered(String messageId) async {
    if (_messages.containsKey(messageId)) {
      _messages[messageId]!['status'] =
          DeliveryStatus.delivered.toString().split('.').last;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    final pendingStatus = DeliveryStatus.sending.toString().split('.').last;
    return _messages.values
        .where((m) => m['status'] == pendingStatus)
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  @override
  Future<void> updateMessageStatus(
      String messageId, DeliveryStatus status) async {
    if (_messages.containsKey(messageId)) {
      _messages[messageId]!['status'] = status.toString().split('.').last;
    }
  }

  @override
  Future<void> deleteExpiredMessages() async {
    final now = DateTime.now();
    _messages.removeWhere((key, value) {
      final timestampStr = value['timestamp'] as String?;
      if (timestampStr == null) return true;
      try {
        final timestamp = DateTime.parse(timestampStr);
        final ttl = value['ttlHours'] as int? ?? 48; // Default to 48 hours
        return now.difference(timestamp).inHours > ttl;
      } catch (e) {
        return true; // Remove if timestamp is malformed
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    return _messages.values.map((m) => Map<String, dynamic>.from(m)).toList();
  }
}

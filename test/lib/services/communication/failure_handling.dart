import 'dart:async';
import 'dart:convert';

import 'package:test/services/communication/messaging_interface.dart';

/// Service to handle communication failures and recovery strategies
class FailureHandlingService implements FailureHandling {
  final TransportManager _transportManager;
  final MessageStorage _messageStorage;
  final MeshPlatformChannels _platformChannels;

  final Map<String, int> _connectionFailureCounts = {};
  final Map<String, int> _messageFailureCounts = {};

  static const int _maxRetries = 3;
  static const int _connectionFailureThreshold = 5;

  FailureHandlingService(
    this._transportManager,
    this._messageStorage,
    this._platformChannels,
  );

  @override
  Future<void> initialize() async {
    // No active monitoring initialization needed for this implementation
  }

  @override
  Future<void> handleConnectionFailure(String deviceId) async {
    _connectionFailureCounts[deviceId] =
        (_connectionFailureCounts[deviceId] ?? 0) + 1;

    if ((_connectionFailureCounts[deviceId] ?? 0) >=
        _connectionFailureThreshold) {
      await _attemptConnectionRecovery(deviceId);
      _connectionFailureCounts[deviceId] = 0;
    }
  }

  @override
  Future<void> handleMessageFailure(String messageId) async {
    _messageFailureCounts[messageId] =
        (_messageFailureCounts[messageId] ?? 0) + 1;

    if ((_messageFailureCounts[messageId] ?? 0) > _maxRetries) {
      // Mark as permanently failed
      final message = await _messageStorage.getMessage(messageId);
      if (message != null) {
        message['status'] = 'failed';
        await _messageStorage.storeMessage(messageId, message);
      }
    }
  }

  @override
  Future<void> retryFailedMessages() async {
    // Get messages that are stuck in sending
    final pendingMessages = await _messageStorage.getPendingMessages();

    for (final message in pendingMessages) {
      final messageId = message['id'];
      if (messageId != null) {
        // Check if we should retry
        if ((_messageFailureCounts[messageId] ?? 0) <= _maxRetries) {
          try {
            // Attempt resend via transport manager
            await _transportManager.sendData(jsonEncode(message));
          } catch (e) {
            await handleMessageFailure(messageId);
          }
        }
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getFailureStats() async {
    return {
      'connectionFailures': _connectionFailureCounts,
      'messageFailures': _messageFailureCounts,
    };
  }

  Future<void> _attemptConnectionRecovery(String deviceId) async {
    // Try to reset the mesh connection
    try {
      await _platformChannels.disconnectFromPeer(deviceId);
      await Future.delayed(const Duration(seconds: 1));
      await _platformChannels.connectToPeer(deviceId);
    } catch (e) {
      // Ignore errors during recovery attempt
    }
  }
}

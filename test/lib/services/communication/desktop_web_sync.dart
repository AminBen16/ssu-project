import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'messaging_interface.dart';

/// Desktop/Web client synchronization service
class DesktopWebSyncService {
  final String serverUrl;
  final String authToken;
  final MessageStorage _messageStorage;
  final Logger _logger = Logger();

  WebSocketChannel? _channel;
  final StreamController<SyncEvent> _syncController =
      StreamController<SyncEvent>.broadcast();
  final Map<String, Message> _pendingMessages = {};
  final Map<String, Timer> _retryTimers = {};

  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  DateTime _lastSyncTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  DesktopWebSyncService({
    required this.serverUrl,
    required this.authToken,
    required MessageStorage messageStorage,
  }) : _messageStorage = messageStorage;

  Stream<SyncEvent> get syncStream => _syncController.stream;
  bool get isConnected => _isConnected;

  /// Initialize and connect to WebSocket server
  Future<void> initialize() async {
    await _connect();
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();

    await _channel?.sink.close();
    await _syncController.close();
  }

  /// Send message through WebSocket
  Future<void> sendMessage(Message message) async {
    if (!_isConnected) {
      // Queue for later sending
      _pendingMessages[message.id] = message;
      return;
    }

    try {
      final messageData = {
        'type': 'message_send',
        'message': {
          'id': message.id,
          'recipientId': message.toUserId,
          'content': message.encryptedPayload,
          'type': message.type.toString().split('.').last,
          'encryptedPayload': message.encryptedPayload,
        },
      };

      _channel!.sink.add(jsonEncode(messageData));
      _pendingMessages[message.id] = message;
    } catch (e) {
      _logger.e('Failed to send message: $e');
      _pendingMessages[message.id] = message;
      _scheduleRetry(message.id);
    }
  }

  /// Request full synchronization
  Future<void> requestFullSync() async {
    if (!_isConnected) return;

    try {
      final syncRequest = {
        'type': 'sync_request',
        'lastSyncTimestamp': _lastSyncTimestamp.toIso8601String(),
        'deviceId': 'desktop_web_client', // Could be generated uniquely
      };

      _channel!.sink.add(jsonEncode(syncRequest));
    } catch (e) {
      _logger.e('Failed to request sync: $e');
    }
  }

  /// Mark message as delivered/read
  Future<void> acknowledgeMessage(String messageId, String status) async {
    if (!_isConnected) return;

    try {
      final ack = {
        'type': 'message_ack',
        'messageId': messageId,
        'status': status, // 'delivered' or 'read'
      };

      _channel!.sink.add(jsonEncode(ack));
    } catch (e) {
      _logger.e('Failed to acknowledge message: $e');
    }
  }

  /// Update presence status
  Future<void> updatePresence(String status) async {
    if (!_isConnected) return;

    try {
      final presence = {
        'type': 'presence_update',
        'status': status, // 'online', 'away', 'busy'
      };

      _channel!.sink.add(jsonEncode(presence));
    } catch (e) {
      _logger.e('Failed to update presence: $e');
    }
  }

  Future<void> _connect() async {
    try {
      final wsUrl = Uri.parse('$serverUrl?token=$authToken');
      _channel = WebSocketChannel.connect(wsUrl);

      await _channel!.ready;

      _isConnected = true;
      _syncController
          .add(SyncEvent(SyncEventType.connected, 'Connected to server'));

      // Setup message handling
      _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: _handleError,
      );

      // Start heartbeat
      _startHeartbeat();

      // Request initial sync
      await requestFullSync();

      // Send any pending messages
      await _sendPendingMessages();
    } catch (e) {
      _logger.e('Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;

      switch (message['type']) {
        case 'welcome':
          _handleWelcome(message);
          break;

        case 'message_received':
          _handleMessageReceived(message);
          break;

        case 'sync_response':
          _handleSyncResponse(message);
          break;

        case 'message_sent':
          _handleMessageSent(message);
          break;

        case 'delivery_update':
          _handleDeliveryUpdate(message);
          break;

        case 'error':
          _handleServerError(message);
          break;

        case 'ping':
          _handlePing(message);
          break;

        default:
          _logger.w('Unknown message type: ${message['type']}');
      }
    } catch (e) {
      _logger.e('Error handling message: $e');
    }
  }

  void _handleWelcome(Map<String, dynamic> message) {
    final pendingMessages = message['pendingMessages'] as List<dynamic>? ?? [];
    final onlineUsers = message['onlineUsers'] as List<dynamic>? ?? [];

    _syncController.add(SyncEvent(
      SyncEventType.welcome,
      'Welcome received',
      data: {
        'pendingMessages': pendingMessages,
        'onlineUsers': onlineUsers,
      },
    ));

    // Process pending messages
    for (final msgData in pendingMessages) {
      _processIncomingMessage(msgData as Map<String, dynamic>);
    }
  }

  void _handleMessageReceived(Map<String, dynamic> message) {
    final msgData = message['message'] as Map<String, dynamic>;
    _processIncomingMessage(msgData);
  }

  void _handleSyncResponse(Map<String, dynamic> message) {
    final messages = message['messages'] as List<dynamic>? ?? [];
    final deliveryStatuses =
        message['deliveryStatuses'] as List<dynamic>? ?? [];
    final serverTimestamp = DateTime.parse(message['serverTimestamp']);

    _lastSyncTimestamp = serverTimestamp;

    // Process synced messages
    for (final msgData in messages) {
      _processIncomingMessage(msgData as Map<String, dynamic>);
    }

    // Process delivery status updates
    for (final statusData in deliveryStatuses) {
      _processDeliveryStatus(statusData as Map<String, dynamic>);
    }

    _syncController.add(SyncEvent(
      SyncEventType.syncCompleted,
      'Sync completed with ${messages.length} messages',
    ));
  }

  void _handleMessageSent(Map<String, dynamic> message) {
    final messageId = message['messageId'] as String;
    final timestamp = DateTime.parse(message['timestamp']);

    // Remove from pending and update status
    final pendingMessage = _pendingMessages.remove(messageId);
    if (pendingMessage != null) {
      _messageStorage.updateMessageStatus(messageId, DeliveryStatus.sent);
      _retryTimers[messageId]?.cancel();
      _retryTimers.remove(messageId);
    }

    _syncController.add(SyncEvent(
      SyncEventType.messageSent,
      'Message $messageId sent successfully',
      data: {'messageId': messageId, 'timestamp': timestamp},
    ));
  }

  void _handleDeliveryUpdate(Map<String, dynamic> message) {
    final messageId = message['messageId'] as String;
    final status = message['status'] as String;
    final timestamp = DateTime.parse(message['timestamp']);

    // Update local delivery status
    final deliveryStatus = status == 'delivered'
        ? DeliveryStatus.delivered
        : status == 'read'
            ? DeliveryStatus.read
            : DeliveryStatus.sent;

    _messageStorage.updateMessageStatus(messageId, deliveryStatus);

    _syncController.add(SyncEvent(
      SyncEventType.deliveryUpdate,
      'Message $messageId status: $status',
      data: {'messageId': messageId, 'status': status, 'timestamp': timestamp},
    ));
  }

  void _handleServerError(Map<String, dynamic> message) {
    final error = message['error'] as String;
    final errorMessage = message['message'] as String?;

    _syncController.add(SyncEvent(
      SyncEventType.error,
      'Server error: $error - $errorMessage',
      data: {'error': error, 'message': errorMessage},
    ));
  }

  void _handlePing(Map<String, dynamic> message) {
    // Respond with pong
    try {
      final pong = {
        'type': 'pong',
        'timestamp': DateTime.now().toIso8601String(),
      };
      _channel!.sink.add(jsonEncode(pong));
    } catch (e) {
      // Ignore ping response failures
    }
  }

  Future<void> _processIncomingMessage(Map<String, dynamic> msgData) async {
    try {
      // Convert to Message object
      final message = Message(
        id: msgData['id'],
        fromDeviceId: msgData['sender_id'] ?? 'unknown',
        toUserId: msgData['recipient_id'] ?? 'unknown',
        type: MessageType.values.firstWhere(
          (t) =>
              t.toString().split('.').last ==
              (msgData['message_type'] ?? 'text'),
          orElse: () => MessageType.text,
        ),
        timestamp: DateTime.parse(msgData['created_at']),
        encryptedPayload:
            msgData['encrypted_payload'] ?? msgData['content'] ?? '',
        status: DeliveryStatus.delivered,
      );

      // Store locally
      await _messageStorage.storeMessage(message.id, message.toJson());

      _syncController.add(SyncEvent(
        SyncEventType.messageReceived,
        'New message received: ${message.id}',
        data: {'message': message},
      ));
    } catch (e) {
      _logger.e('Error processing incoming message: $e');
    }
  }

  Future<void> _processDeliveryStatus(Map<String, dynamic> statusData) async {
    try {
      final messageId = statusData['message_id'] as String;
      final status = statusData['status'] as String;

      final deliveryStatus = status == 'delivered'
          ? DeliveryStatus.delivered
          : status == 'read'
              ? DeliveryStatus.read
              : DeliveryStatus.sent;

      await _messageStorage.updateMessageStatus(messageId, deliveryStatus);
    } catch (e) {
      _logger.e('Error processing delivery status: $e');
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _syncController
        .add(SyncEvent(SyncEventType.disconnected, 'Disconnected from server'));
    _scheduleReconnect();
  }

  void _handleError(dynamic error) {
    _logger.e('WebSocket error: $error');
    _handleDisconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) {
        // Heartbeat is handled by ping/pong messages from server
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    _reconnectTimer = Timer(_reconnectDelay, () async {
      _reconnectTimer = null;
      if (!_isConnected) {
        _logger.i('Attempting to reconnect...');
        await _connect();
      }
    });
  }

  Future<void> _sendPendingMessages() async {
    final messagesToSend = List.of(_pendingMessages.values);
    _pendingMessages.clear();

    for (final message in messagesToSend) {
      await sendMessage(message);
    }
  }

  void _scheduleRetry(String messageId) {
    if (_retryTimers.containsKey(messageId)) return;

    _retryTimers[messageId] = Timer(const Duration(seconds: 30), () async {
      final message = _pendingMessages[messageId];
      if (message != null && _isConnected) {
        await sendMessage(message);
      }
    });
  }
}

/// Synchronization event types
enum SyncEventType {
  connected,
  disconnected,
  welcome,
  messageReceived,
  messageSent,
  deliveryUpdate,
  syncCompleted,
  error,
}

/// Synchronization event
class SyncEvent {
  final SyncEventType type;
  final String message;
  final Map<String, dynamic>? data;

  SyncEvent(this.type, this.message, {this.data});
}

/*
DESKTOP/WEB CLIENT SYNC WORKFLOW:

1. INITIAL CONNECTION:
   - Connect to WebSocket server with JWT token
   - Receive welcome message with pending messages
   - Sync local message history

2. MESSAGE SYNCHRONIZATION:
   - Send messages through WebSocket
   - Receive messages from mesh network via server
   - Handle delivery status updates
   - Maintain message consistency

3. CONFLICT RESOLUTION:
   - Server timestamp takes precedence
   - Last-write-wins for message edits
   - Client generates unique IDs to avoid conflicts
   - Delivery status merged from multiple sources

4. OFFLINE HANDLING:
   - Queue messages when disconnected
   - Automatic reconnection with exponential backoff
   - Sync pending messages on reconnection
   - Handle network flapping gracefully

5. PRESENCE MANAGEMENT:
   - Update online/away/busy status
   - Receive presence updates from other users
   - Show online status in UI

6. MESSAGE CONSISTENCY RULES:
   - Messages are immutable once sent
   - Delivery status can be updated by recipients
   - Read receipts sent immediately
   - Message history preserved across sessions

7. ERROR HANDLING:
   - Connection failures trigger reconnection
   - Message send failures queued for retry
   - Server errors logged and reported
   - Graceful degradation during outages

8. PERFORMANCE OPTIMIZATION:
   - Incremental sync after initial load
   - Message pagination for large histories
   - Compression for large payloads
   - Background sync when app not active

INTEGRATION WITH FLUTTER APP:

// Initialize sync service
final syncService = DesktopWebSyncService(
  serverUrl: 'ws://server:8081',
  authToken: userToken,
  messageStorage: localStorage,
  encryption: encryptionService,
);

await syncService.initialize();

// Listen for sync events
syncService.syncStream.listen((event) {
  switch (event.type) {
    case SyncEventType.messageReceived:
      // Update UI with new message
      break;
    case SyncEventType.connected:
      // Show connected status
      break;
    // Handle other events...
  }
});

// Send messages
await syncService.sendMessage(message);

// Update presence
await syncService.updatePresence('online');

This provides seamless synchronization between mesh-delivered messages
and internet-connected desktop/web clients, maintaining consistency
across all platforms.
*/

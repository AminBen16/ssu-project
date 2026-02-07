import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'database_service.dart';
import 'auth_middleware.dart';

/// WebSocket server for offline-first messaging synchronization
class MessagingWebSocketServer {
  final DatabaseService _databaseService;
  // Removed final AuthMiddleware _authMiddleware;

  HttpServer? _server;
  final Map<String, WebSocket> _connectedClients = {};
  final Map<String, String> _clientUserIds = {}; // sessionId -> userId
  final Map<String, Timer> _heartbeatTimers = {};

  static const int _port = 8081;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _heartbeatTimeout = Duration(seconds: 60);

  // Modified constructor to remove AuthMiddleware instance
  MessagingWebSocketServer(this._databaseService);

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      print('WebSocket server started on port $_port');

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          await _handleWebSocketUpgrade(request);
        } else {
          request.response
            ..statusCode = HttpStatus.methodNotAllowed
            ..write('WebSocket connections only')
            ..close();
        }
      });

      // Start cleanup timer
      Timer.periodic(
          const Duration(minutes: 5), (_) => _cleanupDisconnectedClients());
    } catch (e) {
      print('Failed to start WebSocket server: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _connectedClients.clear();
    _clientUserIds.clear();

    for (final timer in _heartbeatTimers.values) {
      timer.cancel();
    }
    _heartbeatTimers.clear();

    print('WebSocket server stopped');
  }

  Future<void> _handleWebSocketUpgrade(HttpRequest request) async {
    try {
      // Extract token from query parameters or headers
      final token = _extractAuthToken(request);

      if (token == null) {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write('Authentication required')
          ..close();
        return;
      }

      // Authenticate user
      final userId = await _authenticateUser(token);
      if (userId == null) {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write('Invalid authentication')
          ..close();
        return;
      }

      // Upgrade to WebSocket
      final socket = await WebSocketTransformer.upgrade(request);
      final sessionId = _generateSessionId();

      _connectedClients[sessionId] = socket;
      _clientUserIds[sessionId] = userId;

      print('Client connected: $userId (session: $sessionId)');

      // Setup heartbeat monitoring
      _setupHeartbeat(sessionId, socket);

      // Handle incoming messages
      socket.listen(
        (data) => _handleMessage(sessionId, data),
        onDone: () => _handleClientDisconnect(sessionId),
        onError: (error) => _handleClientError(sessionId, error),
      );

      // Send welcome message with pending messages
      await _sendWelcomeMessage(sessionId, userId);
    } catch (e) {
      print('WebSocket upgrade failed: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..close();
    }
  }

  String? _extractAuthToken(HttpRequest request) {
    // Try query parameter first
    final token = request.uri.queryParameters['token'];
    if (token != null) return token;

    // Try Authorization header
    final authHeader = request.headers.value('authorization');
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    return null;
  }

  Future<String?> _authenticateUser(String token) async {
    try {
      // Use existing static auth middleware to validate token
      // Changed from _authMiddleware.validateToken to AuthMiddleware.validateToken
      final payload = AuthMiddleware.validateToken('Bearer $token');
      final userId = payload?['userId'];
      if (userId is String) return userId;
      return null;
    } catch (e) {
      return null;
    }
  }

  void _setupHeartbeat(String sessionId, WebSocket socket) {
    // Send initial ping
    socket.add(jsonEncode(
        {'type': 'ping', 'timestamp': DateTime.now().toIso8601String()}));

    // Setup periodic heartbeat
    _heartbeatTimers[sessionId] = Timer.periodic(_heartbeatInterval, (_) {
      try {
        socket.add(jsonEncode(
            {'type': 'ping', 'timestamp': DateTime.now().toIso8601String()}));
      } catch (e) {
        // Socket probably closed
        _handleClientDisconnect(sessionId);
      }
    });

    // Setup timeout monitoring
    Timer(_heartbeatTimeout, () {
      if (_connectedClients.containsKey(sessionId)) {
        print('Client $sessionId heartbeat timeout');
        _handleClientDisconnect(sessionId);
      }
    });
  }

  Future<void> _handleMessage(String sessionId, dynamic data) async {
    try {
      final message = jsonDecode(data);
      final userId = _clientUserIds[sessionId];

      if (userId == null) return;

      switch (message['type']) {
        case 'pong':
          // Heartbeat response - do nothing special
          break;

        case 'sync_request':
          await _handleSyncRequest(sessionId, userId, message);
          break;

        case 'message_send':
          await _handleMessageSend(sessionId, userId, message);
          break;

        case 'message_ack':
          await _handleMessageAck(sessionId, userId, message);
          break;

        case 'presence_update':
          await _handlePresenceUpdate(sessionId, userId, message);
          break;

        default:
          print('Unknown message type: ${message['type']}');
      }
    } catch (e) {
      print('Error handling message from $sessionId: $e');
    }
  }

  Future<void> _handleSyncRequest(
      String sessionId, String userId, Map<String, dynamic> message) async {
    try {
      final lastSyncTimestamp = DateTime.parse(
          message['lastSyncTimestamp'] ?? '1970-01-01T00:00:00Z');

      // Get messages since last sync
      final messages = await _databaseService.query(
        'SELECT * FROM messages WHERE (sender_id = ? OR recipient_id = ?) AND created_at > ? ORDER BY created_at ASC',
        [userId, userId, lastSyncTimestamp.toIso8601String()],
      );

      // Get delivery status updates
      final deliveryStatuses = await _databaseService.query(
        'SELECT * FROM message_delivery_status WHERE user_id = ? AND updated_at > ?',
        [userId, lastSyncTimestamp.toIso8601String()],
      );

      // Send sync response
      final syncData = {
        'type': 'sync_response',
        'messages': messages,
        'deliveryStatuses': deliveryStatuses,
        'serverTimestamp': DateTime.now().toIso8601String(),
      };

      _sendToClient(sessionId, syncData);
    } catch (e) {
      print('Sync request failed: $e');
      _sendToClient(sessionId, {
        'type': 'error',
        'error': 'sync_failed',
        'message': e.toString(),
      });
    }
  }

  Future<void> _handleMessageSend(
      String sessionId, String userId, Map<String, dynamic> message) async {
    try {
      final messageData = message['message'] as Map<String, dynamic>;

      // Store message in database
      await _databaseService.insert('messages', {
        'id': messageData['id'],
        'sender_id': userId,
        'recipient_id': messageData['recipientId'],
        'content': messageData['content'],
        'message_type': messageData['type'] ?? 'text',
        'encrypted_payload': messageData['encryptedPayload'],
        'created_at': DateTime.now().toIso8601String(),
        'status': 'sent',
      });

      // Store delivery status
      await _databaseService.insert('message_delivery_status', {
        'message_id': messageData['id'],
        'user_id': messageData['recipientId'],
        'status': 'sent',
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Check if recipient is online and forward message
      final recipientSession = _clientUserIds.entries.firstWhere(
          (entry) => entry.value == messageData['recipientId'],
          orElse: () => const MapEntry('', ''));

      if (recipientSession.key.isNotEmpty) {
        _sendToClient(recipientSession.key, {
          'type': 'message_received',
          'message': messageData,
        });
      }

      // Send confirmation to sender
      _sendToClient(sessionId, {
        'type': 'message_sent',
        'messageId': messageData['id'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Message send failed: $e');
      _sendToClient(sessionId, {
        'type': 'error',
        'error': 'send_failed',
        'message': e.toString(),
      });
    }
  }

  Future<void> _handleMessageAck(
      String sessionId, String userId, Map<String, dynamic> message) async {
    try {
      final messageId = message['messageId'] as String;
      final status = message['status'] as String; // 'delivered', 'read'

      // Update delivery status
      await _databaseService.update(
        'message_delivery_status',
        {'status': status, 'updated_at': DateTime.now().toIso8601String()},
        'message_id = ? AND user_id = ?',
        [messageId, userId],
      );

      // Notify sender if they're online
      final senderMessage = await _databaseService.querySingle(
        'SELECT sender_id FROM messages WHERE id = ?',
        [messageId],
      );

      if (senderMessage != null) {
        final senderId = senderMessage['sender_id'] as String;
        final senderSession = _clientUserIds.entries.firstWhere(
            (entry) => entry.value == senderId,
            orElse: () => const MapEntry('', ''));

        if (senderSession.key.isNotEmpty) {
          _sendToClient(senderSession.key, {
            'type': 'delivery_update',
            'messageId': messageId,
            'status': status,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Message ack failed: $e');
    }
  }

  Future<void> _handlePresenceUpdate(
      String sessionId, String userId, Map<String, dynamic> message) async {
    // Update user presence in database
    try {
      await _databaseService.update(
        'user_presence',
        {
          'status': message['status'] ?? 'online',
          'last_seen': DateTime.now().toIso8601String(),
        },
        'user_id = ?',
        [userId],
      );
    } catch (e) {
      // Presence table might not exist, ignore for now
    }
  }

  Future<void> _sendWelcomeMessage(String sessionId, String userId) async {
    // Get pending messages for user
    final pendingMessages = await _databaseService.query(
      'SELECT * FROM messages WHERE recipient_id = ? AND status = ? ORDER BY created_at DESC LIMIT 50',
      [userId, 'sent'],
    );

    // Get user presence info
    final onlineUsers = _clientUserIds.values.toSet();

    _sendToClient(sessionId, {
      'type': 'welcome',
      'userId': userId,
      'pendingMessages': pendingMessages,
      'onlineUsers': onlineUsers.toList(),
      'serverTimestamp': DateTime.now().toIso8601String(),
    });
  }

  void _sendToClient(String sessionId, Map<String, dynamic> data) {
    final socket = _connectedClients[sessionId];
    if (socket != null) {
      try {
        socket.add(jsonEncode(data));
      } catch (e) {
        print('Failed to send to client $sessionId: $e');
        _handleClientDisconnect(sessionId);
      }
    }
  }

  void _handleClientDisconnect(String sessionId) {
    final userId = _clientUserIds[sessionId];
    print('Client disconnected: $userId (session: $sessionId)');

    _connectedClients.remove(sessionId);
    _clientUserIds.remove(sessionId);
    _heartbeatTimers[sessionId]?.cancel();
    _heartbeatTimers.remove(sessionId);
  }

  void _handleClientError(String sessionId, dynamic error) {
    print('Client error for $sessionId: $error');
    _handleClientDisconnect(sessionId);
  }

  void _cleanupDisconnectedClients() {
    // This is handled by heartbeat monitoring, but we can add additional cleanup here
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        (DateTime.now().microsecondsSinceEpoch % 1000).toString();
  }

  /// Broadcast message to all connected clients of a user
  Future<void> broadcastToUser(String userId, Map<String, dynamic> data) async {
    final userSessions = _clientUserIds.entries
        .where((entry) => entry.value == userId)
        .map((entry) => entry.key);

    for (final sessionId in userSessions) {
      _sendToClient(sessionId, data);
    }
  }

  /// Get connection statistics
  Map<String, dynamic> getStats() {
    return {
      'connectedClients': _connectedClients.length,
      'uniqueUsers': _clientUserIds.values.toSet().length,
      'uptime': _server != null
          ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(0))
          : null,
    };
  }
}

/*
WEBSOCKET PROTOCOL SPECIFICATION:

CLIENT TO SERVER MESSAGES:

1. Authentication:
   ws://server:8081?token=<jwt_token>

2. Heartbeat:
   {
     "type": "pong",
     "timestamp": "2024-01-01T12:00:00Z"
   }

3. Sync Request:
   {
     "type": "sync_request",
     "lastSyncTimestamp": "2024-01-01T12:00:00Z",
     "deviceId": "device123"
   }

4. Send Message:
   {
     "type": "message_send",
     "message": {
       "id": "msg123",
       "recipientId": "user456",
       "content": "Hello!",
       "type": "text",
       "encryptedPayload": "base64..."
     }
   }

5. Message Acknowledgment:
   {
     "type": "message_ack",
     "messageId": "msg123",
     "status": "delivered|read"
   }

6. Presence Update:
   {
     "type": "presence_update",
     "status": "online|away|busy"
   }

SERVER TO CLIENT MESSAGES:

1. Welcome:
   {
     "type": "welcome",
     "userId": "user123",
     "pendingMessages": [...],
     "onlineUsers": [...],
     "serverTimestamp": "2024-01-01T12:00:00Z"
   }

2. Message Received:
   {
     "type": "message_received",
     "message": {...}
   }

3. Sync Response:
   {
     "type": "sync_response",
     "messages": [...],
     "deliveryStatuses": [...],
     "serverTimestamp": "2024-01-01T12:00:00Z"
   }

4. Message Sent Confirmation:
   {
     "type": "message_sent",
     "messageId": "msg123",
     "timestamp": "2024-01-01T12:00:00Z"
   }

5. Delivery Update:
   {
     "type": "delivery_update",
     "messageId": "msg123",
     "status": "delivered|read",
     "timestamp": "2024-01-01T12:00:00Z"
   }

6. Error:
   {
     "type": "error",
     "error": "error_code",
     "message": "Human readable message"
   }

7. Ping:
   {
     "type": "ping",
     "timestamp": "2024-01-01T12:00:00Z"
   }

DATABASE SCHEMA EXTENSIONS:

-- Messages table (extends existing)
ALTER TABLE messages ADD COLUMN encrypted_payload TEXT;
ALTER TABLE messages ADD COLUMN message_type VARCHAR(50) DEFAULT 'text';
ALTER TABLE messages ADD COLUMN device_id VARCHAR(255);

-- Message delivery status
CREATE TABLE message_delivery_status (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id VARCHAR(255) NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  status VARCHAR(50) NOT NULL, -- sent, delivered, read
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(message_id, user_id)
);

-- User presence (optional)
CREATE TABLE user_presence (
  user_id VARCHAR(255) PRIMARY KEY,
  status VARCHAR(50) DEFAULT 'offline',
  last_seen DATETIME DEFAULT CURRENT_TIMESTAMP
);

INTEGRATION WITH EXISTING SYSTEM:

1. Add WebSocket server startup to main.dart:
   final wsServer = MessagingWebSocketServer(databaseService, authMiddleware);
   await wsServer.start();

2. Modify existing message sending to also notify WebSocket clients:
   await wsServer.broadcastToUser(recipientId, {
     'type': 'message_received',
     'message': messageData,
   });

3. Add sync endpoint for initial load:
   - Clients can request full message history
   - Server provides incremental updates

4. Authentication integration:
   - Uses existing JWT tokens
   - Validates through AuthMiddleware
   - Maps tokens to user IDs

This WebSocket server acts as a bridge between mesh networks and internet-connected clients,
providing eventual consistency while maintaining the offline-first architecture.
*/

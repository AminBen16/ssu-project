import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

/// A message model for parent-teacher communication
class ParentMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? studentId; // Optional, for messages about specific students

  ParentMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.studentId,
  });

  factory ParentMessage.fromMap(Map<String, dynamic> map) {
    return ParentMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool? ?? false,
      studentId: map['studentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'studentId': studentId,
    };
  }
}

/// Service for handling parent-teacher communication with offline support
class ParentCommunicationService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Send a message from parent to teacher with offline queuing
  Future<void> sendMessage({
    required String schoolId,
    required String parentId,
    required String teacherId,
    required String content,
    String? studentId,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ParentMessage(
      id: messageId,
      senderId: parentId,
      receiverId: teacherId,
      content: content,
      timestamp: DateTime.now(),
      studentId: studentId,
    );

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient
            .post('/api/schools/$schoolId/communications/messages', body: {
          'senderId': parentId,
          'receiverId': teacherId,
          'content': content,
          'studentId': studentId,
          'timestamp': message.timestamp.toIso8601String(),
        });
        // Cache the sent message locally
        await _cacheMessage(message);
      } catch (e) {
        // Queue for sync when online call fails
        await _offlineService.queueForSync('insert', {
          'table': 'parent_messages',
          'schoolId': schoolId,
          ...message.toMap(),
        });
        // Cache locally for immediate display
        await _cacheMessage(message);
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'parent_messages',
        'schoolId': schoolId,
        ...message.toMap(),
      });
      // Cache locally for immediate display
      await _cacheMessage(message);
    }
  }

  /// Get messages for a parent with offline support
  Future<List<ParentMessage>> getParentMessages({
    required String schoolId,
    required String parentId,
  }) async {
    final cacheKey = 'parent_messages_${schoolId}_$parentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/messages',
        );
        final List<dynamic> data = response as List<dynamic>;
        final messages = data
            .map((json) => ParentMessage.fromMap(json as Map<String, dynamic>))
            .toList();

        // Cache messages locally
        await _localDb.saveData('parent_messages', parentId, {
          'messages': messages.map((m) => m.toMap()).toList(),
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return messages;
      },
      offlineFallback: () async {
        // Try to get cached messages
        final cached = await _localDb.getData('parent_messages', parentId);
        if (cached != null && cached['messages'] != null) {
          final List<dynamic> messagesData =
              cached['messages'] as List<dynamic>;
          return messagesData
              .map(
                  (json) => ParentMessage.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Get teachers available for communication with offline caching
  Future<List<Map<String, dynamic>>> getAvailableTeachers({
    required String schoolId,
  }) async {
    final cacheKey = 'available_teachers_$schoolId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/schools/$schoolId/teachers');
        final List<dynamic> data = response as List<dynamic>;
        final teachers = data.cast<Map<String, dynamic>>();

        // Cache teachers locally
        await _localDb.saveData('available_teachers', schoolId, {
          'teachers': teachers,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return teachers;
      },
      offlineFallback: () async {
        // Try to get cached teachers
        final cached = await _localDb.getData('available_teachers', schoolId);
        if (cached != null && cached['teachers'] != null) {
          return List<Map<String, dynamic>>.from(cached['teachers']);
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Mark a message as read with offline support
  Future<void> markMessageAsRead(String messageId) async {
    final online = await _offlineService.isOnline;

    if (online) {
      try {
        await _apiClient.put('/api/communications/messages/$messageId/read');
        await _updateLocalMessageReadStatus(messageId, true);
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('update', {
          'table': 'parent_messages',
          'id': messageId,
          'isRead': true,
          'operation': 'mark_read',
        });
        await _updateLocalMessageReadStatus(messageId, true);
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('update', {
        'table': 'parent_messages',
        'id': messageId,
        'isRead': true,
        'operation': 'mark_read',
      });
      await _updateLocalMessageReadStatus(messageId, true);
    }
  }

  /// Cache a message locally
  Future<void> _cacheMessage(ParentMessage message) async {
    // This is a simplified implementation
    // In a production app, you'd want to maintain a list of messages per parent
    await _localDb.saveData('parent_message', message.id, message.toMap());
  }

  /// Update read status of a message in local cache
  Future<void> _updateLocalMessageReadStatus(
      String messageId, bool isRead) async {
    // Find the message across all parent message caches
    final allParentData = await _localDb.getAllData('parent_messages');
    for (final entry in allParentData) {
      final parentId = entry['id'] as String;
      final cachedData = await _localDb.getData('parent_messages', parentId);
      if (cachedData != null && cachedData['messages'] != null) {
        final messages =
            List<Map<String, dynamic>>.from(cachedData['messages']);
        final messageIndex = messages.indexWhere((m) => m['id'] == messageId);
        if (messageIndex != -1) {
          messages[messageIndex]['isRead'] = isRead;
          messages[messageIndex]['lastUpdated'] =
              DateTime.now().toIso8601String();
          await _localDb.saveData('parent_messages', parentId, {
            'messages': messages,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
          break; // Found and updated, exit loop
        }
      }
    }
  }

  /// Get unread message count for a parent
  Future<int> getUnreadMessageCount({
    required String schoolId,
    required String parentId,
  }) async {
    final messages =
        await getParentMessages(schoolId: schoolId, parentId: parentId);
    return messages.where((message) => !message.isRead).length;
  }

  /// Clear communication cache
  Future<void> clearCommunicationCache() async {
    // This would need to be implemented to clear communication-specific cache
    await _offlineService.clearCache();
  }
}

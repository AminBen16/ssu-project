import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

/// A message model for teacher-parent communication
class TeacherMessage {
  final String id;
  final String senderId; // Teacher ID
  final String receiverId; // Parent ID
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? studentId; // Optional, for messages about specific students
  final String?
      messageType; // 'general', 'academic', 'behavior', 'attendance', etc.
  final String? priority; // 'low', 'medium', 'high', 'urgent'

  TeacherMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.studentId,
    this.messageType = 'general',
    this.priority = 'medium',
  });

  factory TeacherMessage.fromMap(Map<String, dynamic> map) {
    return TeacherMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool? ?? false,
      studentId: map['studentId'] as String?,
      messageType: map['messageType'] as String? ?? 'general',
      priority: map['priority'] as String? ?? 'medium',
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
      'messageType': messageType,
      'priority': priority,
    };
  }
}

/// Service for handling teacher-parent communication with offline queuing and sync
class TeacherCommunicationService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Send a message from teacher to parent with offline queuing
  Future<void> sendMessageToParent({
    required String schoolId,
    required String teacherId,
    required String parentId,
    required String content,
    String? studentId,
    String messageType = 'general',
    String priority = 'medium',
  }) async {
    final messageId = 'teacher_msg_${DateTime.now().millisecondsSinceEpoch}';
    final message = TeacherMessage(
      id: messageId,
      senderId: teacherId,
      receiverId: parentId,
      content: content,
      timestamp: DateTime.now(),
      studentId: studentId,
      messageType: messageType,
      priority: priority,
    );

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post(
            '/api/schools/$schoolId/communications/teacher-messages',
            body: {
              'senderId': teacherId,
              'receiverId': parentId,
              'content': content,
              'studentId': studentId,
              'messageType': messageType,
              'priority': priority,
              'timestamp': message.timestamp.toIso8601String(),
            });
        // Cache the sent message locally
        await _cacheTeacherMessage(message);
      } catch (e) {
        // Queue for sync when online call fails
        await _offlineService.queueForSync('insert', {
          'table': 'teacher_messages',
          'schoolId': schoolId,
          ...message.toMap(),
        });
        // Cache locally for immediate display
        await _cacheTeacherMessage(message);
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'teacher_messages',
        'schoolId': schoolId,
        ...message.toMap(),
      });
      // Cache locally for immediate display
      await _cacheTeacherMessage(message);
    }
  }

  /// Send bulk messages to multiple parents with offline queuing
  Future<void> sendBulkMessages({
    required String schoolId,
    required String teacherId,
    required List<String> parentIds,
    required String content,
    String? studentId,
    String messageType = 'general',
    String priority = 'medium',
  }) async {
    final messages = parentIds.map((parentId) {
      final messageId =
          'teacher_bulk_${DateTime.now().millisecondsSinceEpoch}_$parentId';
      return TeacherMessage(
        id: messageId,
        senderId: teacherId,
        receiverId: parentId,
        content: content,
        timestamp: DateTime.now(),
        studentId: studentId,
        messageType: messageType,
        priority: priority,
      );
    }).toList();

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        final messageData = messages
            .map((msg) => {
                  'senderId': msg.senderId,
                  'receiverId': msg.receiverId,
                  'content': msg.content,
                  'studentId': msg.studentId,
                  'messageType': msg.messageType,
                  'priority': msg.priority,
                  'timestamp': msg.timestamp.toIso8601String(),
                })
            .toList();

        await _apiClient.post(
            '/api/schools/$schoolId/communications/teacher-messages/bulk',
            body: {
              'messages': messageData,
            });

        // Cache all messages locally
        for (final message in messages) {
          await _cacheTeacherMessage(message);
        }
      } catch (e) {
        // Queue for sync when online call fails
        await _offlineService.queueForSync('batch_insert', {
          'table': 'teacher_messages',
          'schoolId': schoolId,
          'messages': messages.map((m) => m.toMap()).toList(),
        });
        // Cache locally for immediate display
        for (final message in messages) {
          await _cacheTeacherMessage(message);
        }
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('batch_insert', {
        'table': 'teacher_messages',
        'schoolId': schoolId,
        'messages': messages.map((m) => m.toMap()).toList(),
      });
      // Cache locally for immediate display
      for (final message in messages) {
        await _cacheTeacherMessage(message);
      }
    }
  }

  /// Get messages sent by a teacher with offline support
  Future<List<TeacherMessage>> getTeacherSentMessages({
    required String schoolId,
    required String teacherId,
  }) async {
    final cacheKey = 'teacher_sent_messages_${schoolId}_$teacherId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/teachers/$teacherId/messages',
        );
        final List<dynamic> data = response as List<dynamic>;
        final messages = data
            .map((json) => TeacherMessage.fromMap(json as Map<String, dynamic>))
            .toList();

        // Cache messages locally
        await _localDb.saveData('teacher_sent_messages', teacherId, {
          'messages': messages.map((m) => m.toMap()).toList(),
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return messages;
      },
      offlineFallback: () async {
        // Try to get cached messages
        final cached =
            await _localDb.getData('teacher_sent_messages', teacherId);
        if (cached != null && cached['messages'] != null) {
          final List<dynamic> messagesData =
              cached['messages'] as List<dynamic>;
          return messagesData
              .map((json) =>
                  TeacherMessage.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Get parents available for communication (parents of students in teacher's classes)
  Future<List<Map<String, dynamic>>> getAvailableParents({
    required String schoolId,
    required String teacherId,
  }) async {
    final cacheKey = 'teacher_available_parents_${schoolId}_$teacherId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/teachers/$teacherId/available-parents',
        );
        final List<dynamic> data = response as List<dynamic>;
        final parents = data.cast<Map<String, dynamic>>();

        // Cache parents locally
        await _localDb.saveData('teacher_available_parents', teacherId, {
          'parents': parents,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return parents;
      },
      offlineFallback: () async {
        // Try to get cached parents
        final cached =
            await _localDb.getData('teacher_available_parents', teacherId);
        if (cached != null && cached['parents'] != null) {
          return List<Map<String, dynamic>>.from(cached['parents']);
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Get message delivery status and read receipts
  Future<Map<String, dynamic>> getMessageStatus(String messageId) async {
    final cacheKey = 'message_status_$messageId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/communications/messages/$messageId/status');
        final status = response as Map<String, dynamic>;

        // Cache status locally
        await _localDb.saveData('message_status', messageId, {
          'status': status,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return status;
      },
      offlineFallback: () async {
        // Try to get cached status
        final cached = await _localDb.getData('message_status', messageId);
        if (cached != null && cached['status'] != null) {
          return cached['status'] as Map<String, dynamic>;
        }
        return {'delivered': false, 'read': false, 'readAt': null};
      },
      cacheKey: cacheKey,
    );
  }

  /// Get communication statistics for a teacher
  Future<Map<String, dynamic>> getCommunicationStats({
    required String schoolId,
    required String teacherId,
    String? period, // 'week', 'month', 'term', 'year'
  }) async {
    final periodParam = period ?? 'month';
    final cacheKey =
        'teacher_communication_stats_${schoolId}_${teacherId}_$periodParam';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/teachers/$teacherId/communication-stats?period=$periodParam',
        );
        final stats = response as Map<String, dynamic>;

        // Cache stats locally
        await _localDb.saveData(
            'teacher_communication_stats', '${teacherId}_$periodParam', {
          'stats': stats,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return stats;
      },
      offlineFallback: () async {
        // Try to get cached stats
        final cached = await _localDb.getData(
            'teacher_communication_stats', '${teacherId}_$periodParam');
        if (cached != null && cached['stats'] != null) {
          return cached['stats'] as Map<String, dynamic>;
        }
        return {
          'totalMessages': 0,
          'deliveredMessages': 0,
          'readMessages': 0,
          'responseRate': 0.0,
          'averageResponseTime': null,
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Send urgent alert to all parents of students in a class
  Future<void> sendClassAlert({
    required String schoolId,
    required String teacherId,
    required String className,
    required String alertTitle,
    required String alertMessage,
    String priority = 'high',
  }) async {
    final online = await _offlineService.isOnline;
    final alertData = {
      'schoolId': schoolId,
      'teacherId': teacherId,
      'className': className,
      'title': alertTitle,
      'message': alertMessage,
      'priority': priority,
      'timestamp': DateTime.now().toIso8601String(),
      'alertType': 'class_alert',
    };

    if (online) {
      try {
        await _apiClient.post(
            '/api/schools/$schoolId/communications/class-alerts',
            body: alertData);
        // Cache the alert locally
        await _cacheClassAlert(alertData);
      } catch (e) {
        // Queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'class_alerts',
          ...alertData,
        });
        await _cacheClassAlert(alertData);
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'class_alerts',
        ...alertData,
      });
      await _cacheClassAlert(alertData);
    }
  }

  /// Cache a teacher message locally
  Future<void> _cacheTeacherMessage(TeacherMessage message) async {
    final cacheKey = 'teacher_message_${message.id}';
    await _localDb.saveData('teacher_message', message.id, message.toMap());
  }

  /// Cache a class alert locally
  Future<void> _cacheClassAlert(Map<String, dynamic> alertData) async {
    final alertId = 'class_alert_${DateTime.now().millisecondsSinceEpoch}';
    await _localDb.saveData('class_alert', alertId, {
      ...alertData,
      'id': alertId,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get pending messages queued for sync
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    final pendingOps = await _offlineService.getOfflineDataStatus();
    // This would need to be implemented to filter communication-specific pending operations
    return [];
  }

  /// Clear communication cache for a teacher
  Future<void> clearTeacherCommunicationCache(String teacherId) async {
    // Clear teacher-specific communication cache
    await _localDb.deleteData('teacher_sent_messages', teacherId);
    await _localDb.deleteData('teacher_available_parents', teacherId);
  }

  /// Get message templates for common communications
  Future<List<Map<String, dynamic>>> getMessageTemplates({
    required String schoolId,
    String? category, // 'academic', 'behavior', 'attendance', 'general'
  }) async {
    final cacheKey = 'message_templates_${schoolId}_${category ?? 'all'}';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final query = category != null ? '?category=$category' : '';
        final response = await _apiClient
            .get('/api/schools/$schoolId/communication-templates$query');
        final List<dynamic> data = response as List<dynamic>;
        final templates = data.cast<Map<String, dynamic>>();

        // Cache templates locally
        await _localDb.saveData('message_templates', category ?? 'all', {
          'templates': templates,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return templates;
      },
      offlineFallback: () async {
        // Try to get cached templates
        final cached =
            await _localDb.getData('message_templates', category ?? 'all');
        if (cached != null && cached['templates'] != null) {
          return List<Map<String, dynamic>>.from(cached['templates']);
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }
}

// Singleton instance
final teacherCommunicationService = TeacherCommunicationService();

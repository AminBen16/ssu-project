import 'package:logger/logger.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';


class NotificationService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;
  final Logger _logger = Logger();

  /// Fetches all notifications for a student with offline support
  Future<List<Map<String, dynamic>>> getStudentNotifications(
      String studentId) async {
    final cacheKey = 'student_notifications_$studentId';

    return await _offlineService.callWithOfflineFallbackAndSync(
      onlineCall: () async {
        try {
          final response =
              await _apiClient.get('/api/students/$studentId/notifications');
          if (response == null) return [];

          final List<dynamic> data = response['notifications'] as List<dynamic>;
          final notifications = data
              .map((notification) => notification as Map<String, dynamic>)
              .toList();

          // Cache notifications locally for offline access
          await _localDb.saveData('notifications', studentId, {
            'notifications': notifications,
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          return notifications;
        } catch (e) {
          throw Exception('Failed to fetch notifications: ${e.toString()}');
        }
      },
      offlineFallback: () async {
        // Try to get cached notifications from local database
        final cached = await _localDb.getData('notifications', studentId);
        if (cached != null && cached['notifications'] != null) {
          return List<Map<String, dynamic>>.from(cached['notifications']);
        }
        return [];
      },
      cacheKey: cacheKey,
      tableName: 'notifications',
      recordId: studentId,
    );
  }

  /// Marks a notification as read with offline support
  Future<void> markNotificationAsRead(String notificationId) async {
    final isOnline = await _offlineService.isOnline;

    if (isOnline) {
      try {
        await _apiClient.put('/api/notifications/$notificationId/read');
        // Update local cache
        await _updateLocalNotificationReadStatus(notificationId, true);
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('update', {
          'table': 'notifications',
          'id': notificationId,
          'isRead': true,
          'operation': 'mark_read',
        });
        // Update local cache optimistically
        await _updateLocalNotificationReadStatus(notificationId, true);
        throw Exception('Failed to mark notification as read: ${e.toString()}');
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('update', {
        'table': 'notifications',
        'id': notificationId,
        'isRead': true,
        'operation': 'mark_read',
      });
      // Update local cache optimistically
      await _updateLocalNotificationReadStatus(notificationId, true);
    }
  }

  /// Updates the read status of a notification in local cache with proper studentId tracking
  Future<void> _updateLocalNotificationReadStatus(
      String notificationId, bool isRead, {String? studentId}) async {
    if (studentId != null) {
      // Direct update using studentId
      final cachedData = await _localDb.getData('notifications', studentId);
      if (cachedData != null && cachedData['notifications'] != null) {
        final notifications =
            List<Map<String, dynamic>>.from(cachedData['notifications']);
        final notificationIndex =
            notifications.indexWhere((n) => n['id'] == notificationId);
        if (notificationIndex != -1) {
          notifications[notificationIndex]['isRead'] = isRead;
          notifications[notificationIndex]['lastUpdated'] =
              DateTime.now().toIso8601String();
          await _localDb.saveData('notifications', studentId, {
            'notifications': notifications,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
          return;
        }
      }
    }

    // Fallback: Search through all cached data if studentId not provided
    final allCached = await _localDb.getAllData('notifications');
    for (final entry in allCached) {
      final currentStudentId = entry['id'] as String;
      final cachedData = await _localDb.getData('notifications', currentStudentId);
      if (cachedData != null && cachedData['notifications'] != null) {
        final notifications =
            List<Map<String, dynamic>>.from(cachedData['notifications']);
        final notificationIndex =
            notifications.indexWhere((n) => n['id'] == notificationId);
        if (notificationIndex != -1) {
          notifications[notificationIndex]['isRead'] = isRead;
          notifications[notificationIndex]['lastUpdated'] =
              DateTime.now().toIso8601String();
          await _localDb.saveData('notifications', currentStudentId, {
            'notifications': notifications,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
          break; // Found and updated, exit loop
        }
      }
    }
  }

  /// Marks a notification as read for a student
  Future<void> markNotificationAsReadForStudent(
      String studentId, String notificationId, bool isRead) async {
    // Get all cached notification data to find the one to update
    final allCached = await _localDb.getAllData('notifications');
    for (final entry in allCached) {
      final cachedStudentId = entry['id'] as String;
      final cachedData = await _localDb.getData('notifications', cachedStudentId);
      if (cachedData != null && cachedData['notifications'] != null) {
        final notifications =
            List<Map<String, dynamic>>.from(cachedData['notifications']);
        final notificationIndex =
            notifications.indexWhere((n) => n['id'] == notificationId);
        if (notificationIndex != -1) {
          notifications[notificationIndex]['isRead'] = isRead;
          notifications[notificationIndex]['lastUpdated'] =
              DateTime.now().toIso8601String();
          await _localDb.saveData('notifications', cachedStudentId, {
            'notifications': notifications,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
          break; // Found and updated, exit loop
        }
      }
    }
  }

  /// Gets the count of unread notifications
  Future<int> getUnreadNotificationCount(String studentId) async {
    try {
      final response = await _apiClient
          .get('/api/students/$studentId/notifications/unread-count');
      if (response == null) return 0;

      return response['count'] as int? ?? 0;
    } catch (e) {
      throw Exception(
          'Failed to fetch unread notification count: ${e.toString()}');
    }
  }

  /// Marks all notifications as read for a student
  Future<void> markAllNotificationsAsRead(String studentId) async {
    try {
      final notifications = await getStudentNotifications(studentId);
      final unreadNotifications =
          notifications.where((n) => !(n['isRead'] as bool)).toList();

      for (final notification in unreadNotifications) {
        await markNotificationAsRead(notification['id'] as String);
      }
    } catch (e) {
      throw Exception(
          'Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  /// Gets offline notification statistics
  Future<Map<String, dynamic>> getOfflineNotificationStats() async {
    final pendingOperations = await _offlineService.getOfflineDataStatus();
    final pendingSync = pendingOperations['pendingSyncCount'] as int? ?? 0;

    return {
      'isOnline': await _offlineService.isOnline,
      'pendingSyncOperations': pendingSync,
      'cachedNotifications':
          true, // Simplified - could count actual cached items
    };
  }

  /// Gets notifications for all children of a parent (aggregated view)
  Future<List<Map<String, dynamic>>> getNotificationsForParent({
    required String schoolId,
    required String parentId,
    required List<String> childrenIds,
  }) async {
    final cacheKey = 'parent_notifications_${schoolId}_$parentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final allNotifications = <Map<String, dynamic>>[];

        // Get notifications for each child
        for (final childId in childrenIds) {
          final childNotifications = await getNotificationsForStudent(
            schoolId: schoolId,
            studentId: childId,
          );
          allNotifications.addAll(childNotifications);
        }

        // Get general parent notifications (announcements, etc.)
        final parentNotifications = await _getParentGeneralNotifications(
          schoolId: schoolId,
          parentId: parentId,
        );
        allNotifications.addAll(parentNotifications);

        // Sort by timestamp (most recent first)
        allNotifications.sort((a, b) {
          final aTime = DateTime.parse(a['timestamp'] as String);
          final bTime = DateTime.parse(b['timestamp'] as String);
          return bTime.compareTo(aTime);
        });

        // Cache aggregated notifications
        await _localDb
            .saveData('parent_notifications', '${schoolId}_$parentId', {
          'notifications': allNotifications,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return allNotifications;
      },
      offlineFallback: () async {
        // Try to get cached parent notifications
        final cached = await _localDb.getData(
            'parent_notifications', '${schoolId}_$parentId');
        if (cached != null && cached['notifications'] != null) {
          return List<Map<String, dynamic>>.from(cached['notifications']);
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Gets notifications specific to a student with offline support
  Future<List<Map<String, dynamic>>> getNotificationsForStudent({
    required String schoolId,
    required String studentId,
  }) async {
    final cacheKey = 'student_notifications_${schoolId}_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        try {
          final response = await _apiClient
              .get('/api/schools/$schoolId/students/$studentId/notifications');
          if (response == null) return [];

          final List<dynamic> data =
              response['notifications'] as List<dynamic>? ?? [];
          final notifications = data
              .map((notification) => notification as Map<String, dynamic>)
              .toList();

          // Cache notifications locally
          await _localDb
              .saveData('student_notifications', '${schoolId}_$studentId', {
            'notifications': notifications,
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          return notifications;
        } catch (e) {
          throw Exception(
              'Failed to fetch student notifications: ${e.toString()}');
        }
      },
      offlineFallback: () async {
        // Try to get cached notifications
        final cached = await _localDb.getData(
            'student_notifications', '${schoolId}_$studentId');
        if (cached != null && cached['notifications'] != null) {
          return List<Map<String, dynamic>>.from(cached['notifications']);
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Gets general notifications for a parent (announcements, school news, etc.)
  Future<List<Map<String, dynamic>>> _getParentGeneralNotifications({
    required String schoolId,
    required String parentId,
  }) async {
    try {
      final response = await _apiClient
          .get('/api/schools/$schoolId/parents/$parentId/notifications');
      if (response == null) return [];

      final List<dynamic> data =
          response['notifications'] as List<dynamic>? ?? [];
      return data
          .map((notification) => notification as Map<String, dynamic>)
          .toList();
    } catch (e) {
      // Return empty list if API fails, don't throw to avoid breaking parent notification aggregation
      _logger.e('Failed to fetch parent general notifications: $e');
      return [];
    }
  }

  /// Gets unread notification count for a parent across all children
  Future<int> getParentUnreadNotificationCount({
    required String schoolId,
    required String parentId,
    required List<String> childrenIds,
  }) async {
    try {
      final notifications = await getNotificationsForParent(
        schoolId: schoolId,
        parentId: parentId,
        childrenIds: childrenIds,
      );
      return notifications
          .where((n) => !(n['isRead'] as bool? ?? false))
          .length;
    } catch (e) {
      _logger.e('Failed to get parent unread notification count: $e');
      return 0;
    }
  }

  /// Clears all cached notification data
  Future<void> clearNotificationCache() async {
    // This would need to be implemented to clear notification-specific cache
    // For now, we'll clear all cache
    await _offlineService.clearCache();
  }
}

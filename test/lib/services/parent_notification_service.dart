import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

/// Model for parent notifications
class ParentNotification {
  final String id;
  final String parentId;
  final String title;
  final String message;
  final String
      category; // 'academic', 'financial', 'administrative', 'emergency', 'general'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;
  final bool isArchived;
  final String? actionUrl; // URL for action button
  final String? actionText; // Text for action button
  final Map<String, dynamic>? metadata; // Additional data
  final String? relatedStudentId; // If notification is about a specific student
  final String? relatedStudentName;

  ParentNotification({
    required this.id,
    required this.parentId,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.readAt,
    this.isRead = false,
    this.isArchived = false,
    this.actionUrl,
    this.actionText,
    this.metadata,
    this.relatedStudentId,
    this.relatedStudentName,
  });

  factory ParentNotification.fromMap(Map<String, dynamic> map) {
    return ParentNotification(
      id: map['id'] as String,
      parentId: map['parentId'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      category: map['category'] as String? ?? 'general',
      priority: map['priority'] as String? ?? 'medium',
      createdAt: DateTime.parse(map['createdAt'] as String),
      readAt: map['readAt'] != null
          ? DateTime.parse(map['readAt'] as String)
          : null,
      isRead: map['isRead'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      actionUrl: map['actionUrl'],
      actionText: map['actionText'],
      metadata: map['metadata'] as Map<String, dynamic>?,
      relatedStudentId: map['relatedStudentId'] as String?,
      relatedStudentName: map['relatedStudentName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'title': title,
      'message': message,
      'category': category,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isRead': isRead,
      'isArchived': isArchived,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'metadata': metadata,
      'relatedStudentId': relatedStudentId,
      'relatedStudentName': relatedStudentName,
    };
  }

  ParentNotification copyWith({
    bool? isRead,
    DateTime? readAt,
    bool? isArchived,
  }) {
    return ParentNotification(
      id: id,
      parentId: parentId,
      title: title,
      message: message,
      category: category,
      priority: priority,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      actionUrl: actionUrl,
      actionText: actionText,
      metadata: metadata,
      relatedStudentId: relatedStudentId,
      relatedStudentName: relatedStudentName,
    );
  }
}

/// Service for managing parent notifications with offline support
class ParentNotificationService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Get all notifications for a parent with offline support
  Future<List<ParentNotification>> getNotifications({
    required String schoolId,
    required String parentId,
    int limit = 50,
    bool includeArchived = false,
    String? category,
  }) async {
    final cacheKey =
        'parent_notifications_${schoolId}_${parentId}_${limit}_${includeArchived}_${category ?? 'all'}';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final queryParams = <String, String>{
          'limit': limit.toString(),
          if (includeArchived) 'includeArchived': 'true',
          if (category != null) 'category': category,
        };

        final queryString =
            queryParams.entries.map((e) => '$e.key=$e.value').join('&');

        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/notifications?$queryString',
        );
        final List<dynamic> data = response as List<dynamic>;
        final notifications = data
            .map((item) =>
                ParentNotification.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache notifications locally
        for (final notification in notifications) {
          await _localDb.saveData(
              'parent_notifications', notification.id, notification.toMap());
        }

        return notifications;
      },
      offlineFallback: () async {
        // Get cached notifications
        final allNotifications =
            await _localDb.getAllData('parent_notifications');
        return allNotifications
            .map((item) => ParentNotification.fromMap(item))
            .where((notification) =>
                notification.parentId == parentId &&
                (!notification.isArchived || includeArchived) &&
                (category == null || notification.category == category))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
      cacheKey: cacheKey,
    );
  }

  /// Get unread notification count
  Future<int> getUnreadCount({
    required String schoolId,
    required String parentId,
  }) async {
    final notifications = await getNotifications(
      schoolId: schoolId,
      parentId: parentId,
      includeArchived: false,
    );
    return notifications.where((n) => !n.isRead).length;
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    // Update local cache
    final cached =
        await _localDb.getData('parent_notifications', notificationId);
    if (cached != null) {
      final notification = ParentNotification.fromMap(cached);
      final updatedNotification = notification.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      await _localDb.saveData(
          'parent_notifications', notificationId, updatedNotification.toMap());
    }

    // Try to update server (don't fail if offline)
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient
            .post('/api/notifications/$notificationId/read', body: {});
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    for (final id in notificationIds) {
      await markAsRead(id);
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    // Update local cache
    final cached =
        await _localDb.getData('parent_notifications', notificationId);
    if (cached != null) {
      final notification = ParentNotification.fromMap(cached);
      final updatedNotification = notification.copyWith(isArchived: true);
      await _localDb.saveData(
          'parent_notifications', notificationId, updatedNotification.toMap());
    }

    // Try to update server
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient
            .post('/api/notifications/$notificationId/archive', body: {});
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    // Remove from local cache
    await _localDb.deleteData('parent_notifications', notificationId);

    // Try to delete from server
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient.delete('/api/notifications/$notificationId');
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Get notifications by category
  Future<List<ParentNotification>> getNotificationsByCategory({
    required String schoolId,
    required String parentId,
    required String category,
    int limit = 20,
  }) async {
    return await getNotifications(
      schoolId: schoolId,
      parentId: parentId,
      limit: limit,
      includeArchived: false,
      category: category,
    );
  }

  /// Get urgent/high priority notifications
  Future<List<ParentNotification>> getUrgentNotifications({
    required String schoolId,
    required String parentId,
  }) async {
    final allNotifications = await getNotifications(
      schoolId: schoolId,
      parentId: parentId,
      includeArchived: false,
    );

    return allNotifications
        .where((notification) =>
            notification.priority == 'urgent' ||
            notification.priority == 'high')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get notifications for a specific student
  Future<List<ParentNotification>> getStudentNotifications({
    required String schoolId,
    required String parentId,
    required String studentId,
    int limit = 20,
  }) async {
    final allNotifications = await getNotifications(
      schoolId: schoolId,
      parentId: parentId,
      limit: limit * 2, // Get more to filter
      includeArchived: false,
    );

    return allNotifications
        .where((notification) => notification.relatedStudentId == studentId)
        .take(limit)
        .toList();
  }

  /// Search notifications
  Future<List<ParentNotification>> searchNotifications({
    required String schoolId,
    required String parentId,
    required String query,
    int limit = 20,
  }) async {
    final cacheKey =
        'notification_search_${schoolId}_${parentId}_${query}_$limit';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/notifications/search?q=$query&limit=$limit',
        );
        final List<dynamic> data = response as List<dynamic>;
        final searchResults = data
            .map((item) =>
                ParentNotification.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache search results
        await _localDb.saveData('notification_search', cacheKey, {
          'results': searchResults.map((n) => n.toMap()).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        });

        return searchResults;
      },
      offlineFallback: () async {
        // Search in cached notifications
        final allNotifications =
            await _localDb.getAllData('parent_notifications');
        final queryLower = query.toLowerCase();

        return allNotifications
            .map((item) => ParentNotification.fromMap(item))
            .where((notification) =>
                notification.parentId == parentId &&
                (notification.title.toLowerCase().contains(queryLower) ||
                    notification.message.toLowerCase().contains(queryLower)))
            .take(limit)
            .toList();
      },
      cacheKey: cacheKey,
    );
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats({
    required String schoolId,
    required String parentId,
  }) async {
    final notifications = await getNotifications(
      schoolId: schoolId,
      parentId: parentId,
      includeArchived: true,
    );

    final stats = {
      'totalNotifications': notifications.length,
      'unreadNotifications': notifications.where((n) => !n.isRead).length,
      'archivedNotifications': notifications.where((n) => n.isArchived).length,
      'notificationsByCategory': <String, int>{},
      'notificationsByPriority': <String, int>{},
      'averageResponseTime': null, // Would need read timestamps to calculate
    };

    // Calculate category stats
    final categoryStats = stats['notificationsByCategory'] as Map<String, int>;
    final priorityStats = stats['notificationsByPriority'] as Map<String, int>;
    for (final notification in notifications) {
      categoryStats[notification.category] =
          (categoryStats[notification.category] ?? 0) + 1;
      priorityStats[notification.priority] =
          (priorityStats[notification.priority] ?? 0) + 1;
    }

    return stats;
  }

  /// Get notification preferences for a parent
  Future<Map<String, dynamic>> getNotificationPreferences({
    required String schoolId,
    required String parentId,
  }) async {
    final cacheKey = 'notification_preferences_${schoolId}_$parentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/notification-preferences',
        );
        final preferences = response as Map<String, dynamic>;

        // Cache preferences
        await _localDb.saveData('notification_preferences', parentId, {
          ...preferences,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return preferences;
      },
      offlineFallback: () async {
        // Try to get cached preferences
        final cached =
            await _localDb.getData('notification_preferences', parentId);
        if (cached != null) {
          return Map<String, dynamic>.from(cached)..remove('lastUpdated');
        }

        // Return default preferences
        return {
          'emailNotifications': true,
          'pushNotifications': true,
          'smsNotifications': false,
          'categories': {
            'academic': true,
            'financial': true,
            'administrative': true,
            'emergency': true,
            'general': true,
          },
          'quietHours': {
            'enabled': false,
            'startTime': '22:00',
            'endTime': '08:00',
          },
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required String schoolId,
    required String parentId,
    required Map<String, dynamic> preferences,
  }) async {
    // Update local cache
    await _localDb.saveData('notification_preferences', parentId, {
      ...preferences,
      'lastUpdated': DateTime.now().toIso8601String(),
    });

    // Try to update server
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient.put(
          '/api/schools/$schoolId/parents/$parentId/notification-preferences',
          body: preferences,
        );
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Create a custom notification (for testing/admin purposes)
  Future<void> createCustomNotification({
    required String schoolId,
    required String parentId,
    required String title,
    required String message,
    required String category,
    required String priority,
    String? actionUrl,
    String? actionText,
    String? relatedStudentId,
    Map<String, dynamic>? metadata,
  }) async {
    final notificationId =
        'custom_notification_${DateTime.now().millisecondsSinceEpoch}';
    final notification = ParentNotification(
      id: notificationId,
      parentId: parentId,
      title: title,
      message: message,
      category: category,
      priority: priority,
      createdAt: DateTime.now(),
      actionUrl: actionUrl,
      actionText: actionText,
      relatedStudentId: relatedStudentId,
      metadata: metadata,
    );

    // Save locally
    await _localDb.saveData(
        'parent_notifications', notificationId, notification.toMap());

    // Try to create on server
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient.post(
          '/api/schools/$schoolId/parents/$parentId/notifications',
          body: {
            'title': title,
            'message': message,
            'category': category,
            'priority': priority,
            'actionUrl': actionUrl,
            'actionText': actionText,
            'relatedStudentId': relatedStudentId,
            'metadata': metadata,
          },
        );
      }
    } catch (e) {
      // Silently fail - notification is saved locally
    }
  }

  /// Get notification digest (summary for dashboard)
  Future<Map<String, dynamic>> getNotificationDigest({
    required String schoolId,
    required String parentId,
  }) async {
    final unreadCount = await getUnreadCount(
      schoolId: schoolId,
      parentId: parentId,
    );

    final urgentNotifications = await getUrgentNotifications(
      schoolId: schoolId,
      parentId: parentId,
    );

    final recentNotifications = await getNotifications(
      schoolId: schoolId,
      parentId: parentId,
      limit: 5,
      includeArchived: false,
    );

    return {
      'unreadCount': unreadCount,
      'urgentCount': urgentNotifications.length,
      'recentNotifications': recentNotifications.map((n) => n.toMap()).toList(),
      'hasUrgentNotifications': urgentNotifications.isNotEmpty,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Clear old notifications (cleanup)
  Future<void> clearOldNotifications({
    required String parentId,
    int maxAgeDays = 90,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
    final allNotifications = await _localDb.getAllData('parent_notifications');

    for (final item in allNotifications) {
      final notification = ParentNotification.fromMap(item);
      if (notification.createdAt.isBefore(cutoffDate) &&
          notification.isRead &&
          notification.isArchived) {
        await _localDb.deleteData('parent_notifications', notification.id);
      }
    }
  }

  /// Refresh notifications from server
  Future<void> refreshNotifications({
    required String schoolId,
    required String parentId,
  }) async {
    final isOnline = await _offlineService.isOnline;
    if (!isOnline) return;

    try {
      await getNotifications(
        schoolId: schoolId,
        parentId: parentId,
        limit: 50,
        includeArchived: false,
      );
    } catch (e) {
      // Error refreshing notifications: $e
    }
  }

  /// Clear all cached notifications for a parent
  Future<void> clearParentNotificationsCache(String parentId) async {
    // This would need to be implemented to clear only parent-specific notifications
    // For now, we'll clear all notification caches
    await _localDb.clearCache();
  }
}

// Singleton instance
final parentNotificationService = ParentNotificationService();

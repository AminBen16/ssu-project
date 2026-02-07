import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

/// Model for school announcements
class SchoolAnnouncement {
  final String id;
  final String title;
  final String content;
  final String
      category; // 'general', 'academic', 'events', 'emergency', 'administrative'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime publishedDate;
  final DateTime? expiryDate;
  final String authorName;
  final String authorRole;
  final List<String>? targetAudiences; // ['parents', 'students', 'staff']
  final List<String>? attachedFiles;
  final bool isRead;
  final DateTime? readAt;
  final bool isArchived;

  SchoolAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.publishedDate,
    this.expiryDate,
    required this.authorName,
    required this.authorRole,
    this.targetAudiences,
    this.attachedFiles,
    this.isRead = false,
    this.readAt,
    this.isArchived = false,
  });

  factory SchoolAnnouncement.fromMap(Map<String, dynamic> map) {
    return SchoolAnnouncement(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String? ?? 'general',
      priority: map['priority'] as String? ?? 'medium',
      publishedDate: DateTime.parse(map['publishedDate'] as String),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
      authorName: map['authorName'] as String,
      authorRole: map['authorRole'] as String,
      targetAudiences:
          (map['targetAudiences'] as List<dynamic>?)?.cast<String>(),
      attachedFiles: (map['attachedFiles'] as List<dynamic>?)?.cast<String>(),
      isRead: map['isRead'] as bool? ?? false,
      readAt: map['readAt'] != null
          ? DateTime.parse(map['readAt'] as String)
          : null,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'publishedDate': publishedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'authorName': authorName,
      'authorRole': authorRole,
      'targetAudiences': targetAudiences,
      'attachedFiles': attachedFiles,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  SchoolAnnouncement copyWith({
    bool? isRead,
    DateTime? readAt,
    bool? isArchived,
  }) {
    return SchoolAnnouncement(
      id: id,
      title: title,
      content: content,
      category: category,
      priority: priority,
      publishedDate: publishedDate,
      expiryDate: expiryDate,
      authorName: authorName,
      authorRole: authorRole,
      targetAudiences: targetAudiences,
      attachedFiles: attachedFiles,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

/// Model for school events
class SchoolEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String
      eventType; // 'academic', 'sports', 'cultural', 'meeting', 'holiday'
  final bool isAllDay;
  final List<String>? targetAudiences;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final List<String>? attachedFiles;
  final bool isRead;
  final DateTime? readAt;
  final bool isArchived;

  SchoolEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.eventType,
    required this.isAllDay,
    this.targetAudiences,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.attachedFiles,
    this.isRead = false,
    this.readAt,
    this.isArchived = false,
  });

  factory SchoolEvent.fromMap(Map<String, dynamic> map) {
    return SchoolEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      location: map['location'] as String,
      eventType: map['eventType'] as String? ?? 'academic',
      isAllDay: map['isAllDay'] as bool? ?? false,
      targetAudiences:
          (map['targetAudiences'] as List<dynamic>?)?.cast<String>(),
      contactPerson: map['contactPerson'] as String?,
      contactEmail: map['contactEmail'] as String?,
      contactPhone: map['contactPhone'] as String?,
      attachedFiles: (map['attachedFiles'] as List<dynamic>?)?.cast<String>(),
      isRead: map['isRead'] as bool? ?? false,
      readAt: map['readAt'] != null
          ? DateTime.parse(map['readAt'] as String)
          : null,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'eventType': eventType,
      'isAllDay': isAllDay,
      'targetAudiences': targetAudiences,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'attachedFiles': attachedFiles,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  SchoolEvent copyWith({
    bool? isRead,
    DateTime? readAt,
    bool? isArchived,
  }) {
    return SchoolEvent(
      id: id,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      location: location,
      eventType: eventType,
      isAllDay: isAllDay,
      targetAudiences: targetAudiences,
      contactPerson: contactPerson,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      attachedFiles: attachedFiles,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

/// Service for managing school announcements and events with offline support
class SchoolAnnouncementsService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Get all announcements for a school with offline support
  Future<List<SchoolAnnouncement>> getAnnouncements({
    required String schoolId,
    String? userRole, // 'parent', 'student', 'staff'
    int limit = 50,
    bool includeArchived = false,
  }) async {
    final cacheKey =
        'announcements_${schoolId}_${userRole ?? 'all'}_${limit}_$includeArchived';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final queryParams = <String, String>{
          'limit': limit.toString(),
          if (userRole != null) 'role': userRole,
          if (includeArchived) 'includeArchived': 'true',
        };

        final queryString =
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

        final response = await _apiClient.get(
          '/api/schools/$schoolId/announcements?$queryString',
        );
        final List<dynamic> data = response as List<dynamic>;
        final announcements = data
            .map((item) =>
                SchoolAnnouncement.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache announcements locally
        for (final announcement in announcements) {
          await _localDb.saveData(
              'announcements', announcement.id, announcement.toMap());
        }

        return announcements;
      },
      offlineFallback: () async {
        // Get cached announcements
        final allAnnouncements = await _localDb.getAllData('announcements');
        return allAnnouncements
            .map((item) => SchoolAnnouncement.fromMap(item))
            .where(
                (announcement) => !announcement.isArchived || includeArchived)
            .toList()
          ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
      },
      cacheKey: cacheKey,
    );
  }

  /// Get unread announcements count
  Future<int> getUnreadAnnouncementsCount({
    required String schoolId,
    String? userRole,
  }) async {
    final announcements = await getAnnouncements(
      schoolId: schoolId,
      userRole: userRole,
      includeArchived: false,
    );
    return announcements.where((announcement) => !announcement.isRead).length;
  }

  /// Mark announcement as read
  Future<void> markAnnouncementAsRead(String announcementId) async {
    // Update local cache
    final cached = await _localDb.getData('announcements', announcementId);
    if (cached != null) {
      final announcement = SchoolAnnouncement.fromMap(cached);
      final updatedAnnouncement = announcement.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      await _localDb.saveData(
          'announcements', announcementId, updatedAnnouncement.toMap());
    }

    // Try to update server (don't fail if offline)
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient
            .post('/api/announcements/$announcementId/read', body: {});
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Archive announcement
  Future<void> archiveAnnouncement(String announcementId) async {
    // Update local cache
    final cached = await _localDb.getData('announcements', announcementId);
    if (cached != null) {
      final announcement = SchoolAnnouncement.fromMap(cached);
      final updatedAnnouncement = announcement.copyWith(isArchived: true);
      await _localDb.saveData(
          'announcements', announcementId, updatedAnnouncement.toMap());
    }

    // Try to update server
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient
            .post('/api/announcements/$announcementId/archive', body: {});
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Get school events with offline support
  Future<List<SchoolEvent>> getEvents({
    required String schoolId,
    String? userRole,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    bool includeArchived = false,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now().add(const Duration(days: 90));
    final cacheKey =
        'events_${schoolId}_${userRole ?? 'all'}_${start.toIso8601String()}_${end.toIso8601String()}_${limit}_$includeArchived';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final queryParams = <String, String>{
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
          'limit': limit.toString(),
          if (userRole != null) 'role': userRole,
          if (includeArchived) 'includeArchived': 'true',
        };

        final queryString =
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

        final response = await _apiClient.get(
          '/api/schools/$schoolId/events?$queryString',
        );
        final List<dynamic> data = response as List<dynamic>;
        final events = data
            .map((item) => SchoolEvent.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache events locally
        for (final event in events) {
          await _localDb.saveData('events', event.id, event.toMap());
        }

        return events;
      },
      offlineFallback: () async {
        // Get cached events within date range
        final allEvents = await _localDb.getAllData('events');
        return allEvents
            .map((item) => SchoolEvent.fromMap(item))
            .where((event) =>
                event.startDate.isAfter(start) &&
                event.startDate.isBefore(end) &&
                (!event.isArchived || includeArchived))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
      },
      cacheKey: cacheKey,
    );
  }

  /// Get upcoming events (next 30 days)
  Future<List<SchoolEvent>> getUpcomingEvents({
    required String schoolId,
    String? userRole,
    int daysAhead = 30,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));

    return await getEvents(
      schoolId: schoolId,
      userRole: userRole,
      startDate: now,
      endDate: endDate,
      includeArchived: false,
    );
  }

  /// Mark event as read
  Future<void> markEventAsRead(String eventId) async {
    // Update local cache
    final cached = await _localDb.getData('events', eventId);
    if (cached != null) {
      final event = SchoolEvent.fromMap(cached);
      final updatedEvent = event.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      await _localDb.saveData('events', eventId, updatedEvent.toMap());
    }

    // Try to update server
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient.post('/api/events/$eventId/read', body: {});
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Archive event
  Future<void> archiveEvent(String eventId) async {
    // Update local cache
    final cached = await _localDb.getData('events', eventId);
    if (cached != null) {
      final event = SchoolEvent.fromMap(cached);
      final updatedEvent = event.copyWith(isArchived: true);
      await _localDb.saveData('events', eventId, updatedEvent.toMap());
    }

    // Try to update server
    try {
      final isOnline = await _offlineService.isOnline;
      if (isOnline) {
        await _apiClient.post('/api/events/$eventId/archive', body: {});
      }
    } catch (e) {
      // Silently fail - will sync when online
    }
  }

  /// Get emergency alerts (high priority announcements)
  Future<List<SchoolAnnouncement>> getEmergencyAlerts({
    required String schoolId,
    String? userRole,
  }) async {
    final announcements = await getAnnouncements(
      schoolId: schoolId,
      userRole: userRole,
      limit: 10,
      includeArchived: false,
    );

    return announcements
        .where((announcement) =>
            announcement.priority == 'urgent' ||
            announcement.category == 'emergency')
        .toList()
      ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
  }

  /// Search announcements and events
  Future<Map<String, List<dynamic>>> searchContent({
    required String schoolId,
    required String query,
    String? userRole,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey =
        'search_${schoolId}_${query}_${userRole ?? 'all'}_${startDate?.toIso8601String() ?? 'none'}_${endDate?.toIso8601String() ?? 'none'}';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final queryParams = <String, String>{
          'q': query,
          if (userRole != null) 'role': userRole,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        };

        final queryString =
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

        final response = await _apiClient.get(
          '/api/schools/$schoolId/search/announcements-events?$queryString',
        );

        final searchResults = response as Map<String, dynamic>;

        // Cache search results
        await _localDb.saveData('search_results', cacheKey, {
          'results': searchResults,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return {
          'announcements': (searchResults['announcements'] as List<dynamic>?)
                  ?.map((item) =>
                      SchoolAnnouncement.fromMap(item as Map<String, dynamic>))
                  .toList() ??
              [],
          'events': (searchResults['events'] as List<dynamic>?)
                  ?.map((item) =>
                      SchoolEvent.fromMap(item as Map<String, dynamic>))
                  .toList() ??
              [],
        };
      },
      offlineFallback: () async {
        // Search in cached data
        final announcements = await _localDb.getAllData('announcements');
        final events = await _localDb.getAllData('events');

        final matchingAnnouncements = announcements
            .map((item) => SchoolAnnouncement.fromMap(item))
            .where((announcement) =>
                announcement.title
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                announcement.content
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();

        final matchingEvents = events
            .map((item) => SchoolEvent.fromMap(item))
            .where((event) =>
                event.title.toLowerCase().contains(query.toLowerCase()) ||
                event.description.toLowerCase().contains(query.toLowerCase()))
            .toList();

        return {
          'announcements': matchingAnnouncements,
          'events': matchingEvents,
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Get announcement categories and their counts
  Future<Map<String, int>> getAnnouncementCategories({
    required String schoolId,
    String? userRole,
  }) async {
    final announcements = await getAnnouncements(
      schoolId: schoolId,
      userRole: userRole,
      includeArchived: false,
    );

    final categories = <String, int>{};
    for (final announcement in announcements) {
      categories[announcement.category] =
          (categories[announcement.category] ?? 0) + 1;
    }

    return categories;
  }

  /// Get event types and their counts
  Future<Map<String, int>> getEventTypes({
    required String schoolId,
    String? userRole,
  }) async {
    final events = await getEvents(
      schoolId: schoolId,
      userRole: userRole,
      includeArchived: false,
    );

    final types = <String, int>{};
    for (final event in events) {
      types[event.eventType] = (types[event.eventType] ?? 0) + 1;
    }

    return types;
  }

  /// Get content summary for dashboard
  Future<Map<String, dynamic>> getContentSummary({
    required String schoolId,
    String? userRole,
  }) async {
    final announcements = await getAnnouncements(
      schoolId: schoolId,
      userRole: userRole,
      limit: 100,
      includeArchived: false,
    );

    final events = await getUpcomingEvents(
      schoolId: schoolId,
      userRole: userRole,
      daysAhead: 30,
    );

    final unreadAnnouncements = announcements.where((a) => !a.isRead).length;
    final urgentAnnouncements =
        announcements.where((a) => a.priority == 'urgent').length;
    final upcomingEvents = events.length;

    return {
      'totalAnnouncements': announcements.length,
      'unreadAnnouncements': unreadAnnouncements,
      'urgentAnnouncements': urgentAnnouncements,
      'upcomingEvents': upcomingEvents,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Refresh announcements and events data
  Future<void> refreshContent({
    required String schoolId,
    String? userRole,
  }) async {
    final isOnline = await _offlineService.isOnline;
    if (!isOnline) return;

    try {
      // Refresh announcements
      await getAnnouncements(
        schoolId: schoolId,
        userRole: userRole,
        limit: 50,
        includeArchived: false,
      );

      // Refresh events
      await getEvents(
        schoolId: schoolId,
        userRole: userRole,
        includeArchived: false,
      );
    } catch (e) {
      // Log error but don't throw - refresh failures shouldn't break the app
      print('Error refreshing announcements and events: $e');
    }
  }

  /// Clear cached content for a school
  Future<void> clearSchoolContentCache(String schoolId) async {
    // This would need to be implemented to clear all announcement and event caches for a school
    // For now, we'll clear all content-related caches
    await _localDb.clearCache();
  }

  /// Get content statistics for admin purposes
  Future<Map<String, dynamic>> getContentStats({
    required String schoolId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final announcements = await getAnnouncements(
      schoolId: schoolId,
      includeArchived: true,
    );

    final events = await getEvents(
      schoolId: schoolId,
      startDate: startDate,
      endDate: endDate,
      includeArchived: true,
    );

    final stats = {
      'totalAnnouncements': announcements.length,
      'totalEvents': events.length,
      'announcementsByCategory': <String, int>{},
      'eventsByType': <String, int>{},
      'announcementsByPriority': <String, int>{},
      'readRate': 0.0,
    };

    // Calculate category stats
    for (final announcement in announcements) {
      final categoryMap = stats['announcementsByCategory'] as Map<String, int>;
      categoryMap[announcement.category] =
          (categoryMap[announcement.category] ?? 0) + 1;

      final priorityMap = stats['announcementsByPriority'] as Map<String, int>;
      priorityMap[announcement.priority] =
          (priorityMap[announcement.priority] ?? 0) + 1;
    }

    // Calculate event type stats
    for (final event in events) {
      final typeMap = stats['eventsByType'] as Map<String, int>;
      typeMap[event.eventType] = (typeMap[event.eventType] ?? 0) + 1;
    }

    // Calculate read rate
    if (announcements.isNotEmpty) {
      final readCount = announcements.where((a) => a.isRead).length;
      stats['readRate'] = readCount / announcements.length;
    }

    return stats;
  }
}

// Singleton instance
final schoolAnnouncementsService = SchoolAnnouncementsService();

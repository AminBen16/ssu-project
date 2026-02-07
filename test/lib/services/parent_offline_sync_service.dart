import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';
import 'package:test/services/student_service.dart';
import 'package:test/services/fee_service.dart';
import 'package:test/services/report_card_service.dart';
import 'package:test/services/notification_service.dart';
import 'package:test/services/parent_communication_service.dart';

/// Service for managing offline sync operations specific to parent data
class ParentOfflineSyncService {
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;
  final StudentService _studentService = StudentService();
  final FeeService _feeService = FeeService();
  final ReportCardService _reportCardService = ReportCardService();
  final NotificationService _notificationService = NotificationService();
  final ParentCommunicationService _communicationService =
      ParentCommunicationService();
  final Logger _logger = Logger();

  /// Performs bulk sync of all parent-related data
  Future<void> syncParentData({
    required String schoolId,
    required String parentId,
  }) async {
    final isOnline = await _offlineService.isOnline;
    if (!isOnline) return;

    try {
      // Cache parent-child relationships
      await _cacheParentChildRelationships(schoolId, parentId);

      // Sync children data
      await _syncChildrenData(schoolId, parentId);

      // Sync fee data for all children
      await _syncFeeData(schoolId, parentId);

      // Sync report cards for all children
      await _syncReportCards(schoolId, parentId);

      // Sync notifications
      await _syncNotifications(schoolId, parentId);

      // Sync announcements
      await _syncAnnouncements(schoolId, parentId);

      // Sync communication data
      await _syncCommunicationData(schoolId, parentId);

      // Update last sync time
      await _updateLastSyncTime(schoolId, parentId);
    } catch (e) {
      _logger.e('Error during parent data sync: $e');
      rethrow;
    }
  }

  /// Syncs children data for the parent
  Future<void> _syncChildrenData(String schoolId, String parentId) async {
    try {
      await _studentService.getStudentsByParentId(
        schoolId: schoolId,
        parentId: parentId,
      );
      // Data is automatically cached by the service
    } catch (e) {
      _logger.e('Error syncing children data: $e');
    }
  }

  /// Syncs fee data for all children of the parent
  Future<void> _syncFeeData(String schoolId, String parentId) async {
    try {
      final children = await _studentService.getStudentsByParentId(
        schoolId: schoolId,
        parentId: parentId,
      );

      for (final child in children) {
        // Sync fee balance
        await _feeService.getStudentFeeBalance(child.id.toString());

        // Sync fee history
        await _feeService.getStudentFeeHistory(child.id.toString());
      }
    } catch (e) {
      _logger.e('Error syncing fee data: $e');
    }
  }

  /// Syncs report cards for all children of the parent
  Future<void> _syncReportCards(String schoolId, String parentId) async {
    try {
      final children = await _studentService.getStudentsByParentId(
        schoolId: schoolId,
        parentId: parentId,
      );

      for (final child in children) {
        // Get available terms
        final terms = await _reportCardService.getAvailableReportTerms(
          schoolId: schoolId,
          studentId: child.id,
        );

        // Sync latest report card for each term
        for (final term in terms) {
          final termData = term;
          final termName = termData['term'] as String;
          final year = termData['year'] is int
              ? termData['year'] as int
              : int.tryParse(termData['year'].toString()) ??
                  DateTime.now().year;

          await _reportCardService.getReportCardData(
            schoolId: schoolId,
            studentId: child.id,
            term: termName,
            year: year,
          );
        }
      }
    } catch (e) {
      _logger.e('Error syncing report cards: $e');
    }
  }

  /// Syncs notifications for the parent
  Future<void> _syncNotifications(String schoolId, String parentId) async {
    try {
      // Get children IDs for parent notification syncing
      final children = await _studentService.getStudentsByParentId(
        schoolId: schoolId,
        parentId: parentId,
      );
      final childrenIds = children.map((child) => child.id).toList();

      // Sync parent notifications (aggregates all children's notifications)
      await _notificationService.getNotificationsForParent(
        schoolId: schoolId,
        parentId: parentId,
        childrenIds: childrenIds,
      );
    } catch (e) {
      _logger.e('Error syncing notifications: $e');
    }
  }

  /// Syncs communication data for the parent
  Future<void> _syncCommunicationData(String schoolId, String parentId) async {
    try {
      // Sync messages (this will cache teacher contacts as well)
      await _communicationService.getParentMessages(
        schoolId: schoolId,
        parentId: parentId,
      );
    } catch (e) {
      _logger.e('Error syncing communication data: $e');
    }
  }

  /// Gets the sync status for parent data
  Future<Map<String, dynamic>> getParentSyncStatus({
    required String schoolId,
    required String parentId,
  }) async {
    final status = <String, dynamic>{};

    try {
      // Check if children data is cached
      final childrenCacheKey = 'students_by_parent_${schoolId}_$parentId';
      final childrenCached = await _localDb.getCache(childrenCacheKey);
      status['childrenSynced'] = childrenCached != null;

      // Check parent-child relationship caching
      final relationshipCacheKey =
          'parent_child_relationship_${schoolId}_$parentId';
      final relationshipCached = await _localDb.getCache(relationshipCacheKey);
      status['relationshipSynced'] = relationshipCached != null;

      // Check fee data sync status for each child
      final children = await _studentService.getStudentsByParentId(
        schoolId: schoolId,
        parentId: parentId,
      );
      bool allFeesSynced = true;
      bool allReportsSynced = true;
      for (final child in children) {
        final feeCacheKey = 'fee_balance_${child.id}';
        final feeCached = await _localDb.getCache(feeCacheKey);
        if (feeCached == null) allFeesSynced = false;

        final reportCacheKey = 'report_card_${child.id}_';
        final reportCached = await _localDb.getCache(reportCacheKey);
        if (reportCached == null) allReportsSynced = false;
      }
      status['feeDataSynced'] = allFeesSynced;
      status['reportCardsSynced'] = allReportsSynced;

      // Check notifications
      final notificationsCacheKey =
          'parent_notifications_${schoolId}_$parentId';
      final notificationsCached =
          await _localDb.getCache(notificationsCacheKey);
      status['notificationsSynced'] = notificationsCached != null;

      // Check announcements
      final announcementsCacheKey =
          'parent_announcements_${schoolId}_$parentId';
      final announcementsCached =
          await _localDb.getCache(announcementsCacheKey);
      status['announcementsSynced'] = announcementsCached != null;

      // Check communication data
      final messagesCacheKey = 'parent_messages_${schoolId}_$parentId';
      final messagesCached = await _localDb.getCache(messagesCacheKey);
      status['communicationSynced'] = messagesCached != null;

      // Get pending operations count
      final pendingOps = await _offlineService.getOfflineDataStatus();
      status['pendingOperations'] =
          int.tryParse(pendingOps['pendingSyncCount'].toString()) ?? 0;

      // Get last sync time
      final lastSyncKey = 'last_parent_sync_${schoolId}_$parentId';
      final lastSyncData = await _localDb.getCache(lastSyncKey);
      if (lastSyncData != null) {
        final Map<String, dynamic> data = jsonDecode(lastSyncData);
        status['lastSyncTime'] = data['timestamp'];
      } else {
        status['lastSyncTime'] = null;
      }

      status['overallSyncStatus'] = _calculateOverallSyncStatus(status);
    } catch (e) {
      _logger.e('Error getting sync status: $e');
      status['error'] = e.toString();
      status['overallSyncStatus'] = 'error';
    }

    return status;
  }

  /// Calculates overall sync status based on individual components
  String _calculateOverallSyncStatus(Map<String, dynamic> status) {
    final components = [
      status['childrenSynced'],
      status['relationshipSynced'],
      status['feeDataSynced'],
      status['reportCardsSynced'],
      status['notificationsSynced'],
      status['announcementsSynced'],
      status['communicationSynced'],
    ];

    final syncedCount = components.where((c) => c == true).length;
    final totalCount = components.length;

    if (syncedCount == totalCount) return 'fully_synced';
    if (syncedCount >= totalCount * 0.7) return 'mostly_synced';
    if (syncedCount >= totalCount * 0.4) return 'partially_synced';
    return 'needs_sync';
  }

  /// Performs selective sync based on what's missing
  Future<void> selectiveSync({
    required String schoolId,
    required String parentId,
    required List<String> dataTypes,
  }) async {
    final isOnline = await _offlineService.isOnline;
    if (!isOnline) return;

    for (final dataType in dataTypes) {
      switch (dataType) {
        case 'children':
          await _syncChildrenData(schoolId, parentId);
          break;
        case 'fees':
          await _syncFeeData(schoolId, parentId);
          break;
        case 'reportCards':
          await _syncReportCards(schoolId, parentId);
          break;
        case 'notifications':
          await _syncNotifications(schoolId, parentId);
          break;
        case 'announcements':
          await _syncAnnouncements(schoolId, parentId);
          break;
        case 'communication':
          await _syncCommunicationData(schoolId, parentId);
          break;
      }
    }
  }

  /// Caches parent-child relationships for offline access
  Future<void> _cacheParentChildRelationships(
      String schoolId, String parentId) async {
    try {
      final children = await _studentService.getStudentsByParentId(
        schoolId: schoolId,
        parentId: parentId,
      );

      final relationships = children
          .map((child) => {
                'childId': child.id,
                'childName': child.fullName,
                'className': child.className,
                'relationship':
                    'parent', // Could be extended for different relationships
              })
          .toList();

      await _localDb.saveData('parent_relationships', '${schoolId}_$parentId', {
        'relationships': relationships,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Error caching parent-child relationships: $e');
    }
  }

  /// Syncs announcements for the parent
  Future<void> _syncAnnouncements(String schoolId, String parentId) async {
    try {
      // Get children IDs for announcement syncing
      final children = await _studentService.getStudentsByParentId(
        schoolId: schoolId,
        parentId: parentId,
      );
      final childrenIds = children.map((child) => child.id).toList();

      // Get announcements for parent (this will cache them)
      await _notificationService.getNotificationsForParent(
        schoolId: schoolId,
        parentId: parentId,
        childrenIds: childrenIds,
      );
    } catch (e) {
      _logger.e('Error syncing announcements: $e');
    }
  }

  /// Updates the last sync time for parent data
  Future<void> _updateLastSyncTime(String schoolId, String parentId) async {
    final lastSyncKey = 'last_parent_sync_${schoolId}_$parentId';
    await _localDb.setMetadata(
        lastSyncKey,
        jsonEncode({
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'parent_data_sync',
        }));
  }
}

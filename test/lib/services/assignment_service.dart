import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class AssignmentService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Get assignments for a specific class with offline support
  Future<List<Map<String, dynamic>>> getClassAssignments({
    required String schoolId,
    required String className,
  }) async {
    final cacheKey = 'assignments_class_${schoolId}_$className';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/schools/$schoolId/classes/$className/assignments');
        return (response as List)
            .map((data) => data as Map<String, dynamic>)
            .toList();
      },
      offlineFallback: () async {
        // Try to get cached assignments
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          return (cached as List)
              .map((data) => data as Map<String, dynamic>)
              .toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Get assignments for a specific student with offline support
  Future<List<Map<String, dynamic>>> getStudentAssignments({
    required String schoolId,
    required String studentId,
  }) async {
    final cacheKey = 'assignments_student_${schoolId}_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/schools/$schoolId/students/$studentId/assignments');
        return (response as List)
            .map((data) => data as Map<String, dynamic>)
            .toList();
      },
      offlineFallback: () async {
        // Try to get cached student assignments
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          return (cached as List)
              .map((data) => data as Map<String, dynamic>)
              .toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Submit assignment with offline queuing
  Future<void> submitAssignment({
    required String schoolId,
    required String assignmentId,
    required String studentId,
    required String submission,
    List<String>? attachments,
  }) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post(
          '/api/schools/$schoolId/assignments/$assignmentId/submit',
          body: {
            'studentId': studentId,
            'submission': submission,
            'attachments': attachments ?? [],
            'submittedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        // If online submission fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'assignment_submissions',
          'schoolId': schoolId,
          'assignmentId': assignmentId,
          'studentId': studentId,
          'submission': submission,
          'attachments': attachments ?? [],
          'submittedAt': DateTime.now().toIso8601String(),
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'assignment_submissions',
        'schoolId': schoolId,
        'assignmentId': assignmentId,
        'studentId': studentId,
        'submission': submission,
        'attachments': attachments ?? [],
        'submittedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get assignment details with offline support
  Future<Map<String, dynamic>?> getAssignment({
    required String schoolId,
    required String assignmentId,
  }) async {
    final cacheKey = 'assignment_${schoolId}_$assignmentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/schools/$schoolId/assignments/$assignmentId');
        return response as Map<String, dynamic>;
      },
      offlineFallback: () async {
        // Try to get cached assignment
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          return cached as Map<String, dynamic>;
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }
}

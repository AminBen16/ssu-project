import 'package:test/models/exam_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class ExamService {
  final ApiClient _apiClient;
  final OfflineService _offlineService;
  final LocalDatabaseService _localDb;

  ExamService({
    ApiClient? apiClient,
    OfflineService? offlineService,
    LocalDatabaseService? localDb,
  })  : _apiClient = apiClient ?? ApiClient(),
        _offlineService = offlineService ?? OfflineService(),
        _localDb = localDb ?? localDatabaseService;

  Future<List<Exam>> getExams(
      {required String schoolId, required String teacherId}) async {
    final cacheKey = 'exams_teacher_${schoolId}_$teacherId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/schools/$schoolId/teachers/$teacherId/exams');
        return (response as List).map((data) => Exam.fromMap(data)).toList();
      },
      offlineFallback: () async {
        // Try to get cached teacher exams
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = cached as List<dynamic>;
          return data
              .map((json) => Exam.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  Future<Exam> saveExam(Exam exam) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        if (exam.id == null) {
          // Create
          final response = await _apiClient.post(
            '/api/schools/${exam.schoolId}/exams',
            body: exam.toMap(),
          );
          return Exam.fromMap(response);
        } else {
          // Update
          final response = await _apiClient.put(
            '/api/schools/${exam.schoolId}/exams/${exam.id}',
            body: exam.toMap(),
          );
          return Exam.fromMap(response);
        }
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService
            .queueForSync(exam.id == null ? 'insert' : 'update', {
          'table': 'exams',
          'schoolId': exam.schoolId,
          ...exam.toMap(),
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService
          .queueForSync(exam.id == null ? 'insert' : 'update', {
        'table': 'exams',
        'schoolId': exam.schoolId,
        ...exam.toMap(),
      });
      // Return the exam as if it was saved (optimistic update)
      return exam;
    }
  }

  Future<void> deleteExam(
      {required String schoolId, required String examId}) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.delete('/api/schools/$schoolId/exams/$examId');
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('delete', {
          'table': 'exams',
          'schoolId': schoolId,
          'examId': examId,
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('delete', {
        'table': 'exams',
        'schoolId': schoolId,
        'examId': examId,
      });
    }
  }

  /// Get exams for a specific class with offline support
  Future<List<Exam>> getClassExams({
    required String schoolId,
    required String className,
  }) async {
    final cacheKey = 'exams_class_${schoolId}_$className';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/schools/$schoolId/classes/$className/exams');
        return (response as List).map((data) => Exam.fromMap(data)).toList();
      },
      offlineFallback: () async {
        // Try to get cached exams
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = cached as List<dynamic>;
          return data
              .map((json) => Exam.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Get exams for a specific student with offline support
  Future<List<Exam>> getStudentExams({
    required String schoolId,
    required String studentId,
  }) async {
    final cacheKey = 'exams_student_${schoolId}_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/schools/$schoolId/students/$studentId/exams');
        return (response as List).map((data) => Exam.fromMap(data)).toList();
      },
      offlineFallback: () async {
        // Try to get cached student exams
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = cached as List<dynamic>;
          return data
              .map((json) => Exam.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Submit exam answers with offline queuing
  Future<void> submitExamAnswers({
    required String schoolId,
    required String examId,
    required String studentId,
    required Map<String, dynamic> answers,
  }) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post(
          '/api/schools/$schoolId/exams/$examId/submit',
          body: {
            'studentId': studentId,
            'answers': answers,
            'submittedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        // If online submission fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'exam_submissions',
          'schoolId': schoolId,
          'examId': examId,
          'studentId': studentId,
          'answers': answers,
          'submittedAt': DateTime.now().toIso8601String(),
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'exam_submissions',
        'schoolId': schoolId,
        'examId': examId,
        'studentId': studentId,
        'answers': answers,
        'submittedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get exam details with offline support
  Future<Exam?> getExam({
    required String schoolId,
    required String examId,
  }) async {
    final cacheKey = 'exam_${schoolId}_$examId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/schools/$schoolId/exams/$examId');
        return Exam.fromMap(response as Map<String, dynamic>);
      },
      offlineFallback: () async {
        // Try to get cached exam
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final Map<String, dynamic> data = cached as Map<String, dynamic>;
          return Exam.fromMap(data);
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }
}

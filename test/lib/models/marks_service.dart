import 'package:test/models/grading_models.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/web_safe_local_database.dart';

class MarksService {
  final ApiClient _apiClient;
  final OfflineService _offlineService;
  final WebSafeLocalDatabaseService _localDb;

  MarksService({
    ApiClient? apiClient,
    OfflineService? offlineService,
    WebSafeLocalDatabaseService? localDb,
  })  : _apiClient = apiClient ?? ApiClient(),
        _offlineService = offlineService ?? OfflineService(),
        _localDb = localDb ?? webSafeLocalDatabaseService;

  /// Saves the raw scores for a student's subject in a specific term and year with offline support.
  Future<void> saveStudentMarks({
    required String studentId,
    required String subjectCode,
    required String term,
    required int year,
    required Map<String, PaperScores> paperScores,
  }) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post('/api/marks', body: {
          'studentId': studentId,
          'subjectCode': subjectCode,
          'term': term,
          'year': year,
          'paperScores':
              paperScores.map((key, value) => MapEntry(key, value.toJson())),
        });
        // Cache the marks locally
        await _localDb
            .saveData('marks', '${studentId}_${subjectCode}_${term}_$year', {
          'studentId': studentId,
          'subjectCode': subjectCode,
          'term': term,
          'year': year,
          'paperScores':
              paperScores.map((key, value) => MapEntry(key, value.toJson())),
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('insert', {
          'table': 'marks',
          'studentId': studentId,
          'subjectCode': subjectCode,
          'term': term,
          'year': year,
          'paperScores':
              paperScores.map((key, value) => MapEntry(key, value.toJson())),
        });
        rethrow;
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('insert', {
        'table': 'marks',
        'studentId': studentId,
        'subjectCode': subjectCode,
        'term': term,
        'year': year,
        'paperScores':
            paperScores.map((key, value) => MapEntry(key, value.toJson())),
      });
      // Cache locally for immediate display
      await _localDb
          .saveData('marks', '${studentId}_${subjectCode}_${term}_$year', {
        'studentId': studentId,
        'subjectCode': subjectCode,
        'term': term,
        'year': year,
        'paperScores':
            paperScores.map((key, value) => MapEntry(key, value.toJson())),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Saves a batch of marks for multiple students in a single API call with offline support.
  Future<void> saveAllMarksForClass(
      List<Map<String, dynamic>> allMarksData) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient
            .post('/api/exams/batch', body: {'marks': allMarksData});
        // Cache the batch marks locally
        for (final marksData in allMarksData) {
          final studentId = marksData['studentId'] as String;
          final subjectCode = marksData['subjectCode'] as String;
          final term = marksData['term'] as String;
          final year = marksData['year'] as int;
          await _localDb
              .saveData('marks', '${studentId}_${subjectCode}_${term}_$year', {
            ...marksData,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('batch_insert', {
          'table': 'marks_batch',
          'marks': allMarksData,
        });
        rethrow;
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('batch_insert', {
        'table': 'marks_batch',
        'marks': allMarksData,
      });
      // Cache locally for immediate display
      for (final marksData in allMarksData) {
        final studentId = marksData['studentId'] as String;
        final subjectCode = marksData['subjectCode'] as String;
        final term = marksData['term'] as String;
        final year = marksData['year'] as int;
        await _localDb
            .saveData('marks', '${studentId}_${subjectCode}_${term}_$year', {
          ...marksData,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  /// Fetches all marks for a given class, subject, term, and year.
  Future<Map<String, Map<String, PaperScores>>> getMarksForClass({
    required String schoolId,
    required String subjectCode,
    required String term,
    required int year,
    required List<String> studentIds,
  }) async {
    final response = await _apiClient.get(
      '/api/marks/class?schoolId=$schoolId&subjectCode=$subjectCode&term=$term&year=$year&studentIds=${studentIds.join(',')}',
    );

    final marksByStudent = <String, Map<String, PaperScores>>{};
    (response as Map<String, dynamic>).forEach((studentId, marksData) {
      final paperScoresMap = <String, PaperScores>{};
      (marksData as Map<String, dynamic>).forEach((paperCode, scores) {
        paperScoresMap[paperCode] = PaperScores.fromMap(scores);
      });
      marksByStudent[studentId] = paperScoresMap;
    });

    return marksByStudent;
  }

  /// Fetches overall grades and GPA for a student with offline support.
  /// WHY this was missing: Student dashboard grades section was using mock data instead of real service calls.
  /// WHAT this enables: Real-time grade display for students with proper offline caching.
  /// WHY this is safe: Non-breaking addition with offline fallback and TODO for backend.
  Future<Map<String, dynamic>> getStudentGrades(int studentId) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        // Implement real backend endpoint /api/marks/student-grades/{studentId}
        // This returns overall grade, GPA, and recent subject grades
        final response =
            await _apiClient.get('/api/marks/student-grades/$studentId');

        // Cache the result
        await _localDb.saveData('student_grades', studentId.toString(), {
          ...response,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return response;
      } catch (e) {
        // Fall back to cached data
        final cached =
            await _localDb.getData('student_grades', studentId.toString());
        if (cached != null) {
          return Map<String, dynamic>.from(cached);
        }
        rethrow;
      }
    } else {
      // Return cached data
      final cached =
          await _localDb.getData('student_grades', studentId.toString());
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      // Return empty data if no cache
      return {
        'overallGrade': 'N/A',
        'gpa': 0.0,
        'recentSubjects': [],
        'lastUpdated': null,
      };
    }
  }
}

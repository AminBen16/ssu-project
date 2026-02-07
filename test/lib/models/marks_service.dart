import 'package:test/models/grading_models.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class MarksService {
  final ApiClient _apiClient;
  final OfflineService _offlineService;
  final LocalDatabaseService _localDb;

  MarksService({
    ApiClient? apiClient,
    OfflineService? offlineService,
    LocalDatabaseService? localDb,
  })  : _apiClient = apiClient ?? ApiClient(),
        _offlineService = offlineService ?? OfflineService(),
        _localDb = localDb ?? localDatabaseService;

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
            .saveData('marks', '${studentId}_${subjectCode}_${term}_${year}', {
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
          .saveData('marks', '${studentId}_${subjectCode}_${term}_${year}', {
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
          await _localDb.saveData(
              'marks', '${studentId}_${subjectCode}_${term}_${year}', {
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
            .saveData('marks', '${studentId}_${subjectCode}_${term}_${year}', {
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
}

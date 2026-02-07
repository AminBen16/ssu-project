import 'package:flutter/foundation.dart';
import 'package:test/models/grading_models.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/staff_service.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

/// A data class to hold all the information needed for a report card.
class ReportCardData {
  final Student student;
  final Map<String, Map<String, PaperScores>>
      marks; // {subjectCode: {paperCode: PaperScores}}

  ReportCardData({required this.student, required this.marks});
}

/// A data class to hold all display data for the report card screen.
class ReportCardDisplayData {
  final ReportCardData reportData;
  final UserProfile? classTeacher;
  final UserProfile? headTeacher;

  ReportCardDisplayData({
    required this.reportData,
    this.classTeacher,
    this.headTeacher,
  });
}

class ReportCardService {
  final StaffService _staffService = StaffService();
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = OfflineService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  /// Fetches the available report terms for a given student from the backend.
  /// Returns a list of maps, each containing a 'term' and 'year'.
  Future<List<Map<String, dynamic>>> getAvailableReportTerms({
    required String schoolId,
    required String studentId,
  }) async {
    try {
      final response = await _apiClient
          .get('/api/students/$studentId/report-terms') as List<dynamic>?;
      final List<dynamic> data = response ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching available report terms: $e');
      rethrow;
    }
  }

  /// Fetches all data required to generate and display a report card.
  Future<ReportCardDisplayData?> getReportCardDisplayData({
    required String schoolId,
    required String studentId,
    required String term,
    required int year,
  }) async {
    // Fetch the core report data (student and marks)
    final reportData = await getReportCardData(
      schoolId: schoolId,
      studentId: studentId,
      term: term,
      year: year,
    );

    if (reportData == null) return null;

    // Fetch the class teacher and head teacher in parallel for efficiency.
    final teacherFutures = await Future.wait([
      _staffService.getClassTeacherForClass(
          schoolId, reportData.student.className),
      _staffService.getHeadTeacher(schoolId),
    ]);

    final classTeacher = teacherFutures[0];
    final headTeacher = teacherFutures[1];

    return ReportCardDisplayData(
      reportData: reportData,
      classTeacher: classTeacher,
      headTeacher: headTeacher,
    );
  }

  /// Fetches all data required to generate a report card for a specific student and term.
  Future<ReportCardData?> getReportCardData({
    required String schoolId,
    required String studentId,
    required String term,
    required int year,
  }) async {
    final cacheKey = 'report_card_${studentId}_${term}_$year';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        try {
          // Fetch both student and report card data from the backend API in parallel.
          final responses = await Future.wait([
            _apiClient.get('/api/students/$studentId'),
            _apiClient.get('/api/students/$studentId/report-cards/$term/$year'),
          ]);

          final studentResponse = responses[0];
          final reportCardResponse = responses[1];

          if (studentResponse == null) return null;

          final student =
              Student.fromMap(studentResponse as Map<String, dynamic>);

          final Map<String, Map<String, PaperScores>> allSubjectMarks = {};
          if (reportCardResponse != null) {
            final reportCardData = reportCardResponse as Map<String, dynamic>;
            if (reportCardData.containsKey('subjects')) {
              final subjects = reportCardData['subjects'] as List<dynamic>;
              for (final subject in subjects) {
                final subjectData = subject as Map<String, dynamic>;
                final paperScoresMap = <String, PaperScores>{};
                // Convert to PaperScores format
                paperScoresMap['main'] = PaperScores(
                  bot: (subjectData['marks'] as num?)?.toDouble() ?? 0.0,
                  mot: 0.0,
                  eot: 0.0,
                  grade: subjectData['grade'] as String? ?? '',
                  remarks: subjectData['remarks'] as String?,
                );
                allSubjectMarks[subjectData['subject'] as String] =
                    paperScoresMap;
              }
            }
          }
          return ReportCardData(student: student, marks: allSubjectMarks);
        } catch (e) {
          debugPrint('Error fetching report card data: $e');
          rethrow;
        }
      },
      offlineFallback: () async {
        // Try to get cached report card data
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final Map<String, dynamic> data = cached as Map<String, dynamic>;
          final student =
              Student.fromMap(data['student'] as Map<String, dynamic>);
          final Map<String, Map<String, PaperScores>> marks = {};

          if (data.containsKey('marks')) {
            final marksData = data['marks'] as Map<String, dynamic>;
            marksData.forEach((subject, subjectMarks) {
              final subjectMarksMap = subjectMarks as Map<String, dynamic>;
              final paperScoresMap = <String, PaperScores>{};
              subjectMarksMap.forEach((paper, scores) {
                final scoresData = scores as Map<String, dynamic>;
                paperScoresMap[paper] = PaperScores(
                  bot: (scoresData['bot'] as num?)?.toDouble() ?? 0.0,
                  mot: (scoresData['mot'] as num?)?.toDouble() ?? 0.0,
                  eot: (scoresData['eot'] as num?)?.toDouble() ?? 0.0,
                  grade: scoresData['grade'] as String? ?? '',
                  remarks: scoresData['remarks'] as String?,
                );
              });
              marks[subject] = paperScoresMap;
            });
          }

          return ReportCardData(student: student, marks: marks);
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }

  /// Creates a new report card
  Future<void> createReportCard(
      String schoolId, Map<String, dynamic> reportCardData) async {
    await _apiClient.post('/api/schools/$schoolId/report-cards',
        body: reportCardData);
  }

  /// Gets all report cards for a student
  Future<List<Map<String, dynamic>>> getStudentReportCards(
      String studentId) async {
    final response =
        await _apiClient.get('/api/students/$studentId/report-cards');
    return (response['report_cards'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
}

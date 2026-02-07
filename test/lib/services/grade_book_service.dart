import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class GradeBookService {
  final ApiClient _apiClient;
  final OfflineService _offlineService;
  final LocalDatabaseService _localDb;

  GradeBookService({
    ApiClient? apiClient,
    OfflineService? offlineService,
    LocalDatabaseService? localDb,
  })  : _apiClient = apiClient ?? ApiClient(),
        _offlineService = offlineService ?? OfflineService(),
        _localDb = localDb ?? localDatabaseService;

  /// Saves a grade book entry for a student with offline support
  Future<void> saveGradeBookEntry({
    required String schoolId,
    required String studentId,
    required String subject,
    required String className,
    required String term,
    required int year,
    required String assessmentType,
    required String assessmentName,
    double? score,
    required double maxScore,
    double weight = 1.0,
    required String date,
    required String teacherId,
    String? notes,
  }) async {
    final gradeBookEntry = {
      'school_id': schoolId,
      'student_id': studentId,
      'subject': subject,
      'class_name': className,
      'term': term,
      'year': year,
      'assessment_type': assessmentType,
      'assessment_name': assessmentName,
      'score': score,
      'max_score': maxScore,
      'weight': weight,
      'date': date,
      'teacher_id': teacherId,
      'notes': notes,
    };

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post('/api/gradebook', body: gradeBookEntry);
        // Cache locally for immediate display
        await _localDb.saveData(
            'gradebook',
            '${studentId}_${subject}_${assessmentName}_$date',
            gradeBookEntry);
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('insert', {
          'table': 'grade_book_entries',
          ...gradeBookEntry,
        });
        rethrow;
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('insert', {
        'table': 'grade_book_entries',
        ...gradeBookEntry,
      });
      // Cache locally for immediate display
      await _localDb.saveData('gradebook',
          '${studentId}_${subject}_${assessmentName}_$date', gradeBookEntry);
    }
  }

  /// Saves multiple grade book entries in batch with offline support
  Future<void> saveBatchGradeBookEntries({
    required String schoolId,
    required List<Map<String, dynamic>> gradeBookEntries,
  }) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient
            .post('/api/gradebook/batch', body: {'entries': gradeBookEntries});
        // Cache locally for immediate display
        for (final entry in gradeBookEntries) {
          final studentId = entry['student_id'];
          final subject = entry['subject'];
          final assessmentName = entry['assessment_name'];
          final date = entry['date'];
          await _localDb.saveData('gradebook',
              '${studentId}_${subject}_${assessmentName}_$date', entry);
        }
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('batch_insert', {
          'table': 'grade_book_entries',
          'entries': gradeBookEntries,
        });
        rethrow;
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('batch_insert', {
        'table': 'grade_book_entries',
        'entries': gradeBookEntries,
      });
      // Cache locally for immediate display
      for (final entry in gradeBookEntries) {
        final studentId = entry['student_id'];
        final subject = entry['subject'];
        final assessmentName = entry['assessment_name'];
        final date = entry['date'];
        await _localDb.saveData('gradebook',
            '${studentId}_${subject}_${assessmentName}_$date', entry);
      }
    }
  }

  /// Fetches grade book entries with offline fallback
  Future<List<Map<String, dynamic>>> getGradeBookEntries({
    required String schoolId,
    String? studentId,
    String? subject,
    String? className,
    String? term,
    int? year,
    String? assessmentType,
    String? teacherId,
  }) async {
    final cacheKey =
        'gradebook_${schoolId}_${studentId ?? 'all'}_${subject ?? 'all'}_${className ?? 'all'}_${term ?? 'all'}_${year ?? 'all'}';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final queryParams = <String, String>{};
        if (studentId != null) {
          queryParams['student_id'] = studentId;
        }
        if (subject != null) {
          queryParams['subject'] = subject;
        }
        if (className != null) {
          queryParams['class_name'] = className;
        }
        if (term != null) {
          queryParams['term'] = term;
        }
        if (year != null) {
          queryParams['year'] = year.toString();
        }
        if (assessmentType != null) {
          queryParams['assessment_type'] = assessmentType;
        }
        if (teacherId != null) {
          queryParams['teacher_id'] = teacherId;
        }

        final queryString = queryParams.isNotEmpty
            ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
            : '';

        return await _apiClient.get('/api/gradebook$queryString');
      },
      offlineFallback: () async {
        // Return cached data from local database
        final cached = await _localDb.getAllData('gradebook');
        return cached.where((entry) {
          if (studentId != null && entry['student_id'] != studentId) {
            return false;
          }
          if (subject != null && entry['subject'] != subject) {
            return false;
          }
          if (className != null && entry['class_name'] != className) {
            return false;
          }
          if (term != null && entry['term'] != term) {
            return false;
          }
          if (year != null && entry['year'] != year) {
            return false;
          }
          if (assessmentType != null &&
              entry['assessment_type'] != assessmentType) {
            return false;
          }
          if (teacherId != null && entry['teacher_id'] != teacherId) {
            return false;
          }
          return true;
        }).toList();
      },
      cacheKey: cacheKey,
    );
  }

  /// Gets grade book summary for a student in a specific subject and term
  Future<Map<String, dynamic>> getStudentGradeBookSummary({
    required String schoolId,
    required String studentId,
    required String subject,
    required String term,
    required int year,
  }) async {
    final cacheKey =
        'gradebook_summary_${schoolId}_${studentId}_${subject}_${term}_$year';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        return await _apiClient.get(
            '/api/gradebook/summary/$studentId/$subject?school_id=$schoolId&term=$term&year=$year');
      },
      offlineFallback: () async {
        // Calculate summary from cached grade book entries
        final allEntries = await _localDb.getAllData('gradebook');
        final studentEntries = allEntries
            .where((entry) =>
                entry['student_id'] == studentId &&
                entry['subject'] == subject &&
                entry['term'] == term &&
                entry['year'] == year &&
                entry['school_id'] == schoolId)
            .toList();

        if (studentEntries.isEmpty) {
          return {
            'subject': subject,
            'term': term,
            'year': year,
            'assessment_breakdown': [],
            'overall_average': 0.0,
            'weighted_average': 0.0,
            'total_assessments': 0,
          };
        }

        // Group by assessment type
        final assessmentBreakdown = <Map<String, dynamic>>[];
        final assessmentTypes = <String>{};
        for (final entry in studentEntries) {
          assessmentTypes.add(entry['assessment_type']);
        }

        for (final type in assessmentTypes) {
          final typeEntries = studentEntries
              .where((e) => e['assessment_type'] == type)
              .toList();
          final averagePercentage = typeEntries.map((e) {
                final score = e['score'] as double?;
                final maxScore = e['max_score'] as double;
                return score != null ? (score / maxScore) * 100 : 0.0;
              }).reduce((a, b) => a + b) /
              typeEntries.length;

          assessmentBreakdown.add({
            'assessment_type': type,
            'average_percentage': averagePercentage,
            'count': typeEntries.length,
          });
        }

        // Calculate overall averages
        double totalWeightedScore = 0.0;
        double totalWeight = 0.0;
        double totalSimpleScore = 0.0;
        int totalAssessments = 0;

        for (final entry in studentEntries) {
          final score = entry['score'] as double?;
          final maxScore = entry['max_score'] as double;
          final weight = entry['weight'] as double? ?? 1.0;

          if (score != null) {
            final percentage = (score / maxScore) * 100;
            totalSimpleScore += percentage;
            totalWeightedScore += percentage * weight;
            totalWeight += weight;
            totalAssessments++;
          }
        }

        final overallAverage =
            totalAssessments > 0 ? totalSimpleScore / totalAssessments : 0.0;
        final weightedAverage =
            totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0;

        return {
          'subject': subject,
          'term': term,
          'year': year,
          'assessment_breakdown': assessmentBreakdown,
          'overall_average': overallAverage,
          'weighted_average': weightedAverage,
          'total_assessments': totalAssessments,
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Gets class grade book overview for a subject
  Future<Map<String, dynamic>> getClassGradeBookOverview({
    required String schoolId,
    required String subject,
    required String className,
    required String term,
    required int year,
  }) async {
    final entries = await getGradeBookEntries(
      schoolId: schoolId,
      subject: subject,
      className: className,
      term: term,
      year: year,
    );

    // Group by student
    final studentSummaries = <String, Map<String, dynamic>>{};
    for (final entry in entries) {
      final studentId = entry['student_id'];
      if (!studentSummaries.containsKey(studentId)) {
        studentSummaries[studentId] = {
          'student_id': studentId,
          'student_name': entry['student_name'] ?? 'Unknown Student',
          'entries': <Map<String, dynamic>>[],
          'total_score': 0.0,
          'total_max_score': 0.0,
          'total_weight': 0.0,
        };
      }

      final studentData = studentSummaries[studentId]!;
      studentData['entries'].add(entry);

      final score = entry['score'] as double?;
      final maxScore = entry['max_score'] as double;
      final weight = entry['weight'] as double? ?? 1.0;

      if (score != null) {
        studentData['total_score'] =
            (studentData['total_score'] as double) + (score * weight);
        studentData['total_max_score'] =
            (studentData['total_max_score'] as double) + (maxScore * weight);
        studentData['total_weight'] =
            (studentData['total_weight'] as double) + weight;
      }
    }

    // Calculate averages for each student
    final studentList = studentSummaries.values.map((student) {
      final totalScore = student['total_score'] as double;
      final totalMaxScore = student['total_max_score'] as double;
      final totalWeight = student['total_weight'] as double;

      final average =
          totalMaxScore > 0 ? (totalScore / totalMaxScore) * 100 : 0.0;
      final weightedAverage = totalWeight > 0 ? totalScore / totalWeight : 0.0;

      return {
        ...student,
        'average_percentage': average,
        'weighted_average': weightedAverage,
        'total_assessments': (student['entries'] as List).length,
      };
    }).toList();

    // Sort by average descending
    studentList.sort((a, b) => (b['average_percentage'] as double)
        .compareTo(a['average_percentage'] as double));

    return {
      'subject': subject,
      'class_name': className,
      'term': term,
      'year': year,
      'total_students': studentList.length,
      'student_summaries': studentList,
    };
  }
}

// Singleton instance
final gradeBookService = GradeBookService();

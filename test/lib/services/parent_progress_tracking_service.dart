import 'package:logger/logger.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

/// Model for child academic progress data
class ChildProgressData {
  final String studentId;
  final String studentName;
  final String className;
  final double overallGrade;
  final double attendanceRate;
  final int completedAssignments;
  final int totalAssignments;
  final List<SubjectProgress> subjectProgress;
  final List<GradeHistory> gradeHistory;
  final DateTime lastUpdated;

  ChildProgressData({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.overallGrade,
    required this.attendanceRate,
    required this.completedAssignments,
    required this.totalAssignments,
    required this.subjectProgress,
    required this.gradeHistory,
    required this.lastUpdated,
  });

  factory ChildProgressData.fromMap(Map<String, dynamic> map) {
    return ChildProgressData(
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      className: map['className'] as String,
      overallGrade: (map['overallGrade'] as num).toDouble(),
      attendanceRate: (map['attendanceRate'] as num).toDouble(),
      completedAssignments: map['completedAssignments'] as int,
      totalAssignments: map['totalAssignments'] as int,
      subjectProgress: (map['subjectProgress'] as List<dynamic>?)
              ?.map((e) => SubjectProgress.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      gradeHistory: (map['gradeHistory'] as List<dynamic>?)
              ?.map((e) => GradeHistory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'overallGrade': overallGrade,
      'attendanceRate': attendanceRate,
      'completedAssignments': completedAssignments,
      'totalAssignments': totalAssignments,
      'subjectProgress': subjectProgress.map((e) => e.toMap()).toList(),
      'gradeHistory': gradeHistory.map((e) => e.toMap()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Model for subject-specific progress
class SubjectProgress {
  final String subjectName;
  final String subjectCode;
  final double currentGrade;
  final double classAverage;
  final String gradeTrend; // 'improving', 'declining', 'stable'
  final int assignmentsCompleted;
  final int assignmentsTotal;
  final String teacherName;
  final List<RecentAssessment> recentAssessments;

  SubjectProgress({
    required this.subjectName,
    required this.subjectCode,
    required this.currentGrade,
    required this.classAverage,
    required this.gradeTrend,
    required this.assignmentsCompleted,
    required this.assignmentsTotal,
    required this.teacherName,
    required this.recentAssessments,
  });

  factory SubjectProgress.fromMap(Map<String, dynamic> map) {
    return SubjectProgress(
      subjectName: map['subjectName'] as String,
      subjectCode: map['subjectCode'] as String,
      currentGrade: (map['currentGrade'] as num).toDouble(),
      classAverage: (map['classAverage'] as num).toDouble(),
      gradeTrend: map['gradeTrend'] as String,
      assignmentsCompleted: map['assignmentsCompleted'] as int,
      assignmentsTotal: map['assignmentsTotal'] as int,
      teacherName: map['teacherName'] as String,
      recentAssessments: (map['recentAssessments'] as List<dynamic>?)
              ?.map((e) => RecentAssessment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'currentGrade': currentGrade,
      'classAverage': classAverage,
      'gradeTrend': gradeTrend,
      'assignmentsCompleted': assignmentsCompleted,
      'assignmentsTotal': assignmentsTotal,
      'teacherName': teacherName,
      'recentAssessments': recentAssessments.map((e) => e.toMap()).toList(),
    };
  }
}

/// Model for recent assessments
class RecentAssessment {
  final String assessmentName;
  final String assessmentType; // 'quiz', 'test', 'exam', 'assignment'
  final double score;
  final double maxScore;
  final DateTime date;
  final String feedback;

  RecentAssessment({
    required this.assessmentName,
    required this.assessmentType,
    required this.score,
    required this.maxScore,
    required this.date,
    required this.feedback,
  });

  factory RecentAssessment.fromMap(Map<String, dynamic> map) {
    return RecentAssessment(
      assessmentName: map['assessmentName'] as String,
      assessmentType: map['assessmentType'] as String,
      score: (map['score'] as num).toDouble(),
      maxScore: (map['maxScore'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      feedback: map['feedback'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assessmentName': assessmentName,
      'assessmentType': assessmentType,
      'score': score,
      'maxScore': maxScore,
      'date': date.toIso8601String(),
      'feedback': feedback,
    };
  }
}

/// Model for grade history
class GradeHistory {
  final String term;
  final int year;
  final double overallGrade;
  final Map<String, double> subjectGrades;
  final String academicStanding;

  GradeHistory({
    required this.term,
    required this.year,
    required this.overallGrade,
    required this.subjectGrades,
    required this.academicStanding,
  });

  factory GradeHistory.fromMap(Map<String, dynamic> map) {
    return GradeHistory(
      term: map['term'] as String,
      year: map['year'] as int,
      overallGrade: (map['overallGrade'] as num).toDouble(),
      subjectGrades: Map<String, double>.from(
        (map['subjectGrades'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      academicStanding: map['academicStanding'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'term': term,
      'year': year,
      'overallGrade': overallGrade,
      'subjectGrades': subjectGrades,
      'academicStanding': academicStanding,
    };
  }
}

/// Service for tracking child academic progress with offline support
class ParentProgressTrackingService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;
  final Logger _logger = Logger();

  /// Get comprehensive progress data for a specific child
  Future<ChildProgressData> getChildProgress({
    required String schoolId,
    required String parentId,
    required String studentId,
  }) async {
    final cacheKey = 'child_progress_${schoolId}_${parentId}_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/students/$studentId/progress',
        );
        final progressData =
            ChildProgressData.fromMap(response as Map<String, dynamic>);

        // Cache the progress data locally
        await _localDb.saveData(
            'child_progress', studentId, progressData.toMap());

        return progressData;
      },
      offlineFallback: () async {
        // Try to get cached progress data
        final cached = await _localDb.getData('child_progress', studentId);
        if (cached != null) {
          return ChildProgressData.fromMap(cached);
        }
        throw Exception(
            'No cached progress data available for student $studentId');
      },
      cacheKey: cacheKey,
    );
  }

  /// Get progress data for all children of a parent
  Future<List<ChildProgressData>> getAllChildrenProgress({
    required String schoolId,
    required String parentId,
  }) async {
    final cacheKey = 'all_children_progress_${schoolId}_$parentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/children/progress',
        );
        final List<dynamic> data = response as List<dynamic>;
        final progressList = data
            .map((item) =>
                ChildProgressData.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache all children progress data
        for (final progress in progressList) {
          await _localDb.saveData(
              'child_progress', progress.studentId, progress.toMap());
        }

        return progressList;
      },
      offlineFallback: () async {
        // Get all cached children progress data
        final allCached = await _localDb.getAllData('child_progress');
        return allCached
            .map((item) => ChildProgressData.fromMap(item))
            .where((progress) =>
                progress.toMap().containsKey('parentId') &&
                progress.toMap()['parentId'] == parentId)
            .toList();
      },
      cacheKey: cacheKey,
    );
  }

  /// Get detailed subject progress for a specific subject
  Future<SubjectProgress> getSubjectProgress({
    required String schoolId,
    required String studentId,
    required String subjectCode,
  }) async {
    final cacheKey = 'subject_progress_${schoolId}_${studentId}_$subjectCode';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/students/$studentId/subjects/$subjectCode/progress',
        );
        final subjectProgress =
            SubjectProgress.fromMap(response as Map<String, dynamic>);

        // Cache subject progress
        await _localDb.saveData(
            'subject_progress', '${studentId}_$subjectCode', subjectProgress.toMap());

        return subjectProgress;
      },
      offlineFallback: () async {
        // Try to get cached subject progress
        final cached = await _localDb.getData(
            'subject_progress', '${studentId}_$subjectCode');
        if (cached != null) {
          return SubjectProgress.fromMap(cached);
        }
        throw Exception(
            'No cached progress data available for subject $subjectCode');
      },
      cacheKey: cacheKey,
    );
  }

  /// Get attendance summary for a child
  Future<Map<String, dynamic>> getAttendanceSummary({
    required String schoolId,
    required String studentId,
    String? period, // 'week', 'month', 'term', 'year'
  }) async {
    final periodParam = period ?? 'month';
    final cacheKey = 'attendance_summary_${schoolId}_${studentId}_$periodParam';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/students/$studentId/attendance/summary?period=$periodParam',
        );
        final summary = response as Map<String, dynamic>;

        // Cache attendance summary
        await _localDb
            .saveData('attendance_summary', '${studentId}_$periodParam', {
          ...summary,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return summary;
      },
      offlineFallback: () async {
        // Try to get cached attendance summary
        final cached = await _localDb.getData(
            'attendance_summary', '${studentId}_$periodParam');
        if (cached != null) {
          return Map<String, dynamic>.from(cached)..remove('lastUpdated');
        }
        return {
          'totalDays': 0,
          'presentDays': 0,
          'absentDays': 0,
          'lateDays': 0,
          'attendanceRate': 0.0,
          'recentAttendance': [],
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Get assignment completion status for a child
  Future<Map<String, dynamic>> getAssignmentStatus({
    required String schoolId,
    required String studentId,
    String? subjectCode,
  }) async {
    final subjectParam = subjectCode != null ? '?subject=$subjectCode' : '';
    final cacheKey =
        'assignment_status_${schoolId}_${studentId}_${subjectCode ?? 'all'}';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/students/$studentId/assignments/status$subjectParam',
        );
        final status = response as Map<String, dynamic>;

        // Cache assignment status
        await _localDb.saveData(
            'assignment_status', '${studentId}_${subjectCode ?? 'all'}', {
          ...status,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return status;
      },
      offlineFallback: () async {
        // Try to get cached assignment status
        final cached = await _localDb.getData(
            'assignment_status', '${studentId}_${subjectCode ?? 'all'}');
        if (cached != null) {
          return Map<String, dynamic>.from(cached)..remove('lastUpdated');
        }
        return {
          'totalAssignments': 0,
          'completedAssignments': 0,
          'pendingAssignments': 0,
          'overdueAssignments': 0,
          'completionRate': 0.0,
          'upcomingDeadlines': [],
          'recentSubmissions': [],
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Get performance analytics and trends
  Future<Map<String, dynamic>> getPerformanceAnalytics({
    required String schoolId,
    required String studentId,
    String period = '6months', // '3months', '6months', '1year', '2years'
  }) async {
    final cacheKey = 'performance_analytics_${schoolId}_${studentId}_$period';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/students/$studentId/analytics/performance?period=$period',
        );
        final analytics = response as Map<String, dynamic>;

        // Cache performance analytics
        await _localDb
            .saveData('performance_analytics', '${studentId}_$period', {
          ...analytics,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return analytics;
      },
      offlineFallback: () async {
        // Try to get cached performance analytics
        final cached = await _localDb.getData(
            'performance_analytics', '${studentId}_$period');
        if (cached != null) {
          return Map<String, dynamic>.from(cached)..remove('lastUpdated');
        }
        return {
          'gradeTrend': 'stable',
          'improvementAreas': [],
          'strengthAreas': [],
          'predictedGrade': null,
          'attendanceCorrelation': 0.0,
          'studyTimeCorrelation': 0.0,
          'recommendations': [],
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Get teacher feedback and comments
  Future<List<Map<String, dynamic>>> getTeacherFeedback({
    required String schoolId,
    required String studentId,
    String? subjectCode,
    int limit = 10,
  }) async {
    final subjectParam = subjectCode != null ? '&subject=$subjectCode' : '';
    final cacheKey =
        'teacher_feedback_${schoolId}_${studentId}_${subjectCode ?? 'all'}_$limit';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/students/$studentId/feedback?limit=$limit$subjectParam',
        );
        final List<dynamic> feedback = response as List<dynamic>;
        final feedbackList = feedback.cast<Map<String, dynamic>>();

        // Cache teacher feedback
        await _localDb.saveData(
            'teacher_feedback', '${studentId}_${subjectCode ?? 'all'}', {
          'feedback': feedbackList,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return feedbackList;
      },
      offlineFallback: () async {
        // Try to get cached teacher feedback
        final cached = await _localDb.getData(
            'teacher_feedback', '${studentId}_${subjectCode ?? 'all'}');
        if (cached != null && cached['feedback'] != null) {
          return List<Map<String, dynamic>>.from(cached['feedback']);
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Get progress comparison with class averages
  Future<Map<String, dynamic>> getClassComparison({
    required String schoolId,
    required String studentId,
    required String className,
  }) async {
    final cacheKey = 'class_comparison_${schoolId}_${studentId}_$className';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/classes/$className/students/$studentId/comparison',
        );
        final comparison = response as Map<String, dynamic>;

        // Cache class comparison
        await _localDb
            .saveData('class_comparison', '${studentId}_$className', {
          ...comparison,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return comparison;
      },
      offlineFallback: () async {
        // Try to get cached class comparison
        final cached = await _localDb.getData(
            'class_comparison', '${studentId}_$className');
        if (cached != null) {
          return Map<String, dynamic>.from(cached)..remove('lastUpdated');
        }
        return {
          'studentRank': null,
          'classSize': 0,
          'percentileRank': 0.0,
          'aboveAverageSubjects': [],
          'belowAverageSubjects': [],
          'classAverageGrade': 0.0,
          'studentGrade': 0.0,
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Refresh progress data for a specific child
  Future<void> refreshChildProgress({
    required String schoolId,
    required String parentId,
    required String studentId,
  }) async {
    final isOnline = await _offlineService.isOnline;
    if (!isOnline) return;

    try {
      await getChildProgress(
        schoolId: schoolId,
        parentId: parentId,
        studentId: studentId,
      );
    } catch (e) {
      _logger.e('Error refreshing child progress: $e');
    }
  }

  /// Clear cached progress data for a parent
  Future<void> clearParentProgressCache(String parentId) async {
    // This would need to be implemented to clear all child progress data for a parent
    // For now, we'll clear all progress-related caches
    await _localDb.clearCache();
  }

  /// Get progress summary for dashboard display
  Future<Map<String, dynamic>> getProgressSummary({
    required String schoolId,
    required String parentId,
  }) async {
    final childrenProgress = await getAllChildrenProgress(
      schoolId: schoolId,
      parentId: parentId,
    );

    final summary = <String, dynamic>{
      'totalChildren': childrenProgress.length,
      'averageGrade': 0.0,
      'averageAttendance': 0.0,
      'totalAssignments': 0,
      'completedAssignments': 0,
      'childrenNeedingAttention': <String>[],
      'topPerformers': <String>[],
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    if (childrenProgress.isNotEmpty) {
      double totalGrade = 0.0;
      double totalAttendance = 0.0;
      int totalAssignments = 0;
      int completedAssignments = 0;

      for (final child in childrenProgress) {
        totalGrade += child.overallGrade;
        totalAttendance += child.attendanceRate;
        totalAssignments += child.totalAssignments;
        completedAssignments += child.completedAssignments;

        // Identify children needing attention (grade < 60% or attendance < 80%)
        if (child.overallGrade < 60.0 || child.attendanceRate < 80.0) {
          summary['childrenNeedingAttention'].add(child.studentName);
        }

        // Identify top performers (grade >= 85%)
        if (child.overallGrade >= 85.0) {
          summary['topPerformers'].add(child.studentName);
        }
      }

      summary['averageGrade'] = totalGrade / childrenProgress.length;
      summary['averageAttendance'] = totalAttendance / childrenProgress.length;
      summary['totalAssignments'] = totalAssignments;
      summary['completedAssignments'] = completedAssignments;
    }

    return summary;
  }
}

// Singleton instance
final parentProgressTrackingService = ParentProgressTrackingService();

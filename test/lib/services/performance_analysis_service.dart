import 'package:test/models/student_model.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/grading_service.dart';
import 'package:test/services/report_card_service.dart';
import 'package:test/services/student_service.dart';

class ClassPerformanceAnalysis {
  final int studentCount;
  final Map<String, double> averageSubjectScores; // {subjectName: averageScore}
  final List<Student> topPerformers; // Top 3 students
  final List<Student> underperformers; // Students needing support

  ClassPerformanceAnalysis({
    required this.studentCount,
    required this.averageSubjectScores,
    required this.topPerformers,
    required this.underperformers,
  });
}

class PerformanceAnalysisService {
  final _studentService = StudentService();
  final _reportCardService = ReportCardService();
  final _gradingService = GradingService();

  Future<ClassPerformanceAnalysis> analyzeClassPerformance({
    required String schoolId,
    required String className,
    required String term,
    required int year,
  }) async {
    final List<Student> students = await _studentService.getStudentsByClass(
      schoolId: schoolId,
      className: className,
    );

    if (students.isEmpty) {
      return ClassPerformanceAnalysis(
        studentCount: 0,
        averageSubjectScores: {},
        topPerformers: [],
        underperformers: [],
      );
    }

    final Map<String, List<double>> subjectScores = {};
    final Map<String, double> studentOverallScores = {};

    for (final student in students) {
      final reportData = await _reportCardService.getReportCardData(
        schoolId: schoolId,
        studentId: student.id,
        term: term,
        year: year,
      );

      if (reportData != null && reportData.marks.isNotEmpty) {
        double totalStudentScore = 0;
        int subjectCount = 0;

        reportData.marks.forEach((subjectCode, paperScores) {
          final subject = findSubjectByCode(subjectCode);
          if (subject == null) return;

          if (subject.level == SchoolLevel.oLevel) {
            final calculatedGrade = _gradingService.calculateOLevelGrade(
              paperScores,
            );
            final ags = calculatedGrade.averagedGradingScore;

            if (ags != null) {
              subjectScores.putIfAbsent(subject.name, () => []).add(ags);
              totalStudentScore += ags;
              subjectCount++;
            }
          } else {
            // A-Level analysis
            final isSubsidiary = subject.code.startsWith('S');
            final calculatedGrade = _gradingService.calculateALevelGrade(
              paperScores: paperScores,
              isSubsidiary: isSubsidiary,
            );
            final points = calculatedGrade.points;
            if (points != null) {
              // Normalize points to a 0-100 scale for averaging
              final normalizedScore = (points / 6.0) * 100.0;
              subjectScores
                  .putIfAbsent(subject.name, () => [])
                  .add(normalizedScore);
              totalStudentScore += normalizedScore;
              subjectCount++;
            }
          }
        });

        if (subjectCount > 0) {
          studentOverallScores[student.id] = totalStudentScore / subjectCount;
        }
      }
    }

    // Calculate average scores per subject
    final Map<String, double> averageSubjectScores = {};
    subjectScores.forEach((subjectName, scores) {
      if (scores.isNotEmpty) {
        averageSubjectScores[subjectName] =
            scores.reduce((a, b) => a + b) / scores.length;
      }
    });

    // Sort students by their overall scores
    final sortedStudentIds = studentOverallScores.keys.toList()
      ..sort(
        (a, b) => studentOverallScores[b]!.compareTo(studentOverallScores[a]!),
      );

    // Identify top performers and underperformers
    final topPerformers = sortedStudentIds
        .take(3)
        .map((id) => students.firstWhere((s) => s.id == id))
        .toList();
    final underperformers = sortedStudentIds
        .where((id) => studentOverallScores[id]! < 50)
        .map((id) => students.firstWhere((s) => s.id == id))
        .toList();

    return ClassPerformanceAnalysis(
      studentCount: students.length,
      averageSubjectScores: averageSubjectScores,
      topPerformers: topPerformers,
      underperformers: underperformers,
    );
  }
}

import 'package:test/models/grading_models.dart';
import 'package:test/services/gemini_service.dart';

class CommentGeneratorService {
  final _geminiService = GeminiService();

  /// Generates a class teacher's comment based on overall performance.
  Future<String> generateClassTeacherComment(
    List<CalculatedSubjectGrade> subjectGrades,
  ) async {
    if (subjectGrades.isEmpty) {
      return 'No grades available to generate a comment.';
    }
    return await generateCommentAsync(subjectGrades, isHeadTeacher: false);
  }

  /// Generates a head teacher's comment based on overall performance.
  Future<String> generateHeadTeacherComment(
    List<CalculatedSubjectGrade> subjectGrades,
  ) async {
    if (subjectGrades.isEmpty) {
      return 'Awaiting full term results for comment.';
    }
    return await generateCommentAsync(subjectGrades, isHeadTeacher: true);
  }

  /// Generates a comment asynchronously using the Gemini service.
  /// Note: The UI (`report_card_screen.dart`) would need to be updated to handle a `Future<String>`.
  /// For now, this demonstrates the connection to the live AI.
  Future<String> generateCommentAsync(
      List<CalculatedSubjectGrade> subjectGrades,
      {required bool isHeadTeacher}) async {
    final averagePerformance = _calculateOverallPerformance(subjectGrades);
    if (averagePerformance == null) {
      return "Awaiting results.";
    }

    final role = isHeadTeacher ? "Head Teacher" : "Class Teacher";
    final performanceSummary = subjectGrades
        .map((g) =>
            "Grade ${g.grade} (${g.descriptor}) with score ${g.averagedGradingScore?.toStringAsFixed(1) ?? g.points}")
        .join(', ');

    final prompt = """
    You are a helpful $role writing a report card comment for a student.
    The student's overall performance score is ${averagePerformance.toStringAsFixed(1)} out of 100.
    Their subject grades are: $performanceSummary.
    Write a concise, encouraging, and professional comment (1-2 sentences).
    Do not use the student's name.
    """;

    final comment = await _geminiService.generateText(prompt);
    return comment ?? "A satisfactory performance this term.";
  }

  /// Helper method to calculate a single performance score (0-100) from all grades.
  double? _calculateOverallPerformance(
    List<CalculatedSubjectGrade> subjectGrades,
  ) {
    double totalScore = 0;
    int gradedSubjects = 0;

    for (var grade in subjectGrades) {
      if (grade.averagedGradingScore != null) {
        // O-Level
        totalScore += grade.averagedGradingScore!;
        gradedSubjects++;
      } else if (grade.points != null) {
        // A-Level
        // Convert points (0-6) to a 0-100 scale for averaging
        totalScore += (grade.points! / 6.0) * 100.0;
        gradedSubjects++;
      }
    }

    if (gradedSubjects == 0) {
      return null;
    }

    return totalScore / gradedSubjects;
  }
}

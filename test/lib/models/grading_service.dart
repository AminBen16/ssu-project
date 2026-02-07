import 'package:test/models/grading_models.dart';

/// A service class to handle all grading calculations based on the school's rules.
class GradingService {
  /// Calculates the final grade for an O-Level subject.
  CalculatedSubjectGrade calculateOLevelGrade(
    Map<String, PaperScores> paperScores,
  ) {
    if (paperScores.isEmpty) {
      return CalculatedSubjectGrade(
        paperGrades: {},
        grade: '-',
        descriptor: 'No marks',
      );
    }

    final calculatedPapers = <String, CalculatedPaperGrade>{};
    double totalGradingScore = 0;

    paperScores.forEach((paperCode, scores) {
      final paperGrade = _calculatePaperGrade(scores);
      calculatedPapers[paperCode] = paperGrade;
      totalGradingScore += paperGrade.gradingScore;
    });

    final averagedGradingScore = totalGradingScore / paperScores.length;

    final String grade;
    final String descriptor;

    if (averagedGradingScore >= 85) {
      grade = 'A';
      descriptor = 'Exceptional';
    } else if (averagedGradingScore >= 75) {
      grade = 'B';
      descriptor = 'Outstanding';
    } else if (averagedGradingScore >= 65) {
      grade = 'C';
      descriptor = 'Satisfactory';
    } else if (averagedGradingScore >= 55) {
      grade = 'D';
      descriptor = 'Basic';
    } else {
      grade = 'E';
      descriptor = 'Elementary';
    }

    return CalculatedSubjectGrade(
      paperGrades: calculatedPapers,
      averagedGradingScore: averagedGradingScore,
      grade: grade,
      descriptor: descriptor,
    );
  }

  /// Calculates the final grade for an A-Level subject.
  CalculatedSubjectGrade calculateALevelGrade({
    required Map<String, PaperScores> paperScores,
    required bool isSubsidiary,
  }) {
    if (paperScores.isEmpty) {
      return CalculatedSubjectGrade(
        paperGrades: {},
        grade: 'F',
        descriptor: 'Fail',
        points: 0,
      );
    }

    final calculatedPapers = <String, CalculatedPaperGrade>{};
    int aggregate = 0;

    paperScores.forEach((paperCode, scores) {
      final paperGrade = _calculatePaperGrade(scores);
      calculatedPapers[paperCode] = paperGrade;
      aggregate += paperGrade.scaledScoreValue;
    });

    if (isSubsidiary) {
      // Subsidiary subjects (like General Paper) have a simple Pass/Fail outcome.
      final paperGradeValue = calculatedPapers.values.first.scaledScoreValue;
      if (paperGradeValue <= 6) {
        // D1 to C6 results in a Subsidiary Pass 'O'
        return CalculatedSubjectGrade(
          paperGrades: calculatedPapers,
          grade: 'O',
          descriptor: 'Subsidiary Pass',
          points: 1,
        );
      } else {
        // P7 to F9 results in a Fail 'F'
        return CalculatedSubjectGrade(
          paperGrades: calculatedPapers,
          grade: 'F',
          descriptor: 'Fail',
          points: 0,
        );
      }
    }

    // Logic for Principal subjects (2 or 3 papers)
    final int numPapers = paperScores.length;
    String grade;
    int points;
    String descriptor;

    if (numPapers <= 2) {
      // 2-Paper Subject Grading
      // Aggregate Ranges: A(<=4), B(5), C(6), D(7), E(8-12), O(13-16), F(17+)
      if (aggregate <= 4) {
        grade = 'A';
      } else if (aggregate == 5) {
        grade = 'B';
      } else if (aggregate == 6) {
        grade = 'C';
      } else if (aggregate == 7) {
        grade = 'D';
      } else if (aggregate <= 12) {
        grade = 'E';
      } else if (aggregate <= 16) {
        grade = 'O';
      } else {
        grade = 'F';
      }
    } else {
      // 3-Paper Subject Grading (or more)
      // This logic implements the complex rules from the plan, combining the
      // "worst paper" rule with aggregate scores and exceptions.
      final paperValues = calculatedPapers.values
          .map((p) => p.scaledScoreValue)
          .toList();
      final worstPaperValue = paperValues.reduce((a, b) => a > b ? a : b);

      // Handle the special case where a Fail (F9) can still result in a Principal Pass
      // if the aggregate is low enough, as per the plan's example (D1, D1, F9) -> B.
      if (paperValues.contains(9) && aggregate <= 12) {
        grade = 'B';
      } else {
        // Apply the "worst paper" rule, with a check for the E/O boundary.
        if (worstPaperValue <= 3) {
          grade = 'A'; // Worst paper is C3 or better
        } else if (worstPaperValue <= 4) {
          grade = 'B'; // Worst paper is C4
        } else if (worstPaperValue <= 5) {
          grade = 'C'; // Worst paper is C5
        } else if (worstPaperValue <= 6) {
          grade = 'D'; // Worst paper is C6
        } else if (worstPaperValue <= 7) {
          // If the worst paper is P7, the aggregate determines E vs O.
          // (C6,C6,P7)=19 is E, but (P7,P7,P7)=21 is O.
          if (aggregate <= 19) {
            grade = 'E';
          } else {
            grade = 'O';
          }
        } else if (worstPaperValue <= 8) {
          // If the worst paper is P8, it's a subsidiary pass.
          grade = 'O';
        } else {
          grade =
              'F'; // Worst paper is F9 (and aggregate is too high for override)
        }
      }
    }

    // Assign points and descriptor based on the final letter grade
    switch (grade) {
      case 'A':
        points = 6;
        descriptor = 'Principal Pass';
        break;
      case 'B':
        points = 5;
        descriptor = 'Principal Pass';
        break;
      case 'C':
        points = 4;
        descriptor = 'Principal Pass';
        break;
      case 'D':
        points = 3;
        descriptor = 'Principal Pass';
        break;
      case 'E':
        points = 2;
        descriptor = 'Principal Pass';
        break;
      case 'O':
        points = 1;
        descriptor = 'Subsidiary Pass';
        break;
      default: // 'F'
        points = 0;
        descriptor = 'Fail';
    }

    return CalculatedSubjectGrade(
      paperGrades: calculatedPapers,
      grade: grade,
      descriptor: descriptor,
      points: points,
    );
  }

  /// A private helper to calculate scores for a single paper.
  /// This logic is common for both O-Level and A-Level papers.
  CalculatedPaperGrade _calculatePaperGrade(PaperScores scores) {
    // Normalize BOT and MOT scores (which are out of 3) to a 0-1 scale.
    final botNormal = (scores.bot ?? 0) / 3.0;
    final motNormal = (scores.mot ?? 0) / 3.0;

    // Calculate Continuous Assessment (CA) contribution (20% of final mark).
    // The formula is: ( (BOT_contrib) + (MOT_contrib) ) * 20%
    // BOT is 40% of CA, MOT is 60% of CA.
    // So, CA = ( (bot_norm * 40) + (mot_norm * 60) )
    // And its contribution to the final score is CA * 0.2
    final continuousAssessment = ((botNormal * 40) + (motNormal * 60)) * 0.2;

    // Calculate End of Term (EOT) contribution (80% of final mark).
    final eotContribution = (scores.eot ?? 0) * 0.8;

    // The final Grading Score (GS) is the sum of the two contributions.
    final gradingScore = continuousAssessment + eotContribution;

    // Determine the A-Level scaled score (D1-F9) based on the grading score.
    final (String scaledScore, int scaledScoreValue) = _getALevelScaledScore(
      gradingScore,
    );

    return CalculatedPaperGrade(
      continuousAssessment: continuousAssessment,
      gradingScore: gradingScore,
      scaledScore: scaledScore,
      scaledScoreValue: scaledScoreValue,
    );
  }

  /// A private helper to get the A-Level scaled score (D1-F9) and its numeric value.
  (String, int) _getALevelScaledScore(double gradingScore) {
    if (gradingScore >= 85) return ('D1', 1);
    if (gradingScore >= 80) return ('D2', 2);
    if (gradingScore >= 75) return ('C3', 3);
    if (gradingScore >= 70) return ('C4', 4);
    if (gradingScore >= 65) return ('C5', 5);
    if (gradingScore >= 60) return ('C6', 6);
    if (gradingScore >= 50) return ('P7', 7);
    if (gradingScore >= 40) return ('P8', 8);
    return ('F9', 9);
  }

  /// Determines the final O-Level result (1, 2, or 3) based on a student's
  /// performance across all subjects, as per the plan.
  int calculateOLevelFinalResult(List<CalculatedSubjectGrade> allGrades) {
    // Result 2: Ineligible due to procedural issues (e.g., no marks submitted).
    if (allGrades.isEmpty) {
      return 2;
    }

    // Result 3: Did not qualify and failed all subjects with the lowest grade.
    final didFailAll = allGrades.every((g) => g.grade == 'E');
    if (didFailAll) {
      return 3;
    }

    // Result 1: Qualified by passing at least one subject with a grade of D or better.
    final didPassOne = allGrades.any(
      (g) =>
          g.grade == 'A' || g.grade == 'B' || g.grade == 'C' || g.grade == 'D',
    );
    if (didPassOne) {
      return 1;
    }

    // Default to Result 2 if none of the above conditions are met.
    return 2;
  }
}

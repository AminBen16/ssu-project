/// Data models for the grading system.
library;

/// Data class for raw scores entered for a single paper.
class PaperScores {
  final double? bot; // Beginning of Term (out of 3)
  final double? mot; // Mid of Term (out of 3)
  final double? eot; // End of Term (out of 100)
  final String? grade;
  final String? remarks;

  PaperScores({this.bot, this.mot, this.eot, this.grade, this.remarks});

  factory PaperScores.fromMap(Map<String, dynamic> map) {
    return PaperScores(
      bot: (map['bot'] as num?)?.toDouble(),
      mot: (map['mot'] as num?)?.toDouble(),
      eot: (map['eot'] as num?)?.toDouble(),
      grade: map['grade'] as String?,
      remarks: map['remarks'] as String?,
    );
  }

  factory PaperScores.fromStrings(String bot, String mot, String eot) {
    return PaperScores(
      bot: double.tryParse(bot),
      mot: double.tryParse(mot),
      eot: double.tryParse(eot),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bot': bot,
      'mot': mot,
      'eot': eot,
    };
  }
}

/// Data class for calculated scores for a single paper.
class CalculatedPaperGrade {
  final double continuousAssessment; // Contribution to final GS (out of 20)
  final double gradingScore; // Final score for the paper (out of 100)
  final String scaledScore; // A-Level grade for the paper (D1, C3, etc.)
  final int
      scaledScoreValue; // A-Level numeric value (1 for D1, 2 for D2, etc.)

  CalculatedPaperGrade({
    required this.continuousAssessment,
    required this.gradingScore,
    required this.scaledScore,
    required this.scaledScoreValue,
  });
}

/// Data class for the final calculated grade for a whole subject.
class CalculatedSubjectGrade {
  final Map<String, CalculatedPaperGrade> paperGrades;
  final double? averagedGradingScore; // O-Level final score
  final String grade; // O-Level (A-E) or A-Level (A-F, O)
  final String descriptor; // Exceptional, Principal Pass, etc.
  final int? points; // A-Level points (0-6)

  CalculatedSubjectGrade({
    required this.paperGrades,
    this.averagedGradingScore,
    required this.grade,
    required this.descriptor,
    this.points,
  });
}

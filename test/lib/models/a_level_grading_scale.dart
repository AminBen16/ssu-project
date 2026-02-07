/// Represents the A' Level scaled score for a single paper, often called a stanine.
enum ScaledScore {
  d1(1, 'D1'),
  d2(2, 'D2'),
  c3(3, 'C3'),
  c4(4, 'C4'),
  c5(5, 'C5'),
  c6(6, 'C6'),
  p7(7, 'P7'),
  p8(8, 'P8'),
  f9(9, 'F9');

  final int value;
  final String name;
  const ScaledScore(this.value, this.name);

  /// Converts a grading score (0-100) to a [ScaledScore].
  static ScaledScore fromGradingScore(double score) {
    if (score >= 85) return ScaledScore.d1;
    if (score >= 80) return ScaledScore.d2;
    if (score >= 75) return ScaledScore.c3;
    if (score >= 70) return ScaledScore.c4;
    if (score >= 65) return ScaledScore.c5;
    if (score >= 60) return ScaledScore.c6;
    if (score >= 50) return ScaledScore.p7;
    if (score >= 40) return ScaledScore.p8;
    return ScaledScore.f9;
  }
}

class Exam {
  final String title;
  final DateTime? examDate;

  Exam({
    required this.title,
    this.examDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'examDate': examDate?.toIso8601String(),
    };
  }
}

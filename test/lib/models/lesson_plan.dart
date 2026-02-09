class LessonPlan {
  final String title;
  final String subject;
  final String grade;

  LessonPlan({
    required this.title,
    required this.subject,
    required this.grade,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'grade': grade,
    };
  }
}

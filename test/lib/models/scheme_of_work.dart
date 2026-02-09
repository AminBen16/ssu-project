class SchemeOfWork {
  final String title;
  final String subject;
  final String grade;

  SchemeOfWork({
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

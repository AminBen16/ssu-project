class MarksEntry {
  final String studentId;
  final String subject;
  final double marks;
  final DateTime? entryDate;

  MarksEntry({
    required this.studentId,
    required this.subject,
    required this.marks,
    this.entryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subject': subject,
      'marks': marks,
      'entryDate': entryDate?.toIso8601String(),
    };
  }
}

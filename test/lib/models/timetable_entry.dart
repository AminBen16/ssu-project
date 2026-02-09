class TimetableEntry {
  final String subject;
  final DateTime? startTime;
  final DateTime? endTime;

  TimetableEntry({
    required this.subject,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }
}

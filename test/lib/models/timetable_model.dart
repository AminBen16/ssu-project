/// Represents a single period in the school day.
class TimeSlot {
  final String id; // e.g., "P1", "BREAK1"
  final String displayTime;

  TimeSlot({required this.id, required this.displayTime});
}

/// Represents a lesson scheduled within a specific time slot.
class ScheduledLesson {
  final String subjectName;
  final String teacherId;
  final String teacherName; // Denormalized for easy display
  final String? room;

  ScheduledLesson({
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    this.room,
  });

  factory ScheduledLesson.fromMap(Map<String, dynamic> map) {
    return ScheduledLesson(
      subjectName: map['subjectName'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      room: map['room'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'room': room,
    };
  }
}

/// Represents a scheduled lesson in the timetable
class ScheduledLesson {
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final String? room;
  final String? className;
  final String? notes;

  const ScheduledLesson({
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    this.room,
    this.className,
    this.notes,
  });

  factory ScheduledLesson.empty() => const ScheduledLesson(
        subjectName: '',
        teacherId: '',
        teacherName: '',
      );

  bool get isEmpty => subjectName.isEmpty && teacherId.isEmpty;

  ScheduledLesson copyWith({
    String? subjectName,
    String? teacherId,
    String? teacherName,
    String? room,
    String? className,
    String? notes,
  }) {
    return ScheduledLesson(
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      room: room ?? this.room,
      className: className ?? this.className,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'room': room,
      'className': className,
      'notes': notes,
    };
  }

  factory ScheduledLesson.fromMap(Map<String, dynamic> map) {
    return ScheduledLesson(
      subjectName: map['subjectName'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      room: map['room'] as String?,
      className: map['className'] as String?,
      notes: map['notes'] as String?,
    );
  }

  @override
/*************  ✨ Windsurf Command ⭐  *************/
/// Returns a string representation of this object.
///
/// The string representation includes the subject name, teacher ID, and teacher name.

  String toString() {
    return 'ScheduledLesson(subjectName: $subjectName, teacherId: $teacherId, teacherName: $teacherName)';
  }
}

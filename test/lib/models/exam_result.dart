class ExamResult {
  final int id;
  final int schoolId;
  final int examId;
  final int studentId;
  final int subjectId;
  final double marksObtained;
  final double totalMarks;
  final String? grade;
  final String? comments;
  final int recordedBy;
  final DateTime recordedAt;
  final DateTime updatedAt;

  ExamResult({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    required this.marksObtained,
    required this.totalMarks,
    this.grade,
    this.comments,
    required this.recordedBy,
    required this.recordedAt,
    required this.updatedAt,
  });

  factory ExamResult.fromMap(Map<String, dynamic> map) {
    return ExamResult(
      id: map['id'] as int,
      schoolId: map['school_id'] as int,
      examId: map['exam_id'] as int,
      studentId: map['student_id'] as int,
      subjectId: map['subject_id'] as int,
      marksObtained: (map['marks_obtained'] as num).toDouble(),
      totalMarks: (map['total_marks'] as num).toDouble(),
      grade: map['grade'] as String?,
      comments: map['comments'] as String?,
      recordedBy: map['recorded_by'] as int,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'exam_id': examId,
      'student_id': studentId,
      'subject_id': subjectId,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'grade': grade,
      'comments': comments,
      'recorded_by': recordedBy,
      'recorded_at': recordedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExamResult &&
        other.id == id &&
        other.schoolId == schoolId &&
        other.examId == examId &&
        other.studentId == studentId &&
        other.subjectId == subjectId &&
        other.marksObtained == marksObtained &&
        other.totalMarks == totalMarks &&
        other.grade == grade &&
        other.comments == comments &&
        other.recordedBy == recordedBy &&
        other.recordedAt == recordedAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        schoolId.hashCode ^
        examId.hashCode ^
        studentId.hashCode ^
        subjectId.hashCode ^
        marksObtained.hashCode ^
        totalMarks.hashCode ^
        grade.hashCode ^
        comments.hashCode ^
        recordedBy.hashCode ^
        recordedAt.hashCode ^
        updatedAt.hashCode;
  }
}

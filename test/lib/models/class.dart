class Class {
  final int id;
  final int schoolId;
  final String name;
  final String? gradeLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Class({
    required this.id,
    required this.schoolId,
    required this.name,
    this.gradeLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Class.fromMap(Map<String, dynamic> map) {
    return Class(
      id: map['id'] as int,
      schoolId: map['school_id'] as int,
      name: map['name'] as String,
      gradeLevel: map['grade_level'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'grade_level': gradeLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Class &&
        other.id == id &&
        other.schoolId == schoolId &&
        other.name == name &&
        other.gradeLevel == gradeLevel &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        schoolId.hashCode ^
        name.hashCode ^
        gradeLevel.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

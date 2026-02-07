class LessonPlan {
  final String? id;
  final String teacherId;
  final String schoolId;
  final String subjectId;
  final String topicId;
  final String className;
  final String title;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String duration;
  final List<String> learningObjectives;
  final List<String> teachingMethods;
  final List<Map<String, dynamic>> activities;
  final List<Map<String, dynamic>> assessments;
  final List<String> materials;
  final Map<String, dynamic> homework;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonPlan({
    this.id,
    required this.teacherId,
    required this.schoolId,
    required this.subjectId,
    required this.topicId,
    required this.className,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.learningObjectives,
    required this.teachingMethods,
    required this.activities,
    required this.assessments,
    required this.materials,
    required this.homework,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Construct a lesson plan from simple form-style fields used by the UI.
  /// This maps single-string fields (topic, objectives, materials, activities,
  /// evaluation/assessment) into the richer internal representations.
  LessonPlan.fromForm({
    this.id,
    required this.teacherId,
    required this.schoolId,
    String? subject,
    String? topic,
    String? className,
    String? title,
    String? objectives,
    String? materials,
    String? activitiesText,
    String? evaluation,
    String? assessmentText,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : subjectId = subject ?? '',
        topicId = topic ?? '',
        className = className ?? '',
        title = title ?? '',
        date = startDate ?? DateTime.now(),
        startTime = startDate ?? DateTime.now(),
        endTime = endDate ?? DateTime.now(),
        duration = '0',
        learningObjectives = objectives != null
            ? objectives
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : <String>[],
        teachingMethods = <String>[],
        activities = activitiesText != null
            ? <Map<String, dynamic>>[
                {'text': activitiesText}
              ]
            : <Map<String, dynamic>>[],
        assessments = assessmentText != null
            ? <Map<String, dynamic>>[
                {'text': assessmentText}
              ]
            : <Map<String, dynamic>>[],
        materials = materials != null
            ? materials
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : <String>[],
        homework = <String, dynamic>{},
        notes = evaluation ?? '',
        status = 'draft',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convenience getters used by legacy UI expecting simple fields
  String? get topic => topicId.isNotEmpty ? topicId : null;
  String? get objectives =>
      learningObjectives.isNotEmpty ? learningObjectives.join('\n') : null;
  String? get materialsText =>
      materials.isNotEmpty ? materials.join('\n') : null;
  String? get activitiesText => activities.isNotEmpty
      ? activities.map((a) => a.values.join(' ')).join('\n')
      : null;
  String? get evaluation => notes.isNotEmpty ? notes : null;
  String get assessment =>
      assessments.isNotEmpty ? assessments.first.values.join(' ') : '';
  DateTime? get startDate => date;
  DateTime? get endDate => date;
  String? get subject => subjectId.isNotEmpty ? subjectId : null;

  factory LessonPlan.fromMap(Map<String, dynamic> json) {
    return LessonPlan(
      id: json['id'] as String?,
      teacherId: json['teacher_id'] as String,
      schoolId: json['school_id'] as String,
      subjectId: json['subject_id'] as String,
      topicId: json['topic_id'] as String,
      className: json['class_name'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      duration: json['duration'] as String,
      learningObjectives:
          List<String>.from(json['learning_objectives'] as List),
      teachingMethods: List<String>.from(json['teaching_methods'] as List),
      activities: List<Map<String, dynamic>>.from(json['activities'] as List),
      assessments: List<Map<String, dynamic>>.from(json['assessments'] as List),
      materials: List<String>.from(json['materials'] as List),
      homework: Map<String, dynamic>.from(json['homework'] as Map),
      notes: json['notes'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'school_id': schoolId,
      'subject_id': subjectId,
      'topic_id': topicId,
      'class_name': className,
      'title': title,
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration,
      'learning_objectives': learningObjectives,
      'teaching_methods': teachingMethods,
      'activities': activities,
      'assessments': assessments,
      'materials': materials,
      'homework': homework,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

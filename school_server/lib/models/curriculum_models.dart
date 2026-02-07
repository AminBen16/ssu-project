/// Curriculum Subject Model
class CurriculumSubject {
  final int? id;
  final String name;
  final String educationLevel;
  final String? description;
  final int? periodsPerWeekS1S2;
  final int? periodsPerWeekS3S4;
  final String? rationale;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumSubject({
    this.id,
    required this.name,
    required this.educationLevel,
    this.description,
    this.periodsPerWeekS1S2,
    this.periodsPerWeekS3S4,
    this.rationale,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumSubject.fromMap(Map<String, dynamic> map) {
    return CurriculumSubject(
      id: map['id'] as int?,
      name: map['name'] as String,
      educationLevel: map['education_level'] as String,
      description: map['description'] as String?,
      periodsPerWeekS1S2: map['periods_per_week_s1_s2'] as int?,
      periodsPerWeekS3S4: map['periods_per_week_s3_s4'] as int?,
      rationale: map['rationale'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'education_level': educationLevel,
      'description': description,
      'periods_per_week_s1_s2': periodsPerWeekS1S2,
      'periods_per_week_s3_s4': periodsPerWeekS3S4,
      'rationale': rationale,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Strand/Theme Model
class CurriculumStrand {
  final int? id;
  final int subjectId;
  final String name;
  final String seniorLevel;
  final String term;
  final int durationPeriods;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumStrand({
    this.id,
    required this.subjectId,
    required this.name,
    required this.seniorLevel,
    required this.term,
    required this.durationPeriods,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumStrand.fromMap(Map<String, dynamic> map) {
    return CurriculumStrand(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      name: map['name'] as String,
      seniorLevel: map['senior_level'] as String,
      term: map['term'] as String,
      durationPeriods: map['duration_periods'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'name': name,
      'senior_level': seniorLevel,
      'term': term,
      'duration_periods': durationPeriods,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Topic Model
class CurriculumTopic {
  final int? id;
  final int strandId;
  final String name;
  final String competency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumTopic({
    this.id,
    required this.strandId,
    required this.name,
    required this.competency,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumTopic.fromMap(Map<String, dynamic> map) {
    return CurriculumTopic(
      id: map['id'] as int?,
      strandId: map['strand_id'] as int,
      name: map['name'] as String,
      competency: map['competency'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strand_id': strandId,
      'name': name,
      'competency': competency,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Competence Model
class CurriculumCompetence {
  final int? id;
  final int topicId;
  final String statement;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumCompetence({
    this.id,
    required this.topicId,
    required this.statement,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumCompetence.fromMap(Map<String, dynamic> map) {
    return CurriculumCompetence(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      statement: map['statement'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'statement': statement,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Content Unit Model
class CurriculumContentUnit {
  final int? id;
  final int topicId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumContentUnit({
    this.id,
    required this.topicId,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumContentUnit.fromMap(Map<String, dynamic> map) {
    return CurriculumContentUnit(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      content: map['content'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Learning Outcome Model
class CurriculumLearningOutcome {
  final int? id;
  final int topicId;
  final String outcome;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumLearningOutcome({
    this.id,
    required this.topicId,
    required this.outcome,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumLearningOutcome.fromMap(Map<String, dynamic> map) {
    return CurriculumLearningOutcome(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      outcome: map['outcome'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'outcome': outcome,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Activity Model
class CurriculumActivity {
  final int? id;
  final int topicId;
  final String activity;
  final String type; // 'suggested_learning', 'assessment'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumActivity({
    this.id,
    required this.topicId,
    required this.activity,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumActivity.fromMap(Map<String, dynamic> map) {
    return CurriculumActivity(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      activity: map['activity'] as String,
      type: map['type'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'activity': activity,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Material Model
class CurriculumMaterial {
  final int? id;
  final int topicId;
  final String material;
  final String type; // 'teaching', 'learning'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumMaterial({
    this.id,
    required this.topicId,
    required this.material,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumMaterial.fromMap(Map<String, dynamic> map) {
    return CurriculumMaterial(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      material: map['material'] as String,
      type: map['type'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'material': material,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Assessment Model
class CurriculumAssessment {
  final int? id;
  final int topicId;
  final String assessment;
  final String type; // 'formative', 'summative'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumAssessment({
    this.id,
    required this.topicId,
    required this.assessment,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumAssessment.fromMap(Map<String, dynamic> map) {
    return CurriculumAssessment(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      assessment: map['assessment'] as String,
      type: map['type'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'assessment': assessment,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Assessment Framework Model
class CurriculumAssessmentFramework {
  final int? id;
  final int subjectId;
  final String frameworkType;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumAssessmentFramework({
    this.id,
    required this.subjectId,
    required this.frameworkType,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumAssessmentFramework.fromMap(Map<String, dynamic> map) {
    return CurriculumAssessmentFramework(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      frameworkType: map['framework_type'] as String,
      content: map['content'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'framework_type': frameworkType,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Curriculum Cross-Cutting Issue Model
class CurriculumCrossCuttingIssue {
  final int? id;
  final int subjectId;
  final String issue;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumCrossCuttingIssue({
    this.id,
    required this.subjectId,
    required this.issue,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory CurriculumCrossCuttingIssue.fromMap(Map<String, dynamic> map) {
    return CurriculumCrossCuttingIssue(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      issue: map['issue'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'issue': issue,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

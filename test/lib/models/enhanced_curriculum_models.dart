import 'dart:convert';

/// Enhanced NCDC Curriculum Models with Full Data Structure Support

/// Enhanced Subject Model with NCDC-specific fields
class EnhancedSubject {
  final int? id;
  final String name;
  final String educationLevel; // 'O-Level' or 'A-Level'
  final String? description;
  final String? rationale;
  final int? periodDuration;
  final int? periodsPerWeek;
  final List<String>? classNames; // S.1-S.4 for O-Level, S.5-S.6 for A-Level
  final String? code;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnhancedSubject({
    this.id,
    required this.name,
    required this.educationLevel,
    this.description,
    this.rationale,
    this.periodDuration,
    this.periodsPerWeek,
    this.classNames,
    this.code,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'education_level': educationLevel,
      'description': description,
      'rationale': rationale,
      'period_duration': periodDuration,
      'periods_per_week': periodsPerWeek,
      'class_names': classNames != null ? json.encode(classNames) : null,
      'code': code,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EnhancedSubject.fromMap(Map<String, dynamic> map) {
    return EnhancedSubject(
      id: map['id'],
      name: map['name'],
      educationLevel: map['education_level'],
      description: map['description'],
      rationale: map['rationale'],
      periodDuration: map['period_duration'],
      periodsPerWeek: map['periods_per_week'],
      classNames: map['class_names'] != null 
          ? List<String>.from(json.decode(map['class_names'])) 
          : [],
      code: map['code'],
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  factory EnhancedSubject.fromJson(Map<String, dynamic> json) {
    return EnhancedSubject(
      name: json['name'] ?? '',
      educationLevel: json['education_level'] ?? '',
      description: json['description'],
      rationale: json['rationale'],
      periodDuration: json['period_duration'],
      periodsPerWeek: json['periods_per_week'],
      classNames: json['class_names'] != null 
          ? List<String>.from(json['class_names']) 
          : null,
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'education_level': educationLevel,
      'description': description,
      'rationale': rationale,
      'period_duration': periodDuration,
      'periods_per_week': periodsPerWeek,
      'class_names': classNames,
      'code': code,
    };
  }
}

/// Enhanced Strand Model with term and duration information
class EnhancedStrand {
  final int? id;
  final int subjectId;
  final String name;
  final String? code;
  final String? description;
  final String? term; // TERM 1, TERM 2, TERM 3
  final String? seniorLevel; // SENIOR FIVE, SENIOR SIX, etc.
  final int? durationPeriods;
  final int? orderIndex;
  final List<String>? keyConcepts;
  final List<String>? teachingApproaches;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnhancedStrand({
    this.id,
    required this.subjectId,
    required this.name,
    this.code,
    this.description,
    this.term,
    this.seniorLevel,
    this.durationPeriods,
    this.orderIndex,
    this.keyConcepts,
    this.teachingApproaches,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'name': name,
      'code': code,
      'description': description,
      'term': term,
      'senior_level': seniorLevel,
      'duration_periods': durationPeriods,
      'order_index': orderIndex,
      'key_concepts': keyConcepts != null ? json.encode(keyConcepts) : null,
      'teaching_approaches': teachingApproaches != null ? json.encode(teachingApproaches) : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EnhancedStrand.fromMap(Map<String, dynamic> map) {
    return EnhancedStrand(
      id: map['id'],
      subjectId: map['subject_id'],
      name: map['name'],
      code: map['code'],
      description: map['description'],
      term: map['term'],
      seniorLevel: map['senior_level'],
      durationPeriods: map['duration_periods'],
      orderIndex: map['order_index'],
      keyConcepts: map['key_concepts'] != null 
          ? List<String>.from(json.decode(map['key_concepts'])) 
          : [],
      teachingApproaches: map['teaching_approaches'] != null 
          ? List<String>.from(json.decode(map['teaching_approaches'])) 
          : [],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }
}

/// Enhanced Topic Model with comprehensive NCDC data
class EnhancedTopic {
  final int? id;
  final int strandId;
  final String name;
  final String? code;
  final String? description;
  final String competency; // Main competency statement
  final int? durationPeriods;
  final String? term;
  final String? className;
  final int? orderIndex;
  final List<String>? keyConcepts;
  final List<String>? prerequisiteTopics;
  final List<String>? relatedTopics;
  final String? assessmentGuidance;
  final String? teachingNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnhancedTopic({
    this.id,
    required this.strandId,
    required this.name,
    this.code,
    this.description,
    required this.competency,
    this.durationPeriods,
    this.term,
    this.className,
    this.orderIndex,
    this.keyConcepts,
    this.prerequisiteTopics,
    this.relatedTopics,
    this.assessmentGuidance,
    this.teachingNotes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strand_id': strandId,
      'name': name,
      'code': code,
      'description': description,
      'competency': competency,
      'duration_periods': durationPeriods,
      'term': term,
      'class_name': className,
      'order_index': orderIndex,
      'key_concepts': keyConcepts != null ? json.encode(keyConcepts) : null,
      'prerequisite_topics': prerequisiteTopics != null ? json.encode(prerequisiteTopics) : null,
      'related_topics': relatedTopics != null ? json.encode(relatedTopics) : null,
      'assessment_guidance': assessmentGuidance,
      'teaching_notes': teachingNotes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EnhancedTopic.fromMap(Map<String, dynamic> map) {
    return EnhancedTopic(
      id: map['id'],
      strandId: map['strand_id'],
      name: map['name'],
      code: map['code'],
      description: map['description'],
      competency: map['competency'] ?? '',
      durationPeriods: map['duration_periods'],
      term: map['term'],
      className: map['class_name'],
      orderIndex: map['order_index'],
      keyConcepts: map['key_concepts'] != null 
          ? List<String>.from(json.decode(map['key_concepts'])) 
          : [],
      prerequisiteTopics: map['prerequisite_topics'] != null 
          ? List<String>.from(json.decode(map['prerequisite_topics'])) 
          : [],
      relatedTopics: map['related_topics'] != null 
          ? List<String>.from(json.decode(map['related_topics'])) 
          : [],
      assessmentGuidance: map['assessment_guidance'],
      teachingNotes: map['teaching_notes'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }
}

/// Enhanced Learning Outcome with full NCDC structure
class EnhancedLearningOutcome {
  final int? id;
  final int topicId;
  final int? subTopicId;
  final String outcomeText;
  final String? outcomeType; // Knowledge, Skills, Attitudes, Values
  final String? lessonUnit;
  final int? orderIndex;
  final List<String>? activities;
  final List<String>? materials;
  final List<String>? teachingStrategies;
  final List<String>? ictIntegration;
  final List<String>? crossCuttingIssues;
  final List<String>? genericSkills;
  final EnhancedAssessment assessment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnhancedLearningOutcome({
    this.id,
    required this.topicId,
    this.subTopicId,
    required this.outcomeText,
    this.outcomeType,
    this.lessonUnit,
    this.orderIndex,
    this.activities,
    this.materials,
    this.teachingStrategies,
    this.ictIntegration,
    this.crossCuttingIssues,
    this.genericSkills,
    required this.assessment,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'sub_topic_id': subTopicId,
      'outcome_text': outcomeText,
      'outcome_type': outcomeType,
      'lesson_unit': lessonUnit,
      'order_index': orderIndex,
      'activities': activities?.isNotEmpty == true ? json.encode(activities) : null,
      'materials': materials?.isNotEmpty == true ? json.encode(materials) : null,
      'teaching_strategies': teachingStrategies?.isNotEmpty == true ? json.encode(teachingStrategies) : null,
      'ict_integration': ictIntegration?.isNotEmpty == true ? json.encode(ictIntegration) : null,
      'cross_cutting_issues': crossCuttingIssues?.isNotEmpty == true ? json.encode(crossCuttingIssues) : null,
      'generic_skills': genericSkills?.isNotEmpty == true ? json.encode(genericSkills) : null,
      'assessment': json.encode(assessment.toMap()),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EnhancedLearningOutcome.fromMap(Map<String, dynamic> map) {
    return EnhancedLearningOutcome(
      id: map['id'],
      topicId: map['topic_id'],
      subTopicId: map['sub_topic_id'],
      outcomeText: map['outcome_text'],
      outcomeType: map['outcome_type'],
      lessonUnit: map['lesson_unit'],
      orderIndex: map['order_index'],
      activities: map['activities'] != null 
          ? List<String>.from(json.decode(map['activities'])) 
          : [],
      materials: map['materials'] != null 
          ? List<String>.from(json.decode(map['materials'])) 
          : [],
      teachingStrategies: map['teaching_strategies'] != null 
          ? List<String>.from(json.decode(map['teaching_strategies'])) 
          : [],
      ictIntegration: map['ict_integration'] != null 
          ? List<String>.from(json.decode(map['ict_integration'])) 
          : [],
      crossCuttingIssues: map['cross_cutting_issues'] != null 
          ? List<String>.from(json.decode(map['cross_cutting_issues'])) 
          : [],
      genericSkills: map['generic_skills'] != null 
          ? List<String>.from(json.decode(map['generic_skills'])) 
          : [],
      assessment: map['assessment'] != null 
          ? EnhancedAssessment.fromMap(json.decode(map['assessment']))
          : EnhancedAssessment(),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }
}

/// Enhanced Assessment Model with detailed NCDC assessment information
class EnhancedAssessment {
  final String? guidance;
  final String mode; // Formative, Summative, Diagnostic
  final String examEligibility;
  final String? weighting;
  final String? method;
  final List<String>? assessmentCriteria;
  final List<String>? assessmentMethods;
  final String? feedbackStrategy;

  EnhancedAssessment({
    this.guidance,
    this.mode = 'Formative',
    this.examEligibility = 'Yes',
    this.weighting,
    this.method,
    this.assessmentCriteria,
    this.assessmentMethods,
    this.feedbackStrategy,
  });

  Map<String, dynamic> toMap() {
    return {
      'guidance': guidance,
      'mode': mode,
      'exam_eligibility': examEligibility,
      'weighting': weighting,
      'method': method,
      'assessment_criteria': assessmentCriteria,
      'assessment_methods': assessmentMethods,
      'feedback_strategy': feedbackStrategy,
    };
  }

  factory EnhancedAssessment.fromMap(Map<String, dynamic> map) {
    return EnhancedAssessment(
      guidance: map['guidance'],
      mode: map['mode'] ?? 'Formative',
      examEligibility: map['exam_eligibility'] ?? 'Yes',
      weighting: map['weighting'],
      method: map['method'],
      assessmentCriteria: map['assessment_criteria'] != null 
          ? List<String>.from(map['assessment_criteria']) 
          : [],
      assessmentMethods: map['assessment_methods'] != null 
          ? List<String>.from(map['assessment_methods']) 
          : [],
      feedbackStrategy: map['feedback_strategy'],
    );
  }
}

/// Enhanced Activity Model with detailed information
class EnhancedActivity {
  final int? id;
  final int learningOutcomeId;
  final String activityText;
  final String? description;
  final String? activityType; // Individual, Group, Class, Demonstration
  final int? durationMinutes;
  final List<String>? requiredMaterials;
  final List<String>? instructions;
  final String? assessmentMethod;
  final int? orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnhancedActivity({
    this.id,
    required this.learningOutcomeId,
    required this.activityText,
    this.description,
    this.activityType,
    this.durationMinutes,
    this.requiredMaterials,
    this.instructions,
    this.assessmentMethod,
    this.orderIndex,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'learning_outcome_id': learningOutcomeId,
      'activity_text': activityText,
      'description': description,
      'activity_type': activityType,
      'duration_minutes': durationMinutes,
      'required_materials': requiredMaterials?.isNotEmpty == true ? json.encode(requiredMaterials) : null,
      'instructions': instructions?.isNotEmpty == true ? json.encode(instructions) : null,
      'assessment_method': assessmentMethod,
      'order_index': orderIndex,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EnhancedActivity.fromMap(Map<String, dynamic> map) {
    return EnhancedActivity(
      id: map['id'],
      learningOutcomeId: map['learning_outcome_id'],
      activityText: map['activity_text'],
      description: map['description'],
      activityType: map['activity_type'],
      durationMinutes: map['duration_minutes'],
      requiredMaterials: map['required_materials'] != null 
          ? List<String>.from(json.decode(map['required_materials'])) 
          : [],
      instructions: map['instructions'] != null 
          ? List<String>.from(json.decode(map['instructions'])) 
          : [],
      assessmentMethod: map['assessment_method'],
      orderIndex: map['order_index'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }
}

/// Enhanced Material Model with detailed resource information
class EnhancedMaterial {
  final int? id;
  final int learningOutcomeId;
  final String materialName;
  final String? description;
  final String? materialType; // Textbook, Workbook, Digital, Equipment, etc.
  final String? source;
  final bool isRequired;
  final String? quantity;
  final String? specifications;
  final int? orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnhancedMaterial({
    this.id,
    required this.learningOutcomeId,
    required this.materialName,
    this.description,
    this.materialType,
    this.source,
    this.isRequired = true,
    this.quantity,
    this.specifications,
    this.orderIndex,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'learning_outcome_id': learningOutcomeId,
      'material_name': materialName,
      'description': description,
      'material_type': materialType,
      'source': source,
      'is_required': isRequired ? 1 : 0,
      'quantity': quantity,
      'specifications': specifications,
      'order_index': orderIndex,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EnhancedMaterial.fromMap(Map<String, dynamic> map) {
    return EnhancedMaterial(
      id: map['id'],
      learningOutcomeId: map['learning_outcome_id'],
      materialName: map['material_name'],
      description: map['description'],
      materialType: map['material_type'],
      source: map['source'],
      isRequired: (map['is_required'] ?? 1) == 1,
      quantity: map['quantity'],
      specifications: map['specifications'],
      orderIndex: map['order_index'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }
}

/// Curriculum Data Integrity Model for tracking data sources and validation
class CurriculumDataIntegrity {
  final int? id;
  final String entityType; // subject, strand, topic, etc.
  final int entityId;
  final String sourceFile; // Original markdown file
  final String extractionMethod; // manual, automated, hybrid
  final double confidenceScore; // 0.0 to 1.0
  final String? validationStatus; // validated, pending, failed
  final List<String>? validationErrors;
  final String? lastValidatedBy;
  final DateTime? lastValidatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumDataIntegrity({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.sourceFile,
    required this.extractionMethod,
    required this.confidenceScore,
    this.validationStatus,
    this.validationErrors,
    this.lastValidatedBy,
    this.lastValidatedAt,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'source_file': sourceFile,
      'extraction_method': extractionMethod,
      'confidence_score': confidenceScore,
      'validation_status': validationStatus,
      'validation_errors': validationErrors?.isNotEmpty == true ? json.encode(validationErrors) : null,
      'last_validated_by': lastValidatedBy,
      'last_validated_at': lastValidatedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CurriculumDataIntegrity.fromMap(Map<String, dynamic> map) {
    return CurriculumDataIntegrity(
      id: map['id'],
      entityType: map['entity_type'],
      entityId: map['entity_id'],
      sourceFile: map['source_file'],
      extractionMethod: map['extraction_method'],
      confidenceScore: (map['confidence_score'] ?? 0.0).toDouble(),
      validationStatus: map['validation_status'],
      validationErrors: map['validation_errors'] != null 
          ? List<String>.from(json.decode(map['validation_errors'])) 
          : [],
      lastValidatedBy: map['last_validated_by'],
      lastValidatedAt: map['last_validated_at'] != null 
          ? DateTime.parse(map['last_validated_at']) 
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }
}

/// Curriculum Change Log Model for tracking modifications
class CurriculumChangeLog {
  final int? id;
  final String entityType;
  final int entityId;
  final String changeType; // created, updated, deleted
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final String? changedBy;
  final String? changeReason;
  final DateTime? createdAt;

  CurriculumChangeLog({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.changeType,
    required this.oldValues,
    required this.newValues,
    this.changedBy,
    this.changeReason,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'change_type': changeType,
      'old_values': json.encode(oldValues),
      'new_values': json.encode(newValues),
      'changed_by': changedBy,
      'change_reason': changeReason,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory CurriculumChangeLog.fromMap(Map<String, dynamic> map) {
    return CurriculumChangeLog(
      id: map['id'],
      entityType: map['entity_type'],
      entityId: map['entity_id'],
      changeType: map['change_type'],
      oldValues: map['old_values'] != null 
          ? Map<String, dynamic>.from(json.decode(map['old_values'])) 
          : {},
      newValues: map['new_values'] != null 
          ? Map<String, dynamic>.from(json.decode(map['new_values'])) 
          : {},
      changedBy: map['changed_by'],
      changeReason: map['change_reason'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }
}

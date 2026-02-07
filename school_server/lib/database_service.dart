// Removed unused imports to avoid analyzer warnings.

// Re-export the concrete implementation so existing imports of
// `database_service.dart` continue to resolve `DatabaseService`.
// Re-export the concrete implementation so existing imports of
// `database_service.dart` continue to resolve `DatabaseService`.
// Prefer the SQLite-backed implementation when present.
export 'database_service_sqlite.dart' show DatabaseService;

// Minimal, conservative DatabaseService implementation.
// This version opens a short-lived Connection for each operation to avoid
// driver runtime mismatches. It's slower but reliable for debugging.

// ===================== LEGACY CURRICULUM MODELS (FOR BACKWARD COMPATIBILITY) =====================

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

  factory CurriculumSubject.fromMap(Map<String, dynamic> map) {
    return CurriculumSubject(
      id: map['id'],
      name: map['name'],
      educationLevel: map['education_level'],
      description: map['description'],
      periodsPerWeekS1S2: map['periods_per_week_s1_s2'],
      periodsPerWeekS3S4: map['periods_per_week_s3_s4'],
      rationale: map['rationale'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

// Note: Implementations should extend `DatabaseServiceBase` directly.
// The concrete `DatabaseService` implementation lives in
// `database_service_impl.dart` and should be imported where an
// instantiable service is required.

class CurriculumStrand {
  final int? id;
  final int subjectId;
  final String name;
  final String? seniorLevel;
  final String? term;
  final int? durationPeriods;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumStrand({
    this.id,
    required this.subjectId,
    required this.name,
    this.seniorLevel,
    this.term,
    this.durationPeriods,
    this.createdAt,
    this.updatedAt,
  });

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

  factory CurriculumStrand.fromMap(Map<String, dynamic> map) {
    return CurriculumStrand(
      id: map['id'],
      subjectId: map['subject_id'],
      name: map['name'],
      seniorLevel: map['senior_level'],
      term: map['term'],
      durationPeriods: map['duration_periods'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class CurriculumTopic {
  final int? id;
  final int strandId;
  final String name;
  final String? competency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumTopic({
    this.id,
    required this.strandId,
    required this.name,
    this.competency,
    this.createdAt,
    this.updatedAt,
  });

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

  factory CurriculumTopic.fromMap(Map<String, dynamic> map) {
    return CurriculumTopic(
      id: map['id'],
      strandId: map['strand_id'],
      name: map['name'],
      competency: map['competency'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class CurriculumCompetence {
  final int? id;
  final int topicId;
  final String competence;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumCompetence({
    this.id,
    required this.topicId,
    required this.competence,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'competence': competence,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CurriculumCompetence.fromMap(Map<String, dynamic> map) {
    return CurriculumCompetence(
      id: map['id'],
      topicId: map['topic_id'],
      competence: map['competence'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class CurriculumLearningOutcome {
  final int? id;
  final int topicId;
  final String outcome;
  final String? outcomeType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumLearningOutcome({
    this.id,
    required this.topicId,
    required this.outcome,
    this.outcomeType,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'outcome': outcome,
      'outcome_type': outcomeType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CurriculumLearningOutcome.fromMap(Map<String, dynamic> map) {
    return CurriculumLearningOutcome(
      id: map['id'],
      topicId: map['topic_id'],
      outcome: map['outcome'],
      outcomeType: map['outcome_type'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class CurriculumActivity {
  final int? id;
  final int topicId;
  final String activity;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumActivity({
    this.id,
    required this.topicId,
    required this.activity,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

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

  factory CurriculumActivity.fromMap(Map<String, dynamic> map) {
    return CurriculumActivity(
      id: map['id'],
      topicId: map['topic_id'],
      activity: map['activity'],
      type: map['type'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class CurriculumMaterial {
  final int? id;
  final int topicId;
  final String material;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumMaterial({
    this.id,
    required this.topicId,
    required this.material,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

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

  factory CurriculumMaterial.fromMap(Map<String, dynamic> map) {
    return CurriculumMaterial(
      id: map['id'],
      topicId: map['topic_id'],
      material: map['material'],
      type: map['type'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class CurriculumAssessment {
  final int? id;
  final int topicId;
  final String assessment;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CurriculumAssessment({
    this.id,
    required this.topicId,
    required this.assessment,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

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

  factory CurriculumAssessment.fromMap(Map<String, dynamic> map) {
    return CurriculumAssessment(
      id: map['id'],
      topicId: map['topic_id'],
      assessment: map['assessment'],
      type: map['type'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

// ===================== DATABASE SERVICE =====================

abstract class DatabaseServiceBase {
  Future<void> initialize();

  // User management methods
  Future<Map<String, dynamic>?> findUserByEmail(String email);
  Future<Map<String, dynamic>?> findUserById(String id);
  Future<int> getTotalUserCount();
  Future<List<Map<String, dynamic>>> getAllUsers(int limit, int offset);
  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings);
  Future<void> deleteUser(String userId);

  // Email verification methods
  Future<void> createEmailVerificationToken(
      String userId, String token, DateTime expires);
  Future<Map<String, dynamic>?> findUserByVerificationToken(String token);
  Future<void> verifyUserEmail(String userId);
  Future<bool> isUserEmailVerified(String userId);
  Future<void> cleanupExpiredVerificationTokens();

  // Token management methods
  Future<bool> isTokenBlacklisted(String token);
  Future<Map<String, dynamic>?> findPasswordResetToken(String token);
  Future<void> blacklistToken(String token, String tokenType, String? userId);
  Future<void> cleanupExpiredTokens();
  Future<void> markPasswordResetTokenAsUsed(String token);
  Future<void> cleanupExpiredPasswordResetTokens();

  // School management methods
  Future<Map<String, dynamic>?> findSchoolByName(String name);
  Future<Map<String, dynamic>?> findSchoolById(String id);
  Future<List<Map<String, dynamic>>> getAllSchools();
  Future<Map<String, dynamic>> createSchool(
      {required String name, required String classification});
  Future<void> updateClassStreams(
      String schoolId, Map<String, List<String>> streams);

  // General-purpose query method used by server code. Accepts either a
  // raw SQL string with positional parameters or a table name when no
  // parameters are passed.
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]);

  /// Convenience for fetching a single row with raw SQL.
  Future<Map<String, dynamic>?> querySingle(String sql,
      [List<dynamic>? params]);

  /// Generic CRUD helpers used by components that operate directly with
  /// SQL or table maps.
  Future<void> insert(String table, Map<String, dynamic> data);
  Future<void> update(String table, Map<String, dynamic> data,
      String whereClause, List<dynamic> params);
  Future<void> deleteWhere(
      String table, String whereClause, List<dynamic> params);

  // Class management methods
  Future<Map<String, dynamic>> createClass(
      {required String schoolId, required String name, String? gradeLevel});
  Future<Map<String, dynamic>?> findClassById(String id);
  Future<List<Map<String, dynamic>>> getClassesBySchool(String schoolId);
  Future<void> updateClass(String classId, Map<String, dynamic> classData);
  Future<void> deleteClass(String classId);

  // Curriculum management methods
  Future<int> insertSubject(Map<String, dynamic> subject);
  Future<int> insertStrand(Map<String, dynamic> strand);
  Future<int> insertTopic(Map<String, dynamic> topic);
  Future<int> insertSubTopic(Map<String, dynamic> subTopic);
  Future<int> insertLearningOutcome(Map<String, dynamic> outcome);
  Future<int> insertSuggestedActivity(Map<String, dynamic> activity);
  Future<int> insertAssessmentStrategy(Map<String, dynamic> strategy);
  Future<int> insertCrossCuttingIssue(Map<String, dynamic> issue);
  Future<int> insertValue(Map<String, dynamic> value);
  Future<int> insertGenericSkill(Map<String, dynamic> skill);
  Future<List<Map<String, dynamic>>> getSubjects();
  Future<List<Map<String, dynamic>>> getStrandsBySubject(int subjectId);
  Future<List<Map<String, dynamic>>> getTopicsByStrand(int strandId);
  Future<List<Map<String, dynamic>>> getLearningOutcomesByTopic(int topicId);
  Future<List<Map<String, dynamic>>> getActivitiesByOutcome(int outcomeId);
  Future<List<Map<String, dynamic>>> getStrategiesByOutcome(int outcomeId);

  // Subject management methods
  Future<Map<String, dynamic>> createSubject(
      {required String schoolId, required String name, String? description});
  Future<Map<String, dynamic>?> findSubjectById(String id);
  Future<List<Map<String, dynamic>>> getSubjectsBySchool(String schoolId);
  Future<void> updateSubject(
      String subjectId, Map<String, dynamic> subjectData);
  Future<void> deleteSubject(String subjectId);

  // Exam Results management methods
  Future<Map<String, dynamic>> createExamResult({
    required String schoolId,
    required String examId,
    required String studentId,
    required String subjectId,
    required double marksObtained,
    required double totalMarks,
    required String recordedBy,
    String? grade,
    String? comments,
  });
  Future<Map<String, dynamic>?> getExamResultById(String id);
  Future<List<Map<String, dynamic>>> getExamResultsByExam(String examId);
  Future<List<Map<String, dynamic>>> getExamResultsByStudent(String studentId);
  Future<void> updateExamResult(
      String resultId, Map<String, dynamic> resultData);
  Future<void> deleteExamResult(String resultId);

  // Timetable constraints methods
  Future<void> setTimetableConstraint(Map<String, dynamic> constraint);
  Future<List<Map<String, dynamic>>> getTeacherConstraints(
      String schoolId, String teacherId);

  // Subject constraints methods
  Future<Map<String, dynamic>> getSubjectConstraints(String schoolId);
  Future<void> saveSubjectConstraints(
      String schoolId, Map<String, dynamic> constraints);

  // Social media methods
  Future<List<Map<String, dynamic>>> getSocialPosts(String schoolId);
  Future<void> createSocialPost(String schoolId, Map<String, dynamic> post);
  Future<void> deleteSocialPost(String schoolId, String postId);

  // Student management methods
  Future<void> createStudent(String schoolId, Map<String, dynamic> studentData);

  // Notification methods
  Future<List<Map<String, dynamic>>> getStudentNotifications(String studentId);
  Future<void> createNotification(Map<String, dynamic> notificationData);
  Future<void> markNotificationAsRead(String notificationId);
  Future<int> getUnreadNotificationCount(String studentId);

  // Class management methods
  Future<List<Map<String, dynamic>>> getClasses(String schoolId);

  // Exam management methods
  Future<void> createExam(String schoolId, Map<String, dynamic> examData);
  Future<List<Map<String, dynamic>>> getExamsBySchool(String schoolId);
  Future<List<Map<String, dynamic>>> getExamsByTeacher(
      String schoolId, String teacherId);
  Future<void> updateExam(
      String schoolId, String examId, Map<String, dynamic> examData);
  Future<void> deleteExam(String schoolId, String examId);

  // Timetable management methods
  Future<void> setTimetableLesson(Map<String, dynamic> lesson);
  Future<List<Map<String, dynamic>>> getClassTimetableLessons(
      String schoolId, String className);
  Future<List<Map<String, dynamic>>> getTeacherTimetableLessons(
      String schoolId, String teacherId);
  Future<void> removeTimetableLesson(
      String schoolId, String className, String day, String slotId);
  Future<void> saveFullClassTimetable(
      String schoolId, String className, List<Map<String, dynamic>> lessons);

  // Salary management methods
  Future<void> createSalaryRecord(
      String schoolId, Map<String, dynamic> salaryData);
  Future<List<Map<String, dynamic>>> getSalaryRecords(
      String schoolId, String? staffId);
  Future<void> updateSalaryRecord(
      String schoolId, String recordId, Map<String, dynamic> updateData);

  // Report card methods
  Future<void> createReportCard(
      String schoolId, Map<String, dynamic> reportCard);
  Future<List<Map<String, dynamic>>> getStudentReportCards(
      String schoolId, String studentId);
  Future<Map<String, dynamic>> getReportCard(
      String schoolId, String studentId, String term, String year);

  // Library management methods
  Future<void> addBook(String schoolId, Map<String, dynamic> bookData);
  Future<List<Map<String, dynamic>>> getBooks(String schoolId);
  Future<void> borrowBook(String schoolId, Map<String, dynamic> borrowingData);
  Future<void> returnBook(String schoolId, String borrowingId);
  Future<List<Map<String, dynamic>>> getBorrowedBooks(
      String schoolId, String studentId);

  // Scheme of work methods
  Future<void> saveSchemeOfWork(Map<String, dynamic> scheme);
  Future<Map<String, dynamic>> getSchemeOfWork(
      String schoolId, String subject, String className, String term, int year);
  Future<List<Map<String, dynamic>>> getSchemesOfWork(
      String schoolId, Map<String, String> queryParams);

  // Lesson plan methods
  Future<void> saveLessonPlan(String schoolId, Map<String, dynamic> lessonPlan);
  Future<List<Map<String, dynamic>>> getLessonPlans(
      String schoolId, String teacherId, Map<String, String> queryParams);

  // Student enrollment (returns a map with created entities, e.g. user_id)
  Future<Map<String, dynamic>> enrollStudent({
    required String schoolId,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String dateOfBirth,
    required String className,
    String? stream,
    String? sex,
    String? religion,
    String? address,
    String? phoneNumber,
    String? parentName,
    String? parentNin,
    String? parentContact,
    String? specialNeeds,
    List<String>? subjectCodes,
    String? admissionNumber,
  });

  // Attendance & Gradebook methods
  Future<void> saveAttendanceRecord(
      String schoolId, Map<String, dynamic> attendanceRecord);
  Future<List<Map<String, dynamic>>> getAttendanceRecords(
      String schoolId, Map<String, String> queryParams);
  Future<Map<String, dynamic>> getStudentAttendanceSummary(
      String schoolId, String studentId, String term, int year);
  Future<void> saveGradeBookEntry(
      String schoolId, Map<String, dynamic> gradeBookEntry);
  Future<List<Map<String, dynamic>>> getGradeBookEntries(
      String schoolId, Map<String, String> queryParams);
  Future<Map<String, dynamic>> getStudentGradeBookSummary(
      String schoolId, String studentId, String subject, String term, int year);

  // Additional missing methods
  Future<List<Map<String, dynamic>>> getStudentApplications(String schoolId);
  Future<void> updateStudentApplication(
      String schoolId, String applicationId, Map<String, dynamic> updateData);
  Future<List<Map<String, dynamic>>> getFeeStructures(String schoolId);
  Future<void> createFeeStructure(
      String schoolId, Map<String, dynamic> structure);
  Future<void> updateFeeStructure(
      String schoolId, String structureId, Map<String, dynamic> structure);

  // Generic utilities and user helpers expected by tests/server
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String hashedPassword,
    required Map<String, dynamic> otherData,
  });

  Future<String> createPasswordResetToken(String email, String userId);

  Future<void> delete(String itemType, int itemId);

  /// Close any underlying database connections
  Future<void> close();

  // Students retrieval with optional query params (filter/pagination)
  Future<List<Map<String, dynamic>>> getStudentsBySchool(String schoolId,
      [Map<String, String>? queryParams]);

  Future<Map<String, dynamic>> getStudentFeeBalance(String studentId);

  // Accept an update data map instead of a single role string
  Future<void> updateUserRole(String userId, Map<String, dynamic> updateData);

  // Record a fee payment; paymentData may include schoolId
  Future<void> recordFeePayment(Map<String, dynamic> paymentData);

  // Allow calling without arguments
  Future<void> ingestChemistryCurriculum(
      [Map<String, dynamic>? curriculumData]);

  // Parent-student linking helpers used by tests
  Future<void> linkParentToStudents(
      {required String parentUserId, required List<String> studentIds});
  Future<List<Map<String, dynamic>>> getStudentsByParentId(String parentUserId);
}

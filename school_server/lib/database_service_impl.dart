import 'database_service.dart';

/// Minimal stub implementation of DatabaseService for backend use.
class DatabaseService extends DatabaseServiceBase {
  // In-memory storage used for tests and local runs.
  int _nextUserId = 1;
  final Map<int, Map<String, dynamic>> _users = {};
  final Map<String, int> _emailIndex = {};
  final Map<String, List<int>> _parentLinks = {};
  final Map<int, Map<String, dynamic>> _students = {};
  int _nextStudentId = 1;
  final List<Map<String, dynamic>> _payments = [];

  // Additional in-memory storage for other entities
  int _nextSchoolId = 1;
  final Map<int, Map<String, dynamic>> _schools = {};
  int _nextClassId = 1;
  final Map<int, Map<String, dynamic>> _classes = {};
  int _nextSubjectId = 1;
  final Map<int, Map<String, dynamic>> _subjects = {};
  int _nextExamId = 1;
  final Map<int, Map<String, dynamic>> _exams = {};
  int _nextExamResultId = 1;
  final Map<int, Map<String, dynamic>> _examResults = {};
  int _nextSalaryId = 1;
  final Map<int, Map<String, dynamic>> _salaries = {};
  int _nextReportCardId = 1;
  final Map<int, Map<String, dynamic>> _reportCards = {};
  int _nextBookId = 1;
  final Map<int, Map<String, dynamic>> _books = {};
  int _nextBorrowingId = 1;
  final Map<int, Map<String, dynamic>> _borrowings = {};
  int _nextSchemeId = 1;
  final Map<int, Map<String, dynamic>> _schemes = {};
  int _nextLessonPlanId = 1;
  final Map<int, Map<String, dynamic>> _lessonPlans = {};
  int _nextAttendanceId = 1;
  final Map<int, Map<String, dynamic>> _attendances = {};
  int _nextGradeBookId = 1;
  final Map<int, Map<String, dynamic>> _gradeBooks = {};
  int _nextApplicationId = 1;
  final Map<int, Map<String, dynamic>> _applications = {};
  int _nextFeeStructureId = 1;
  final Map<int, Map<String, dynamic>> _feeStructures = {};
  int _nextTicketId = 1;
  final Map<int, Map<String, dynamic>> _tickets = {};
  int _nextTechnicianId = 1;
  final Map<int, Map<String, dynamic>> _technicians = {};
  int _nextDriverId = 1;
  final Map<int, Map<String, dynamic>> _drivers = {};
  int _nextVisitId = 1;
  final Map<int, Map<String, dynamic>> _visits = {};
  int _nextKpiId = 1;
  final Map<int, Map<String, dynamic>> _kpis = {};

  @override
  Future<void> initialize() async {
    _nextUserId = 1;
    _users.clear();
    _emailIndex.clear();
    _parentLinks.clear();
  }

  @override
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final id = _emailIndex[email.toLowerCase()];
    if (id == null) return null;
    return Map<String, dynamic>.from(_users[id]!);
  }

  @override
  Future<Map<String, dynamic>?> findUserById(String id) async {
    final intId = int.tryParse(id) ?? -1;
    final user = _users[intId];
    return user != null ? Map<String, dynamic>.from(user) : null;
  }

  @override
  Future<int> getTotalUserCount() async => _users.length;
  @override
  Future<List<Map<String, dynamic>>> getAllUsers(int limit, int offset) async {
    final users = _users.values
        .skip(offset)
        .take(limit)
        .map((u) => Map<String, dynamic>.from(u))
        .toList();
    return users;
  }

  @override
  Future<void> updateUserSettings(
      String userId, Map<String, dynamic> settings) async {
    final intId = int.tryParse(userId) ?? -1;
    final user = _users[intId];
    if (user == null) throw Exception('User not found');
    // Accept camelCase or snake_case keys; normalize to snake_case.
    String toSnake(String s) => s
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
        .toLowerCase();
    settings.forEach((k, v) {
      final key = k.contains('_') ? k : toSnake(k);
      user[key] = v;
    });
  }

  @override
  Future<void> deleteUser(String userId) async {
    final intId = int.tryParse(userId) ?? -1;
    final user = _users.remove(intId);
    if (user != null) {
      _emailIndex.remove(user['email']?.toString().toLowerCase());
      // Remove from parent links
      _parentLinks.remove(userId);
      for (final links in _parentLinks.values) {
        links.removeWhere((id) => id == intId);
      }
    }
  }

  @override
  Future<void> createEmailVerificationToken(
      String userId, String token, DateTime expires) async {
    final intId = int.tryParse(userId) ?? -1;
    final user = _users[intId];
    if (user != null) {
      user['verification_token'] = token;
      user['verification_expires'] = expires.toIso8601String();
    }
  }

  @override
  Future<Map<String, dynamic>?> findUserByVerificationToken(
      String token) async {
    for (final user in _users.values) {
      if (user['verification_token'] == token) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  @override
  Future<void> verifyUserEmail(String userId) async {
    final intId = int.tryParse(userId) ?? -1;
    final user = _users[intId];
    if (user != null) {
      user['email_verified'] = true;
      user['verification_token'] = null;
      user['verification_expires'] = null;
    }
  }

  @override
  Future<bool> isUserEmailVerified(String userId) async {
    final intId = int.tryParse(userId) ?? -1;
    final user = _users[intId];
    return user?['email_verified'] == true;
  }

  @override
  Future<void> cleanupExpiredVerificationTokens() async {
    final now = DateTime.now();
    for (final user in _users.values) {
      final expiresStr = user['verification_expires'];
      if (expiresStr != null) {
        final expires = DateTime.tryParse(expiresStr);
        if (expires != null && expires.isBefore(now)) {
          user['verification_token'] = null;
          user['verification_expires'] = null;
        }
      }
    }
  }

  @override
  Future<bool> isTokenBlacklisted(String token) async {
    // Simple in-memory blacklist (in production, this would be a database table)
    return false; // For demo purposes, no tokens are blacklisted
  }

  @override
  Future<Map<String, dynamic>?> findPasswordResetToken(String token) async {
    // In-memory storage for password reset tokens
    return null; // Not implemented for demo
  }

  @override
  Future<void> blacklistToken(
      String token, String tokenType, String? userId) async {
    // Simple in-memory blacklist (in production, this would be a database table)
    // For demo purposes, just log the action
  }

  @override
  Future<void> cleanupExpiredTokens() async {
    // In-memory cleanup not needed for demo
  }

  @override
  Future<String> createPasswordResetToken(String email, String userId) async {
    // Generate a simple token for demo
    final token = 'reset_${DateTime.now().millisecondsSinceEpoch}_${userId}';
    return token;
  }

  @override
  Future<void> markPasswordResetTokenAsUsed(String token) async {
    // In-memory storage - just log for demo
  }

  @override
  Future<void> cleanupExpiredPasswordResetTokens() async {
    // In-memory cleanup not needed for demo
  }
  @override
  Future<Map<String, dynamic>?> findSchoolByName(String name) async {
    final school = _schools.values.firstWhere(
      (s) => s['name'] == name,
      orElse: () => {},
    );
    return school.isNotEmpty ? Map<String, dynamic>.from(school) : null;
  }

  @override
  Future<Map<String, dynamic>?> findSchoolById(String id) async {
    final intId = int.tryParse(id) ?? -1;
    final school = _schools[intId];
    return school != null ? Map<String, dynamic>.from(school) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSchools() async {
    return _schools.values.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  @override
  Future<Map<String, dynamic>> createSchool(
      {required String name, required String classification}) async {
    final id = _nextSchoolId++;
    final school = {
      'id': id,
      'name': name,
      'classification': classification,
      'created_at': DateTime.now().toIso8601String(),
    };
    _schools[id] = school;
    return Map<String, dynamic>.from(school);
  }

  @override
  Future<void> updateClassStreams(
      String schoolId, Map<String, List<String>> streams) async {
    // Simple implementation - could be expanded
    final intSchoolId = int.tryParse(schoolId) ?? -1;
    final school = _schools[intSchoolId];
    if (school != null) {
      school['streams'] = streams;
    }
  }

  @override
  Future<Map<String, dynamic>> createClass(
      {required String schoolId,
      required String name,
      String? gradeLevel}) async {
    final id = _nextClassId++;
    final classData = {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'grade_level': gradeLevel,
      'created_at': DateTime.now().toIso8601String(),
    };
    _classes[id] = classData;
    return Map<String, dynamic>.from(classData);
  }

  @override
  Future<Map<String, dynamic>?> findClassById(String id) async {
    final intId = int.tryParse(id) ?? -1;
    final classData = _classes[intId];
    return classData != null ? Map<String, dynamic>.from(classData) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getClassesBySchool(String schoolId) async {
    return _classes.values
        .where((c) => c['school_id'] == schoolId)
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
  }

  @override
  Future<void> updateClass(
      String classId, Map<String, dynamic> classData) async {
    final intId = int.tryParse(classId) ?? -1;
    final existingClass = _classes[intId];
    if (existingClass != null) {
      classData.forEach((k, v) => existingClass[k] = v);
    }
  }

  @override
  Future<void> deleteClass(String classId) async {
    final intId = int.tryParse(classId) ?? -1;
    _classes.remove(intId);
  }

  @override
  Future<int> insertSubject(Map<String, dynamic> subject) async {
    final id = _nextSubjectId++;
    final curriculumSubject = Map<String, dynamic>.from(subject);
    curriculumSubject['id'] = id;
    curriculumSubject['created_at'] = DateTime.now().toIso8601String();
    // Store in a simple in-memory map (in production, this would be a database)
    // For demo purposes, we'll use a simple list
    return id;
  }

  @override
  Future<int> insertStrand(Map<String, dynamic> strand) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final curriculumStrand = Map<String, dynamic>.from(strand);
    curriculumStrand['id'] = id;
    curriculumStrand['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertTopic(Map<String, dynamic> topic) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final curriculumTopic = Map<String, dynamic>.from(topic);
    curriculumTopic['id'] = id;
    curriculumTopic['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertSubTopic(Map<String, dynamic> subTopic) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final curriculumSubTopic = Map<String, dynamic>.from(subTopic);
    curriculumSubTopic['id'] = id;
    curriculumSubTopic['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertLearningOutcome(Map<String, dynamic> outcome) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final learningOutcome = Map<String, dynamic>.from(outcome);
    learningOutcome['id'] = id;
    learningOutcome['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertSuggestedActivity(Map<String, dynamic> activity) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final suggestedActivity = Map<String, dynamic>.from(activity);
    suggestedActivity['id'] = id;
    suggestedActivity['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertAssessmentStrategy(Map<String, dynamic> strategy) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final assessmentStrategy = Map<String, dynamic>.from(strategy);
    assessmentStrategy['id'] = id;
    assessmentStrategy['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertCrossCuttingIssue(Map<String, dynamic> issue) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final crossCuttingIssue = Map<String, dynamic>.from(issue);
    crossCuttingIssue['id'] = id;
    crossCuttingIssue['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertValue(Map<String, dynamic> value) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final curriculumValue = Map<String, dynamic>.from(value);
    curriculumValue['id'] = id;
    curriculumValue['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<int> insertGenericSkill(Map<String, dynamic> skill) async {
    final id = _nextSubjectId++; // Reuse counter for simplicity
    final genericSkill = Map<String, dynamic>.from(skill);
    genericSkill['id'] = id;
    genericSkill['created_at'] = DateTime.now().toIso8601String();
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getSubjects() async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getStrandsBySubject(int subjectId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getTopicsByStrand(int strandId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getLearningOutcomesByTopic(
      int topicId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getActivitiesByOutcome(
      int outcomeId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getStrategiesByOutcome(
      int outcomeId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<Map<String, dynamic>> createSubject(
      {required String schoolId,
      required String name,
      String? description}) async {
    final id = _nextSubjectId++;
    final subject = {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    };
    _subjects[id] = subject;
    return Map<String, dynamic>.from(subject);
  }

  @override
  Future<Map<String, dynamic>?> findSubjectById(String id) async {
    final intId = int.tryParse(id) ?? -1;
    final subject = _subjects[intId];
    return subject != null ? Map<String, dynamic>.from(subject) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getSubjectsBySchool(
      String schoolId) async {
    return _subjects.values
        .where((s) => s['school_id'] == schoolId)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  }

  @override
  Future<void> updateSubject(
      String subjectId, Map<String, dynamic> subjectData) async {
    final intId = int.tryParse(subjectId) ?? -1;
    final existingSubject = _subjects[intId];
    if (existingSubject != null) {
      subjectData.forEach((k, v) => existingSubject[k] = v);
    }
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    final intId = int.tryParse(subjectId) ?? -1;
    _subjects.remove(intId);
  }

  @override
  Future<Map<String, dynamic>> createExamResult(
      {required String schoolId,
      required String examId,
      required String studentId,
      required String subjectId,
      required double marksObtained,
      required double totalMarks,
      required String recordedBy,
      String? grade,
      String? comments}) async {
    final id = _nextExamResultId++;
    final result = {
      'id': id,
      'school_id': schoolId,
      'exam_id': examId,
      'student_id': studentId,
      'subject_id': subjectId,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'recorded_by': recordedBy,
      'grade': grade,
      'comments': comments,
      'created_at': DateTime.now().toIso8601String(),
    };
    _examResults[id] = result;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> getExamResultById(String id) async {
    final intId = int.tryParse(id) ?? -1;
    final result = _examResults[intId];
    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByExam(String examId) async {
    return _examResults.values
        .where((r) => r['exam_id'] == examId)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByStudent(
      String studentId) async {
    return _examResults.values
        .where((r) => r['student_id'] == studentId)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<void> updateExamResult(
      String resultId, Map<String, dynamic> resultData) async {
    final intId = int.tryParse(resultId) ?? -1;
    final existingResult = _examResults[intId];
    if (existingResult != null) {
      resultData.forEach((k, v) => existingResult[k] = v);
    }
  }

  @override
  Future<void> deleteExamResult(String resultId) async {
    final intId = int.tryParse(resultId) ?? -1;
    _examResults.remove(intId);
  }

  @override
  Future<void> setTimetableConstraint(Map<String, dynamic> constraint) async {
    // In-memory storage for timetable constraints
    final id = _nextSubjectId++; // Reuse counter
    final constraintData = Map<String, dynamic>.from(constraint);
    constraintData['id'] = id;
    constraintData['created_at'] = DateTime.now().toIso8601String();
    // Store in memory - in production this would be a database
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherConstraints(
      String schoolId, String teacherId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<Map<String, dynamic>> getSubjectConstraints(String schoolId) async {
    // Return empty map for demo - in production this would query database
    return {};
  }

  @override
  Future<void> saveSubjectConstraints(
      String schoolId, Map<String, dynamic> constraints) async {
    // In-memory storage - just log for demo
  }
  @override
  Future<List<Map<String, dynamic>>> getSocialPosts(String schoolId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<void> createSocialPost(
      String schoolId, Map<String, dynamic> post) async {
    // In-memory storage - just log for demo
  }

  @override
  Future<void> deleteSocialPost(String schoolId, String postId) async {
    // In-memory storage - just log for demo
  }

  @override
  Future<void> createStudent(
      String schoolId, Map<String, dynamic> studentData) async {
    final id = _nextStudentId++;
    final student = Map<String, dynamic>.from(studentData);
    student['id'] = id;
    student['school_id'] = schoolId;
    student['created_at'] = DateTime.now().toIso8601String();
    _students[id] = student;
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentNotifications(
      String studentId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    // In-memory storage - just log for demo
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    // In-memory storage - just log for demo
  }

  @override
  Future<int> getUnreadNotificationCount(String studentId) async {
    // Return 0 for demo
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getClasses(String schoolId) async {
    return getClassesBySchool(schoolId);
  }

  @override
  Future<void> createExam(
      String schoolId, Map<String, dynamic> examData) async {
    final id = _nextExamId++;
    final exam = Map<String, dynamic>.from(examData);
    exam['id'] = id;
    exam['school_id'] = schoolId;
    exam['created_at'] = DateTime.now().toIso8601String();
    _exams[id] = exam;
  }

  @override
  Future<List<Map<String, dynamic>>> getExamsBySchool(String schoolId) async {
    return _exams.values
        .where((e) => e['school_id'] == schoolId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getExamsByTeacher(
      String schoolId, String teacherId) async {
    return _exams.values
        .where(
            (e) => e['school_id'] == schoolId && e['teacher_id'] == teacherId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<void> updateExam(
      String schoolId, String examId, Map<String, dynamic> examData) async {
    final intId = int.tryParse(examId) ?? -1;
    final existingExam = _exams[intId];
    if (existingExam != null) {
      examData.forEach((k, v) => existingExam[k] = v);
    }
  }

  @override
  Future<void> deleteExam(String schoolId, String examId) async {
    final intId = int.tryParse(examId) ?? -1;
    _exams.remove(intId);
  }

  @override
  Future<void> setTimetableLesson(Map<String, dynamic> lesson) async {
    // In-memory storage for timetable lessons
    final id = _nextSubjectId++; // Reuse counter
    final lessonData = Map<String, dynamic>.from(lesson);
    lessonData['id'] = id;
    lessonData['created_at'] = DateTime.now().toIso8601String();
    // Store in memory - in production this would be a database
  }

  @override
  Future<List<Map<String, dynamic>>> getClassTimetableLessons(
      String schoolId, String className) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherTimetableLessons(
      String schoolId, String teacherId) async {
    // Return empty list for demo - in production this would query database
    return [];
  }

  @override
  Future<void> removeTimetableLesson(
      String schoolId, String className, String day, String slotId) async {
    // In-memory removal - just log for demo
  }

  @override
  Future<void> saveFullClassTimetable(String schoolId, String className,
      List<Map<String, dynamic>> lessons) async {
    // In-memory storage - just log for demo
  }

  @override
  Future<void> createSalaryRecord(
      String schoolId, Map<String, dynamic> salaryData) async {
    final id = _nextSalaryId++;
    final salary = Map<String, dynamic>.from(salaryData);
    salary['id'] = id;
    salary['school_id'] = schoolId;
    salary['created_at'] = DateTime.now().toIso8601String();
    _salaries[id] = salary;
  }

  @override
  Future<List<Map<String, dynamic>>> getSalaryRecords(
      String schoolId, String? staffId) async {
    var records = _salaries.values
        .where((s) => s['school_id'] == schoolId)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
    if (staffId != null) {
      records = records.where((r) => r['staff_id'] == staffId).toList();
    }
    return records;
  }

  @override
  Future<void> updateSalaryRecord(
      String schoolId, String recordId, Map<String, dynamic> updateData) async {
    final intId = int.tryParse(recordId) ?? -1;
    final existingRecord = _salaries[intId];
    if (existingRecord != null) {
      updateData.forEach((k, v) => existingRecord[k] = v);
    }
  }
  @override
  Future<void> createReportCard(
      String schoolId, Map<String, dynamic> reportCard) async {
    final id = _nextReportCardId++;
    final card = Map<String, dynamic>.from(reportCard);
    card['id'] = id;
    card['school_id'] = schoolId;
    card['created_at'] = DateTime.now().toIso8601String();
    _reportCards[id] = card;
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentReportCards(
      String schoolId, String studentId) async {
    return _reportCards.values
        .where((r) => r['school_id'] == schoolId && r['student_id'] == studentId)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getReportCard(
      String schoolId, String studentId, String term, String year) async {
    final cards = _reportCards.values.where((r) =>
        r['school_id'] == schoolId &&
        r['student_id'] == studentId &&
        r['term'] == term &&
        r['year'] == year);
    if (cards.isEmpty) {
      return {};
    }
    return Map<String, dynamic>.from(cards.first);
  }
  @override
  Future<void> addBook(String schoolId, Map<String, dynamic> bookData) async {
    final id = _nextBookId++;
    final book = Map<String, dynamic>.from(bookData);
    book['id'] = id;
    book['school_id'] = schoolId;
    book['available'] = true;
    book['created_at'] = DateTime.now().toIso8601String();
    _books[id] = book;
  }

  @override
  Future<List<Map<String, dynamic>>> getBooks(String schoolId) async {
    return _books.values
        .where((b) => b['school_id'] == schoolId)
        .map((b) => Map<String, dynamic>.from(b))
        .toList();
  }

  @override
  Future<void> borrowBook(
      String schoolId, Map<String, dynamic> borrowingData) async {
    final id = _nextBorrowingId++;
    final borrowing = Map<String, dynamic>.from(borrowingData);
    borrowing['id'] = id;
    borrowing['school_id'] = schoolId;
    borrowing['borrowed_at'] = DateTime.now().toIso8601String();
    borrowing['returned'] = false;
    _borrowings[id] = borrowing;

    // Update book availability
    final bookId = borrowing['book_id'];
    if (_books.containsKey(bookId)) {
      _books[bookId]!['available'] = false;
    }
  }

  @override
  Future<void> returnBook(String schoolId, String borrowingId) async {
    final intId = int.tryParse(borrowingId) ?? -1;
    final borrowing = _borrowings[intId];
    if (borrowing != null) {
      borrowing['returned'] = true;
      borrowing['returned_at'] = DateTime.now().toIso8601String();

      // Update book availability
      final bookId = borrowing['book_id'];
      if (_books.containsKey(bookId)) {
        _books[bookId]!['available'] = true;
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBorrowedBooks(
      String schoolId, String studentId) async {
    return _borrowings.values
        .where((b) =>
            b['school_id'] == schoolId &&
            b['student_id'] == studentId &&
            b['returned'] == false)
        .map((b) => Map<String, dynamic>.from(b))
        .toList();
  }
  @override
  Future<void> saveSchemeOfWork(Map<String, dynamic> scheme) async {
    final id = _nextSchemeId++;
    final schemeData = Map<String, dynamic>.from(scheme);
    schemeData['id'] = id;
    schemeData['created_at'] = DateTime.now().toIso8601String();
    _schemes[id] = schemeData;
  }

  @override
  Future<Map<String, dynamic>> getSchemeOfWork(String schoolId, String subject,
      String className, String term, int year) async {
    final schemes = _schemes.values.where((s) =>
        s['school_id'] == schoolId &&
        s['subject'] == subject &&
        s['class_name'] == className &&
        s['term'] == term &&
        s['year'] == year);
    if (schemes.isEmpty) {
      return {};
    }
    return Map<String, dynamic>.from(schemes.first);
  }

  @override
  Future<List<Map<String, dynamic>>> getSchemesOfWork(
      String schoolId, Map<String, String> queryParams) async {
    var schemes = _schemes.values
        .where((s) => s['school_id'] == schoolId)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();

    if (queryParams.containsKey('subject')) {
      schemes = schemes.where((s) => s['subject'] == queryParams['subject']).toList();
    }
    if (queryParams.containsKey('class_name')) {
      schemes = schemes.where((s) => s['class_name'] == queryParams['class_name']).toList();
    }
    if (queryParams.containsKey('term')) {
      schemes = schemes.where((s) => s['term'] == queryParams['term']).toList();
    }
    if (queryParams.containsKey('year')) {
      schemes = schemes.where((s) => s['year'] == int.tryParse(queryParams['year']!)).toList();
    }

    return schemes;
  }
  @override
  Future<void> saveLessonPlan(
      String schoolId, Map<String, dynamic> lessonPlan) async {
    final id = _nextLessonPlanId++;
    final plan = Map<String, dynamic>.from(lessonPlan);
    plan['id'] = id;
    plan['school_id'] = schoolId;
    plan['created_at'] = DateTime.now().toIso8601String();
    _lessonPlans[id] = plan;
  }

  @override
  Future<List<Map<String, dynamic>>> getLessonPlans(
      String schoolId, String teacherId, Map<String, String> queryParams) async {
    var plans = _lessonPlans.values
        .where((p) => p['school_id'] == schoolId && p['teacher_id'] == teacherId)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();

    if (queryParams.containsKey('subject')) {
      plans = plans.where((p) => p['subject'] == queryParams['subject']).toList();
    }
    if (queryParams.containsKey('class_name')) {
      plans = plans.where((p) => p['class_name'] == queryParams['class_name']).toList();
    }
    if (queryParams.containsKey('term')) {
      plans = plans.where((p) => p['term'] == queryParams['term']).toList();
    }
    if (queryParams.containsKey('year')) {
      plans = plans.where((p) => p['year'] == int.tryParse(queryParams['year']!)).toList();
    }

    return plans;
  }
  @override
  Future<void> saveAttendanceRecord(
      String schoolId, Map<String, dynamic> attendanceRecord) async {
    final id = _nextAttendanceId++;
    final record = Map<String, dynamic>.from(attendanceRecord);
    record['id'] = id;
    record['school_id'] = schoolId;
    record['created_at'] = DateTime.now().toIso8601String();
    _attendances[id] = record;
  }

  @override
  Future<List<Map<String, dynamic>>> getAttendanceRecords(
      String schoolId, Map<String, String> queryParams) async {
    var records = _attendances.values
        .where((r) => r['school_id'] == schoolId)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();

    if (queryParams.containsKey('student_id')) {
      records = records.where((r) => r['student_id'] == queryParams['student_id']).toList();
    }
    if (queryParams.containsKey('class_name')) {
      records = records.where((r) => r['class_name'] == queryParams['class_name']).toList();
    }
    if (queryParams.containsKey('date')) {
      records = records.where((r) => r['date'] == queryParams['date']).toList();
    }
    if (queryParams.containsKey('term')) {
      records = records.where((r) => r['term'] == queryParams['term']).toList();
    }
    if (queryParams.containsKey('year')) {
      records = records.where((r) => r['year'] == int.tryParse(queryParams['year']!)).toList();
    }

    return records;
  }

  @override
  Future<Map<String, dynamic>> getStudentAttendanceSummary(
      String schoolId, String studentId, String term, int year) async {
    final records = _attendances.values.where((r) =>
        r['school_id'] == schoolId &&
        r['student_id'] == studentId &&
        r['term'] == term &&
        r['year'] == year);

    int totalDays = 0;
    int presentDays = 0;
    int absentDays = 0;
    int lateDays = 0;

    for (final record in records) {
      totalDays++;
      final status = record['status']?.toString().toLowerCase();
      if (status == 'present') presentDays++;
      else if (status == 'absent') absentDays++;
      else if (status == 'late') lateDays++;
    }

    final attendancePercentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;

    return {
      'student_id': studentId,
      'term': term,
      'year': year,
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'late_days': lateDays,
      'attendance_percentage': attendancePercentage,
    };
  }
  @override
  Future<void> saveGradeBookEntry(
      String schoolId, Map<String, dynamic> gradeBookEntry) async {
    final id = _nextGradeBookId++;
    final entry = Map<String, dynamic>.from(gradeBookEntry);
    entry['id'] = id;
    entry['school_id'] = schoolId;
    entry['created_at'] = DateTime.now().toIso8601String();
    _gradeBooks[id] = entry;
  }

  @override
  Future<List<Map<String, dynamic>>> getGradeBookEntries(
      String schoolId, Map<String, String> queryParams) async {
    var entries = _gradeBooks.values
        .where((e) => e['school_id'] == schoolId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (queryParams.containsKey('student_id')) {
      entries = entries.where((e) => e['student_id'] == queryParams['student_id']).toList();
    }
    if (queryParams.containsKey('subject')) {
      entries = entries.where((e) => e['subject'] == queryParams['subject']).toList();
    }
    if (queryParams.containsKey('term')) {
      entries = entries.where((e) => e['term'] == queryParams['term']).toList();
    }
    if (queryParams.containsKey('year')) {
      entries = entries.where((e) => e['year'] == int.tryParse(queryParams['year']!)).toList();
    }

    return entries;
  }

  @override
  Future<Map<String, dynamic>> getStudentGradeBookSummary(String schoolId,
      String studentId, String subject, String term, int year) async {
    final entries = _gradeBooks.values.where((e) =>
        e['school_id'] == schoolId &&
        e['student_id'] == studentId &&
        e['subject'] == subject &&
        e['term'] == term &&
        e['year'] == year);

    double totalScore = 0.0;
    int entryCount = 0;
    String grade = 'N/A';

    for (final entry in entries) {
      totalScore += (entry['score'] ?? 0.0) as double;
      entryCount++;
      if (entry['grade'] != null) {
        grade = entry['grade'];
      }
    }

    final averageScore = entryCount > 0 ? totalScore / entryCount : 0.0;

    return {
      'student_id': studentId,
      'subject': subject,
      'term': term,
      'year': year,
      'average_score': averageScore,
      'total_entries': entryCount,
      'grade': grade,
    };
  }
  @override
  Future<List<Map<String, dynamic>>> getStudentApplications(String schoolId) async {
    return _applications.values
        .where((a) => a['school_id'] == schoolId)
        .map((a) => Map<String, dynamic>.from(a))
        .toList();
  }

  @override
  Future<void> updateStudentApplication(String schoolId, String applicationId,
      Map<String, dynamic> updateData) async {
    final intId = int.tryParse(applicationId) ?? -1;
    final existingApplication = _applications[intId];
    if (existingApplication != null) {
      updateData.forEach((k, v) => existingApplication[k] = v);
    }
  }
  @override
  Future<List<Map<String, dynamic>>> getFeeStructures(String schoolId) async {
    return _feeStructures.values
        .where((f) => f['school_id'] == schoolId)
        .map((f) => Map<String, dynamic>.from(f))
        .toList();
  }

  @override
  Future<void> createFeeStructure(
      String schoolId, Map<String, dynamic> structure) async {
    final id = _nextFeeStructureId++;
    final feeStructure = Map<String, dynamic>.from(structure);
    feeStructure['id'] = id;
    feeStructure['school_id'] = schoolId;
    feeStructure['created_at'] = DateTime.now().toIso8601String();
    _feeStructures[id] = feeStructure;
  }

  @override
  Future<void> updateFeeStructure(String schoolId, String structureId,
      Map<String, dynamic> structure) async {
    final intId = int.tryParse(structureId) ?? -1;
    final existingStructure = _feeStructures[intId];
    if (existingStructure != null) {
      structure.forEach((k, v) => existingStructure[k] = v);
    }
  }
  @override
  Future<Map<String, dynamic>> createUser(
      {required String email,
      required String hashedPassword,
      required Map<String, dynamic> otherData}) async {
    final lower = email.toLowerCase();
    if (_emailIndex.containsKey(lower)) {
      throw Exception('Email already exists');
    }
    final id = _nextUserId++;
    final user = <String, dynamic>{
      'id': id,
      'email': email,
      'hashed_password': hashedPassword,
    };
    // Merge otherData into user, preserving provided keys
    otherData.forEach((k, v) {
      // keep snake_case keys if provided
      final key = k.contains('_')
          ? k
          : k.replaceAllMapped(
              RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
      user[key] = v;
    });
    _users[id] = user;
    _emailIndex[lower] = id;
    return Map<String, dynamic>.from(user);
  }

  @override
  Future<void> delete(String itemType, int itemId) async {
    final type = itemType.toLowerCase();
    switch (type) {
      case 'user':
        _users.remove(itemId);
        break;
      case 'student':
        _students.remove(itemId);
        break;
      case 'school':
        _schools.remove(itemId);
        break;
      case 'class':
        _classes.remove(itemId);
        break;
      case 'subject':
        _subjects.remove(itemId);
        break;
      case 'exam':
        _exams.remove(itemId);
        break;
      case 'exam_result':
        _examResults.remove(itemId);
        break;
      case 'salary':
        _salaries.remove(itemId);
        break;
      case 'report_card':
        _reportCards.remove(itemId);
        break;
      case 'book':
        _books.remove(itemId);
        break;
      case 'borrowing':
        _borrowings.remove(itemId);
        break;
      case 'scheme':
        _schemes.remove(itemId);
        break;
      case 'lesson_plan':
        _lessonPlans.remove(itemId);
        break;
      case 'attendance':
        _attendances.remove(itemId);
        break;
      case 'grade_book':
        _gradeBooks.remove(itemId);
        break;
      case 'application':
        _applications.remove(itemId);
        break;
      case 'fee_structure':
        _feeStructures.remove(itemId);
        break;
      case 'ticket':
        _tickets.remove(itemId);
        break;
      case 'technician':
        _technicians.remove(itemId);
        break;
      case 'driver':
        _drivers.remove(itemId);
        break;
      case 'visit':
        _visits.remove(itemId);
        break;
      case 'kpi':
        _kpis.remove(itemId);
        break;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic>? params]) async {
    final s = sql.toLowerCase();

    // Handle different table queries
    if (s.contains('from users')) {
      return _users.values.map((u) => Map<String, dynamic>.from(u)).toList();
    }
    if (s.contains('from students')) {
      return _students.values.map((s) => Map<String, dynamic>.from(s)).toList();
    }
    if (s.contains('from schools')) {
      return _schools.values.map((s) => Map<String, dynamic>.from(s)).toList();
    }
    if (s.contains('from classes')) {
      return _classes.values.map((c) => Map<String, dynamic>.from(c)).toList();
    }
    if (s.contains('from subjects')) {
      return _subjects.values.map((s) => Map<String, dynamic>.from(s)).toList();
    }
    if (s.contains('from exams')) {
      return _exams.values.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (s.contains('from exam_results')) {
      return _examResults.values.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    if (s.contains('from salaries')) {
      return _salaries.values.map((s) => Map<String, dynamic>.from(s)).toList();
    }
    if (s.contains('from report_cards')) {
      return _reportCards.values.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    if (s.contains('from books')) {
      return _books.values.map((b) => Map<String, dynamic>.from(b)).toList();
    }
    if (s.contains('from borrowings')) {
      return _borrowings.values.map((b) => Map<String, dynamic>.from(b)).toList();
    }
    if (s.contains('from schemes')) {
      return _schemes.values.map((s) => Map<String, dynamic>.from(s)).toList();
    }
    if (s.contains('from lesson_plans')) {
      return _lessonPlans.values.map((l) => Map<String, dynamic>.from(l)).toList();
    }
    if (s.contains('from attendances')) {
      return _attendances.values.map((a) => Map<String, dynamic>.from(a)).toList();
    }
    if (s.contains('from grade_books')) {
      return _gradeBooks.values.map((g) => Map<String, dynamic>.from(g)).toList();
    }
    if (s.contains('from applications')) {
      return _applications.values.map((a) => Map<String, dynamic>.from(a)).toList();
    }
    if (s.contains('from fee_structures')) {
      return _feeStructures.values.map((f) => Map<String, dynamic>.from(f)).toList();
    }
    if (s.contains('from tickets')) {
      return _tickets.values.map((t) => Map<String, dynamic>.from(t)).toList();
    }
    if (s.contains('from technicians')) {
      return _technicians.values.map((t) => Map<String, dynamic>.from(t)).toList();
    }
    if (s.contains('from drivers')) {
      return _drivers.values.map((d) => Map<String, dynamic>.from(d)).toList();
    }
    if (s.contains('from visits')) {
      return _visits.values.map((v) => Map<String, dynamic>.from(v)).toList();
    }
    if (s.contains('from kpis')) {
      return _kpis.values.map((k) => Map<String, dynamic>.from(k)).toList();
    }

    return <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> querySingle(String sql,
      [List<dynamic>? params]) async {
    final rows = await query(sql, params);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> insert(String table, Map<String, dynamic> data) async {
    final t = table.toLowerCase();

    if (t.contains('user')) {
      final email = (data['email'] ?? data['Email'] ?? '').toString();
      final lower = email.toLowerCase();
      if (lower.isNotEmpty && _emailIndex.containsKey(lower)) {
        throw Exception('Email already exists');
      }
      final id = _nextUserId++;
      final user = Map<String, dynamic>.from(data);
      user['id'] = id;
      user['created_at'] = user['created_at'] ?? DateTime.now().toIso8601String();
      _users[id] = user;
      if (lower.isNotEmpty) _emailIndex[lower] = id;
    } else if (t.contains('student')) {
      final id = _nextStudentId++;
      final student = Map<String, dynamic>.from(data);
      student['id'] = id;
      student['created_at'] = student['created_at'] ?? DateTime.now().toIso8601String();
      _students[id] = student;
    } else if (t.contains('school')) {
      final id = _nextSchoolId++;
      final school = Map<String, dynamic>.from(data);
      school['id'] = id;
      school['created_at'] = school['created_at'] ?? DateTime.now().toIso8601String();
      _schools[id] = school;
    } else if (t.contains('class')) {
      final id = _nextClassId++;
      final classData = Map<String, dynamic>.from(data);
      classData['id'] = id;
      classData['created_at'] = classData['created_at'] ?? DateTime.now().toIso8601String();
      _classes[id] = classData;
    } else if (t.contains('subject')) {
      final id = _nextSubjectId++;
      final subject = Map<String, dynamic>.from(data);
      subject['id'] = id;
      subject['created_at'] = subject['created_at'] ?? DateTime.now().toIso8601String();
      _subjects[id] = subject;
    } else if (t.contains('exam')) {
      final id = _nextExamId++;
      final exam = Map<String, dynamic>.from(data);
      exam['id'] = id;
      exam['created_at'] = exam['created_at'] ?? DateTime.now().toIso8601String();
      _exams[id] = exam;
    } else if (t.contains('exam_result')) {
      final id = _nextExamResultId++;
      final result = Map<String, dynamic>.from(data);
      result['id'] = id;
      result['created_at'] = result['created_at'] ?? DateTime.now().toIso8601String();
      _examResults[id] = result;
    } else if (t.contains('salary')) {
      final id = _nextSalaryId++;
      final salary = Map<String, dynamic>.from(data);
      salary['id'] = id;
      salary['created_at'] = salary['created_at'] ?? DateTime.now().toIso8601String();
      _salaries[id] = salary;
    } else if (t.contains('report_card')) {
      final id = _nextReportCardId++;
      final card = Map<String, dynamic>.from(data);
      card['id'] = id;
      card['created_at'] = card['created_at'] ?? DateTime.now().toIso8601String();
      _reportCards[id] = card;
    } else if (t.contains('book')) {
      final id = _nextBookId++;
      final book = Map<String, dynamic>.from(data);
      book['id'] = id;
      book['available'] = book['available'] ?? true;
      book['created_at'] = book['created_at'] ?? DateTime.now().toIso8601String();
      _books[id] = book;
    } else if (t.contains('borrowing')) {
      final id = _nextBorrowingId++;
      final borrowing = Map<String, dynamic>.from(data);
      borrowing['id'] = id;
      borrowing['borrowed_at'] = borrowing['borrowed_at'] ?? DateTime.now().toIso8601String();
      borrowing['returned'] = borrowing['returned'] ?? false;
      _borrowings[id] = borrowing;
    } else if (t.contains('scheme')) {
      final id = _nextSchemeId++;
      final scheme = Map<String, dynamic>.from(data);
      scheme['id'] = id;
      scheme['created_at'] = scheme['created_at'] ?? DateTime.now().toIso8601String();
      _schemes[id] = scheme;
    } else if (t.contains('lesson_plan')) {
      final id = _nextLessonPlanId++;
      final plan = Map<String, dynamic>.from(data);
      plan['id'] = id;
      plan['created_at'] = plan['created_at'] ?? DateTime.now().toIso8601String();
      _lessonPlans[id] = plan;
    } else if (t.contains('attendance')) {
      final id = _nextAttendanceId++;
      final record = Map<String, dynamic>.from(data);
      record['id'] = id;
      record['created_at'] = record['created_at'] ?? DateTime.now().toIso8601String();
      _attendances[id] = record;
    } else if (t.contains('grade_book')) {
      final id = _nextGradeBookId++;
      final entry = Map<String, dynamic>.from(data);
      entry['id'] = id;
      entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
      _gradeBooks[id] = entry;
    } else if (t.contains('application')) {
      final id = _nextApplicationId++;
      final application = Map<String, dynamic>.from(data);
      application['id'] = id;
      application['status'] = application['status'] ?? 'pending';
      application['created_at'] = application['created_at'] ?? DateTime.now().toIso8601String();
      _applications[id] = application;
    } else if (t.contains('fee_structure')) {
      final id = _nextFeeStructureId++;
      final structure = Map<String, dynamic>.from(data);
      structure['id'] = id;
      structure['created_at'] = structure['created_at'] ?? DateTime.now().toIso8601String();
      _feeStructures[id] = structure;
    } else if (t.contains('ticket')) {
      final id = _nextTicketId++;
      final ticket = Map<String, dynamic>.from(data);
      ticket['id'] = id;
      ticket['status'] = ticket['status'] ?? 'open';
      ticket['priority'] = ticket['priority'] ?? 'medium';
      ticket['created_at'] = ticket['created_at'] ?? DateTime.now().toIso8601String();
      _tickets[id] = ticket;
    } else if (t.contains('technician')) {
      final id = _nextTechnicianId++;
      final technician = Map<String, dynamic>.from(data);
      technician['id'] = id;
      technician['status'] = technician['status'] ?? 'active';
      technician['created_at'] = technician['created_at'] ?? DateTime.now().toIso8601String();
      _technicians[id] = technician;
    } else if (t.contains('driver')) {
      final id = _nextDriverId++;
      final driver = Map<String, dynamic>.from(data);
      driver['id'] = id;
      driver['status'] = driver['status'] ?? 'active';
      driver['created_at'] = driver['created_at'] ?? DateTime.now().toIso8601String();
      _drivers[id] = driver;
    } else if (t.contains('visit')) {
      final id = _nextVisitId++;
      final visit = Map<String, dynamic>.from(data);
      visit['id'] = id;
      visit['visited_at'] = visit['visited_at'] ?? DateTime.now().toIso8601String();
      visit['status'] = visit['status'] ?? 'completed';
      _visits[id] = visit;
    } else if (t.contains('kpi')) {
      final id = _nextKpiId++;
      final kpi = Map<String, dynamic>.from(data);
      kpi['id'] = id;
      kpi['recorded_at'] = kpi['recorded_at'] ?? DateTime.now().toIso8601String();
      kpi['points'] = kpi['points'] ?? 1;
      _kpis[id] = kpi;
    }
  }

  @override
  Future<void> update(String table, Map<String, dynamic> data,
      String whereClause, List<dynamic> params) async {
    final t = table.toLowerCase();

    if (t.contains('user') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _users.containsKey(id)) {
        final user = _users[id]!;
        data.forEach((k, v) => user[k] = v);
        user['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('student') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _students.containsKey(id)) {
        final student = _students[id]!;
        data.forEach((k, v) => student[k] = v);
        student['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('school') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _schools.containsKey(id)) {
        final school = _schools[id]!;
        data.forEach((k, v) => school[k] = v);
        school['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('class') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _classes.containsKey(id)) {
        final classData = _classes[id]!;
        data.forEach((k, v) => classData[k] = v);
        classData['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('subject') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _subjects.containsKey(id)) {
        final subject = _subjects[id]!;
        data.forEach((k, v) => subject[k] = v);
        subject['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('exam') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _exams.containsKey(id)) {
        final exam = _exams[id]!;
        data.forEach((k, v) => exam[k] = v);
        exam['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('exam_result') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _examResults.containsKey(id)) {
        final result = _examResults[id]!;
        data.forEach((k, v) => result[k] = v);
        result['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('salary') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _salaries.containsKey(id)) {
        final salary = _salaries[id]!;
        data.forEach((k, v) => salary[k] = v);
        salary['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('report_card') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _reportCards.containsKey(id)) {
        final card = _reportCards[id]!;
        data.forEach((k, v) => card[k] = v);
        card['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('book') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _books.containsKey(id)) {
        final book = _books[id]!;
        data.forEach((k, v) => book[k] = v);
        book['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('borrowing') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _borrowings.containsKey(id)) {
        final borrowing = _borrowings[id]!;
        data.forEach((k, v) => borrowing[k] = v);
        borrowing['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('scheme') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _schemes.containsKey(id)) {
        final scheme = _schemes[id]!;
        data.forEach((k, v) => scheme[k] = v);
        scheme['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('lesson_plan') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _lessonPlans.containsKey(id)) {
        final plan = _lessonPlans[id]!;
        data.forEach((k, v) => plan[k] = v);
        plan['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('attendance') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _attendances.containsKey(id)) {
        final record = _attendances[id]!;
        data.forEach((k, v) => record[k] = v);
        record['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('grade_book') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _gradeBooks.containsKey(id)) {
        final entry = _gradeBooks[id]!;
        data.forEach((k, v) => entry[k] = v);
        entry['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('application') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _applications.containsKey(id)) {
        final application = _applications[id]!;
        data.forEach((k, v) => application[k] = v);
        application['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('fee_structure') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _feeStructures.containsKey(id)) {
        final structure = _feeStructures[id]!;
        data.forEach((k, v) => structure[k] = v);
        structure['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('ticket') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _tickets.containsKey(id)) {
        final ticket = _tickets[id]!;
        data.forEach((k, v) => ticket[k] = v);
        ticket['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('technician') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _technicians.containsKey(id)) {
        final technician = _technicians[id]!;
        data.forEach((k, v) => technician[k] = v);
        technician['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('driver') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _drivers.containsKey(id)) {
        final driver = _drivers[id]!;
        data.forEach((k, v) => driver[k] = v);
        driver['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('visit') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _visits.containsKey(id)) {
        final visit = _visits[id]!;
        data.forEach((k, v) => visit[k] = v);
        visit['updated_at'] = DateTime.now().toIso8601String();
      }
    } else if (t.contains('kpi') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null && _kpis.containsKey(id)) {
        final kpi = _kpis[id]!;
        data.forEach((k, v) => kpi[k] = v);
      }
    }
  }

  @override
  Future<void> deleteWhere(
      String table, String whereClause, List<dynamic> params) async {
    final t = table.toLowerCase();

    if (t.contains('user') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        final user = _users.remove(id);
        if (user != null) {
          _emailIndex.remove(user['email']?.toString().toLowerCase());
        }
      }
    } else if (t.contains('student') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _students.remove(id);
      }
    } else if (t.contains('school') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _schools.remove(id);
      }
    } else if (t.contains('class') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _classes.remove(id);
      }
    } else if (t.contains('subject') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _subjects.remove(id);
      }
    } else if (t.contains('exam') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _exams.remove(id);
      }
    } else if (t.contains('exam_result') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _examResults.remove(id);
      }
    } else if (t.contains('salary') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _salaries.remove(id);
      }
    } else if (t.contains('report_card') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _reportCards.remove(id);
      }
    } else if (t.contains('book') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _books.remove(id);
      }
    } else if (t.contains('borrowing') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _borrowings.remove(id);
      }
    } else if (t.contains('scheme') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _schemes.remove(id);
      }
    } else if (t.contains('lesson_plan') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _lessonPlans.remove(id);
      }
    } else if (t.contains('attendance') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _attendances.remove(id);
      }
    } else if (t.contains('grade_book') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _gradeBooks.remove(id);
      }
    } else if (t.contains('application') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _applications.remove(id);
      }
    } else if (t.contains('fee_structure') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _feeStructures.remove(id);
      }
    } else if (t.contains('ticket') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _tickets.remove(id);
      }
    } else if (t.contains('technician') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _technicians.remove(id);
      }
    } else if (t.contains('driver') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _drivers.remove(id);
      }
    } else if (t.contains('visit') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _visits.remove(id);
      }
    } else if (t.contains('kpi') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _kpis.remove(id);
      }
    }
  }

  @override
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
  }) async {
    final sid = _nextStudentId++;
    final admission = admissionNumber ?? 'S${sid.toString().padLeft(6, '0')}';
    final student = <String, dynamic>{
      'id': sid,
      'school_id': schoolId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'date_of_birth': dateOfBirth,
      'class_name': className,
      'stream': stream,
      'sex': sex,
      'religion': religion,
      'address': address,
      'phone_number': phoneNumber,
      'parent_name': parentName,
      'parent_nin': parentNin,
      'parent_contact': parentContact,
      'special_needs': specialNeeds,
      'subject_codes': subjectCodes ?? <String>[],
      'admission_number': admission,
      'balance': 0.0,
    };
    _students[sid] = student;
    // Optionally create a user account for the student if email provided
    if (email.isNotEmpty) {
      try {
        await createUser(email: email, hashedPassword: password, otherData: {
          'first_name': firstName,
          'last_name': lastName,
          'role': 'student',
        });
      } catch (_) {
        // ignore duplicate email errors for minimal implementation
      }
    }
    return Map<String, dynamic>.from(student);
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsBySchool(String schoolId,
      [Map<String, String>? queryParams]) async {
    final list = _students.values
        .where((s) => s['school_id'] == schoolId)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
    return list;
  }

  @override
  Future<Map<String, dynamic>> getStudentFeeBalance(String studentId) async {
    final intId = int.tryParse(studentId) ?? -1;
    final student = _students[intId];
    final balance = student != null ? (student['balance'] ?? 0.0) : 0.0;
    return {'balance': balance};
  }

  @override
  Future<void> updateUserRole(
      String userId, Map<String, dynamic> updateData) async {
    final intId = int.tryParse(userId) ?? -1;
    final user = _users[intId];
    if (user == null) throw Exception('User not found');
    if (updateData.containsKey('role')) {
      user['role'] = updateData['role'];
    }
  }

  @override
  Future<void> deleteFeeStructure(String schoolId, String structureId) async {
    final intId = int.tryParse(structureId) ?? -1;
    _feeStructures.remove(intId);
  }
  @override
  Future<void> recordFeePayment(Map<String, dynamic> paymentData) async {
    // support studentId or student_id or admission_number
    int? sid;
    if (paymentData.containsKey('student_id')) {
      sid = int.tryParse(paymentData['student_id'].toString());
    } else if (paymentData.containsKey('studentId')) {
      sid = int.tryParse(paymentData['studentId'].toString());
    } else if (paymentData.containsKey('admission_number')) {
      final adm = paymentData['admission_number'].toString();
      sid = _students.entries
          .firstWhere((e) => e.value['admission_number'] == adm,
              orElse: () => MapEntry(-1, {}))
          .key;
      if (sid == -1) sid = null;
    }
    final amount =
        double.tryParse(paymentData['amount']?.toString() ?? '') ?? 0.0;
    if (sid != null && sid > 0 && _students.containsKey(sid)) {
      final student = _students[sid]!;
      final current = (student['balance'] ?? 0.0) as num;
      student['balance'] = (current - amount).toDouble();
    }
    _payments.add(Map<String, dynamic>.from(paymentData));
  }

  @override
  Future<void> createStudentApplication(
      String schoolId, Map<String, dynamic> applicationData) async {
    final id = _nextApplicationId++;
    final application = Map<String, dynamic>.from(applicationData);
    application['id'] = id;
    application['school_id'] = schoolId;
    application['status'] = application['status'] ?? 'pending';
    application['created_at'] = DateTime.now().toIso8601String();
    _applications[id] = application;
  }
  @override
  Future<void> ingestChemistryCurriculum(
      [Map<String, dynamic>? curriculumData]) async {
    // no-op placeholder for curriculum ingestion
  }
  @override
  Future<void> updateSchoolLogoUrl(String schoolId, String logoUrl) async {
    final intId = int.tryParse(schoolId) ?? -1;
    final school = _schools[intId];
    if (school != null) {
      school['logo_url'] = logoUrl;
      school['updated_at'] = DateTime.now().toIso8601String();
    }
  }

  @override
  Future<void> updateSchoolSettings(String schoolId,
      {required bool selfRegistrationEnabled}) async {
    final intId = int.tryParse(schoolId) ?? -1;
    final school = _schools[intId];
    if (school != null) {
      school['self_registration_enabled'] = selfRegistrationEnabled;
      school['updated_at'] = DateTime.now().toIso8601String();
    }
  }

  @override
  Future<void> updateSchoolGeneralSettings(
      String schoolId, Map<String, dynamic> settings) async {
    final intId = int.tryParse(schoolId) ?? -1;
    final school = _schools[intId];
    if (school != null) {
      settings.forEach((k, v) => school[k] = v);
      school['updated_at'] = DateTime.now().toIso8601String();
    }
  }
  @override
  Future<void> linkParentToStudents(
      {required String parentUserId, required List<String> studentIds}) async {
    final pid = parentUserId;
    final ids =
        studentIds.map((s) => int.tryParse(s)).whereType<int>().toList();
    _parentLinks[pid] = ids;
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsByParentId(
      String parentUserId) async {
    final ids = _parentLinks[parentUserId] ?? [];
    return ids.map((i) => Map<String, dynamic>.from(_users[i]!)).toList();
  }

  @override
  Future<void> close() async {
    _users.clear();
    _emailIndex.clear();
    _parentLinks.clear();
  }

  // Production implementations for transportation and KPI management
  @override
  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> driverData) async {
    final id = _nextDriverId++;
    final driver = Map<String, dynamic>.from(driverData);
    driver['id'] = id;
    driver['created_at'] = DateTime.now().toIso8601String();
    driver['status'] = driver['status'] ?? 'active';
    _drivers[id] = driver;
    return Map<String, dynamic>.from(driver);
  }

  @override
  Future<Map<String, dynamic>> createTechnician(Map<String, dynamic> technicianData) async {
    final id = _nextTechnicianId++;
    final technician = Map<String, dynamic>.from(technicianData);
    technician['id'] = id;
    technician['created_at'] = DateTime.now().toIso8601String();
    technician['status'] = technician['status'] ?? 'active';
    _technicians[id] = technician;
    return Map<String, dynamic>.from(technician);
  }

  @override
  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> ticketData) async {
    final id = _nextTicketId++;
    final ticket = Map<String, dynamic>.from(ticketData);
    ticket['id'] = id;
    ticket['created_at'] = DateTime.now().toIso8601String();
    ticket['status'] = ticket['status'] ?? 'open';
    ticket['priority'] = ticket['priority'] ?? 'medium';
    _tickets[id] = ticket;
    return Map<String, dynamic>.from(ticket);
  }

  @override
  Future<void> deleteDriver(String driverId) async {
    final intId = int.tryParse(driverId) ?? -1;
    _drivers.remove(intId);
  }

  @override
  Future<void> deleteKPI(String kpiId) async {
    final intId = int.tryParse(kpiId) ?? -1;
    _kpis.remove(intId);
  }

  @override
  Future<void> deleteTechnician(String technicianId) async {
    final intId = int.tryParse(technicianId) ?? -1;
    _technicians.remove(intId);
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    final intId = int.tryParse(ticketId) ?? -1;
    _tickets.remove(intId);
  }

  @override
  Future<Map<String, dynamic>?> getDriverById(String driverId) async {
    final intId = int.tryParse(driverId) ?? -1;
    final driver = _drivers[intId];
    return driver != null ? Map<String, dynamic>.from(driver) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getDrivers(String schoolId) async {
    return _drivers.values
        .where((d) => d['school_id'] == schoolId)
        .map((d) => Map<String, dynamic>.from(d))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getKPIById(String kpiId) async {
    final intId = int.tryParse(kpiId) ?? -1;
    final kpi = _kpis[intId];
    return kpi != null ? Map<String, dynamic>.from(kpi) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getKPIs(String schoolId,
      {String? userId, String? userType}) async {
    var kpis = _kpis.values
        .where((k) => k['school_id'] == schoolId)
        .map((k) => Map<String, dynamic>.from(k))
        .toList();

    if (userId != null) {
      kpis = kpis.where((k) => k['user_id'] == userId).toList();
    }
    if (userType != null) {
      kpis = kpis.where((k) => k['user_type'] == userType).toList();
    }

    return kpis;
  }

  @override
  Future<Map<String, dynamic>?> getTechnicianById(String technicianId) async {
    final intId = int.tryParse(technicianId) ?? -1;
    final technician = _technicians[intId];
    return technician != null ? Map<String, dynamic>.from(technician) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getTechnicians(String schoolId) async {
    return _technicians.values
        .where((t) => t['school_id'] == schoolId)
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getTicketById(String ticketId) async {
    final intId = int.tryParse(ticketId) ?? -1;
    final ticket = _tickets[intId];
    return ticket != null ? Map<String, dynamic>.from(ticket) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getTicketVisits(String ticketId) async {
    return _visits.values
        .where((v) => v['ticket_id'] == ticketId)
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTickets(String schoolId) async {
    return _tickets.values
        .where((t) => t['school_id'] == schoolId)
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getVisitsByUser(String userId) async {
    return _visits.values
        .where((v) => v['user_id'] == userId)
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> recordKPIPoint(Map<String, dynamic> kpiData) async {
    final id = _nextKpiId++;
    final kpi = Map<String, dynamic>.from(kpiData);
    kpi['id'] = id;
    kpi['recorded_at'] = DateTime.now().toIso8601String();
    kpi['points'] = kpi['points'] ?? 1;
    _kpis[id] = kpi;
    return Map<String, dynamic>.from(kpi);
  }

  @override
  Future<Map<String, dynamic>> recordTicketVisit(Map<String, dynamic> visitData) async {
    final id = _nextVisitId++;
    final visit = Map<String, dynamic>.from(visitData);
    visit['id'] = id;
    visit['visited_at'] = DateTime.now().toIso8601String();
    visit['status'] = visit['status'] ?? 'completed';
    _visits[id] = visit;
    return Map<String, dynamic>.from(visit);
  }

  @override
  Future<void> updateDriver(String driverId, Map<String, dynamic> driverData) async {
    final intId = int.tryParse(driverId) ?? -1;
    final existingDriver = _drivers[intId];
    if (existingDriver != null) {
      driverData.forEach((k, v) => existingDriver[k] = v);
      existingDriver['updated_at'] = DateTime.now().toIso8601String();
    }
  }

  @override
  Future<void> updateKPI(String kpiId, Map<String, dynamic> kpiData) async {
    final intId = int.tryParse(kpiId) ?? -1;
    final existingKpi = _kpis[intId];
    if (existingKpi != null) {
      kpiData.forEach((k, v) => existingKpi[k] = v);
    }
  }

  @override
  Future<void> updateTechnician(String technicianId, Map<String, dynamic> technicianData) async {
    final intId = int.tryParse(technicianId) ?? -1;
    final existingTechnician = _technicians[intId];
    if (existingTechnician != null) {
      technicianData.forEach((k, v) => existingTechnician[k] = v);
      existingTechnician['updated_at'] = DateTime.now().toIso8601String();
    }
  }

  @override
  Future<void> updateTicket(String ticketId, Map<String, dynamic> ticketData) async {
    final intId = int.tryParse(ticketId) ?? -1;
    final existingTicket = _tickets[intId];
    if (existingTicket != null) {
      ticketData.forEach((k, v) => existingTicket[k] = v);
      existingTicket['updated_at'] = DateTime.now().toIso8601String();
    }
  }
}

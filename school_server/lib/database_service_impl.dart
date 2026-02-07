import 'dart:math';

import 'database_service.dart';

/// In-memory implementation of DatabaseService for backend use.
class DatabaseService extends DatabaseServiceBase {
  // In-memory storage used for tests and local runs.
  int _nextUserId = 1;
  int _nextStudentId = 1;
  int _nextSchoolId = 1;
  int _nextClassId = 1;
  int _nextSubjectId = 1;
  int _nextExamResultId = 1;
  int _nextExamId = 1;
  int _nextNotificationId = 1;
  int _nextSocialPostId = 1;
  int _nextSalaryId = 1;
  int _nextReportCardId = 1;
  int _nextBookId = 1;
  int _nextBorrowId = 1;
  int _nextSchemeId = 1;
  int _nextLessonPlanId = 1;
  int _nextAttendanceId = 1;
  int _nextGradeBookId = 1;
  int _nextApplicationId = 1;
  int _nextFeeStructureId = 1;
  int _nextCurriculumId = 1;

  final Map<int, Map<String, dynamic>> _users = {};
  final Map<String, int> _emailIndex = {};
  final Map<String, List<int>> _parentLinks = {};
  final Map<int, Map<String, dynamic>> _students = {};
  final Map<int, Map<String, dynamic>> _schools = {};
  final Map<int, Map<String, dynamic>> _classes = {};
  final Map<int, Map<String, dynamic>> _subjects = {};
  final Map<int, Map<String, dynamic>> _examResults = {};
  final Map<int, Map<String, dynamic>> _exams = {};
  final Map<int, Map<String, dynamic>> _notifications = {};
  final Map<String, List<Map<String, dynamic>>> _socialPosts = {};
  final Map<String, List<Map<String, dynamic>>> _timetableConstraints = {};
  final Map<String, Map<String, dynamic>> _subjectConstraints = {};
  final Map<String, List<Map<String, dynamic>>> _classTimetables = {};
  final List<Map<String, dynamic>> _salaryRecords = [];
  final List<Map<String, dynamic>> _reportCards = [];
  final Map<int, Map<String, dynamic>> _books = {};
  final List<Map<String, dynamic>> _borrowings = [];
  final List<Map<String, dynamic>> _schemesOfWork = [];
  final List<Map<String, dynamic>> _lessonPlans = [];
  final List<Map<String, dynamic>> _attendanceRecords = [];
  final List<Map<String, dynamic>> _gradeBookEntries = [];
  final List<Map<String, dynamic>> _studentApplications = [];
  final List<Map<String, dynamic>> _feeStructures = [];
  final List<Map<String, dynamic>> _payments = [];

  final Map<String, Map<String, dynamic>> _emailVerificationTokens = {};
  final Map<String, Map<String, dynamic>> _passwordResetTokens = {};
  final Set<String> _blacklistedTokens = {};

  final List<Map<String, dynamic>> _curriculumSubjects = [];
  final List<Map<String, dynamic>> _curriculumStrands = [];
  final List<Map<String, dynamic>> _curriculumTopics = [];
  final List<Map<String, dynamic>> _curriculumSubTopics = [];
  final List<Map<String, dynamic>> _curriculumLearningOutcomes = [];
  final List<Map<String, dynamic>> _curriculumActivities = [];
  final List<Map<String, dynamic>> _curriculumStrategies = [];
  final List<Map<String, dynamic>> _curriculumIssues = [];
  final List<Map<String, dynamic>> _curriculumValues = [];
  final List<Map<String, dynamic>> _curriculumSkills = [];

  final Random _random = Random();

  @override
  Future<void> initialize() async {
    _nextUserId = 1;
    _nextStudentId = 1;
    _nextSchoolId = 1;
    _nextClassId = 1;
    _nextSubjectId = 1;
    _nextExamResultId = 1;
    _nextExamId = 1;
    _nextNotificationId = 1;
    _nextSocialPostId = 1;
    _nextSalaryId = 1;
    _nextReportCardId = 1;
    _nextBookId = 1;
    _nextBorrowId = 1;
    _nextSchemeId = 1;
    _nextLessonPlanId = 1;
    _nextAttendanceId = 1;
    _nextGradeBookId = 1;
    _nextApplicationId = 1;
    _nextFeeStructureId = 1;
    _nextCurriculumId = 1;
    _users.clear();
    _emailIndex.clear();
    _parentLinks.clear();
    _students.clear();
    _schools.clear();
    _classes.clear();
    _subjects.clear();
    _examResults.clear();
    _exams.clear();
    _notifications.clear();
    _socialPosts.clear();
    _timetableConstraints.clear();
    _subjectConstraints.clear();
    _classTimetables.clear();
    _salaryRecords.clear();
    _reportCards.clear();
    _books.clear();
    _borrowings.clear();
    _schemesOfWork.clear();
    _lessonPlans.clear();
    _attendanceRecords.clear();
    _gradeBookEntries.clear();
    _studentApplications.clear();
    _feeStructures.clear();
    _payments.clear();
    _emailVerificationTokens.clear();
    _passwordResetTokens.clear();
    _blacklistedTokens.clear();
    _curriculumSubjects.clear();
    _curriculumStrands.clear();
    _curriculumTopics.clear();
    _curriculumSubTopics.clear();
    _curriculumLearningOutcomes.clear();
    _curriculumActivities.clear();
    _curriculumStrategies.clear();
    _curriculumIssues.clear();
    _curriculumValues.clear();
    _curriculumSkills.clear();
  }

  int? _parseId(String id) => int.tryParse(id);

  Map<String, dynamic> _copyMap(Map<String, dynamic> map) {
    return Map<String, dynamic>.from(map);
  }

  List<Map<String, dynamic>> _copyList(Iterable<Map<String, dynamic>> list) {
    return list.map(_copyMap).toList();
  }

  @override
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final id = _emailIndex[email.toLowerCase()];
    if (id == null) return null;
    return Map<String, dynamic>.from(_users[id]!);
  }

  @override
  Future<Map<String, dynamic>?> findUserById(String id) async {
    final intId = _parseId(id) ?? -1;
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
    final intId = _parseId(userId) ?? -1;
    final user = _users[intId];
    if (user == null) throw Exception('User not found');
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
    final intId = _parseId(userId);
    if (intId == null) return;
    final user = _users.remove(intId);
    if (user != null) {
      final email = user['email']?.toString().toLowerCase();
      if (email != null) {
        _emailIndex.remove(email);
      }
    }
  }

  @override
  Future<void> createEmailVerificationToken(
      String userId, String token, DateTime expires) async {
    _emailVerificationTokens[token] = {
      'user_id': userId,
      'token': token,
      'expires_at': expires.toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> findUserByVerificationToken(String token) async {
    final entry = _emailVerificationTokens[token];
    if (entry == null) return null;
    final expiresAt = DateTime.tryParse(entry['expires_at']?.toString() ?? '');
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      _emailVerificationTokens.remove(token);
      return null;
    }
    final userId = entry['user_id']?.toString();
    if (userId == null) return null;
    return findUserById(userId);
  }

  @override
  Future<void> verifyUserEmail(String userId) async {
    final intId = _parseId(userId) ?? -1;
    final user = _users[intId];
    if (user == null) throw Exception('User not found');
    user['email_verified'] = true;
  }

  @override
  Future<bool> isUserEmailVerified(String userId) async {
    final intId = _parseId(userId) ?? -1;
    final user = _users[intId];
    if (user == null) return false;
    final verified = user['email_verified'];
    if (verified == null) return false;
    if (verified is bool) return verified;
    if (verified is num) return verified != 0;
    return verified.toString().toLowerCase() == 'true' ||
        verified.toString() == '1';
  }

  @override
  Future<void> cleanupExpiredVerificationTokens() async {
    final now = DateTime.now();
    final expired = _emailVerificationTokens.entries
        .where((entry) {
          final expiresAt =
              DateTime.tryParse(entry.value['expires_at']?.toString() ?? '');
          return expiresAt != null && expiresAt.isBefore(now);
        })
        .map((entry) => entry.key)
        .toList();
    for (final token in expired) {
      _emailVerificationTokens.remove(token);
    }
  }

  @override
  Future<bool> isTokenBlacklisted(String token) async {
    return _blacklistedTokens.contains(token);
  }

  @override
  Future<Map<String, dynamic>?> findPasswordResetToken(String token) async {
    final entry = _passwordResetTokens[token];
    if (entry == null) return null;
    final expiresAt = DateTime.tryParse(entry['expires_at']?.toString() ?? '');
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      _passwordResetTokens.remove(token);
      return null;
    }
    if (entry['used'] == true) return null;
    return Map<String, dynamic>.from(entry);
  }

  @override
  Future<void> blacklistToken(
      String token, String tokenType, String? userId) async {
    _blacklistedTokens.add(token);
  }

  @override
  Future<void> cleanupExpiredTokens() async {
    await cleanupExpiredVerificationTokens();
    await cleanupExpiredPasswordResetTokens();
  }

  @override
  Future<void> markPasswordResetTokenAsUsed(String token) async {
    final entry = _passwordResetTokens[token];
    if (entry != null) {
      entry['used'] = true;
    }
  }

  @override
  Future<void> cleanupExpiredPasswordResetTokens() async {
    final now = DateTime.now();
    final expired = _passwordResetTokens.entries
        .where((entry) {
          final expiresAt =
              DateTime.tryParse(entry.value['expires_at']?.toString() ?? '');
          return expiresAt != null && expiresAt.isBefore(now);
        })
        .map((entry) => entry.key)
        .toList();
    for (final token in expired) {
      _passwordResetTokens.remove(token);
    }
  }

  @override
  Future<Map<String, dynamic>?> findSchoolByName(String name) async {
    final lower = name.toLowerCase();
    final school = _schools.values.firstWhere(
        (s) => s['name']?.toString().toLowerCase() == lower,
        orElse: () => {});
    return school.isEmpty ? null : _copyMap(school);
  }

  @override
  Future<Map<String, dynamic>?> findSchoolById(String id) async {
    final intId = _parseId(id) ?? -1;
    final school = _schools[intId];
    return school != null ? _copyMap(school) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSchools() async {
    return _copyList(_schools.values);
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
    return _copyMap(school);
  }

  @override
  Future<void> updateClassStreams(
      String schoolId, Map<String, List<String>> streams) async {
    final intId = _parseId(schoolId) ?? -1;
    final school = _schools[intId];
    if (school == null) throw Exception('School not found');
    school['class_streams'] = streams;
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
    return _copyMap(classData);
  }

  @override
  Future<Map<String, dynamic>?> findClassById(String id) async {
    final intId = _parseId(id) ?? -1;
    final classData = _classes[intId];
    return classData != null ? _copyMap(classData) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getClassesBySchool(String schoolId) async {
    final classes = _classes.values
        .where((c) => c['school_id'].toString() == schoolId)
        .map(_copyMap)
        .toList();
    return classes;
  }

  @override
  Future<void> updateClass(
      String classId, Map<String, dynamic> classData) async {
    final intId = _parseId(classId) ?? -1;
    final classEntry = _classes[intId];
    if (classEntry == null) throw Exception('Class not found');
    classEntry.addAll(classData);
  }

  @override
  Future<void> deleteClass(String classId) async {
    final intId = _parseId(classId);
    if (intId != null) {
      _classes.remove(intId);
    }
  }

  @override
  Future<int> insertSubject(Map<String, dynamic> subject) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(subject)..['id'] = id;
    _curriculumSubjects.add(entry);
    return id;
  }

  @override
  Future<int> insertStrand(Map<String, dynamic> strand) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(strand)..['id'] = id;
    _curriculumStrands.add(entry);
    return id;
  }

  @override
  Future<int> insertTopic(Map<String, dynamic> topic) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(topic)..['id'] = id;
    _curriculumTopics.add(entry);
    return id;
  }

  @override
  Future<int> insertSubTopic(Map<String, dynamic> subTopic) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(subTopic)..['id'] = id;
    _curriculumSubTopics.add(entry);
    return id;
  }

  @override
  Future<int> insertLearningOutcome(Map<String, dynamic> outcome) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(outcome)..['id'] = id;
    _curriculumLearningOutcomes.add(entry);
    return id;
  }

  @override
  Future<int> insertSuggestedActivity(Map<String, dynamic> activity) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(activity)..['id'] = id;
    _curriculumActivities.add(entry);
    return id;
  }

  @override
  Future<int> insertAssessmentStrategy(Map<String, dynamic> strategy) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(strategy)..['id'] = id;
    _curriculumStrategies.add(entry);
    return id;
  }

  @override
  Future<int> insertCrossCuttingIssue(Map<String, dynamic> issue) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(issue)..['id'] = id;
    _curriculumIssues.add(entry);
    return id;
  }

  @override
  Future<int> insertValue(Map<String, dynamic> value) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(value)..['id'] = id;
    _curriculumValues.add(entry);
    return id;
  }

  @override
  Future<int> insertGenericSkill(Map<String, dynamic> skill) async {
    final id = _nextCurriculumId++;
    final entry = _copyMap(skill)..['id'] = id;
    _curriculumSkills.add(entry);
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getSubjects() async {
    return _copyList(_curriculumSubjects);
  }

  @override
  Future<List<Map<String, dynamic>>> getStrandsBySubject(int subjectId) async {
    return _copyList(
        _curriculumStrands.where((s) => s['subject_id'] == subjectId));
  }

  @override
  Future<List<Map<String, dynamic>>> getTopicsByStrand(int strandId) async {
    return _copyList(
        _curriculumTopics.where((t) => t['strand_id'] == strandId));
  }

  @override
  Future<List<Map<String, dynamic>>> getLearningOutcomesByTopic(
      int topicId) async {
    return _copyList(
        _curriculumLearningOutcomes.where((o) => o['topic_id'] == topicId));
  }

  @override
  Future<List<Map<String, dynamic>>> getActivitiesByOutcome(
      int outcomeId) async {
    return _copyList(
        _curriculumActivities.where((a) => a['outcome_id'] == outcomeId));
  }

  @override
  Future<List<Map<String, dynamic>>> getStrategiesByOutcome(
      int outcomeId) async {
    return _copyList(
        _curriculumStrategies.where((s) => s['outcome_id'] == outcomeId));
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
    return _copyMap(subject);
  }

  @override
  Future<Map<String, dynamic>?> findSubjectById(String id) async {
    final intId = _parseId(id) ?? -1;
    final subject = _subjects[intId];
    return subject != null ? _copyMap(subject) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getSubjectsBySchool(
      String schoolId) async {
    return _copyList(
        _subjects.values.where((s) => s['school_id'].toString() == schoolId));
  }

  @override
  Future<void> updateSubject(
      String subjectId, Map<String, dynamic> subjectData) async {
    final intId = _parseId(subjectId) ?? -1;
    final subject = _subjects[intId];
    if (subject == null) throw Exception('Subject not found');
    subject.addAll(subjectData);
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    final intId = _parseId(subjectId);
    if (intId != null) {
      _subjects.remove(intId);
    }
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
    return _copyMap(result);
  }

  @override
  Future<Map<String, dynamic>?> getExamResultById(String id) async {
    final intId = _parseId(id) ?? -1;
    final result = _examResults[intId];
    return result != null ? _copyMap(result) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByExam(
      String examId) async {
    return _copyList(
        _examResults.values.where((r) => r['exam_id'].toString() == examId));
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByStudent(
      String studentId) async {
    return _copyList(_examResults.values
        .where((r) => r['student_id'].toString() == studentId));
  }

  @override
  Future<void> updateExamResult(
      String resultId, Map<String, dynamic> resultData) async {
    final intId = _parseId(resultId) ?? -1;
    final result = _examResults[intId];
    if (result == null) throw Exception('Exam result not found');
    result.addAll(resultData);
  }

  @override
  Future<void> deleteExamResult(String resultId) async {
    final intId = _parseId(resultId);
    if (intId != null) {
      _examResults.remove(intId);
    }
  }

  @override
  Future<void> setTimetableConstraint(
      Map<String, dynamic> constraint) async {
    final schoolId = constraint['school_id']?.toString() ??
        constraint['schoolId']?.toString();
    if (schoolId == null) return;
    final list = _timetableConstraints.putIfAbsent(schoolId, () => []);
    final teacherId = constraint['teacher_id']?.toString() ??
        constraint['teacherId']?.toString();
    if (teacherId != null) {
      list.removeWhere((c) =>
          c['teacher_id']?.toString() == teacherId &&
          (constraint['day'] == null || c['day'] == constraint['day']) &&
          (constraint['slot_id'] == null ||
              c['slot_id'] == constraint['slot_id']));
    }
    list.add(_copyMap(constraint));
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherConstraints(
      String schoolId, String teacherId) async {
    final list = _timetableConstraints[schoolId] ?? [];
    return _copyList(list.where(
        (c) => c['teacher_id']?.toString() == teacherId ||
            c['teacherId']?.toString() == teacherId));
  }

  @override
  Future<Map<String, dynamic>> getSubjectConstraints(
      String schoolId) async {
    return Map<String, dynamic>.from(
        _subjectConstraints[schoolId] ?? <String, dynamic>{});
  }

  @override
  Future<void> saveSubjectConstraints(
      String schoolId, Map<String, dynamic> constraints) async {
    _subjectConstraints[schoolId] = _copyMap(constraints);
  }

  @override
  Future<List<Map<String, dynamic>>> getSocialPosts(String schoolId) async {
    return _copyList(_socialPosts[schoolId] ?? []);
  }

  @override
  Future<void> createSocialPost(
      String schoolId, Map<String, dynamic> post) async {
    final list = _socialPosts.putIfAbsent(schoolId, () => []);
    final entry = _copyMap(post);
    entry['id'] = entry['id'] ?? _nextSocialPostId++;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    list.add(entry);
  }

  @override
  Future<void> deleteSocialPost(String schoolId, String postId) async {
    final list = _socialPosts[schoolId];
    if (list == null) return;
    list.removeWhere((p) => p['id']?.toString() == postId);
  }

  @override
  Future<void> createStudent(
      String schoolId, Map<String, dynamic> studentData) async {
    final id = _nextStudentId++;
    final entry = _copyMap(studentData);
    final storedId = entry['id'] is int
        ? entry['id'] as int
        : int.tryParse(entry['id']?.toString() ?? '') ?? id;
    entry['id'] = storedId;
    entry['school_id'] = schoolId;
    _students[storedId] = entry;
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentNotifications(
      String studentId) async {
    return _copyList(_notifications.values
        .where((n) => n['student_id']?.toString() == studentId));
  }

  @override
  Future<void> createNotification(
      Map<String, dynamic> notificationData) async {
    final id = _nextNotificationId++;
    final entry = _copyMap(notificationData);
    final storedId = entry['id'] is int
        ? entry['id'] as int
        : int.tryParse(entry['id']?.toString() ?? '') ?? id;
    entry['id'] = storedId;
    entry['read'] = entry['read'] ?? false;
    entry['created_at'] =
        entry['created_at'] ?? DateTime.now().toIso8601String();
    _notifications[storedId] = entry;
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    final intId = _parseId(notificationId) ?? -1;
    final notification = _notifications[intId];
    if (notification == null) return;
    notification['read'] = true;
  }

  @override
  Future<int> getUnreadNotificationCount(String studentId) async {
    return _notifications.values
        .where((n) =>
            n['student_id']?.toString() == studentId && n['read'] != true)
        .length;
  }

  @override
  Future<List<Map<String, dynamic>>> getClasses(String schoolId) async {
    return getClassesBySchool(schoolId);
  }

  @override
  Future<void> createExam(String schoolId, Map<String, dynamic> examData) async {
    final id = _nextExamId++;
    final entry = _copyMap(examData);
    final storedId = entry['id'] is int
        ? entry['id'] as int
        : int.tryParse(entry['id']?.toString() ?? '') ?? id;
    entry['id'] = storedId;
    entry['school_id'] = schoolId;
    entry['created_at'] =
        entry['created_at'] ?? DateTime.now().toIso8601String();
    _exams[storedId] = entry;
  }

  @override
  Future<List<Map<String, dynamic>>> getExamsBySchool(
      String schoolId) async {
    return _copyList(
        _exams.values.where((e) => e['school_id'].toString() == schoolId));
  }

  @override
  Future<List<Map<String, dynamic>>> getExamsByTeacher(
      String schoolId, String teacherId) async {
    return _copyList(_exams.values.where((e) =>
        e['school_id'].toString() == schoolId &&
        (e['teacher_id']?.toString() == teacherId ||
            e['teacherId']?.toString() == teacherId)));
  }

  @override
  Future<void> updateExam(
      String schoolId, String examId, Map<String, dynamic> examData) async {
    final intId = _parseId(examId) ?? -1;
    final exam = _exams[intId];
    if (exam == null || exam['school_id'].toString() != schoolId) {
      throw Exception('Exam not found');
    }
    exam.addAll(examData);
  }

  @override
  Future<void> deleteExam(String schoolId, String examId) async {
    final intId = _parseId(examId);
    if (intId != null) {
      final exam = _exams[intId];
      if (exam != null && exam['school_id'].toString() == schoolId) {
        _exams.remove(intId);
      }
    }
  }

  @override
  Future<void> setTimetableLesson(Map<String, dynamic> lesson) async {
    final schoolId = lesson['school_id']?.toString() ??
        lesson['schoolId']?.toString();
    final className = lesson['class_name']?.toString() ??
        lesson['className']?.toString();
    if (schoolId == null || className == null) return;
    final key = '$schoolId|$className';
    final list = _classTimetables.putIfAbsent(key, () => []);
    final day = lesson['day']?.toString();
    final slotId = lesson['slot_id']?.toString() ?? lesson['slotId']?.toString();
    if (day != null && slotId != null) {
      list.removeWhere((l) =>
          l['day']?.toString() == day &&
          (l['slot_id']?.toString() == slotId ||
              l['slotId']?.toString() == slotId));
    }
    list.add(_copyMap(lesson));
  }

  @override
  Future<List<Map<String, dynamic>>> getClassTimetableLessons(
      String schoolId, String className) async {
    final key = '$schoolId|$className';
    return _copyList(_classTimetables[key] ?? []);
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherTimetableLessons(
      String schoolId, String teacherId) async {
    final lessons = _classTimetables.entries
        .where((entry) => entry.key.startsWith('$schoolId|'))
        .expand((entry) => entry.value)
        .where((lesson) =>
            lesson['teacher_id']?.toString() == teacherId ||
            lesson['teacherId']?.toString() == teacherId);
    return _copyList(lessons);
  }

  @override
  Future<void> removeTimetableLesson(
      String schoolId, String className, String day, String slotId) async {
    final key = '$schoolId|$className';
    final list = _classTimetables[key];
    if (list == null) return;
    list.removeWhere((lesson) =>
        lesson['day']?.toString() == day &&
        (lesson['slot_id']?.toString() == slotId ||
            lesson['slotId']?.toString() == slotId));
  }

  @override
  Future<void> saveFullClassTimetable(String schoolId, String className,
      List<Map<String, dynamic>> lessons) async {
    final key = '$schoolId|$className';
    _classTimetables[key] = _copyList(lessons);
  }

  @override
  Future<void> createSalaryRecord(
      String schoolId, Map<String, dynamic> salaryData) async {
    final entry = _copyMap(salaryData);
    entry['id'] = entry['id'] ?? _nextSalaryId++;
    entry['school_id'] = schoolId;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _salaryRecords.add(entry);
  }

  @override
  Future<List<Map<String, dynamic>>> getSalaryRecords(
      String schoolId, String? staffId) async {
    return _copyList(_salaryRecords.where((record) {
      final matchesSchool = record['school_id'].toString() == schoolId;
      if (!matchesSchool) return false;
      if (staffId == null) return true;
      return record['staff_id']?.toString() == staffId ||
          record['staffId']?.toString() == staffId;
    }));
  }

  @override
  Future<void> updateSalaryRecord(String schoolId, String recordId,
      Map<String, dynamic> updateData) async {
    final record = _salaryRecords.firstWhere(
        (r) =>
            r['id']?.toString() == recordId &&
            r['school_id'].toString() == schoolId,
        orElse: () => {});
    if (record.isEmpty) throw Exception('Salary record not found');
    record.addAll(updateData);
  }

  @override
  Future<void> createReportCard(
      String schoolId, Map<String, dynamic> reportCard) async {
    final entry = _copyMap(reportCard);
    entry['id'] = entry['id'] ?? _nextReportCardId++;
    entry['school_id'] = schoolId;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _reportCards.add(entry);
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentReportCards(
      String schoolId, String studentId) async {
    return _copyList(_reportCards.where((r) =>
        r['school_id'].toString() == schoolId &&
        r['student_id']?.toString() == studentId));
  }

  @override
  Future<Map<String, dynamic>> getReportCard(
      String schoolId, String studentId, String term, String year) async {
    final report = _reportCards.firstWhere(
        (r) =>
            r['school_id'].toString() == schoolId &&
            r['student_id']?.toString() == studentId &&
            r['term']?.toString() == term &&
            r['year']?.toString() == year,
        orElse: () => {});
    if (report.isEmpty) throw Exception('Report card not found');
    return _copyMap(report);
  }

  @override
  Future<void> addBook(String schoolId, Map<String, dynamic> bookData) async {
    final id = _nextBookId++;
    final entry = _copyMap(bookData);
    final storedId = entry['id'] is int
        ? entry['id'] as int
        : int.tryParse(entry['id']?.toString() ?? '') ?? id;
    entry['id'] = storedId;
    entry['school_id'] = schoolId;
    entry['created_at'] =
        entry['created_at'] ?? DateTime.now().toIso8601String();
    _books[storedId] = entry;
  }

  @override
  Future<List<Map<String, dynamic>>> getBooks(String schoolId) async {
    return _copyList(
        _books.values.where((b) => b['school_id'].toString() == schoolId));
  }

  @override
  Future<void> borrowBook(
      String schoolId, Map<String, dynamic> borrowingData) async {
    final id = _nextBorrowId++;
    final entry = _copyMap(borrowingData);
    entry['id'] = entry['id'] ?? id;
    entry['school_id'] = schoolId;
    entry['status'] = entry['status'] ?? 'borrowed';
    entry['borrowed_at'] =
        entry['borrowed_at'] ?? DateTime.now().toIso8601String();
    _borrowings.add(entry);
  }

  @override
  Future<void> returnBook(String schoolId, String borrowingId) async {
    final borrowing = _borrowings.firstWhere(
        (b) =>
            b['id']?.toString() == borrowingId &&
            b['school_id'].toString() == schoolId,
        orElse: () => {});
    if (borrowing.isEmpty) throw Exception('Borrowing not found');
    borrowing['status'] = 'returned';
    borrowing['returned_at'] = DateTime.now().toIso8601String();
  }

  @override
  Future<List<Map<String, dynamic>>> getBorrowedBooks(
      String schoolId, String studentId) async {
    return _copyList(_borrowings.where((b) =>
        b['school_id'].toString() == schoolId &&
        b['student_id']?.toString() == studentId &&
        b['status'] != 'returned'));
  }

  @override
  Future<void> saveSchemeOfWork(Map<String, dynamic> scheme) async {
    final entry = _copyMap(scheme);
    entry['id'] = entry['id'] ?? _nextSchemeId++;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _schemesOfWork.add(entry);
  }

  @override
  Future<Map<String, dynamic>> getSchemeOfWork(String schoolId, String subject,
      String className, String term, int year) async {
    final scheme = _schemesOfWork.firstWhere(
        (s) =>
            s['school_id']?.toString() == schoolId &&
            s['subject']?.toString() == subject &&
            s['class_name']?.toString() == className &&
            s['term']?.toString() == term &&
            s['year']?.toString() == year.toString(),
        orElse: () => {});
    if (scheme.isEmpty) throw Exception('Scheme of work not found');
    return _copyMap(scheme);
  }

  @override
  Future<List<Map<String, dynamic>>> getSchemesOfWork(
      String schoolId, Map<String, String> queryParams) async {
    return _copyList(_schemesOfWork.where((s) {
      if (s['school_id']?.toString() != schoolId) return false;
      for (final entry in queryParams.entries) {
        if (s[entry.key]?.toString() != entry.value) return false;
      }
      return true;
    }));
  }

  @override
  Future<void> saveLessonPlan(
      String schoolId, Map<String, dynamic> lessonPlan) async {
    final entry = _copyMap(lessonPlan);
    entry['id'] = entry['id'] ?? _nextLessonPlanId++;
    entry['school_id'] = schoolId;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _lessonPlans.add(entry);
  }

  @override
  Future<List<Map<String, dynamic>>> getLessonPlans(String schoolId,
      String teacherId, Map<String, String> queryParams) async {
    return _copyList(_lessonPlans.where((p) {
      if (p['school_id']?.toString() != schoolId) return false;
      if (p['teacher_id']?.toString() != teacherId &&
          p['teacherId']?.toString() != teacherId) {
        return false;
      }
      for (final entry in queryParams.entries) {
        if (p[entry.key]?.toString() != entry.value) return false;
      }
      return true;
    }));
  }

  @override
  Future<void> saveAttendanceRecord(
      String schoolId, Map<String, dynamic> attendanceRecord) async {
    final entry = _copyMap(attendanceRecord);
    entry['id'] = entry['id'] ?? _nextAttendanceId++;
    entry['school_id'] = schoolId;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _attendanceRecords.add(entry);
  }

  @override
  Future<List<Map<String, dynamic>>> getAttendanceRecords(
      String schoolId, Map<String, String> queryParams) async {
    return _copyList(_attendanceRecords.where((r) {
      if (r['school_id']?.toString() != schoolId) return false;
      for (final entry in queryParams.entries) {
        if (r[entry.key]?.toString() != entry.value) return false;
      }
      return true;
    }));
  }

  @override
  Future<Map<String, dynamic>> getStudentAttendanceSummary(
      String schoolId, String studentId, String term, int year) async {
    final records = _attendanceRecords.where((r) =>
        r['school_id']?.toString() == schoolId &&
        r['student_id']?.toString() == studentId &&
        r['term']?.toString() == term &&
        r['year']?.toString() == year.toString());
    final total = records.length;
    final present =
        records.where((r) => r['status']?.toString() == 'present').length;
    return {
      'student_id': studentId,
      'term': term,
      'year': year,
      'total': total,
      'present': present,
      'absent': total - present,
    };
  }

  @override
  Future<void> saveGradeBookEntry(
      String schoolId, Map<String, dynamic> gradeBookEntry) async {
    final entry = _copyMap(gradeBookEntry);
    entry['id'] = entry['id'] ?? _nextGradeBookId++;
    entry['school_id'] = schoolId;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _gradeBookEntries.add(entry);
  }

  @override
  Future<List<Map<String, dynamic>>> getGradeBookEntries(
      String schoolId, Map<String, String> queryParams) async {
    return _copyList(_gradeBookEntries.where((e) {
      if (e['school_id']?.toString() != schoolId) return false;
      for (final entry in queryParams.entries) {
        if (e[entry.key]?.toString() != entry.value) return false;
      }
      return true;
    }));
  }

  @override
  Future<Map<String, dynamic>> getStudentGradeBookSummary(
      String schoolId, String studentId, String subject, String term,
      int year) async {
    final entries = _gradeBookEntries.where((e) =>
        e['school_id']?.toString() == schoolId &&
        e['student_id']?.toString() == studentId &&
        e['subject']?.toString() == subject &&
        e['term']?.toString() == term &&
        e['year']?.toString() == year.toString());
    double total = 0;
    for (final entry in entries) {
      total += double.tryParse(entry['score']?.toString() ?? '') ?? 0;
    }
    return {
      'student_id': studentId,
      'subject': subject,
      'term': term,
      'year': year,
      'total_score': total,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentApplications(
      String schoolId) async {
    return _copyList(_studentApplications
        .where((a) => a['school_id']?.toString() == schoolId));
  }

  @override
  Future<void> updateStudentApplication(String schoolId, String applicationId,
      Map<String, dynamic> updateData) async {
    final application = _studentApplications.firstWhere(
        (a) =>
            a['id']?.toString() == applicationId &&
            a['school_id']?.toString() == schoolId,
        orElse: () => {});
    if (application.isEmpty) throw Exception('Application not found');
    application.addAll(updateData);
  }

  @override
  Future<List<Map<String, dynamic>>> getFeeStructures(String schoolId) async {
    return _copyList(
        _feeStructures.where((f) => f['school_id']?.toString() == schoolId));
  }

  @override
  Future<void> createFeeStructure(
      String schoolId, Map<String, dynamic> structure) async {
    final entry = _copyMap(structure);
    entry['id'] = entry['id'] ?? _nextFeeStructureId++;
    entry['school_id'] = schoolId;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _feeStructures.add(entry);
  }

  @override
  Future<void> updateFeeStructure(String schoolId, String structureId,
      Map<String, dynamic> structure) async {
    final entry = _feeStructures.firstWhere(
        (s) =>
            s['id']?.toString() == structureId &&
            s['school_id']?.toString() == schoolId,
        orElse: () => {});
    if (entry.isEmpty) throw Exception('Fee structure not found');
    entry.addAll(structure);
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
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    otherData.forEach((k, v) {
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
  Future<String> createPasswordResetToken(String email, String userId) async {
    final token =
        '${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(100000)}';
    _passwordResetTokens[token] = {
      'token': token,
      'email': email,
      'user_id': userId,
      'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'used': false,
    };
    return token;
  }

  @override
  Future<void> delete(String itemType, int itemId) async {
    switch (itemType) {
      case 'users':
        _users.remove(itemId);
        break;
      case 'students':
        _students.remove(itemId);
        break;
      case 'schools':
        _schools.remove(itemId);
        break;
      case 'classes':
        _classes.remove(itemId);
        break;
      case 'subjects':
        _subjects.remove(itemId);
        break;
      case 'exams':
        _exams.remove(itemId);
        break;
      default:
        break;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic>? params]) async {
    final s = sql.toLowerCase();
    if (s.contains('from users')) {
      return _users.values.map(_copyMap).toList();
    }
    if (s.contains('from students')) {
      return _students.values.map(_copyMap).toList();
    }
    if (s.contains('from schools')) {
      return _schools.values.map(_copyMap).toList();
    }
    if (s.contains('from classes')) {
      return _classes.values.map(_copyMap).toList();
    }
    if (s.contains('from subjects')) {
      return _subjects.values.map(_copyMap).toList();
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
      _users[id] = user;
      if (lower.isNotEmpty) _emailIndex[lower] = id;
      return;
    }
    if (t.contains('student')) {
      final id = _nextStudentId++;
      final student = Map<String, dynamic>.from(data);
      student['id'] = id;
      _students[id] = student;
    }
  }

  @override
  Future<void> update(String table, Map<String, dynamic> data,
      String whereClause, List<dynamic> params) async {
    final t = table.toLowerCase();
    if (t.contains('user')) {
      if (params.isNotEmpty) {
        final id = params.first is int
            ? params.first as int
            : int.tryParse(params.first.toString());
        if (id != null && _users.containsKey(id)) {
          final user = _users[id]!;
          data.forEach((k, v) => user[k] = v);
        }
      }
    }
    if (t.contains('student')) {
      if (params.isNotEmpty) {
        final id = params.first is int
            ? params.first as int
            : int.tryParse(params.first.toString());
        if (id != null && _students.containsKey(id)) {
          final student = _students[id]!;
          data.forEach((k, v) => student[k] = v);
        }
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
    }
    if (t.contains('student') && params.isNotEmpty) {
      final id = params.first is int
          ? params.first as int
          : int.tryParse(params.first.toString());
      if (id != null) {
        _students.remove(id);
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
    if (email.isNotEmpty) {
      try {
        await createUser(email: email, hashedPassword: password, otherData: {
          'first_name': firstName,
          'last_name': lastName,
          'role': 'student',
        });
      } catch (_) {}
    }
    return _copyMap(student);
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsBySchool(String schoolId,
      [Map<String, String>? queryParams]) async {
    final list = _students.values
        .where((s) => s['school_id'] == schoolId)
        .where((s) {
          if (queryParams == null) return true;
          for (final entry in queryParams.entries) {
            if (s[entry.key]?.toString() != entry.value) return false;
          }
          return true;
        })
        .map(_copyMap)
        .toList();
    return list;
  }

  @override
  Future<Map<String, dynamic>> getStudentFeeBalance(String studentId) async {
    final intId = _parseId(studentId) ?? -1;
    final student = _students[intId];
    final balance = student != null ? (student['balance'] ?? 0.0) : 0.0;
    return {'balance': balance};
  }

  @override
  Future<void> updateUserRole(
      String userId, Map<String, dynamic> updateData) async {
    final intId = _parseId(userId) ?? -1;
    final user = _users[intId];
    if (user == null) throw Exception('User not found');
    if (updateData.containsKey('role')) {
      user['role'] = updateData['role'];
    }
  }

  Future<void> deleteFeeStructure(String schoolId, String structureId) async {
    _feeStructures.removeWhere((f) =>
        f['school_id']?.toString() == schoolId &&
        f['id']?.toString() == structureId);
  }

  @override
  Future<void> recordFeePayment(Map<String, dynamic> paymentData) async {
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
    _payments.add(_copyMap(paymentData));
  }

  Future<void> createStudentApplication(
      String schoolId, Map<String, dynamic> applicationData) async {
    final entry = _copyMap(applicationData);
    entry['id'] = entry['id'] ?? _nextApplicationId++;
    entry['school_id'] = schoolId;
    entry['created_at'] = entry['created_at'] ?? DateTime.now().toIso8601String();
    _studentApplications.add(entry);
  }

  @override
  Future<void> ingestChemistryCurriculum(
      [Map<String, dynamic>? curriculumData]) async {
    if (curriculumData == null) return;
    await insertSubject(curriculumData);
  }

  Future<void> updateSchoolLogoUrl(String schoolId, String logoUrl) async {
    final intId = _parseId(schoolId) ?? -1;
    final school = _schools[intId];
    if (school == null) throw Exception('School not found');
    school['logo_url'] = logoUrl;
  }

  Future<void> updateSchoolSettings(String schoolId,
      {required bool selfRegistrationEnabled}) async {
    final intId = _parseId(schoolId) ?? -1;
    final school = _schools[intId];
    if (school == null) throw Exception('School not found');
    school['self_registration_enabled'] = selfRegistrationEnabled;
  }

  Future<void> updateSchoolGeneralSettings(
      String schoolId, Map<String, dynamic> settings) async {
    final intId = _parseId(schoolId) ?? -1;
    final school = _schools[intId];
    if (school == null) throw Exception('School not found');
    school.addAll(settings);
  }

  @override
  Future<void> linkParentToStudents(
      {required String parentUserId,
      required List<String> studentIds}) async {
    final ids =
        studentIds.map((s) => int.tryParse(s)).whereType<int>().toList();
    _parentLinks[parentUserId] = ids;
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsByParentId(
      String parentUserId) async {
    final ids = _parentLinks[parentUserId] ?? [];
    return ids
        .map((i) => _students[i])
        .whereType<Map<String, dynamic>>()
        .map(_copyMap)
        .toList();
  }

  @override
  Future<void> close() async {
    _users.clear();
    _emailIndex.clear();
    _parentLinks.clear();
  }
}

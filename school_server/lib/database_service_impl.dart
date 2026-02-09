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
  Future<void> deleteUser(String userId) => throw UnimplementedError();
  @override
  Future<void> createEmailVerificationToken(
          String userId, String token, DateTime expires) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> findUserByVerificationToken(String token) =>
      throw UnimplementedError();
  @override
  Future<void> verifyUserEmail(String userId) => throw UnimplementedError();
  @override
  Future<bool> isUserEmailVerified(String userId) => throw UnimplementedError();
  @override
  Future<void> cleanupExpiredVerificationTokens() => throw UnimplementedError();
  @override
  Future<bool> isTokenBlacklisted(String token) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> findPasswordResetToken(String token) =>
      throw UnimplementedError();
  @override
  Future<void> blacklistToken(String token, String tokenType, String? userId) =>
      throw UnimplementedError();
  @override
  Future<void> cleanupExpiredTokens() => throw UnimplementedError();
  @override
  Future<void> markPasswordResetTokenAsUsed(String token) =>
      throw UnimplementedError();
  @override
  Future<void> cleanupExpiredPasswordResetTokens() =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> findSchoolByName(String name) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> findSchoolById(String id) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getAllSchools() =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> createSchool(
          {required String name, required String classification}) =>
      throw UnimplementedError();
  @override
  Future<void> updateClassStreams(
          String schoolId, Map<String, List<String>> streams) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> createClass(
          {required String schoolId,
          required String name,
          String? gradeLevel}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> findClassById(String id) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getClassesBySchool(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> updateClass(String classId, Map<String, dynamic> classData) =>
      throw UnimplementedError();
  @override
  Future<void> deleteClass(String classId) => throw UnimplementedError();
  @override
  Future<int> insertSubject(Map<String, dynamic> subject) =>
      throw UnimplementedError();
  @override
  Future<int> insertStrand(Map<String, dynamic> strand) =>
      throw UnimplementedError();
  @override
  Future<int> insertTopic(Map<String, dynamic> topic) =>
      throw UnimplementedError();
  @override
  Future<int> insertSubTopic(Map<String, dynamic> subTopic) =>
      throw UnimplementedError();
  @override
  Future<int> insertLearningOutcome(Map<String, dynamic> outcome) =>
      throw UnimplementedError();
  @override
  Future<int> insertSuggestedActivity(Map<String, dynamic> activity) =>
      throw UnimplementedError();
  @override
  Future<int> insertAssessmentStrategy(Map<String, dynamic> strategy) =>
      throw UnimplementedError();
  @override
  Future<int> insertCrossCuttingIssue(Map<String, dynamic> issue) =>
      throw UnimplementedError();
  @override
  Future<int> insertValue(Map<String, dynamic> value) =>
      throw UnimplementedError();
  @override
  Future<int> insertGenericSkill(Map<String, dynamic> skill) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getSubjects() =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getStrandsBySubject(int subjectId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getTopicsByStrand(int strandId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getLearningOutcomesByTopic(int topicId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getActivitiesByOutcome(int outcomeId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getStrategiesByOutcome(int outcomeId) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> createSubject(
          {required String schoolId,
          required String name,
          String? description}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> findSubjectById(String id) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getSubjectsBySchool(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> updateSubject(
          String subjectId, Map<String, dynamic> subjectData) =>
      throw UnimplementedError();
  @override
  Future<void> deleteSubject(String subjectId) => throw UnimplementedError();
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
          String? comments}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> getExamResultById(String id) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getExamResultsByExam(String examId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getExamResultsByStudent(
          String studentId) =>
      throw UnimplementedError();
  @override
  Future<void> updateExamResult(
          String resultId, Map<String, dynamic> resultData) =>
      throw UnimplementedError();
  @override
  Future<void> deleteExamResult(String resultId) => throw UnimplementedError();
  @override
  Future<void> setTimetableConstraint(Map<String, dynamic> constraint) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getTeacherConstraints(
          String schoolId, String teacherId) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getSubjectConstraints(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> saveSubjectConstraints(
          String schoolId, Map<String, dynamic> constraints) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getSocialPosts(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> createSocialPost(String schoolId, Map<String, dynamic> post) =>
      throw UnimplementedError();
  @override
  Future<void> deleteSocialPost(String schoolId, String postId) =>
      throw UnimplementedError();
  @override
  Future<void> createStudent(
          String schoolId, Map<String, dynamic> studentData) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getStudentNotifications(
          String studentId) =>
      throw UnimplementedError();
  @override
  Future<void> createNotification(Map<String, dynamic> notificationData) =>
      throw UnimplementedError();
  @override
  Future<void> markNotificationAsRead(String notificationId) =>
      throw UnimplementedError();
  @override
  Future<int> getUnreadNotificationCount(String studentId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getClasses(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> createExam(String schoolId, Map<String, dynamic> examData) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getExamsBySchool(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getExamsByTeacher(
          String schoolId, String teacherId) =>
      throw UnimplementedError();
  @override
  Future<void> updateExam(
          String schoolId, String examId, Map<String, dynamic> examData) =>
      throw UnimplementedError();
  @override
  Future<void> deleteExam(String schoolId, String examId) =>
      throw UnimplementedError();
  @override
  Future<void> setTimetableLesson(Map<String, dynamic> lesson) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getClassTimetableLessons(
          String schoolId, String className) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getTeacherTimetableLessons(
          String schoolId, String teacherId) =>
      throw UnimplementedError();
  @override
  Future<void> removeTimetableLesson(
          String schoolId, String className, String day, String slotId) =>
      throw UnimplementedError();
  @override
  Future<void> saveFullClassTimetable(String schoolId, String className,
          List<Map<String, dynamic>> lessons) =>
      throw UnimplementedError();
  @override
  Future<void> createSalaryRecord(
          String schoolId, Map<String, dynamic> salaryData) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getSalaryRecords(
          String schoolId, String? staffId) =>
      throw UnimplementedError();
  @override
  Future<void> updateSalaryRecord(
          String schoolId, String recordId, Map<String, dynamic> updateData) =>
      throw UnimplementedError();
  @override
  Future<void> createReportCard(
          String schoolId, Map<String, dynamic> reportCard) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getStudentReportCards(
          String schoolId, String studentId) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getReportCard(
          String schoolId, String studentId, String term, String year) =>
      throw UnimplementedError();
  @override
  Future<void> addBook(String schoolId, Map<String, dynamic> bookData) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getBooks(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> borrowBook(
          String schoolId, Map<String, dynamic> borrowingData) =>
      throw UnimplementedError();
  @override
  Future<void> returnBook(String schoolId, String borrowingId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getBorrowedBooks(
          String schoolId, String studentId) =>
      throw UnimplementedError();
  @override
  Future<void> saveSchemeOfWork(Map<String, dynamic> scheme) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getSchemeOfWork(String schoolId, String subject,
          String className, String term, int year) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getSchemesOfWork(
          String schoolId, Map<String, String> queryParams) =>
      throw UnimplementedError();
  @override
  Future<void> saveLessonPlan(
          String schoolId, Map<String, dynamic> lessonPlan) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getLessonPlans(
          String schoolId, String teacherId, Map<String, String> queryParams) =>
      throw UnimplementedError();
  @override
  Future<void> saveAttendanceRecord(
          String schoolId, Map<String, dynamic> attendanceRecord) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getAttendanceRecords(
          String schoolId, Map<String, String> queryParams) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getStudentAttendanceSummary(
          String schoolId, String studentId, String term, int year) =>
      throw UnimplementedError();
  @override
  Future<void> saveGradeBookEntry(
          String schoolId, Map<String, dynamic> gradeBookEntry) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getGradeBookEntries(
          String schoolId, Map<String, String> queryParams) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getStudentGradeBookSummary(String schoolId,
          String studentId, String subject, String term, int year) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getStudentApplications(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> updateStudentApplication(String schoolId, String applicationId,
          Map<String, dynamic> updateData) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getFeeStructures(String schoolId) =>
      throw UnimplementedError();
  @override
  Future<void> createFeeStructure(
          String schoolId, Map<String, dynamic> structure) =>
      throw UnimplementedError();
  @override
  Future<void> updateFeeStructure(String schoolId, String structureId,
          Map<String, dynamic> structure) =>
      throw UnimplementedError();
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
  Future<String> createPasswordResetToken(String email, String userId) =>
      throw UnimplementedError();
  @override
  Future<void> delete(String itemType, int itemId) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic>? params]) async {
    final s = sql.toLowerCase();
    if (s.contains('from users')) {
      return _users.values.map((u) => Map<String, dynamic>.from(u)).toList();
    }
    if (s.contains('from students')) {
      // no students store yet
      return <Map<String, dynamic>>[];
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
    }
  }

  @override
  Future<void> update(String table, Map<String, dynamic> data,
      String whereClause, List<dynamic> params) async {
    final t = table.toLowerCase();
    if (t.contains('user')) {
      // naive whereClause handling: support 'id = ?' or 'id = ?'
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
        if (user != null)
          _emailIndex.remove(user['email']?.toString().toLowerCase());
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

  Future<void> deleteFeeStructure(String schoolId, String structureId) =>
      throw UnimplementedError();
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

  Future<void> createStudentApplication(
          String schoolId, Map<String, dynamic> applicationData) =>
      throw UnimplementedError();
  @override
  Future<void> ingestChemistryCurriculum(
      [Map<String, dynamic>? curriculumData]) async {
    // no-op placeholder for curriculum ingestion
  }
  Future<void> updateSchoolLogoUrl(String schoolId, String logoUrl) =>
      throw UnimplementedError();
  Future<void> updateSchoolSettings(String schoolId,
          {required bool selfRegistrationEnabled}) =>
      throw UnimplementedError();
  Future<void> updateSchoolGeneralSettings(
          String schoolId, Map<String, dynamic> settings) =>
      throw UnimplementedError();
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

  // Stub implementations for missing methods
  @override
  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> driverData) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> createTechnician(Map<String, dynamic> technicianData) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> ticketData) => throw UnimplementedError();
  @override
  Future<void> deleteDriver(String driverId) => throw UnimplementedError();
  @override
  Future<void> deleteKPI(String kpiId) => throw UnimplementedError();
  @override
  Future<void> deleteTechnician(String technicianId) => throw UnimplementedError();
  @override
  Future<void> deleteTicket(String ticketId) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> getDriverById(String driverId) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getDrivers(String schoolId) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> getKPIById(String kpiId) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getKPIs(String schoolId, {String? userId, String? userType}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> getTechnicianById(String technicianId) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getTechnicians(String schoolId) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> getTicketById(String ticketId) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getTicketVisits(String ticketId) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getTickets(String schoolId) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getVisitsByUser(String userId) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> recordKPIPoint(Map<String, dynamic> kpiData) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> recordTicketVisit(Map<String, dynamic> visitData) => throw UnimplementedError();
  @override
  Future<void> updateDriver(String driverId, Map<String, dynamic> driverData) => throw UnimplementedError();
  @override
  Future<void> updateKPI(String kpiId, Map<String, dynamic> kpiData) => throw UnimplementedError();
  @override
  Future<void> updateTechnician(String technicianId, Map<String, dynamic> technicianData) => throw UnimplementedError();
  @override
  Future<void> updateTicket(String ticketId, Map<String, dynamic> ticketData) => throw UnimplementedError();
}

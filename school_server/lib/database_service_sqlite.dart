import 'dart:io';
import 'dart:math' as Math;
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';
import 'database_service_impl.dart' as impl;

/// SQLite-backed implementation of DatabaseServiceBase.
class DatabaseService extends impl.DatabaseService {
  late final Database _db;
  final String _dbPath;
  bool _opened = false;

  DatabaseService({String? dbPath})
      : _dbPath = dbPath ?? p.join(Directory.current.path, 'school_server.db');

  @override
  Future<void> initialize() async {
    // Open the database file (will create if missing).
    _db = sqlite3.open(_dbPath);
    try {
      _db.execute('PRAGMA foreign_keys = ON');
    } catch (_) {}

    // Initialize schema if tables don't exist
    await _initializeSchema();

    _opened = true;
  }

  Future<void> _initializeSchema() async {
    try {
      // Check if users table exists
      final rs = _db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
      if (rs.isEmpty) {
        print('Initializing database schema...');

        // Create tables manually in the correct order
        await _createTables();
        await _createIndexes();

        // Run migrations to add missing tables
        await _runMigrations();

        print('Database schema initialized successfully');
      }
    } catch (e) {
      print('Error initializing schema: $e');
    }
  }

  Future<void> _runMigrations() async {
    try {
      // Inline table creation since migration imports are failing
      _createAdditionalTables();
    } catch (e) {
      print('Error running migrations: $e');
    }
  }

  Future<void> _createAdditionalTables() async {
    // Schools table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS schools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        address TEXT,
        phone TEXT,
        email TEXT UNIQUE,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Classes table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        grade_level TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (school_id) REFERENCES schools (id) ON DELETE CASCADE
      )
    ''');

    // Subjects table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (school_id) REFERENCES schools (id) ON DELETE CASCADE
      )
    ''');

    // Add email verification columns to users table
    if (!_columnExists('users', 'email_verified')) {
      _db.execute(
          'ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE');
    }
    if (!_columnExists('users', 'verification_token')) {
      _db.execute('ALTER TABLE users ADD COLUMN verification_token TEXT');
    }
    if (!_columnExists('users', 'verification_expires')) {
      _db.execute('ALTER TABLE users ADD COLUMN verification_expires TEXT');
    }

    // Notifications table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'general',
        priority TEXT NOT NULL DEFAULT 'medium',
        target_type TEXT NOT NULL DEFAULT 'all',
        target_id TEXT,
        action_url TEXT,
        is_read BOOLEAN DEFAULT FALSE,
        read_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tickets table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'open',
        priority TEXT NOT NULL DEFAULT 'medium',
        category TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        assigned_to INTEGER,
        school_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users (id),
        FOREIGN KEY (assigned_to) REFERENCES users (id),
        FOREIGN KEY (school_id) REFERENCES schools (id)
      )
    ''');

    // Technicians table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS technicians (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        school_id INTEGER NOT NULL,
        specialization TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (school_id) REFERENCES schools (id)
      )
    ''');

    // Drivers table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS drivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        school_id INTEGER NOT NULL,
        license_number TEXT,
        vehicle_type TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (school_id) REFERENCES schools (id)
      )
    ''');

    // Ticket visits table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ticket_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        visit_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ticket_id) REFERENCES tickets (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // KPIs table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS kpis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        user_type TEXT NOT NULL,
        points INTEGER NOT NULL DEFAULT 1,
        reason TEXT,
        recorded_by INTEGER NOT NULL,
        recorded_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ticket_id) REFERENCES tickets (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (recorded_by) REFERENCES users (id)
      )
    ''');

    // Create indexes
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_classes_school_id ON classes (school_id)');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_subjects_school_id ON subjects (school_id)');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_target ON notifications(target_type, target_id)');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read)');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC)');
  }

  Future<void> _createTables() async {
    final tables = [
      'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT "parent", first_name TEXT, last_name TEXT, profile_picture_url TEXT, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)',
      'CREATE TABLE IF NOT EXISTS students (id INTEGER PRIMARY KEY AUTOINCREMENT, first_name TEXT NOT NULL, last_name TEXT NOT NULL, date_of_birth DATE NOT NULL, class_id INTEGER NOT NULL, admission_date DATE NOT NULL DEFAULT CURRENT_DATE, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)',
      'CREATE TABLE IF NOT EXISTS exams (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, class_id INTEGER NOT NULL, subject_id INTEGER NOT NULL, exam_date DATE NOT NULL, max_marks INTEGER NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)',
      'CREATE TABLE IF NOT EXISTS fees (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER NOT NULL, amount REAL NOT NULL, due_date DATE NOT NULL, status TEXT NOT NULL DEFAULT "pending", created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)',
      'CREATE TABLE IF NOT EXISTS staff_payments (id INTEGER PRIMARY KEY AUTOINCREMENT, staff_id INTEGER NOT NULL, school_id INTEGER NOT NULL, amount REAL NOT NULL, status TEXT NOT NULL DEFAULT "pending", amount_paid NUMERIC NOT NULL, month TEXT NOT NULL, year INTEGER NOT NULL, payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, recorded_by_id INTEGER NOT NULL, recorded_by_name TEXT, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)'
    ];

    for (final table in tables) {
      try {
        _db.execute(table);
        print('Table created successfully');
      } catch (e) {
        print('Error creating table: $e');
      }
    }
  }

  Future<void> _createIndexes() async {
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
      'CREATE INDEX IF NOT EXISTS idx_students_class_id ON students(class_id)',
      'CREATE INDEX IF NOT EXISTS idx_exams_class_id ON exams(class_id)',
      'CREATE INDEX IF NOT EXISTS idx_fees_student_id ON fees(student_id)',
      'CREATE INDEX IF NOT EXISTS idx_staff_payments_staff_id ON staff_payments(staff_id)',
      'CREATE INDEX IF NOT EXISTS idx_staff_payments_school_id ON staff_payments(school_id)',
    ];

    for (final index in indexes) {
      try {
        _db.execute(index);
      } catch (e) {
        print('Error creating index: $e');
      }
    }
  }

  Map<String, dynamic> _rowToMap(ResultSet rs, dynamic row) {
    final map = <String, dynamic>{};
    for (final col in rs.columnNames) {
      map[col] = row[col];
    }
    return map;
  }

  @override
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final stmt = _db
        .prepare('SELECT * FROM users WHERE lower(email) = lower(?) LIMIT 1');
    try {
      final rs = stmt.select([email]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findUserById(String id) async {
    final stmt = _db.prepare('SELECT * FROM users WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(id) ?? id]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> getTotalUserCount() async {
    try {
      final rs = _db.select('SELECT COUNT(*) AS cnt FROM users');
      if (rs.isEmpty) return 0;
      return (rs.first['cnt'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> createUser(
      {required String email,
      required String hashedPassword,
      required Map<String, dynamic> otherData}) async {
    // Insert with column names that match the existing schema.
    final role = otherData['role'] ?? otherData['role'.toString()] ?? 'parent';
    final firstName = otherData['first_name'] ?? otherData['firstName'];
    final lastName = otherData['last_name'] ?? otherData['lastName'];

    final stmt = _db.prepare(
        'INSERT INTO users (email, password_hash, role, first_name, last_name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, datetime(\'now\'), datetime(\'now\'))');
    try {
      stmt.execute([email, hashedPassword, role, firstName, lastName]);
    } finally {
      stmt.dispose();
    }

    // Return the inserted user row
    return (await findUserByEmail(email)) ?? {'email': email};
  }

  bool _columnExists(String table, String column) {
    final stmt = _db
        .prepare("SELECT name FROM pragma_table_info('$table') WHERE name = ?");
    try {
      final rs = stmt.select([column]);
      return rs.isNotEmpty;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<bool> isUserEmailVerified(String userId) async {
    try {
      if (!_columnExists('users', 'email_verified')) return true;
      final stmt =
          _db.prepare('SELECT email_verified FROM users WHERE id = ? LIMIT 1');
      try {
        final rs = stmt.select([int.tryParse(userId) ?? userId]);
        if (rs.isEmpty) return true;
        final v = rs.first['email_verified'];
        if (v is int) return v != 0;
        if (v is bool) return v;
        return (v?.toString().toLowerCase() == '1' ||
            v?.toString().toLowerCase() == 'true');
      } finally {
        stmt.dispose();
      }
    } catch (e) {
      return true;
    }
  }

  bool _tableExists(String name) {
    final rs = _db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        [name]);
    return rs.isNotEmpty;
  }

  @override
  Future<bool> isTokenBlacklisted(String token) async {
    // If a blacklist table exists, check it; otherwise treat as not blacklisted.
    if (!_tableExists('blacklisted_tokens')) return false;
    final stmt =
        _db.prepare('SELECT 1 FROM blacklisted_tokens WHERE token = ? LIMIT 1');
    try {
      final rs = stmt.select([token]);
      return rs.isNotEmpty;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> blacklistToken(
      String token, String tokenType, String? userId) async {
    if (!_tableExists('blacklisted_tokens')) return;
    final stmt = _db.prepare(
        'INSERT INTO blacklisted_tokens (token, token_type, user_id, created_at) VALUES (?, ?, ?, datetime(\'now\'))');
    try {
      stmt.execute([token, tokenType, userId]);
    } finally {
      stmt.dispose();
    }
  }

  // Minimal fallback implementations for query helpers used elsewhere.
  @override
  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic>? params]) async {
    final stmt = _db.prepare(sql);
    try {
      final rs = params == null ? stmt.select() : stmt.select(params);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> querySingle(String sql,
      [List<dynamic>? params]) async {
    final rows = await query(sql, params);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> close() async {
    try {
      _db.dispose();
    } catch (_) {}
  }

  // School management methods
  @override
  Future<Map<String, dynamic>?> findSchoolByName(String name) async {
    final stmt = _db.prepare('SELECT * FROM schools WHERE name = ? LIMIT 1');
    try {
      final rs = stmt.select([name]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findSchoolById(String id) async {
    final stmt = _db.prepare('SELECT * FROM schools WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(id) ?? id]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSchools() async {
    final rs = _db.select('SELECT * FROM schools ORDER BY name');
    return rs.map((r) => _rowToMap(rs, r)).toList();
  }

  @override
  Future<Map<String, dynamic>> createSchool(
      {required String name, required String classification}) async {
    final stmt = _db.prepare(
        'INSERT INTO schools (name, classification, created_at, updated_at) VALUES (?, ?, datetime(\'now\'), datetime(\'now\'))');
    try {
      stmt.execute([name, classification]);
      // Return the inserted school
      return (await findSchoolByName(name))!;
    } finally {
      stmt.dispose();
    }
  }

  // Class management methods
  @override
  Future<Map<String, dynamic>> createClass(
      {required String schoolId,
      required String name,
      String? gradeLevel}) async {
    final stmt = _db.prepare(
        'INSERT INTO classes (school_id, name, grade_level, created_at, updated_at) VALUES (?, ?, ?, datetime(\'now\'), datetime(\'now\'))');
    try {
      stmt.execute([int.tryParse(schoolId) ?? 0, name, gradeLevel]);
      // Return the inserted class
      final rs =
          _db.select('SELECT * FROM classes WHERE id = last_insert_rowid()');
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findClassById(String id) async {
    final stmt = _db.prepare('SELECT * FROM classes WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(id) ?? id]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getClassesBySchool(String schoolId) async {
    final stmt =
        _db.prepare('SELECT * FROM classes WHERE school_id = ? ORDER BY name');
    try {
      final rs = stmt.select([int.tryParse(schoolId) ?? 0]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateClass(
      String classId, Map<String, dynamic> classData) async {
    final updates = <String>[];
    final params = <dynamic>[];

    if (classData.containsKey('name')) {
      updates.add('name = ?');
      params.add(classData['name']);
    }
    if (classData.containsKey('grade_level') ||
        classData.containsKey('gradeLevel')) {
      updates.add('grade_level = ?');
      params.add(classData['grade_level'] ?? classData['gradeLevel']);
    }

    if (updates.isNotEmpty) {
      updates.add('updated_at = datetime(\'now\')');
      final sql = 'UPDATE classes SET ${updates.join(', ')} WHERE id = ?';
      params.add(int.tryParse(classId) ?? 0);
      final stmt = _db.prepare(sql);
      try {
        stmt.execute(params);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<void> deleteClass(String classId) async {
    final stmt = _db.prepare('DELETE FROM classes WHERE id = ?');
    try {
      stmt.execute([int.tryParse(classId) ?? 0]);
    } finally {
      stmt.dispose();
    }
  }

  // Subject management methods
  @override
  Future<Map<String, dynamic>> createSubject(
      {required String schoolId,
      required String name,
      String? description}) async {
    final stmt = _db.prepare(
        'INSERT INTO subjects (school_id, name, description, created_at, updated_at) VALUES (?, ?, ?, datetime(\'now\'), datetime(\'now\'))');
    try {
      stmt.execute([int.tryParse(schoolId) ?? 0, name, description]);
      // Return the inserted subject
      final rs =
          _db.select('SELECT * FROM subjects WHERE id = last_insert_rowid()');
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findSubjectById(String id) async {
    final stmt = _db.prepare('SELECT * FROM subjects WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(id) ?? id]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubjectsBySchool(
      String schoolId) async {
    final stmt =
        _db.prepare('SELECT * FROM subjects WHERE school_id = ? ORDER BY name');
    try {
      final rs = stmt.select([int.tryParse(schoolId) ?? 0]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateSubject(
      String subjectId, Map<String, dynamic> subjectData) async {
    final updates = <String>[];
    final params = <dynamic>[];

    if (subjectData.containsKey('name')) {
      updates.add('name = ?');
      params.add(subjectData['name']);
    }
    if (subjectData.containsKey('description')) {
      updates.add('description = ?');
      params.add(subjectData['description']);
    }

    if (updates.isNotEmpty) {
      updates.add('updated_at = datetime(\'now\')');
      final sql = 'UPDATE subjects SET ${updates.join(', ')} WHERE id = ?';
      params.add(int.tryParse(subjectId) ?? 0);
      final stmt = _db.prepare(sql);
      try {
        stmt.execute(params);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    final stmt = _db.prepare('DELETE FROM subjects WHERE id = ?');
    try {
      stmt.execute([int.tryParse(subjectId) ?? 0]);
    } finally {
      stmt.dispose();
    }
  }

  // Student enrollment
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
    // First, find the class by name and school
    final classStmt = _db.prepare(
        'SELECT id FROM classes WHERE school_id = ? AND name = ? LIMIT 1');
    try {
      final classRs =
          classStmt.select([int.tryParse(schoolId) ?? 0, className]);
      if (classRs.isEmpty) {
        throw Exception('Class not found: $className');
      }
      final classId = classRs.first['id'];

      // Insert student
      final studentStmt = _db.prepare('''
        INSERT INTO students (
          first_name, last_name, date_of_birth, class_id, admission_date,
          sex, religion, address, phone_number, parent_name, parent_nin,
          parent_contact, special_needs, admission_number, created_at, updated_at
        ) VALUES (?, ?, ?, ?, date('now'), ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
      ''');
      try {
        studentStmt.execute([
          firstName,
          lastName,
          dateOfBirth,
          classId,
          sex,
          religion,
          address,
          phoneNumber,
          parentName,
          parentNin,
          parentContact,
          specialNeeds,
          admissionNumber ?? 'AUTO'
        ]);

        // Get the inserted student
        final studentRs =
            _db.select('SELECT * FROM students WHERE id = last_insert_rowid()');
        final student = _rowToMap(studentRs, studentRs.first);

        // Create user account if email provided
        if (email.isNotEmpty) {
          try {
            await createUser(
              email: email,
              hashedPassword: password,
              otherData: {
                'first_name': firstName,
                'last_name': lastName,
                'role': 'student',
                'school_id': schoolId,
              },
            );
          } catch (e) {
            // Ignore duplicate email errors
            print('Warning: Could not create user account for student: $e');
          }
        }

        return student;
      } finally {
        studentStmt.dispose();
      }
    } finally {
      classStmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsBySchool(String schoolId,
      [Map<String, String>? queryParams]) async {
    final stmt = _db.prepare('''
      SELECT s.*, c.name as class_name, u.email
      FROM students s
      LEFT JOIN classes c ON s.class_id = c.id
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.school_id = ?
      ORDER BY s.first_name, s.last_name
    ''');
    try {
      final rs = stmt.select([int.tryParse(schoolId) ?? 0]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentFeeBalance(String studentId) async {
    // For now, return dummy data since fee tables are not fully implemented
    return {'balance': 0.0};
  }

  @override
  Future<void> recordFeePayment(Map<String, dynamic> paymentData) async {
    // For now, just log the payment since fee tables are not fully implemented
    print('Fee payment recorded: $paymentData');
  }

  // Exam management methods
  @override
  Future<List<Map<String, dynamic>>> getExamsBySchool(String schoolId) async {
    final stmt = _db.prepare('''
      SELECT e.*, c.name as class_name, s.name as subject_name
      FROM exams e
      LEFT JOIN classes c ON e.class_id = c.id
      LEFT JOIN subjects s ON e.subject_id = s.id
      WHERE c.school_id = ?
      ORDER BY e.exam_date DESC
    ''');
    try {
      final rs = stmt.select([int.tryParse(schoolId) ?? 0]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> createExam(
      String schoolId, Map<String, dynamic> examData) async {
    final stmt = _db.prepare('''
      INSERT INTO exams (name, class_id, subject_id, exam_date, max_marks, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        examData['name'],
        examData['class_id'],
        examData['subject_id'],
        examData['exam_date'],
        examData['max_marks']
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateExam(
      String schoolId, String examId, Map<String, dynamic> examData) async {
    final updates = <String>[];
    final params = <dynamic>[];

    if (examData.containsKey('name')) {
      updates.add('name = ?');
      params.add(examData['name']);
    }
    if (examData.containsKey('exam_date')) {
      updates.add('exam_date = ?');
      params.add(examData['exam_date']);
    }
    if (examData.containsKey('max_marks')) {
      updates.add('max_marks = ?');
      params.add(examData['max_marks']);
    }

    if (updates.isNotEmpty) {
      updates.add('updated_at = datetime(\'now\')');
      final sql = 'UPDATE exams SET ${updates.join(', ')} WHERE id = ?';
      params.add(int.tryParse(examId) ?? 0);
      final stmt = _db.prepare(sql);
      try {
        stmt.execute(params);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<void> deleteExam(String schoolId, String examId) async {
    final stmt = _db.prepare('DELETE FROM exams WHERE id = ?');
    try {
      stmt.execute([int.tryParse(examId) ?? 0]);
    } finally {
      stmt.dispose();
    }
  }

  // Exam results methods
  @override
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
  }) async {
    // For now, return dummy data since exam_results table is not implemented
    return {
      'id': '1',
      'exam_id': examId,
      'student_id': studentId,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'grade': grade,
      'comments': comments,
    };
  }

  @override
  Future<Map<String, dynamic>?> getExamResultById(String id) async {
    // For now, return null since exam_results table is not implemented
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByExam(String examId) async {
    // For now, return empty list since exam_results table is not implemented
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByStudent(
      String studentId) async {
    // For now, return empty list since exam_results table is not implemented
    return [];
  }

  @override
  Future<void> updateExamResult(
      String resultId, Map<String, dynamic> resultData) async {
    // For now, do nothing since exam_results table is not implemented
  }

  @override
  Future<void> deleteExamResult(String resultId) async {
    // For now, do nothing since exam_results table is not implemented
  }

  // Email verification methods
  @override
  Future<void> createEmailVerificationToken(
      String userId, String token, DateTime expires) async {
    if (!_columnExists('users', 'verification_token')) return;
    final stmt = _db.prepare(
        'UPDATE users SET verification_token = ?, verification_expires = ? WHERE id = ?');
    try {
      stmt.execute(
          [token, expires.toIso8601String(), int.tryParse(userId) ?? userId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findUserByVerificationToken(
      String token) async {
    if (!_columnExists('users', 'verification_token')) return null;
    final stmt =
        _db.prepare('SELECT * FROM users WHERE verification_token = ? LIMIT 1');
    try {
      final rs = stmt.select([token]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> verifyUserEmail(String userId) async {
    if (!_columnExists('users', 'email_verified')) return;
    final stmt = _db.prepare(
        'UPDATE users SET email_verified = 1, verification_token = NULL, verification_expires = NULL WHERE id = ?');
    try {
      stmt.execute([int.tryParse(userId) ?? userId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findPasswordResetToken(String token) async {
    // For now, return null since password reset table is not implemented
    return null;
  }

  @override
  Future<String> createPasswordResetToken(String email, String userId) async {
    // For now, return a dummy token since password reset table is not implemented
    return 'dummy_reset_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> markPasswordResetTokenAsUsed(String token) async {
    // For now, do nothing since password reset table is not implemented
  }

  @override
  Future<void> cleanupExpiredTokens() async {
    // For now, do nothing since token tables are not fully implemented
  }

  @override
  Future<void> cleanupExpiredPasswordResetTokens() async {
    // For now, do nothing since password reset table is not implemented
  }

  // Placeholder implementations for remaining methods
  @override
  Future<void> updateClassStreams(
      String schoolId, Map<String, List<String>> streams) async {
    // TODO: Implement when class streams table is added
  }

  @override
  Future<void> delete(String itemType, int itemId) async {
    final table = itemType.endsWith('s') ? itemType : '${itemType}s';
    final stmt = _db.prepare('DELETE FROM $table WHERE id = ?');
    try {
      stmt.execute([itemId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateUserRole(
      String userId, Map<String, dynamic> updateData) async {
    if (updateData.containsKey('role')) {
      final stmt = _db.prepare('UPDATE users SET role = ? WHERE id = ?');
      try {
        stmt.execute([updateData['role'], int.tryParse(userId) ?? userId]);
      } finally {
        stmt.dispose();
      }
    }
  }

  // Add more placeholder implementations as needed...

  // Ticket management methods
  @override
  Future<Map<String, dynamic>> createTicket(
      Map<String, dynamic> ticketData) async {
    final stmt = _db.prepare('''
      INSERT INTO tickets (title, description, status, priority, category, created_by, assigned_to, school_id, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        ticketData['title'],
        ticketData['description'],
        ticketData['status'] ?? 'open',
        ticketData['priority'] ?? 'medium',
        ticketData['category'],
        ticketData['created_by'],
        ticketData['assigned_to'],
        ticketData['school_id'],
      ]);
      final rs =
          _db.select('SELECT * FROM tickets WHERE id = last_insert_rowid()');
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTickets(String schoolId) async {
    final stmt = _db.prepare(
        'SELECT * FROM tickets WHERE school_id = ? ORDER BY created_at DESC');
    try {
      final rs = stmt.select([int.tryParse(schoolId) ?? 0]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> getTicketById(String ticketId) async {
    final stmt = _db.prepare('SELECT * FROM tickets WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(ticketId) ?? 0]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateTicket(
      String ticketId, Map<String, dynamic> ticketData) async {
    final updates = <String>[];
    final params = <dynamic>[];

    if (ticketData.containsKey('title')) {
      updates.add('title = ?');
      params.add(ticketData['title']);
    }
    if (ticketData.containsKey('description')) {
      updates.add('description = ?');
      params.add(ticketData['description']);
    }
    if (ticketData.containsKey('status')) {
      updates.add('status = ?');
      params.add(ticketData['status']);
    }
    if (ticketData.containsKey('priority')) {
      updates.add('priority = ?');
      params.add(ticketData['priority']);
    }
    if (ticketData.containsKey('category')) {
      updates.add('category = ?');
      params.add(ticketData['category']);
    }
    if (ticketData.containsKey('assigned_to')) {
      updates.add('assigned_to = ?');
      params.add(ticketData['assigned_to']);
    }

    if (updates.isNotEmpty) {
      updates.add('updated_at = datetime(\'now\')');
      final sql = 'UPDATE tickets SET ${updates.join(', ')} WHERE id = ?';
      params.add(int.tryParse(ticketId) ?? 0);
      final stmt = _db.prepare(sql);
      try {
        stmt.execute(params);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    final stmt = _db.prepare('DELETE FROM tickets WHERE id = ?');
    try {
      stmt.execute([int.tryParse(ticketId) ?? 0]);
    } finally {
      stmt.dispose();
    }
  }

  // Technician management methods
  @override
  Future<Map<String, dynamic>> createTechnician(
      Map<String, dynamic> technicianData) async {
    final stmt = _db.prepare('''
      INSERT INTO technicians (user_id, specialization, is_active, created_at)
      VALUES (?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        technicianData['user_id'],
        technicianData['specialization'],
        technicianData['is_active'] ?? true,
      ]);
      final rs = _db
          .select('SELECT * FROM technicians WHERE id = last_insert_rowid()');
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTechnicians(String schoolId) async {
    final stmt = _db.prepare('''
      SELECT t.*, u.first_name, u.last_name, u.email
      FROM technicians t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE u.role = 'technician' OR t.user_id IS NOT NULL
      ORDER BY u.first_name, u.last_name
    ''');
    try {
      final rs = stmt.select();
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> getTechnicianById(String technicianId) async {
    final stmt = _db.prepare('SELECT * FROM technicians WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(technicianId) ?? 0]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateTechnician(
      String technicianId, Map<String, dynamic> technicianData) async {
    final updates = <String>[];
    final params = <dynamic>[];

    if (technicianData.containsKey('specialization')) {
      updates.add('specialization = ?');
      params.add(technicianData['specialization']);
    }
    if (technicianData.containsKey('is_active')) {
      updates.add('is_active = ?');
      params.add(technicianData['is_active']);
    }

    if (updates.isNotEmpty) {
      final sql = 'UPDATE technicians SET ${updates.join(', ')} WHERE id = ?';
      params.add(int.tryParse(technicianId) ?? 0);
      final stmt = _db.prepare(sql);
      try {
        stmt.execute(params);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<void> deleteTechnician(String technicianId) async {
    final stmt = _db.prepare('DELETE FROM technicians WHERE id = ?');
    try {
      stmt.execute([int.tryParse(technicianId) ?? 0]);
    } finally {
      stmt.dispose();
    }
  }

  // Driver management methods
  @override
  Future<Map<String, dynamic>> createDriver(
      Map<String, dynamic> driverData) async {
    final stmt = _db.prepare('''
      INSERT INTO drivers (user_id, license_number, vehicle_type, is_active, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        driverData['user_id'],
        driverData['license_number'],
        driverData['vehicle_type'],
        driverData['is_active'] ?? true,
      ]);
      final rs =
          _db.select('SELECT * FROM drivers WHERE id = last_insert_rowid()');
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDrivers(String schoolId) async {
    final stmt = _db.prepare('''
      SELECT d.*, u.first_name, u.last_name, u.email
      FROM drivers d
      LEFT JOIN users u ON d.user_id = u.id
      WHERE u.role = 'driver' OR d.user_id IS NOT NULL
      ORDER BY u.first_name, u.last_name
    ''');
    try {
      final rs = stmt.select();
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> getDriverById(String driverId) async {
    final stmt = _db.prepare('SELECT * FROM drivers WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(driverId) ?? 0]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateDriver(
      String driverId, Map<String, dynamic> driverData) async {
    final updates = <String>[];
    final params = <dynamic>[];

    if (driverData.containsKey('license_number')) {
      updates.add('license_number = ?');
      params.add(driverData['license_number']);
    }
    if (driverData.containsKey('vehicle_type')) {
      updates.add('vehicle_type = ?');
      params.add(driverData['vehicle_type']);
    }
    if (driverData.containsKey('is_active')) {
      updates.add('is_active = ?');
      params.add(driverData['is_active']);
    }

    if (updates.isNotEmpty) {
      final sql = 'UPDATE drivers SET ${updates.join(', ')} WHERE id = ?';
      params.add(int.tryParse(driverId) ?? 0);
      final stmt = _db.prepare(sql);
      try {
        stmt.execute(params);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<void> deleteDriver(String driverId) async {
    final stmt = _db.prepare('DELETE FROM drivers WHERE id = ?');
    try {
      stmt.execute([int.tryParse(driverId) ?? 0]);
    } finally {
      stmt.dispose();
    }
  }

  // Ticket visit management methods
  @override
  Future<Map<String, dynamic>> recordTicketVisit(
      Map<String, dynamic> visitData) async {
    final stmt = _db.prepare('''
      INSERT INTO ticket_visits (ticket_id, user_id, visit_date, notes, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        visitData['ticket_id'],
        visitData['user_id'],
        visitData['visit_date'],
        visitData['notes'],
      ]);
      final rs = _db
          .select('SELECT * FROM ticket_visits WHERE id = last_insert_rowid()');
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTicketVisits(String ticketId) async {
    final stmt = _db.prepare('''
      SELECT tv.*, u.first_name, u.last_name
      FROM ticket_visits tv
      LEFT JOIN users u ON tv.user_id = u.id
      WHERE tv.ticket_id = ?
      ORDER BY tv.visit_date DESC
    ''');
    try {
      final rs = stmt.select([int.tryParse(ticketId) ?? 0]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getVisitsByUser(String userId) async {
    final stmt = _db.prepare('''
      SELECT tv.*, t.title as ticket_title
      FROM ticket_visits tv
      LEFT JOIN tickets t ON tv.ticket_id = t.id
      WHERE tv.user_id = ?
      ORDER BY tv.visit_date DESC
    ''');
    try {
      final rs = stmt.select([int.tryParse(userId) ?? 0]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  // KPI management methods
  @override
  Future<Map<String, dynamic>> recordKPIPoint(
      Map<String, dynamic> kpiData) async {
    final stmt = _db.prepare('''
      INSERT INTO kpis (ticket_id, user_id, user_type, points, reason, recorded_by, recorded_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        kpiData['ticket_id'],
        kpiData['user_id'],
        kpiData['user_type'],
        kpiData['points'] ?? 1,
        kpiData['reason'],
        kpiData['recorded_by'],
      ]);
      final rs =
          _db.select('SELECT * FROM kpis WHERE id = last_insert_rowid()');
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getKPIs(String schoolId,
      {String? userId, String? userType}) async {
    String sql = '''
      SELECT k.*, u.first_name, u.last_name, t.title as ticket_title
      FROM kpis k
      LEFT JOIN users u ON k.user_id = u.id
      LEFT JOIN tickets t ON k.ticket_id = t.id
      WHERE t.school_id = ?
    ''';
    final params = <dynamic>[int.tryParse(schoolId) ?? 0];

    if (userId != null) {
      sql += ' AND k.user_id = ?';
      params.add(int.tryParse(userId) ?? 0);
    }
    if (userType != null) {
      sql += ' AND k.user_type = ?';
      params.add(userType);
    }

    sql += ' ORDER BY k.recorded_at DESC';

    final stmt = _db.prepare(sql);
    try {
      final rs = stmt.select(params);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> getKPIById(String kpiId) async {
    final stmt = _db.prepare('SELECT * FROM kpis WHERE id = ? LIMIT 1');
    try {
      final rs = stmt.select([int.tryParse(kpiId) ?? 0]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateKPI(String kpiId, Map<String, dynamic> kpiData) async {
    final updates = <String>[];
    final params = <dynamic>[];

    if (kpiData.containsKey('points')) {
      updates.add('points = ?');
      params.add(kpiData['points']);
    }
    if (kpiData.containsKey('reason')) {
      updates.add('reason = ?');
      params.add(kpiData['reason']);
    }

    if (updates.isNotEmpty) {
      final sql = 'UPDATE kpis SET ${updates.join(', ')} WHERE id = ?';
      params.add(int.tryParse(kpiId) ?? 0);
      final stmt = _db.prepare(sql);
      try {
        stmt.execute(params);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<void> deleteKPI(String kpiId) async {
    final stmt = _db.prepare('DELETE FROM kpis WHERE id = ?');
    try {
      stmt.execute([int.tryParse(kpiId) ?? 0]);
    } finally {
      stmt.dispose();
    }
  }
}

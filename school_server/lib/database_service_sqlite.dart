import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

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

    // Initialize schema if tables don't exist.
    await _initializeSchema();

    _opened = true;
  }

  Future<void> _initializeSchema() async {
    try {
      // Check if users table exists.
      final rs = _db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
      if (rs.isEmpty) {
        print('Initializing database schema...');
        await _createTables();
        await _createIndexes();
        print('Database schema initialized successfully');
      } else {
        // Ensure newer columns exist for older databases.
        await _ensureBaseColumns();
      }
    } catch (e) {
      print('Error initializing schema: $e');
    }
  }

  Future<void> _createTables() async {
    // NOTE: Each CREATE TABLE includes the fields used by server queries.
    final tables = <String>[
      '''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'parent',
        first_name TEXT,
        last_name TEXT,
        profile_picture_url TEXT,
        school_id INTEGER,
        email_verified BOOLEAN DEFAULT FALSE,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS schools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        classification TEXT DEFAULT 'Primary',
        address TEXT,
        phone TEXT,
        email TEXT UNIQUE,
        self_registration_enabled BOOLEAN DEFAULT FALSE,
        logo_url TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        grade_level TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (school_id) REFERENCES schools (id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS class_streams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        class_name TEXT NOT NULL,
        streams_json TEXT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (school_id, class_name)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT,
        description TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (school_id) REFERENCES schools (id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        school_id INTEGER NOT NULL,
        class_id INTEGER NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        date_of_birth DATE,
        admission_number TEXT,
        sex TEXT,
        religion TEXT,
        phone_number TEXT,
        address TEXT,
        parent_name TEXT,
        parent_nin TEXT,
        parent_contact TEXT,
        special_needs TEXT,
        subject_codes TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (school_id) REFERENCES schools (id) ON DELETE CASCADE,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS student_parents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        parent_user_id INTEGER NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (parent_user_id) REFERENCES users (id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        class_id INTEGER,
        subject_id INTEGER,
        teacher_id INTEGER,
        exam_date DATE,
        max_marks REAL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS exam_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        exam_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        marks_obtained REAL NOT NULL,
        total_marks REAL NOT NULL,
        recorded_by TEXT NOT NULL,
        grade TEXT,
        comments TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS fee_structures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT,
        amount REAL,
        description TEXT,
        class_name TEXT,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS fee_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER,
        student_id INTEGER,
        amount REAL NOT NULL,
        payment_method TEXT,
        reference TEXT,
        paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS student_applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        status TEXT DEFAULT 'pending',
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS salary_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        staff_id INTEGER,
        amount REAL,
        status TEXT,
        month TEXT,
        year INTEGER,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS report_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        term TEXT NOT NULL,
        year TEXT NOT NULL,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        author TEXT,
        isbn TEXT,
        copies_total INTEGER DEFAULT 1,
        copies_available INTEGER DEFAULT 1,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS book_borrowings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        book_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        borrowed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        due_at DATETIME,
        returned_at DATETIME,
        data_json TEXT
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS schemes_of_work (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        class_name TEXT NOT NULL,
        term TEXT NOT NULL,
        year INTEGER NOT NULL,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS lesson_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        teacher_id INTEGER,
        subject TEXT,
        class_name TEXT,
        term TEXT,
        year INTEGER,
        lesson_date TEXT,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS timetable_constraints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        day TEXT,
        slot_id TEXT,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS timetable_lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        class_name TEXT NOT NULL,
        teacher_id TEXT,
        day TEXT NOT NULL,
        slot_id TEXT NOT NULL,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS subject_constraints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL UNIQUE,
        constraints_json TEXT NOT NULL,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS social_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        data_json TEXT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
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
      ''',
      '''
      CREATE TABLE IF NOT EXISTS email_verification_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        expires_at DATETIME NOT NULL,
        used BOOLEAN DEFAULT FALSE,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS password_reset_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        email TEXT NOT NULL,
        token TEXT NOT NULL,
        expires_at DATETIME NOT NULL,
        used BOOLEAN DEFAULT FALSE,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS blacklisted_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token TEXT NOT NULL,
        token_type TEXT NOT NULL,
        user_id TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        class_id INTEGER,
        student_id INTEGER,
        attendance_date TEXT,
        status TEXT,
        term TEXT,
        year INTEGER,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS gradebook_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        class_id INTEGER,
        student_id INTEGER,
        subject TEXT,
        term TEXT,
        year INTEGER,
        score REAL,
        total REAL,
        data_json TEXT,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        education_level TEXT NOT NULL,
        description TEXT,
        periods_per_week_s1_s2 INTEGER,
        periods_per_week_s3_s4 INTEGER,
        rationale TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_strands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        senior_level TEXT NOT NULL,
        term TEXT NOT NULL,
        duration_periods INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES curriculum_subjects(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        strand_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        competency TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (strand_id) REFERENCES curriculum_strands(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_learning_outcomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        outcome TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        activity TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        assessment TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_cross_cutting_issues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        issue TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES curriculum_subjects(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        value TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES curriculum_subjects(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS curriculum_generic_skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        skill TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES curriculum_subjects(id) ON DELETE CASCADE
      )
      ''',
    ];

    for (final table in tables) {
      try {
        _db.execute(table);
      } catch (e) {
        print('Error creating table: $e');
      }
    }

    await _ensureBaseColumns();
  }

  Future<void> _ensureBaseColumns() async {
    // Ensure columns for backwards compatibility with older DB files.
    _ensureColumn('users', 'school_id', 'INTEGER');
    _ensureColumn('users', 'email_verified', 'BOOLEAN DEFAULT FALSE');
    _ensureColumn('schools', 'classification', "TEXT DEFAULT 'Primary'");
    _ensureColumn('schools', 'self_registration_enabled',
        'BOOLEAN DEFAULT FALSE');
    _ensureColumn('schools', 'logo_url', 'TEXT');
    _ensureColumn('subjects', 'code', 'TEXT');
    _ensureColumn('students', 'user_id', 'INTEGER');
    _ensureColumn('students', 'school_id', 'INTEGER');
    _ensureColumn('students', 'subject_codes', 'TEXT');
  }

  Future<void> _createIndexes() async {
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
      'CREATE INDEX IF NOT EXISTS idx_students_class_id ON students(class_id)',
      'CREATE INDEX IF NOT EXISTS idx_exams_class_id ON exams(class_id)',
      'CREATE INDEX IF NOT EXISTS idx_fee_structures_school_id ON fee_structures(school_id)',
      'CREATE INDEX IF NOT EXISTS idx_fee_payments_student_id ON fee_payments(student_id)',
      'CREATE INDEX IF NOT EXISTS idx_student_applications_school_id ON student_applications(school_id)',
      'CREATE INDEX IF NOT EXISTS idx_salary_records_school_id ON salary_records(school_id)',
      'CREATE INDEX IF NOT EXISTS idx_report_cards_student_id ON report_cards(student_id)',
      'CREATE INDEX IF NOT EXISTS idx_books_school_id ON books(school_id)',
      'CREATE INDEX IF NOT EXISTS idx_borrowings_student_id ON book_borrowings(student_id)',
      'CREATE INDEX IF NOT EXISTS idx_timetable_lessons_school ON timetable_lessons(school_id, class_name)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_target ON notifications(target_type, target_id)',
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

  String _toSnakeCase(String key) {
    if (key.contains('_')) return key;
    return key
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
        .toLowerCase();
  }

  String _generateToken({int length = 32}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = math.Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  dynamic _safeJsonDecode(Object? raw, {dynamic fallback}) {
    if (raw is String && raw.isNotEmpty) {
      return jsonDecode(raw);
    }
    return fallback;
  }

  void _ensureColumn(String table, String column, String definition) {
    if (_columnExists(table, column)) return;
    try {
      _db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    } catch (e) {
      print('Error adding column $column to $table: $e');
    }
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

  bool _tableExists(String name) {
    final rs = _db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        [name]);
    return rs.isNotEmpty;
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
  Future<List<Map<String, dynamic>>> getAllUsers(int limit, int offset) async {
    final stmt = _db.prepare(
        'SELECT * FROM users ORDER BY created_at DESC LIMIT ? OFFSET ?');
    try {
      final rs = stmt.select([limit, offset]);
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateUserSettings(
      String userId, Map<String, dynamic> settings) async {
    if (settings.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];

    settings.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });

    updates.add('updated_at = CURRENT_TIMESTAMP');

    final stmt =
        _db.prepare('UPDATE users SET ${updates.join(', ')} WHERE id = ?');
    try {
      values.add(int.tryParse(userId) ?? userId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    final stmt = _db.prepare('DELETE FROM users WHERE id = ?');
    try {
      stmt.execute([int.tryParse(userId) ?? userId]);
    } finally {
      stmt.dispose();
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
    final schoolId = otherData['school_id'] ?? otherData['schoolId'];

    final stmt = _db.prepare('''
      INSERT INTO users (email, password_hash, role, first_name, last_name, school_id, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([email, hashedPassword, role, firstName, lastName, schoolId]);
    } finally {
      stmt.dispose();
    }

    // Return the inserted user row.
    return (await findUserByEmail(email)) ?? {'email': email};
  }

  @override
  Future<void> createEmailVerificationToken(
      String userId, String token, DateTime expires) async {
    final stmt = _db.prepare('''
      INSERT INTO email_verification_tokens (user_id, token, expires_at, used)
      VALUES (?, ?, ?, 0)
    ''');
    try {
      stmt.execute([int.tryParse(userId) ?? userId, token, expires.toIso8601String()]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findUserByVerificationToken(String token) async {
    final stmt = _db.prepare('''
      SELECT u.*, evt.token, evt.expires_at, evt.used
      FROM email_verification_tokens evt
      JOIN users u ON evt.user_id = u.id
      WHERE evt.token = ? AND evt.used = 0
      LIMIT 1
    ''');
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
    // Mark user verified.
    final stmt =
        _db.prepare('UPDATE users SET email_verified = 1 WHERE id = ?');
    try {
      stmt.execute([int.tryParse(userId) ?? userId]);
    } finally {
      stmt.dispose();
    }

    // Mark tokens used.
    final tokenStmt = _db.prepare(
        'UPDATE email_verification_tokens SET used = 1 WHERE user_id = ?');
    try {
      tokenStmt.execute([int.tryParse(userId) ?? userId]);
    } finally {
      tokenStmt.dispose();
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

  @override
  Future<void> cleanupExpiredVerificationTokens() async {
    final stmt = _db.prepare(
        "DELETE FROM email_verification_tokens WHERE expires_at < datetime('now')");
    try {
      stmt.execute();
    } finally {
      stmt.dispose();
    }
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

  @override
  Future<void> cleanupExpiredTokens() async {
    // Cleanup tokens older than 45 days to keep table bounded.
    final stmt = _db.prepare(
        "DELETE FROM blacklisted_tokens WHERE created_at < datetime('now', '-45 days')");
    try {
      stmt.execute();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<String> createPasswordResetToken(String email, String userId) async {
    final token = _generateToken();
    final expires = DateTime.now().add(const Duration(hours: 1));
    final stmt = _db.prepare('''
      INSERT INTO password_reset_tokens (user_id, email, token, expires_at, used)
      VALUES (?, ?, ?, ?, 0)
    ''');
    try {
      stmt.execute(
          [int.tryParse(userId) ?? userId, email, token, expires.toIso8601String()]);
    } finally {
      stmt.dispose();
    }
    return token;
  }

  @override
  Future<Map<String, dynamic>?> findPasswordResetToken(String token) async {
    final stmt = _db.prepare('''
      SELECT * FROM password_reset_tokens
      WHERE token = ? AND used = 0 AND expires_at >= datetime('now')
      LIMIT 1
    ''');
    try {
      final rs = stmt.select([token]);
      if (rs.isEmpty) return null;
      return _rowToMap(rs, rs.first);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> markPasswordResetTokenAsUsed(String token) async {
    final stmt = _db.prepare(
        'UPDATE password_reset_tokens SET used = 1 WHERE token = ?');
    try {
      stmt.execute([token]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> cleanupExpiredPasswordResetTokens() async {
    final stmt = _db.prepare(
        "DELETE FROM password_reset_tokens WHERE expires_at < datetime('now')");
    try {
      stmt.execute();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> findSchoolByName(String name) async {
    final stmt =
        _db.prepare('SELECT * FROM schools WHERE lower(name) = lower(?)');
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
    final stmt = _db.prepare('SELECT * FROM schools WHERE id = ?');
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
    final stmt = _db.prepare('SELECT * FROM schools ORDER BY name ASC');
    try {
      final rs = stmt.select();
      return rs.map((r) => _rowToMap(rs, r)).toList();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>> createSchool(
      {required String name, required String classification}) async {
    final stmt = _db.prepare('''
      INSERT INTO schools (name, classification, created_at, updated_at)
      VALUES (?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([name, classification]);
    } finally {
      stmt.dispose();
    }
    return (await findSchoolByName(name)) ?? {'name': name};
  }

  Future<void> updateSchoolSettings(String schoolId,
      {required bool selfRegistrationEnabled}) async {
    final stmt = _db.prepare('''
      UPDATE schools
      SET self_registration_enabled = ?, updated_at = datetime('now')
      WHERE id = ?
    ''');
    try {
      stmt.execute([selfRegistrationEnabled ? 1 : 0, int.tryParse(schoolId) ?? schoolId]);
    } finally {
      stmt.dispose();
    }
  }

  Future<void> updateSchoolGeneralSettings(
      String schoolId, Map<String, dynamic> settings) async {
    if (settings.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    settings.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt =
        _db.prepare('UPDATE schools SET ${updates.join(', ')} WHERE id = ?');
    try {
      values.add(int.tryParse(schoolId) ?? schoolId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  Future<void> updateSchoolLogoUrl(String schoolId, String logoUrl) async {
    final stmt = _db.prepare(
        'UPDATE schools SET logo_url = ?, updated_at = datetime(\'now\') WHERE id = ?');
    try {
      stmt.execute([logoUrl, int.tryParse(schoolId) ?? schoolId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateClassStreams(
      String schoolId, Map<String, List<String>> streams) async {
    for (final entry in streams.entries) {
      // Replace existing stream data for the class (safe even without UNIQUE constraints).
      final deleteStmt = _db.prepare(
          'DELETE FROM class_streams WHERE school_id = ? AND class_name = ?');
      try {
        deleteStmt.execute([
          int.tryParse(schoolId) ?? schoolId,
          entry.key,
        ]);
      } finally {
        deleteStmt.dispose();
      }

      final stmt = _db.prepare('''
        INSERT INTO class_streams (school_id, class_name, streams_json, updated_at)
        VALUES (?, ?, ?, datetime('now'))
      ''');
      try {
        stmt.execute([
          int.tryParse(schoolId) ?? schoolId,
          entry.key,
          jsonEncode(entry.value),
        ]);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<Map<String, dynamic>> createClass(
      {required String schoolId, required String name, String? gradeLevel}) async {
    final stmt = _db.prepare('''
      INSERT INTO classes (school_id, name, grade_level, created_at, updated_at)
      VALUES (?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([int.tryParse(schoolId) ?? schoolId, name, gradeLevel]);
    } finally {
      stmt.dispose();
    }
    final classRow = await querySingle(
        'SELECT * FROM classes WHERE school_id = ? AND name = ? ORDER BY id DESC LIMIT 1',
        [int.tryParse(schoolId) ?? schoolId, name]);
    return classRow ?? {'name': name};
  }

  @override
  Future<Map<String, dynamic>?> findClassById(String id) async {
    return querySingle('SELECT * FROM classes WHERE id = ?',
        [int.tryParse(id) ?? id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getClassesBySchool(String schoolId) async {
    return query('SELECT * FROM classes WHERE school_id = ? ORDER BY name ASC',
        [int.tryParse(schoolId) ?? schoolId]);
  }

  @override
  Future<void> updateClass(String classId, Map<String, dynamic> classData) async {
    if (classData.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    classData.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt =
        _db.prepare('UPDATE classes SET ${updates.join(', ')} WHERE id = ?');
    try {
      values.add(int.tryParse(classId) ?? classId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> deleteClass(String classId) async {
    final stmt = _db.prepare('DELETE FROM classes WHERE id = ?');
    try {
      stmt.execute([int.tryParse(classId) ?? classId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertSubject(Map<String, dynamic> subject) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_subjects (name, education_level, description, periods_per_week_s1_s2, periods_per_week_s3_s4, rationale)
      VALUES (?, ?, ?, ?, ?, ?)
    ''');
    try {
      stmt.execute([
        subject['name'],
        subject['education_level'],
        subject['description'],
        subject['periods_per_week_s1_s2'],
        subject['periods_per_week_s3_s4'],
        subject['rationale'],
      ]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertStrand(Map<String, dynamic> strand) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_strands (subject_id, name, senior_level, term, duration_periods)
      VALUES (?, ?, ?, ?, ?)
    ''');
    try {
      stmt.execute([
        strand['subject_id'],
        strand['name'],
        strand['senior_level'],
        strand['term'],
        strand['duration_periods'],
      ]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertTopic(Map<String, dynamic> topic) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_topics (strand_id, name, competency)
      VALUES (?, ?, ?)
    ''');
    try {
      stmt.execute([
        topic['strand_id'],
        topic['name'],
        topic['competency'],
      ]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertSubTopic(Map<String, dynamic> subTopic) async {
    // Store sub-topics as learning outcomes for now.
    return insertLearningOutcome(subTopic);
  }

  @override
  Future<int> insertLearningOutcome(Map<String, dynamic> outcome) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_learning_outcomes (topic_id, outcome)
      VALUES (?, ?)
    ''');
    try {
      stmt.execute([outcome['topic_id'], outcome['outcome'] ?? outcome['name']]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertSuggestedActivity(Map<String, dynamic> activity) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_activities (topic_id, activity, type)
      VALUES (?, ?, ?)
    ''');
    try {
      stmt.execute([
        activity['topic_id'],
        activity['activity'] ?? activity['name'],
        activity['type'] ?? 'suggested',
      ]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertAssessmentStrategy(Map<String, dynamic> strategy) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_assessments (topic_id, assessment, type)
      VALUES (?, ?, ?)
    ''');
    try {
      stmt.execute([
        strategy['topic_id'],
        strategy['assessment'] ?? strategy['name'],
        strategy['type'] ?? 'formative',
      ]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertCrossCuttingIssue(Map<String, dynamic> issue) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_cross_cutting_issues (subject_id, issue, description)
      VALUES (?, ?, ?)
    ''');
    try {
      stmt.execute([issue['subject_id'], issue['issue'], issue['description']]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertValue(Map<String, dynamic> value) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_values (subject_id, value)
      VALUES (?, ?)
    ''');
    try {
      stmt.execute([value['subject_id'], value['value'] ?? value['name']]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertGenericSkill(Map<String, dynamic> skill) async {
    final stmt = _db.prepare('''
      INSERT INTO curriculum_generic_skills (subject_id, skill)
      VALUES (?, ?)
    ''');
    try {
      stmt.execute([skill['subject_id'], skill['skill'] ?? skill['name']]);
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubjects() async {
    return query('SELECT * FROM curriculum_subjects ORDER BY name ASC');
  }

  @override
  Future<List<Map<String, dynamic>>> getStrandsBySubject(int subjectId) async {
    return query('SELECT * FROM curriculum_strands WHERE subject_id = ?',
        [subjectId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getTopicsByStrand(int strandId) async {
    return query('SELECT * FROM curriculum_topics WHERE strand_id = ?',
        [strandId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getLearningOutcomesByTopic(
      int topicId) async {
    return query(
        'SELECT * FROM curriculum_learning_outcomes WHERE topic_id = ?',
        [topicId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getActivitiesByOutcome(
      int outcomeId) async {
    // Activities are stored by topic, so treat outcomeId as topicId for now.
    return query('SELECT * FROM curriculum_activities WHERE topic_id = ?',
        [outcomeId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getStrategiesByOutcome(
      int outcomeId) async {
    return query('SELECT * FROM curriculum_assessments WHERE topic_id = ?',
        [outcomeId]);
  }

  @override
  Future<Map<String, dynamic>> createSubject(
      {required String schoolId,
      required String name,
      String? description}) async {
    final code = name
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, math.min(10, name.length));
    final stmt = _db.prepare('''
      INSERT INTO subjects (school_id, name, code, description, created_at, updated_at)
      VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([int.tryParse(schoolId) ?? schoolId, name, code, description]);
    } finally {
      stmt.dispose();
    }
    return (await querySingle(
            'SELECT * FROM subjects WHERE school_id = ? AND name = ? ORDER BY id DESC LIMIT 1',
            [int.tryParse(schoolId) ?? schoolId, name])) ??
        {'name': name};
  }

  @override
  Future<Map<String, dynamic>?> findSubjectById(String id) async {
    return querySingle('SELECT * FROM subjects WHERE id = ?',
        [int.tryParse(id) ?? id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getSubjectsBySchool(String schoolId) async {
    return query('SELECT * FROM subjects WHERE school_id = ? ORDER BY name ASC',
        [int.tryParse(schoolId) ?? schoolId]);
  }

  @override
  Future<void> updateSubject(
      String subjectId, Map<String, dynamic> subjectData) async {
    if (subjectData.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    subjectData.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt =
        _db.prepare('UPDATE subjects SET ${updates.join(', ')} WHERE id = ?');
    try {
      values.add(int.tryParse(subjectId) ?? subjectId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    final stmt = _db.prepare('DELETE FROM subjects WHERE id = ?');
    try {
      stmt.execute([int.tryParse(subjectId) ?? subjectId]);
    } finally {
      stmt.dispose();
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
    final stmt = _db.prepare('''
      INSERT INTO exam_results
        (school_id, exam_id, student_id, subject_id, marks_obtained, total_marks, recorded_by, grade, comments, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        int.tryParse(examId) ?? examId,
        int.tryParse(studentId) ?? studentId,
        int.tryParse(subjectId) ?? subjectId,
        marksObtained,
        totalMarks,
        recordedBy,
        grade,
        comments,
      ]);
    } finally {
      stmt.dispose();
    }

    final row = await querySingle(
        'SELECT * FROM exam_results WHERE school_id = ? ORDER BY id DESC LIMIT 1',
        [int.tryParse(schoolId) ?? schoolId]);
    return row ?? {'exam_id': examId};
  }

  @override
  Future<Map<String, dynamic>?> getExamResultById(String id) async {
    return querySingle('SELECT * FROM exam_results WHERE id = ?',
        [int.tryParse(id) ?? id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByExam(String examId) async {
    return query('SELECT * FROM exam_results WHERE exam_id = ?',
        [int.tryParse(examId) ?? examId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getExamResultsByStudent(
      String studentId) async {
    return query('SELECT * FROM exam_results WHERE student_id = ?',
        [int.tryParse(studentId) ?? studentId]);
  }

  @override
  Future<void> updateExamResult(
      String resultId, Map<String, dynamic> resultData) async {
    if (resultData.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    resultData.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt = _db
        .prepare('UPDATE exam_results SET ${updates.join(', ')} WHERE id = ?');
    try {
      values.add(int.tryParse(resultId) ?? resultId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> deleteExamResult(String resultId) async {
    final stmt = _db.prepare('DELETE FROM exam_results WHERE id = ?');
    try {
      stmt.execute([int.tryParse(resultId) ?? resultId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> setTimetableConstraint(Map<String, dynamic> constraint) async {
    final stmt = _db.prepare('''
      INSERT INTO timetable_constraints (school_id, teacher_id, day, slot_id, data_json, updated_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        constraint['school_id'],
        constraint['teacher_id'],
        constraint['day'],
        constraint['slot_id'],
        jsonEncode(constraint),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherConstraints(
      String schoolId, String teacherId) async {
    return query(
        'SELECT * FROM timetable_constraints WHERE school_id = ? AND teacher_id = ?',
        [int.tryParse(schoolId) ?? schoolId, teacherId]);
  }

  @override
  Future<Map<String, dynamic>> getSubjectConstraints(String schoolId) async {
    final row = await querySingle(
        'SELECT constraints_json FROM subject_constraints WHERE school_id = ?',
        [int.tryParse(schoolId) ?? schoolId]);
    if (row == null) {
      return {'constraints': {}};
    }
    return {
      'constraints': _safeJsonDecode(row['constraints_json'], fallback: {}),
    };
  }

  @override
  Future<void> saveSubjectConstraints(
      String schoolId, Map<String, dynamic> constraints) async {
    final stmt = _db.prepare('''
      INSERT INTO subject_constraints (school_id, constraints_json, updated_at)
      VALUES (?, ?, datetime('now'))
      ON CONFLICT(school_id) DO UPDATE SET constraints_json = excluded.constraints_json, updated_at = datetime('now')
    ''');
    try {
      stmt.execute([int.tryParse(schoolId) ?? schoolId, jsonEncode(constraints)]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSocialPosts(String schoolId) async {
    final rows = await query(
        'SELECT * FROM social_posts WHERE school_id = ? ORDER BY created_at DESC',
        [int.tryParse(schoolId) ?? schoolId]);
    return rows
        .map((row) => {
              ...row,
              'data': _safeJsonDecode(row['data_json']),
            })
        .toList();
  }

  @override
  Future<void> createSocialPost(String schoolId, Map<String, dynamic> post) async {
    final stmt = _db.prepare(
        'INSERT INTO social_posts (school_id, data_json, created_at) VALUES (?, ?, datetime(\'now\'))');
    try {
      stmt.execute([int.tryParse(schoolId) ?? schoolId, jsonEncode(post)]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> deleteSocialPost(String schoolId, String postId) async {
    final stmt =
        _db.prepare('DELETE FROM social_posts WHERE school_id = ? AND id = ?');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        int.tryParse(postId) ?? postId
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> createStudent(String schoolId, Map<String, dynamic> studentData) async {
    final stmt = _db.prepare('''
      INSERT INTO students
        (user_id, school_id, class_id, first_name, last_name, date_of_birth, admission_number, sex, religion, phone_number, address, parent_name, parent_nin, parent_contact, special_needs, subject_codes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        studentData['user_id'],
        int.tryParse(schoolId) ?? schoolId,
        studentData['class_id'],
        studentData['first_name'],
        studentData['last_name'],
        studentData['date_of_birth'],
        studentData['admission_number'],
        studentData['sex'],
        studentData['religion'],
        studentData['phone_number'],
        studentData['address'],
        studentData['parent_name'],
        studentData['parent_nin'],
        studentData['parent_contact'],
        studentData['special_needs'],
        studentData['subject_codes'],
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentNotifications(
      String studentId) async {
    return query(
        'SELECT * FROM notifications WHERE target_type = ? OR target_id = ? ORDER BY created_at DESC',
        ['all', studentId]);
  }

  @override
  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    final stmt = _db.prepare('''
      INSERT INTO notifications
        (title, message, type, priority, target_type, target_id, action_url, is_read, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 0, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        notificationData['title'],
        notificationData['message'],
        notificationData['type'] ?? 'general',
        notificationData['priority'] ?? 'medium',
        notificationData['target_type'] ?? 'all',
        notificationData['target_id'],
        notificationData['action_url'],
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    final stmt = _db.prepare(
        'UPDATE notifications SET is_read = 1, read_at = datetime(\'now\') WHERE id = ?');
    try {
      stmt.execute([int.tryParse(notificationId) ?? notificationId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> getUnreadNotificationCount(String studentId) async {
    final stmt = _db.prepare('''
      SELECT COUNT(*) as cnt FROM notifications
      WHERE is_read = 0 AND (target_type = 'all' OR target_id = ?)
    ''');
    try {
      final rs = stmt.select([studentId]);
      return (rs.first['cnt'] as int?) ?? 0;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getClasses(String schoolId) async {
    return getClassesBySchool(schoolId);
  }

  @override
  Future<void> createExam(String schoolId, Map<String, dynamic> examData) async {
    final stmt = _db.prepare('''
      INSERT INTO exams (school_id, name, class_id, subject_id, teacher_id, exam_date, max_marks, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        examData['name'],
        examData['class_id'] ?? examData['classId'],
        examData['subject_id'] ?? examData['subjectId'],
        examData['teacher_id'] ?? examData['teacherId'],
        examData['exam_date'] ?? examData['examDate'],
        examData['max_marks'] ?? examData['maxMarks'],
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getExamsBySchool(String schoolId) async {
    return query('SELECT * FROM exams WHERE school_id = ?',
        [int.tryParse(schoolId) ?? schoolId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getExamsByTeacher(
      String schoolId, String teacherId) async {
    return query('SELECT * FROM exams WHERE school_id = ? AND teacher_id = ?',
        [int.tryParse(schoolId) ?? schoolId, teacherId]);
  }

  @override
  Future<void> updateExam(
      String schoolId, String examId, Map<String, dynamic> examData) async {
    if (examData.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    examData.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt = _db.prepare(
        'UPDATE exams SET ${updates.join(', ')} WHERE id = ? AND school_id = ?');
    try {
      values.add(int.tryParse(examId) ?? examId);
      values.add(int.tryParse(schoolId) ?? schoolId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> deleteExam(String schoolId, String examId) async {
    final stmt = _db
        .prepare('DELETE FROM exams WHERE id = ? AND school_id = ?');
    try {
      stmt.execute([
        int.tryParse(examId) ?? examId,
        int.tryParse(schoolId) ?? schoolId
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> setTimetableLesson(Map<String, dynamic> lesson) async {
    // Remove any existing lesson in this slot before inserting the update.
    final deleteStmt = _db.prepare('''
      DELETE FROM timetable_lessons
      WHERE school_id = ? AND class_name = ? AND day = ? AND slot_id = ?
    ''');
    try {
      deleteStmt.execute([
        lesson['school_id'],
        lesson['class_name'],
        lesson['day'],
        lesson['slot_id'],
      ]);
    } finally {
      deleteStmt.dispose();
    }

    final stmt = _db.prepare('''
      INSERT INTO timetable_lessons (school_id, class_name, teacher_id, day, slot_id, data_json, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        lesson['school_id'],
        lesson['class_name'],
        lesson['teacher_id'],
        lesson['day'],
        lesson['slot_id'],
        jsonEncode(lesson),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getClassTimetableLessons(
      String schoolId, String className) async {
    final rows = await query(
        'SELECT * FROM timetable_lessons WHERE school_id = ? AND class_name = ?',
        [int.tryParse(schoolId) ?? schoolId, className]);
    return rows
        .map((row) => {
              ...row,
              'lesson': _safeJsonDecode(row['data_json']),
            })
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherTimetableLessons(
      String schoolId, String teacherId) async {
    final rows = await query(
        'SELECT * FROM timetable_lessons WHERE school_id = ? AND teacher_id = ?',
        [int.tryParse(schoolId) ?? schoolId, teacherId]);
    return rows
        .map((row) => {
              ...row,
              'lesson': _safeJsonDecode(row['data_json']),
            })
        .toList();
  }

  @override
  Future<void> removeTimetableLesson(
      String schoolId, String className, String day, String slotId) async {
    final stmt = _db.prepare('''
      DELETE FROM timetable_lessons
      WHERE school_id = ? AND class_name = ? AND day = ? AND slot_id = ?
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        className,
        day,
        slotId
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> saveFullClassTimetable(
      String schoolId, String className, List<Map<String, dynamic>> lessons) async {
    // Clear existing lessons for the class then insert the full list.
    final deleteStmt = _db.prepare(
        'DELETE FROM timetable_lessons WHERE school_id = ? AND class_name = ?');
    try {
      deleteStmt.execute([int.tryParse(schoolId) ?? schoolId, className]);
    } finally {
      deleteStmt.dispose();
    }
    for (final lesson in lessons) {
      await setTimetableLesson({
        ...lesson,
        'school_id': schoolId,
        'class_name': className,
      });
    }
  }

  @override
  Future<void> createSalaryRecord(
      String schoolId, Map<String, dynamic> salaryData) async {
    final stmt = _db.prepare('''
      INSERT INTO salary_records
        (school_id, staff_id, amount, status, month, year, data_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        salaryData['staff_id'] ?? salaryData['staffId'],
        salaryData['amount'],
        salaryData['status'] ?? 'pending',
        salaryData['month'],
        salaryData['year'],
        jsonEncode(salaryData),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSalaryRecords(
      String schoolId, String? staffId) async {
    if (staffId != null) {
      return query(
          'SELECT * FROM salary_records WHERE school_id = ? AND staff_id = ? ORDER BY created_at DESC',
          [int.tryParse(schoolId) ?? schoolId, staffId]);
    }
    return query(
        'SELECT * FROM salary_records WHERE school_id = ? ORDER BY created_at DESC',
        [int.tryParse(schoolId) ?? schoolId]);
  }

  @override
  Future<void> updateSalaryRecord(
      String schoolId, String recordId, Map<String, dynamic> updateData) async {
    if (updateData.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    updateData.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt = _db.prepare(
        'UPDATE salary_records SET ${updates.join(', ')} WHERE id = ? AND school_id = ?');
    try {
      values.add(int.tryParse(recordId) ?? recordId);
      values.add(int.tryParse(schoolId) ?? schoolId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> createReportCard(
      String schoolId, Map<String, dynamic> reportCard) async {
    final stmt = _db.prepare('''
      INSERT INTO report_cards (school_id, student_id, term, year, data_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        reportCard['student_id'] ?? reportCard['studentId'],
        reportCard['term'],
        reportCard['year'].toString(),
        jsonEncode(reportCard),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentReportCards(
      String schoolId, String studentId) async {
    final rows = await query(
        'SELECT * FROM report_cards WHERE school_id = ? AND student_id = ? ORDER BY created_at DESC',
        [int.tryParse(schoolId) ?? schoolId, studentId]);
    return rows
        .map((row) => {
              ...row,
              'data': _safeJsonDecode(row['data_json']),
            })
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getReportCard(
      String schoolId, String studentId, String term, String year) async {
    final row = await querySingle(
        'SELECT * FROM report_cards WHERE school_id = ? AND student_id = ? AND term = ? AND year = ? ORDER BY created_at DESC LIMIT 1',
        [
          int.tryParse(schoolId) ?? schoolId,
          studentId,
          term,
          year
        ]);
    if (row == null) {
      return {};
    }
    return {
      ...row,
      'data': _safeJsonDecode(row['data_json']),
    };
  }

  @override
  Future<void> addBook(String schoolId, Map<String, dynamic> bookData) async {
    final stmt = _db.prepare('''
      INSERT INTO books (school_id, title, author, isbn, copies_total, copies_available, data_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        bookData['title'],
        bookData['author'],
        bookData['isbn'],
        bookData['copies_total'] ?? bookData['copiesTotal'] ?? 1,
        bookData['copies_available'] ?? bookData['copiesAvailable'] ?? 1,
        jsonEncode(bookData),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBooks(String schoolId) async {
    final rows = await query(
        'SELECT * FROM books WHERE school_id = ? ORDER BY title ASC',
        [int.tryParse(schoolId) ?? schoolId]);
    return rows
        .map((row) => {
              ...row,
              'data': _safeJsonDecode(row['data_json']),
            })
        .toList();
  }

  @override
  Future<void> borrowBook(
      String schoolId, Map<String, dynamic> borrowingData) async {
    final stmt = _db.prepare('''
      INSERT INTO book_borrowings (school_id, book_id, student_id, borrowed_at, due_at, data_json)
      VALUES (?, ?, ?, datetime('now'), ?, ?)
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        borrowingData['book_id'] ?? borrowingData['bookId'],
        borrowingData['student_id'] ?? borrowingData['studentId'],
        borrowingData['due_at'] ?? borrowingData['dueAt'],
        jsonEncode(borrowingData),
      ]);
    } finally {
      stmt.dispose();
    }

    // Reduce available copies.
    final updateStmt = _db.prepare(
        'UPDATE books SET copies_available = copies_available - 1 WHERE id = ? AND copies_available > 0');
    try {
      updateStmt.execute([
        borrowingData['book_id'] ?? borrowingData['bookId']
      ]);
    } finally {
      updateStmt.dispose();
    }
  }

  @override
  Future<void> returnBook(String schoolId, String borrowingId) async {
    final stmt = _db.prepare(
        'UPDATE book_borrowings SET returned_at = datetime(\'now\') WHERE id = ? AND school_id = ?');
    try {
      stmt.execute([
        int.tryParse(borrowingId) ?? borrowingId,
        int.tryParse(schoolId) ?? schoolId
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBorrowedBooks(
      String schoolId, String studentId) async {
    final rows = await query(
        'SELECT * FROM book_borrowings WHERE school_id = ? AND student_id = ? ORDER BY borrowed_at DESC',
        [int.tryParse(schoolId) ?? schoolId, studentId]);
    return rows
        .map((row) => {
              ...row,
              'data': row['data_json'] != null
                  ? _safeJsonDecode(row['data_json'])
                  : null,
            })
        .toList();
  }

  @override
  Future<void> saveSchemeOfWork(Map<String, dynamic> scheme) async {
    final stmt = _db.prepare('''
      INSERT INTO schemes_of_work (school_id, subject, class_name, term, year, data_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        scheme['school_id'],
        scheme['subject'],
        scheme['class_name'],
        scheme['term'],
        scheme['year'],
        jsonEncode(scheme),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>> getSchemeOfWork(
      String schoolId, String subject, String className, String term, int year) async {
    final rows = await query('''
      SELECT * FROM schemes_of_work
      WHERE school_id = ? AND subject = ? AND class_name = ? AND term = ? AND year = ?
      ORDER BY created_at DESC
    ''', [int.tryParse(schoolId) ?? schoolId, subject, className, term, year]);

    return {
      'schemes': rows
          .map((row) => {
                ...row,
                'data': _safeJsonDecode(row['data_json']),
              })
          .toList()
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getSchemesOfWork(
      String schoolId, Map<String, String> queryParams) async {
    final where = <String>['school_id = ?'];
    final values = <dynamic>[int.tryParse(schoolId) ?? schoolId];
    if (queryParams['subject'] != null) {
      where.add('subject = ?');
      values.add(queryParams['subject']);
    }
    if (queryParams['className'] != null) {
      where.add('class_name = ?');
      values.add(queryParams['className']);
    }
    if (queryParams['term'] != null) {
      where.add('term = ?');
      values.add(queryParams['term']);
    }
    if (queryParams['year'] != null) {
      where.add('year = ?');
      values.add(int.tryParse(queryParams['year']!) ?? queryParams['year']);
    }

    final rows = await query(
        'SELECT * FROM schemes_of_work WHERE ${where.join(' AND ')} ORDER BY created_at DESC',
        values);
    return rows
        .map((row) => {
              ...row,
              'data': _safeJsonDecode(row['data_json']),
            })
        .toList();
  }

  @override
  Future<void> saveLessonPlan(String schoolId, Map<String, dynamic> lessonPlan) async {
    final stmt = _db.prepare('''
      INSERT INTO lesson_plans (school_id, teacher_id, subject, class_name, term, year, lesson_date, data_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        lessonPlan['teacher_id'] ?? lessonPlan['teacherId'],
        lessonPlan['subject'],
        lessonPlan['class_name'] ?? lessonPlan['className'],
        lessonPlan['term'],
        lessonPlan['year'],
        lessonPlan['lesson_date'] ?? lessonPlan['lessonDate'],
        jsonEncode(lessonPlan),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLessonPlans(
      String schoolId, String teacherId, Map<String, String> queryParams) async {
    final where = <String>['school_id = ?', 'teacher_id = ?'];
    final values = <dynamic>[int.tryParse(schoolId) ?? schoolId, teacherId];
    if (queryParams['subject'] != null) {
      where.add('subject = ?');
      values.add(queryParams['subject']);
    }
    if (queryParams['className'] != null) {
      where.add('class_name = ?');
      values.add(queryParams['className']);
    }
    if (queryParams['term'] != null) {
      where.add('term = ?');
      values.add(queryParams['term']);
    }
    if (queryParams['year'] != null) {
      where.add('year = ?');
      values.add(int.tryParse(queryParams['year']!) ?? queryParams['year']);
    }

    final rows = await query(
        'SELECT * FROM lesson_plans WHERE ${where.join(' AND ')} ORDER BY created_at DESC',
        values);
    return rows
        .map((row) => {
              ...row,
              'data': _safeJsonDecode(row['data_json']),
            })
        .toList();
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
    // Create or locate class.
    final classRow = await querySingle(
        'SELECT * FROM classes WHERE school_id = ? AND name = ? LIMIT 1',
        [int.tryParse(schoolId) ?? schoolId, className]);
    final classId = classRow != null
        ? classRow['id']
        : (await createClass(schoolId: schoolId, name: className))['id'];

    // Create user for the student.
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    final user = await createUser(
      email: email,
      hashedPassword: hashedPassword,
      otherData: {
        'role': 'student',
        'first_name': firstName,
        'last_name': lastName,
        'school_id': int.tryParse(schoolId) ?? schoolId,
      },
    );

    // Create student record.
    final stmt = _db.prepare('''
      INSERT INTO students
        (user_id, school_id, class_id, first_name, last_name, date_of_birth, admission_number, sex, religion, phone_number, address, parent_name, parent_nin, parent_contact, special_needs, subject_codes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        user['id'],
        int.tryParse(schoolId) ?? schoolId,
        classId,
        firstName,
        lastName,
        dateOfBirth,
        admissionNumber,
        sex,
        religion,
        phoneNumber,
        address,
        parentName,
        parentNin,
        parentContact,
        specialNeeds,
        subjectCodes?.join(','),
      ]);
    } finally {
      stmt.dispose();
    }

    final student = await querySingle(
        'SELECT * FROM students WHERE user_id = ? ORDER BY id DESC LIMIT 1',
        [user['id']]);

    return {
      'user_id': user['id'],
      'student_id': student?['id'],
      'class_id': classId,
      'school_id': schoolId,
    };
  }

  @override
  Future<void> saveAttendanceRecord(
      String schoolId, Map<String, dynamic> attendanceRecord) async {
    final stmt = _db.prepare('''
      INSERT INTO attendance_records
        (school_id, class_id, student_id, attendance_date, status, term, year, data_json, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        attendanceRecord['class_id'] ?? attendanceRecord['classId'],
        attendanceRecord['student_id'] ?? attendanceRecord['studentId'],
        attendanceRecord['date'] ?? attendanceRecord['attendance_date'],
        attendanceRecord['status'],
        attendanceRecord['term'],
        attendanceRecord['year'],
        jsonEncode(attendanceRecord),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAttendanceRecords(
      String schoolId, Map<String, String> queryParams) async {
    final where = <String>['school_id = ?'];
    final values = <dynamic>[int.tryParse(schoolId) ?? schoolId];
    if (queryParams['studentId'] != null) {
      where.add('student_id = ?');
      values.add(queryParams['studentId']);
    }
    if (queryParams['classId'] != null) {
      where.add('class_id = ?');
      values.add(queryParams['classId']);
    }
    if (queryParams['term'] != null) {
      where.add('term = ?');
      values.add(queryParams['term']);
    }
    if (queryParams['year'] != null) {
      where.add('year = ?');
      values.add(int.tryParse(queryParams['year']!) ?? queryParams['year']);
    }

    final rows = await query(
        'SELECT * FROM attendance_records WHERE ${where.join(' AND ')} ORDER BY attendance_date DESC',
        values);
    return rows
        .map((row) => {
              ...row,
              'data': row['data_json'] != null
                  ? _safeJsonDecode(row['data_json'])
                  : null,
            })
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getStudentAttendanceSummary(
      String schoolId, String studentId, String term, int year) async {
    final rows = await query('''
      SELECT status, COUNT(*) as cnt
      FROM attendance_records
      WHERE school_id = ? AND student_id = ? AND term = ? AND year = ?
      GROUP BY status
    ''', [int.tryParse(schoolId) ?? schoolId, studentId, term, year]);
    final summary = <String, int>{};
    for (final row in rows) {
      summary[row['status']?.toString() ?? 'unknown'] = row['cnt'] as int? ?? 0;
    }
    return {'summary': summary};
  }

  @override
  Future<void> saveGradeBookEntry(
      String schoolId, Map<String, dynamic> gradeBookEntry) async {
    final stmt = _db.prepare('''
      INSERT INTO gradebook_entries
        (school_id, class_id, student_id, subject, term, year, score, total, data_json, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        gradeBookEntry['class_id'] ?? gradeBookEntry['classId'],
        gradeBookEntry['student_id'] ?? gradeBookEntry['studentId'],
        gradeBookEntry['subject'],
        gradeBookEntry['term'],
        gradeBookEntry['year'],
        gradeBookEntry['score'],
        gradeBookEntry['total'],
        jsonEncode(gradeBookEntry),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getGradeBookEntries(
      String schoolId, Map<String, String> queryParams) async {
    final where = <String>['school_id = ?'];
    final values = <dynamic>[int.tryParse(schoolId) ?? schoolId];
    if (queryParams['studentId'] != null) {
      where.add('student_id = ?');
      values.add(queryParams['studentId']);
    }
    if (queryParams['classId'] != null) {
      where.add('class_id = ?');
      values.add(queryParams['classId']);
    }
    if (queryParams['subject'] != null) {
      where.add('subject = ?');
      values.add(queryParams['subject']);
    }
    if (queryParams['term'] != null) {
      where.add('term = ?');
      values.add(queryParams['term']);
    }
    if (queryParams['year'] != null) {
      where.add('year = ?');
      values.add(int.tryParse(queryParams['year']!) ?? queryParams['year']);
    }

    final rows = await query(
        'SELECT * FROM gradebook_entries WHERE ${where.join(' AND ')} ORDER BY created_at DESC',
        values);
    return rows
        .map((row) => {
              ...row,
              'data': row['data_json'] != null
                  ? _safeJsonDecode(row['data_json'])
                  : null,
            })
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getStudentGradeBookSummary(
      String schoolId, String studentId, String subject, String term, int year) async {
    final rows = await query('''
      SELECT SUM(score) as total_score, SUM(total) as total_possible
      FROM gradebook_entries
      WHERE school_id = ? AND student_id = ? AND subject = ? AND term = ? AND year = ?
    ''', [
      int.tryParse(schoolId) ?? schoolId,
      studentId,
      subject,
      term,
      year
    ]);
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    return {
      'total_score': row['total_score'] ?? 0,
      'total_possible': row['total_possible'] ?? 0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentApplications(String schoolId) async {
    final rows = await query(
        'SELECT * FROM student_applications WHERE school_id = ? ORDER BY created_at DESC',
        [int.tryParse(schoolId) ?? schoolId]);
    return rows
        .map((row) => {
              ...row,
              'data': row['data_json'] != null
                  ? _safeJsonDecode(row['data_json'])
                  : null,
            })
        .toList();
  }

  Future<void> createStudentApplication(
      String schoolId, Map<String, dynamic> applicationData) async {
    final stmt = _db.prepare('''
      INSERT INTO student_applications (school_id, status, data_json, created_at, updated_at)
      VALUES (?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        applicationData['status'] ?? 'pending',
        jsonEncode(applicationData),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateStudentApplication(
      String schoolId, String applicationId, Map<String, dynamic> updateData) async {
    if (updateData.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    updateData.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt = _db.prepare(
        'UPDATE student_applications SET ${updates.join(', ')} WHERE id = ? AND school_id = ?');
    try {
      values.add(int.tryParse(applicationId) ?? applicationId);
      values.add(int.tryParse(schoolId) ?? schoolId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFeeStructures(String schoolId) async {
    return query('SELECT * FROM fee_structures WHERE school_id = ?',
        [int.tryParse(schoolId) ?? schoolId]);
  }

  @override
  Future<void> createFeeStructure(
      String schoolId, Map<String, dynamic> structure) async {
    final stmt = _db.prepare('''
      INSERT INTO fee_structures (school_id, name, amount, description, class_name, data_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ''');
    try {
      stmt.execute([
        int.tryParse(schoolId) ?? schoolId,
        structure['name'],
        structure['amount'],
        structure['description'],
        structure['class_name'] ?? structure['className'],
        jsonEncode(structure),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> updateFeeStructure(
      String schoolId, String structureId, Map<String, dynamic> structure) async {
    if (structure.isEmpty) return;
    final updates = <String>[];
    final values = <dynamic>[];
    structure.forEach((key, value) {
      final column = _toSnakeCase(key);
      updates.add('$column = ?');
      values.add(value);
    });
    updates.add('updated_at = datetime(\'now\')');
    final stmt = _db.prepare(
        'UPDATE fee_structures SET ${updates.join(', ')} WHERE id = ? AND school_id = ?');
    try {
      values.add(int.tryParse(structureId) ?? structureId);
      values.add(int.tryParse(schoolId) ?? schoolId);
      stmt.execute(values);
    } finally {
      stmt.dispose();
    }
  }

  Future<void> deleteFeeStructure(String schoolId, String structureId) async {
    final stmt = _db.prepare(
        'DELETE FROM fee_structures WHERE id = ? AND school_id = ?');
    try {
      stmt.execute([
        int.tryParse(structureId) ?? structureId,
        int.tryParse(schoolId) ?? schoolId
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> recordFeePayment(Map<String, dynamic> paymentData) async {
    final stmt = _db.prepare('''
      INSERT INTO fee_payments (school_id, student_id, amount, payment_method, reference, paid_at, data_json, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
    ''');
    try {
      stmt.execute([
        paymentData['school_id'] ?? paymentData['schoolId'],
        paymentData['student_id'] ?? paymentData['studentId'],
        paymentData['amount'],
        paymentData['payment_method'] ?? paymentData['paymentMethod'],
        paymentData['reference'],
        paymentData['paid_at'] ?? paymentData['paidAt'],
        jsonEncode(paymentData),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentFeeBalance(String studentId) async {
    final payments = await query(
        'SELECT SUM(amount) as total_paid FROM fee_payments WHERE student_id = ?',
        [studentId]);
    final paid = payments.first['total_paid'] as num? ?? 0;
    // Sum all structures for now; if class-specific structures exist, filter later.
    final structures = await query(
        'SELECT SUM(amount) as total_expected FROM fee_structures');
    final expected = structures.isNotEmpty
        ? structures.first['total_expected'] as num? ?? 0
        : 0;
    return {
      'totalExpected': expected,
      'totalPaid': paid,
      'balance': expected - paid,
    };
  }

  @override
  Future<void> updateUserRole(String userId, Map<String, dynamic> updateData) async {
    if (!updateData.containsKey('role')) return;
    final stmt = _db.prepare('UPDATE users SET role = ? WHERE id = ?');
    try {
      stmt.execute([updateData['role'], int.tryParse(userId) ?? userId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> ingestChemistryCurriculum(
      [Map<String, dynamic>? curriculumData]) async {
    // This is a stub ingest: if data is provided, store it in curriculum tables.
    if (curriculumData == null) return;
    final subjectId = await insertSubject(curriculumData);
    final strands = curriculumData['strands'] as List<dynamic>? ?? [];
    for (final strand in strands) {
      final strandId = await insertStrand({
        'subject_id': subjectId,
        ...strand as Map<String, dynamic>,
      });
      final topics = (strand as Map<String, dynamic>)['topics'] as List<dynamic>? ?? [];
      for (final topic in topics) {
        await insertTopic({
          'strand_id': strandId,
          ...topic as Map<String, dynamic>,
        });
      }
    }
  }

  @override
  Future<void> linkParentToStudents(
      {required String parentUserId, required List<String> studentIds}) async {
    final stmt = _db.prepare(
        'INSERT INTO student_parents (student_id, parent_user_id) VALUES (?, ?)');
    try {
      for (final studentId in studentIds) {
        stmt.execute([
          int.tryParse(studentId) ?? studentId,
          int.tryParse(parentUserId) ?? parentUserId
        ]);
      }
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsByParentId(
      String parentUserId) async {
    return query('''
      SELECT s.* FROM students s
      JOIN student_parents sp ON sp.student_id = s.id
      WHERE sp.parent_user_id = ?
    ''', [int.tryParse(parentUserId) ?? parentUserId]);
  }

  @override
  Future<void> delete(String itemType, int itemId) async {
    final table = itemType;
    final stmt = _db.prepare('DELETE FROM $table WHERE id = ?');
    try {
      stmt.execute([itemId]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsBySchool(String schoolId,
      [Map<String, String>? queryParams]) async {
    final where = <String>['school_id = ?'];
    final values = <dynamic>[int.tryParse(schoolId) ?? schoolId];
    if (queryParams != null) {
      if (queryParams['classId'] != null) {
        where.add('class_id = ?');
        values.add(queryParams['classId']);
      }
      if (queryParams['sex'] != null) {
        where.add('sex = ?');
        values.add(queryParams['sex']);
      }
    }
    return query(
        'SELECT * FROM students WHERE ${where.join(' AND ')} ORDER BY created_at DESC',
        values);
  }

  @override
  Future<void> insert(String table, Map<String, dynamic> data) async {
    final columns = data.keys.map(_toSnakeCase).toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final stmt =
        _db.prepare('INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)');
    try {
      stmt.execute(data.values.toList());
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> update(String table, Map<String, dynamic> data,
      String whereClause, List<dynamic> params) async {
    if (data.isEmpty) return;
    final assignments = data.keys.map((k) => '${_toSnakeCase(k)} = ?').join(', ');
    final stmt = _db.prepare('UPDATE $table SET $assignments WHERE $whereClause');
    try {
      stmt.execute([...data.values, ...params]);
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> deleteWhere(
      String table, String whereClause, List<dynamic> params) async {
    final stmt = _db.prepare('DELETE FROM $table WHERE $whereClause');
    try {
      stmt.execute(params);
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
}

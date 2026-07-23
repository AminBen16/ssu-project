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

        print('Database schema initialized successfully');
      }
    } catch (e) {
      print('Error initializing schema: $e');
    }
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
}

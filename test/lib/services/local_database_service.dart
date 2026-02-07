import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:test/services/message_storage.dart';
import 'package:test/models/domain_models.dart';

/// Local database service for offline data storage and synchronization.
/// Provides SQLite-based storage for caching API responses and queuing offline operations.
class LocalDatabaseService implements MessageStorage {
  static Database? _database;
  static const String _databaseName = 'ssu_offline.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String cacheTable = 'cache';
  static const String syncQueueTable = 'sync_queue';
  static const String userDataTable = 'user_data';
  static const String schoolDataTable = 'school_data';
  static const String studentsTable = 'students';
  static const String staffTable = 'staff';
  static const String timetablesTable = 'timetables';
  static const String examsTable = 'exams';
  static const String marksTable = 'marks';
  static const String feesTable = 'fees';
  static const String booksTable = 'books';
  static const String lessonPlansTable = 'lesson_plans';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database; // Ensure database is initialized
  }

  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      // Fallback to temporary directory if getApplicationDocumentsDirectory fails
      print('Failed to get application documents directory: $e');
      print('Using temporary directory as fallback');
      Directory tempDir = Directory.systemTemp;
      String path = join(tempDir.path, _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cache table for API responses
    await db.execute('''
      CREATE TABLE $cacheTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        expiry TEXT
      )
    ''');

    // Sync queue for offline operations
    await db.execute('''
      CREATE TABLE $syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        error_message TEXT
      )
    ''');

    // User data cache
    await db.execute('''
      CREATE TABLE $userDataTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // School data cache
    await db.execute('''
      CREATE TABLE $schoolDataTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Students data
    await db.execute('''
      CREATE TABLE $studentsTable (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Staff data
    await db.execute('''
      CREATE TABLE $staffTable (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Timetables
    await db.execute('''
      CREATE TABLE $timetablesTable (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        class_id TEXT,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Exams
    await db.execute('''
      CREATE TABLE $examsTable (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Marks
    await db.execute('''
      CREATE TABLE $marksTable (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        exam_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Fees
    await db.execute('''
      CREATE TABLE $feesTable (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Books
    await db.execute('''
      CREATE TABLE $booksTable (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Lesson plans
    await db.execute('''
      CREATE TABLE $lessonPlansTable (
        id TEXT PRIMARY KEY,
        teacher_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');

    // Messages
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        last_sync TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic as needed
    }
  }

  // Cache operations
  Future<void> setCache(String key, String data, {Duration? expiry}) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();
    final expiryTime =
        expiry != null ? DateTime.now().add(expiry).toIso8601String() : null;

    await db.insert(
      cacheTable,
      {
        'key': key,
        'data': data,
        'timestamp': timestamp,
        'expiry': expiryTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCache(String key) async {
    final db = await database;
    final now = DateTime.now();

    final results = await db.query(
      cacheTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isNotEmpty) {
      final row = results.first;
      final expiry = row['expiry'] as String?;

      if (expiry != null) {
        final expiryDate = DateTime.parse(expiry);
        if (now.isAfter(expiryDate)) {
          // Cache expired, delete it
          await db.delete(cacheTable, where: 'key = ?', whereArgs: [key]);
          return null;
        }
      }

      return row['data'] as String;
    }

    return null;
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.delete(
      cacheTable,
      where: 'expiry IS NOT NULL AND expiry < ?',
      whereArgs: [now],
    );
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete(cacheTable);
  }

  // Sync queue operations
  Future<void> addToSyncQueue(
      String tableName, String operation, Map<String, dynamic> data) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();

    await db.insert(syncQueueTable, {
      'table_name': tableName,
      'operation': operation,
      'data': jsonEncode(data),
      'timestamp': timestamp,
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    final results = await db.query(syncQueueTable, orderBy: 'timestamp ASC');
    return results.map((row) {
      return {
        'id': row['id'],
        'tableName': row['table_name'],
        'operation': row['operation'],
        'data': jsonDecode(row['data'] as String),
        'timestamp': row['timestamp'],
        'retryCount': row['retry_count'],
        'errorMessage': row['error_message'],
      };
    }).toList();
  }

  Future<void> removeFromSyncQueue(int id) async {
    final db = await database;
    await db.delete(syncQueueTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSyncRetryCount(
      int id, int retryCount, String errorMessage) async {
    final db = await database;
    await db.update(
      syncQueueTable,
      {
        'retry_count': retryCount,
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Metadata operations (for backward compatibility with existing code)
  Future<void> setMetadata(String key, String value) async {
    await setCache(key, value);
  }

  Future<String?> getMetadata(String key) async {
    return await getCache(key);
  }

  // Generic data operations
  Future<void> saveData(
      String table, String id, Map<String, dynamic> data) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();

    await db.insert(
      table,
      {
        'id': id,
        'data': jsonEncode(data),
        'last_sync': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getData(String table, String id) async {
    final db = await database;
    final results = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final row = results.first;
      return jsonDecode(row['data'] as String);
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    final db = await database;
    final results = await db.query(table);

    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  Future<void> deleteData(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // Database maintenance
  Future<Map<String, dynamic>> getDatabaseSize() async {
    final db = await database;

    // Get table counts
    final cacheCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $cacheTable'),
        ) ??
        0;

    final syncCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $syncQueueTable'),
        ) ??
        0;

    // Estimate size (rough calculation)
    final estimatedSize =
        (cacheCount + syncCount) * 1024; // Rough 1KB per record

    return {
      'cacheRecords': cacheCount,
      'syncQueueRecords': syncCount,
      'estimatedSizeKB': estimatedSize,
    };
  }

  Future<void> clearAllData() async {
    final db = await database;

    await db.delete(cacheTable);
    await db.delete(syncQueueTable);
    await db.delete(userDataTable);
    await db.delete(schoolDataTable);
    await db.delete(studentsTable);
    await db.delete(staffTable);
    await db.delete(timetablesTable);
    await db.delete(examsTable);
    await db.delete(marksTable);
    await db.delete(feesTable);
    await db.delete(booksTable);
    await db.delete(lessonPlansTable);
  }

  @override
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // MessageStorage implementation
  @override
  Future<void> saveMessage(Message message) async {
    final messageMap = message.toMap();
    await saveData('messages', message.id, messageMap);
  }

  @override
  Future<Message?> getMessage(String id) async {
    final data = await getData('messages', id);
    if (data != null) {
      return Message.fromMap(data);
    }
    return null;
  }

  @override
  Future<List<Message>> getMessagesForPeer(String peerId) async {
    final allData = await getAllData('messages');
    final messages = allData.map((data) => Message.fromMap(data)).toList();
    return messages
        .where((msg) => msg.senderId == peerId || msg.receiverId == peerId)
        .toList();
  }

  @override
  Future<List<Message>> getAllMessages() async {
    final allData = await getAllData('messages');
    return allData.map((data) => Message.fromMap(data)).toList();
  }

  @override
  Future<void> updateMessageStatus(String id, DeliveryStatus status) async {
    final message = await getMessage(id);
    if (message != null) {
      final updatedMessage = message.copyWith(status: status);
      await saveMessage(updatedMessage);
    }
  }

  @override
  Future<void> deleteMessage(String id) async {
    await deleteData('messages', id);
  }

  @override
  Stream<List<Message>> getMessagesStream(String peerId) async* {
    // For simplicity, yield current messages and don't implement real-time updates
    // In a full implementation, this would use a StreamController
    yield await getMessagesForPeer(peerId);
  }
}

// Singleton instance
final localDatabaseService = LocalDatabaseService();

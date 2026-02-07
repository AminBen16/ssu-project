import 'package:sqlite3/sqlite3.dart';

void addSchoolsTable(Database db) {
  print('Adding schools table...');
  try {
    db.execute('''
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
    print('Schools table added successfully.');
  } catch (e) {
    print('Error adding schools table: $e');
    rethrow;
  }
}

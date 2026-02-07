import 'package:sqlite3/sqlite3.dart';

void addClassesTable(Database db) {
  print('Adding classes table...');
  try {
    db.execute('''
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
    db.execute('CREATE INDEX IF NOT EXISTS idx_classes_school_id ON classes (school_id)');
    print('Classes table added successfully.');
  } catch (e) {
    print('Error adding classes table: $e');
    rethrow;
  }
}

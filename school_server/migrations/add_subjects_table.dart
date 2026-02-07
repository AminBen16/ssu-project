import 'package:sqlite3/sqlite3.dart';

void addSubjectsTable(Database db) {
  print('Adding subjects table...');
  try {
    db.execute('''
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
    db.execute('CREATE INDEX IF NOT EXISTS idx_subjects_school_id ON subjects (school_id)');
    print('Subjects table added successfully.');
  } catch (e) {
    print('Error adding subjects table: $e');
    rethrow;
  }
}

import 'package:sqlite3/sqlite3.dart';

void addCurriculumTables(Database db) {
  print('Adding curriculum tables...');

  try {
    // Subjects table (curriculum subjects)
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        education_level TEXT NOT NULL, -- 'lower_secondary', 'upper_secondary', etc.
        description TEXT,
        periods_per_week_s1_s2 INTEGER,
        periods_per_week_s3_s4 INTEGER,
        rationale TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Strands/Themes table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_strands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        senior_level TEXT NOT NULL, -- 'senior_1', 'senior_2', etc.
        term TEXT NOT NULL, -- 'term_1', 'term_2', 'term_3'
        duration_periods INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES curriculum_subjects(id) ON DELETE CASCADE
      )
    ''');

    // Topics table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        strand_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        competency TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (strand_id) REFERENCES curriculum_strands(id) ON DELETE CASCADE
      )
    ''');

    // Competences table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_competences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        statement TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
    ''');

    // Content units table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_content_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
    ''');

    // Learning outcomes table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_learning_outcomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        outcome TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
    ''');

    // Activities table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        activity TEXT NOT NULL,
        type TEXT NOT NULL, -- 'suggested_learning', 'assessment'
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
    ''');

    // Materials table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        material TEXT NOT NULL,
        type TEXT NOT NULL, -- 'teaching', 'learning'
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
    ''');

    // Assessments table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        assessment TEXT NOT NULL,
        type TEXT NOT NULL, -- 'formative', 'summative'
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES curriculum_topics(id) ON DELETE CASCADE
      )
    ''');

    // Assessment framework table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_assessment_framework (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        framework_type TEXT NOT NULL, -- 'global', 'cognitive_levels', etc.
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES curriculum_subjects(id) ON DELETE CASCADE
      )
    ''');

    // Cross-cutting issues table
    db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_cross_cutting_issues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        issue TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES curriculum_subjects(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_strands_subject_id ON curriculum_strands (subject_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_topics_strand_id ON curriculum_topics (strand_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_competences_topic_id ON curriculum_competences (topic_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_content_units_topic_id ON curriculum_content_units (topic_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_learning_outcomes_topic_id ON curriculum_learning_outcomes (topic_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_activities_topic_id ON curriculum_activities (topic_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_materials_topic_id ON curriculum_materials (topic_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_assessments_topic_id ON curriculum_assessments (topic_id)');

    print('Curriculum tables added successfully.');
  } catch (e) {
    print('Error adding curriculum tables: $e');
    rethrow;
  }
}

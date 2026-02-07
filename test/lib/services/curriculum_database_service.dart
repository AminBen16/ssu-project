import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/curriculum_models.dart';
import '../models/enhanced_curriculum_models.dart';

/// Enhanced Database Service for NCDC Curriculum Management
class CurriculumDatabaseService {
  static Database? _database;
  static const String _dbName = 'curriculum_database.db';
  static const int _dbVersion = 2;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createCurriculumTables(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCurriculumTables(db);
    }
  }

  static Future<void> _createCurriculumTables(Database db) async {
    // Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        education_level TEXT NOT NULL,
        class_name TEXT,
        period_duration INTEGER,
        periods_per_week INTEGER,
        description TEXT,
        rationale TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Strands table
    await db.execute('''
      CREATE TABLE strands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT,
        description TEXT,
        term TEXT,
        senior_level TEXT,
        duration_periods INTEGER,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Topics table
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        strand_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT,
        description TEXT,
        competency TEXT,
        duration_periods INTEGER,
        term TEXT,
        class_name TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (strand_id) REFERENCES strands (id) ON DELETE CASCADE
      )
    ''');

    // Sub-strands table (for hierarchical organization)
    await db.execute('''
      CREATE TABLE sub_strands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        strand_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (strand_id) REFERENCES strands (id) ON DELETE CASCADE
      )
    ''');

    // Learning outcomes table
    await db.execute('''
      CREATE TABLE learning_outcomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        sub_topic_id INTEGER,
        outcome_text TEXT NOT NULL,
        outcome_type TEXT,
        lesson_unit TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE
      )
    ''');

    // Competencies table
    await db.execute('''
      CREATE TABLE competencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        competency_type TEXT NOT NULL,
        text TEXT NOT NULL,
        assessment_criteria TEXT,
        key_concepts TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE
      )
    ''');

    // Activities table
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        learning_outcome_id INTEGER NOT NULL,
        activity_text TEXT NOT NULL,
        description TEXT,
        activity_type TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (learning_outcome_id) REFERENCES learning_outcomes (id) ON DELETE CASCADE
      )
    ''');

    // Materials table
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        learning_outcome_id INTEGER NOT NULL,
        material_name TEXT NOT NULL,
        material_type TEXT,
        description TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (learning_outcome_id) REFERENCES learning_outcomes (id) ON DELETE CASCADE
      )
    ''');

    // Assessments table
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        learning_outcome_id INTEGER NOT NULL,
        assessment_method TEXT NOT NULL,
        guidance TEXT,
        mode TEXT,
        exam_eligibility TEXT,
        weighting TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (learning_outcome_id) REFERENCES learning_outcomes (id) ON DELETE CASCADE
      )
    ''');

    // Cross-cutting issues table
    await db.execute('''
      CREATE TABLE cross_cutting_issues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        issue_name TEXT NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Generic skills table
    await db.execute('''
      CREATE TABLE generic_skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        skill_name TEXT NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // ICT integration table
    await db.execute('''
      CREATE TABLE ict_integration (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        learning_outcome_id INTEGER NOT NULL,
        ict_tool TEXT NOT NULL,
        description TEXT,
        integration_level TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (learning_outcome_id) REFERENCES learning_outcomes (id) ON DELETE CASCADE
      )
    ''');

    // Teaching strategies table
    await db.execute('''
      CREATE TABLE teaching_strategies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        learning_outcome_id INTEGER NOT NULL,
        strategy_name TEXT NOT NULL,
        description TEXT,
        strategy_type TEXT,
        order_index INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (learning_outcome_id) REFERENCES learning_outcomes (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_subjects_name ON subjects(name)');
    await db.execute('CREATE INDEX idx_subjects_level ON subjects(education_level)');
    await db.execute('CREATE INDEX idx_strands_subject ON strands(subject_id)');
    await db.execute('CREATE INDEX idx_topics_strand ON topics(strand_id)');
    await db.execute('CREATE INDEX idx_learning_outcomes_topic ON learning_outcomes(topic_id)');
    await db.execute('CREATE INDEX idx_competencies_topic ON competencies(topic_id)');
    await db.execute('CREATE INDEX idx_activities_outcome ON activities(learning_outcome_id)');
    await db.execute('CREATE INDEX idx_materials_outcome ON materials(learning_outcome_id)');
    await db.execute('CREATE INDEX idx_assessments_outcome ON assessments(learning_outcome_id)');
  }

  // Subject CRUD operations
  static Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return await db.insert('subjects', subject.toMap());
  }

  static Future<int> insertEnhancedSubject(EnhancedSubject enhancedSubject) async {
    final subject = Subject(
      id: enhancedSubject.id,
      name: enhancedSubject.name,
      educationLevel: enhancedSubject.educationLevel,
      className: enhancedSubject.classNames?.first ?? 'Unknown',
      periodDuration: enhancedSubject.periodDuration,
      periodsPerWeek: enhancedSubject.periodsPerWeek,
      createdAt: enhancedSubject.createdAt,
    );
    return await insertSubject(subject);
  }

  static Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('subjects', orderBy: 'name');
    return List.generate(maps.length, (i) => Subject.fromMap(maps[i]));
  }

  static Future<List<Subject>> getSubjectsByLevel(String educationLevel) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'education_level = ?',
      whereArgs: [educationLevel],
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => Subject.fromMap(maps[i]));
  }

  static Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  static Future<int> deleteSubject(int id) async {
    final db = await database;
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // Strand CRUD operations
  static Future<int> insertStrand(Strand strand) async {
    final db = await database;
    return await db.insert('strands', strand.toMap());
  }

  static Future<int> insertEnhancedStrand(EnhancedStrand enhancedStrand) async {
    final strand = Strand(
      id: enhancedStrand.id,
      subjectId: enhancedStrand.subjectId,
      name: enhancedStrand.name,
      code: enhancedStrand.code,
      description: enhancedStrand.description,
      orderIndex: enhancedStrand.orderIndex,
    );
    return await insertStrand(strand);
  }

  static Future<List<Strand>> getStrandsBySubject(int subjectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'strands',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'order_index ASC, name ASC',
    );
    return List.generate(maps.length, (i) => Strand.fromMap(maps[i]));
  }

  static Future<Strand?> getStrandById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'strands',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Strand.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateStrand(Strand strand) async {
    final db = await database;
    return await db.update(
      'strands',
      strand.toMap(),
      where: 'id = ?',
      whereArgs: [strand.id],
    );
  }

  static Future<int> deleteStrand(int id) async {
    final db = await database;
    return await db.delete('strands', where: 'id = ?', whereArgs: [id]);
  }

  // Topic CRUD operations
  static Future<int> insertTopic(Topic topic) async {
    final db = await database;
    return await db.insert('topics', topic.toMap());
  }

  static Future<int> insertEnhancedTopic(EnhancedTopic enhancedTopic) async {
    final topic = Topic(
      id: enhancedTopic.id,
      strandId: enhancedTopic.strandId,
      name: enhancedTopic.name,
      code: enhancedTopic.code,
      description: enhancedTopic.description,
      competency: enhancedTopic.competency,
      durationPeriods: enhancedTopic.durationPeriods,
      term: enhancedTopic.term,
      className: enhancedTopic.className,
      orderIndex: enhancedTopic.orderIndex,
    );
    return await insertTopic(topic);
  }

  static Future<List<Topic>> getTopicsByStrand(int strandId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'topics',
      where: 'strand_id = ?',
      whereArgs: [strandId],
      orderBy: 'order_index ASC, name ASC',
    );
    return List.generate(maps.length, (i) => Topic.fromMap(maps[i]));
  }

  static Future<List<Topic>> getTopicsBySubject(int subjectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM topics t
      INNER JOIN strands s ON t.strand_id = s.id
      WHERE s.subject_id = ?
      ORDER BY s.order_index ASC, t.order_index ASC, t.name ASC
    ''', [subjectId]);
    return List.generate(maps.length, (i) => Topic.fromMap(maps[i]));
  }

  static Future<Topic?> getTopicById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'topics',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Topic.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateTopic(Topic topic) async {
    final db = await database;
    return await db.update(
      'topics',
      topic.toMap(),
      where: 'id = ?',
      whereArgs: [topic.id],
    );
  }

  static Future<int> deleteTopic(int id) async {
    final db = await database;
    return await db.delete('topics', where: 'id = ?', whereArgs: [id]);
  }

  // Learning Outcome CRUD operations
  static Future<int> insertLearningOutcome(LearningOutcome learningOutcome) async {
    final db = await database;
    return await db.insert('learning_outcomes', learningOutcome.toMap());
  }

  static Future<int> insertEnhancedLearningOutcome(EnhancedLearningOutcome enhancedLearningOutcome) async {
    final learningOutcome = LearningOutcome(
      id: enhancedLearningOutcome.id,
      topicId: enhancedLearningOutcome.topicId,
      subTopicId: enhancedLearningOutcome.subTopicId,
      outcomeText: enhancedLearningOutcome.outcomeText,
      outcomeType: enhancedLearningOutcome.outcomeType,
      orderIndex: enhancedLearningOutcome.orderIndex,
    );
    return await insertLearningOutcome(learningOutcome);
  }

  static Future<List<LearningOutcome>> getLearningOutcomesByTopic(int topicId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_outcomes',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => LearningOutcome.fromMap(maps[i]));
  }

  static Future<LearningOutcome?> getLearningOutcomeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_outcomes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return LearningOutcome.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateLearningOutcome(LearningOutcome learningOutcome) async {
    final db = await database;
    return await db.update(
      'learning_outcomes',
      learningOutcome.toMap(),
      where: 'id = ?',
      whereArgs: [learningOutcome.id],
    );
  }

  static Future<int> deleteLearningOutcome(int id) async {
    final db = await database;
    return await db.delete('learning_outcomes', where: 'id = ?', whereArgs: [id]);
  }

  // Activity CRUD operations
  static Future<int> insertActivity(SuggestedActivity activity) async {
    final db = await database;
    return await db.insert('activities', activity.toMap());
  }

  static Future<int> insertEnhancedActivity(EnhancedActivity enhancedActivity) async {
    final activity = SuggestedActivity(
      id: enhancedActivity.id,
      learningOutcomeId: enhancedActivity.learningOutcomeId,
      activityText: enhancedActivity.activityText,
      description: enhancedActivity.description,
      orderIndex: enhancedActivity.orderIndex,
    );
    return await insertActivity(activity);
  }

  // Material CRUD operations
  static Future<int> insertMaterial(EnhancedMaterial material) async {
    final db = await database;
    return await db.insert('materials', material.toMap());
  }

  static Future<List<SuggestedActivity>> getActivitiesByLearningOutcome(int learningOutcomeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'learning_outcome_id = ?',
      whereArgs: [learningOutcomeId],
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => SuggestedActivity.fromMap(maps[i]));
  }

  static Future<List<EnhancedMaterial>> getMaterialsByLearningOutcome(int learningOutcomeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'materials',
      where: 'learning_outcome_id = ?',
      whereArgs: [learningOutcomeId],
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => EnhancedMaterial.fromMap(maps[i]));
  }

  static Future<int> updateActivity(SuggestedActivity activity) async {
    final db = await database;
    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  static Future<int> deleteActivity(int id) async {
    final db = await database;
    return await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  // Assessment CRUD operations
  static Future<int> insertAssessment(AssessmentStrategy assessment) async {
    final db = await database;
    return await db.insert('assessments', {
      'learning_outcome_id': assessment.learningOutcomeId,
      'assessment_method': assessment.strategyText,
      'guidance': assessment.strategyText,
      'mode': 'Formative',
      'exam_eligibility': 'Yes',
      'weighting': null,
      'order_index': assessment.orderIndex,
    });
  }

  static Future<int> updateAssessment(AssessmentStrategy assessment) async {
    final db = await database;
    return await db.update(
      'assessments',
      {
        'learning_outcome_id': assessment.learningOutcomeId,
        'assessment_method': assessment.strategyText,
        'guidance': assessment.strategyText,
        'mode': 'Formative',
        'exam_eligibility': 'Yes',
        'weighting': null,
        'order_index': assessment.orderIndex,
      },
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  static Future<List<AssessmentStrategy>> getAssessmentsByLearningOutcome(int learningOutcomeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'learning_outcome_id = ?',
      whereArgs: [learningOutcomeId],
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => AssessmentStrategy.fromMap({
      'id': maps[i]['id'],
      'learning_outcome_id': maps[i]['learning_outcome_id'],
      'strategy_text': maps[i]['assessment_method'],
      'order_index': maps[i]['order_index'],
    }));
  }

  // Cross-cutting issues CRUD operations
  static Future<int> insertCrossCuttingIssue(CrossCuttingIssue issue) async {
    final db = await database;
    return await db.insert('cross_cutting_issues', issue.toMap());
  }

  static Future<List<CrossCuttingIssue>> getCrossCuttingIssuesBySubject(int subjectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cross_cutting_issues',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'issue_name ASC',
    );
    return List.generate(maps.length, (i) => CrossCuttingIssue.fromMap(maps[i]));
  }

  // Generic skills CRUD operations
  static Future<int> insertGenericSkill(GenericSkill skill) async {
    final db = await database;
    return await db.insert('generic_skills', skill.toMap());
  }

  static Future<List<GenericSkill>> getGenericSkillsBySubject(int subjectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'generic_skills',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'skill_name ASC',
    );
    return List.generate(maps.length, (i) => GenericSkill.fromMap(maps[i]));
  }

  // Search and filter operations
  static Future<List<Topic>> searchTopics(String query, {int? subjectId}) async {
    final db = await database;
    String whereClause = "t.name LIKE ? OR t.description LIKE ? OR t.competency LIKE ?";
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%'];
    
    if (subjectId != null) {
      whereClause += " AND s.subject_id = ?";
      whereArgs.add(subjectId);
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM topics t
      INNER JOIN strands s ON t.strand_id = s.id
      WHERE $whereClause
      ORDER BY t.name ASC
    ''', whereArgs);
    
    return List.generate(maps.length, (i) => Topic.fromMap(maps[i]));
  }

  static Future<Map<String, dynamic>> getCurriculumStatistics() async {
    final db = await database;
    
    final subjectCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM subjects')) ?? 0;
    final strandCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM strands')) ?? 0;
    final topicCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM topics')) ?? 0;
    final learningOutcomeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM learning_outcomes')) ?? 0;
    final activityCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM activities')) ?? 0;
    
    return {
      'subjects': subjectCount,
      'strands': strandCount,
      'topics': topicCount,
      'learningOutcomes': learningOutcomeCount,
      'activities': activityCount,
    };
  }

  // Batch operations for data ingestion
  static Future<void> batchInsertSubjects(List<Subject> subjects) async {
    final db = await database;
    final batch = db.batch();
    
    for (final subject in subjects) {
      batch.insert('subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  static Future<void> batchInsertStrands(List<Strand> strands) async {
    final db = await database;
    final batch = db.batch();
    
    for (final strand in strands) {
      batch.insert('strands', strand.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  static Future<void> batchInsertTopics(List<Topic> topics) async {
    final db = await database;
    final batch = db.batch();
    
    for (final topic in topics) {
      batch.insert('topics', topic.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('teaching_strategies');
      await txn.delete('ict_integration');
      await txn.delete('generic_skills');
      await txn.delete('cross_cutting_issues');
      await txn.delete('assessments');
      await txn.delete('materials');
      await txn.delete('activities');
      await txn.delete('learning_outcomes');
      await txn.delete('competencies');
      await txn.delete('sub_strands');
      await txn.delete('topics');
      await txn.delete('strands');
      await txn.delete('subjects');
    });
  }
}

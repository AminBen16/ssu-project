import 'dart:developer' as developer;

import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Models for syllabus data
class SyllabusEntry {
  final String subject;
  final String level;
  final String className;
  final String strand;
  final String topic;
  final int? suggestedPeriods;
  final List<Competence> competences;
  final String? topicCode;
  final TeachingTime? teachingTime;

  SyllabusEntry({
    required this.subject,
    required this.level,
    required this.className,
    required this.strand,
    required this.topic,
    this.suggestedPeriods,
    required this.competences,
    this.topicCode,
    this.teachingTime,
  });

  factory SyllabusEntry.fromJson(Map<String, dynamic> json) {
    return SyllabusEntry(
      subject: json['subject'] ?? '',
      level: json['level'] ?? '',
      className: json['class'] ?? '',
      strand: json['strand'] ?? '',
      topic: json['topic'] ?? '',
      suggestedPeriods: json['suggested_periods'],
      competences: (json['competences'] as List?)
          ?.map((c) => Competence.fromJson(c))
          .toList() ?? [],
      topicCode: json['topic_code'],
      teachingTime: json['teaching_time'] != null 
          ? TeachingTime.fromJson(json['teaching_time']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'level': level,
      'class': className,
      'strand': strand,
      'topic': topic,
      'suggested_periods': suggestedPeriods,
      'competences': competences.map((c) => c.toJson()).toList(),
      'topic_code': topicCode,
      'teaching_time': teachingTime?.toJson(),
    };
  }
}

class Competence {
  final String text;
  final String competencyType;
  final List<LearningOutcome> learningOutcomes;
  final List<String> assessmentCriteria;
  final List<String> keyConcepts;

  Competence({
    required this.text,
    required this.competencyType,
    required this.learningOutcomes,
    required this.assessmentCriteria,
    required this.keyConcepts,
  });

  factory Competence.fromJson(Map<String, dynamic> json) {
    return Competence(
      text: json['text'] ?? '',
      competencyType: json['competency_type'] ?? '',
      learningOutcomes: (json['learning_outcomes'] as List?)
          ?.map((lo) => LearningOutcome.fromJson(lo))
          .toList() ?? [],
      assessmentCriteria: List<String>.from(json['assessment_criteria'] ?? []),
      keyConcepts: List<String>.from(json['key_concepts'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'competency_type': competencyType,
      'learning_outcomes': learningOutcomes.map((lo) => lo.toJson()).toList(),
      'assessment_criteria': assessmentCriteria,
      'key_concepts': keyConcepts,
    };
  }
}

class LearningOutcome {
  final String text;
  final String outcomeType;
  final String lessonUnit;
  final List<String> activities;
  final List<String> materials;
  final Assessment assessment;
  final List<String> crossCuttingIssues;
  final List<String> genericSkills;
  final List<String> ictIntegration;
  final List<String> teachingStrategies;

  LearningOutcome({
    required this.text,
    required this.outcomeType,
    required this.lessonUnit,
    required this.activities,
    required this.materials,
    required this.assessment,
    required this.crossCuttingIssues,
    required this.genericSkills,
    required this.ictIntegration,
    required this.teachingStrategies,
  });

  factory LearningOutcome.fromJson(Map<String, dynamic> json) {
    return LearningOutcome(
      text: json['text'] ?? '',
      outcomeType: json['outcome_type'] ?? '',
      lessonUnit: json['lesson_unit'] ?? '',
      activities: List<String>.from(json['activities'] ?? []),
      materials: List<String>.from(json['materials'] ?? []),
      assessment: Assessment.fromJson(json['assessment'] ?? {}),
      crossCuttingIssues: List<String>.from(json['cross_cutting_issues'] ?? []),
      genericSkills: List<String>.from(json['generic_skills'] ?? []),
      ictIntegration: List<String>.from(json['ict_integration'] ?? []),
      teachingStrategies: List<String>.from(json['teaching_strategies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'outcome_type': outcomeType,
      'lesson_unit': lessonUnit,
      'activities': activities,
      'materials': materials,
      'assessment': assessment.toJson(),
      'cross_cutting_issues': crossCuttingIssues,
      'generic_skills': genericSkills,
      'ict_integration': ictIntegration,
      'teaching_strategies': teachingStrategies,
    };
  }
}

class Assessment {
  final String? guidance;
  final String mode;
  final String examEligibility;
  final String? weighting;
  final String? method;

  Assessment({
    this.guidance,
    required this.mode,
    required this.examEligibility,
    this.weighting,
    this.method,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      guidance: json['guidance'],
      mode: json['mode'] ?? '',
      examEligibility: json['exam_eligibility'] ?? '',
      weighting: json['weighting'],
      method: json['method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guidance': guidance,
      'mode': mode,
      'exam_eligibility': examEligibility,
      'weighting': weighting,
      'method': method,
    };
  }
}

class TeachingTime {
  final int periods;
  final int minutes;
  final double hours;

  TeachingTime({
    required this.periods,
    required this.minutes,
    required this.hours,
  });

  factory TeachingTime.fromJson(Map<String, dynamic> json) {
    return TeachingTime(
      periods: json['periods'] ?? 0,
      minutes: json['minutes'] ?? 0,
      hours: (json['hours'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periods': periods,
      'minutes': minutes,
      'hours': hours,
    };
  }
}

/// Database service for syllabus data
class SyllabusDatabaseService {
  static Database? _database;
  static const String _dbName = 'syllabus_database.db';
  static const String _tableName = 'syllabus_entries';

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT,
        level TEXT,
        class TEXT,
        strand TEXT,
        topic TEXT,
        suggested_periods INTEGER,
        topic_code TEXT,
        teaching_time TEXT,
        competences TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_subject ON $_tableName(subject)');
    await db.execute('CREATE INDEX idx_level ON $_tableName(level)');
    await db.execute('CREATE INDEX idx_class ON $_tableName(class)');
    await db.execute('CREATE INDEX idx_topic ON $_tableName(topic)');
  }

  static Future<void> loadSyllabusData() async {
    try {
      final db = await database;
      
      // Clear existing data
      await db.delete(_tableName);
      
      // Load A-Level data
      await _loadDataFromFile('assets/data/alevel_data.json', 'Advanced Secondary');
      
      // Load O-Level data
      await _loadDataFromFile('assets/data/olevel_data.json', 'Lower Secondary');
      
      developer.log('Syllabus data loaded successfully into database');
    } catch (e) {
      developer.log('Error loading syllabus data: $e');
    }
  }

  static Future<void> _loadDataFromFile(String filename, String level) async {
    try {
      final String content = await rootBundle.loadString(filename);
      final List<dynamic> jsonData = json.decode(content);
      
      final db = await database;
      
      for (var item in jsonData) {
        final entry = SyllabusEntry.fromJson(item);
        
        await db.insert(_tableName, {
          'subject': entry.subject,
          'level': entry.level,
          'class': entry.className,
          'strand': entry.strand,
          'topic': entry.topic,
          'suggested_periods': entry.suggestedPeriods,
          'topic_code': entry.topicCode,
          'teaching_time': json.encode(entry.teachingTime?.toJson()),
          'competences': json.encode(entry.competences.map((c) => c.toJson()).toList()),
        });
      }
      
      developer.log('Loaded ${jsonData.length} entries from $filename');
    } catch (e) {
      developer.log('Error loading data from $filename: $e');
    }
  }

  static Future<List<SyllabusEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    
    return List.generate(maps.length, (i) {
      return _mapToEntry(maps[i]);
    });
  }

  static Future<List<SyllabusEntry>> getEntriesByLevel(String level) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'level = ?',
      whereArgs: [level],
    );
    
    return List.generate(maps.length, (i) {
      return _mapToEntry(maps[i]);
    });
  }

  static Future<List<SyllabusEntry>> getEntriesBySubject(String subject) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'subject = ?',
      whereArgs: [subject],
    );
    
    return List.generate(maps.length, (i) {
      return _mapToEntry(maps[i]);
    });
  }

  static Future<List<SyllabusEntry>> getEntriesByClass(String className) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'class = ?',
      whereArgs: [className],
    );
    
    return List.generate(maps.length, (i) {
      return _mapToEntry(maps[i]);
    });
  }

  static Future<List<SyllabusEntry>> searchEntries(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $_tableName 
      WHERE subject LIKE ? OR topic LIKE ? OR strand LIKE ?
      ORDER BY subject, topic
    ''', ['%$query%', '%$query%', '%$query%']);
    
    return List.generate(maps.length, (i) {
      return _mapToEntry(maps[i]);
    });
  }

  static Future<List<String>> getSubjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT subject FROM $_tableName ORDER BY subject'
    );
    
    return maps.map((m) => m['subject'] as String).toList();
  }

  static Future<List<String>> getClasses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT class FROM $_tableName ORDER BY class'
    );
    
    return maps.map((m) => m['class'] as String).toList();
  }

  static Future<List<String>> getLevels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT level FROM $_tableName ORDER BY level'
    );
    
    return maps.map((m) => m['level'] as String).toList();
  }

  static SyllabusEntry _mapToEntry(Map<String, dynamic> map) {
    final competencesJson = map['competences'] as String;
    final competencesList = json.decode(competencesJson) as List;
    
    final teachingTimeJson = map['teaching_time'] as String?;
    TeachingTime? teachingTime;
    if (teachingTimeJson != null && teachingTimeJson.isNotEmpty) {
      teachingTime = TeachingTime.fromJson(json.decode(teachingTimeJson));
    }

    return SyllabusEntry(
      subject: map['subject'] as String,
      level: map['level'] as String,
      className: map['class'] as String,
      strand: map['strand'] as String,
      topic: map['topic'] as String,
      suggestedPeriods: map['suggested_periods'] as int?,
      topicCode: map['topic_code'] as String?,
      teachingTime: teachingTime,
      competences: competencesList.map((c) => Competence.fromJson(c)).toList(),
    );
  }
}

/// Navigation service for hierarchical browsing
class NavigationService {
  static List<NavigationNode> buildNavigationTree(List<SyllabusEntry> entries) {
    final Map<String, NavigationNode> nodes = {};
    
    // Root node
    nodes['root'] = NavigationNode(
      id: 'root',
      title: 'NCDC Syllabus',
      type: NavigationType.root,
      parentId: null,
      children: [],
      data: {},
    );

    // Level nodes
    final aLevelEntries = entries.where((e) => e.level == 'Advanced Secondary').toList();
    final oLevelEntries = entries.where((e) => e.level == 'Lower Secondary').toList();

    if (aLevelEntries.isNotEmpty) {
      nodes['alevel'] = NavigationNode(
        id: 'alevel',
        title: 'Advanced Secondary (A-Level)',
        type: NavigationType.level,
        parentId: 'root',
        children: [],
        data: {'level': 'Advanced Secondary', 'entryCount': aLevelEntries.length},
      );
      nodes['root']!.children.add('alevel');
    }

    if (oLevelEntries.isNotEmpty) {
      nodes['olevel'] = NavigationNode(
        id: 'olevel',
        title: 'Lower Secondary (O-Level)',
        type: NavigationType.level,
        parentId: 'root',
        children: [],
        data: {'level': 'Lower Secondary', 'entryCount': oLevelEntries.length},
      );
      nodes['root']!.children.add('olevel');
    }

    // Subject nodes
    _addSubjectNodes(nodes, aLevelEntries, 'alevel');
    _addSubjectNodes(nodes, oLevelEntries, 'olevel');

    return nodes.values.toList();
  }

  static void _addSubjectNodes(
    Map<String, NavigationNode> nodes,
    List<SyllabusEntry> entries,
    String levelNodeId,
  ) {
    final levelNode = nodes[levelNodeId];
    if (levelNode == null) return;

    final subjectGroups = <String, List<SyllabusEntry>>{};
    for (final entry in entries) {
      subjectGroups.putIfAbsent(entry.subject, () => []).add(entry);
    }

    for (final subject in subjectGroups.keys) {
      final subjectId = '${levelNodeId}_${subject.toLowerCase().replaceAll(' ', '_')}';
      final subjectEntries = subjectGroups[subject]!;

      nodes[subjectId] = NavigationNode(
        id: subjectId,
        title: subject,
        type: NavigationType.subject,
        parentId: levelNodeId,
        children: [],
        data: {
          'subject': subject,
          'level': levelNode.data['level'],
          'entryCount': subjectEntries.length,
        },
      );

      levelNode.children.add(subjectId);
      _addClassNodes(nodes, subjectEntries, subjectId);
    }
  }

  static void _addClassNodes(
    Map<String, NavigationNode> nodes,
    List<SyllabusEntry> entries,
    String subjectNodeId,
  ) {
    final subjectNode = nodes[subjectNodeId];
    if (subjectNode == null) return;

    final classGroups = <String, List<SyllabusEntry>>{};
    for (final entry in entries) {
      classGroups.putIfAbsent(entry.className, () => []).add(entry);
    }

    for (final className in classGroups.keys) {
      final classId = '${subjectNodeId}_${className.toLowerCase().replaceAll(' ', '_')}';
      final classEntries = classGroups[className]!;

      nodes[classId] = NavigationNode(
        id: classId,
        title: className,
        type: NavigationType.class_,
        parentId: subjectNodeId,
        children: [],
        data: {
          'subject': subjectNode.data['subject'],
          'level': subjectNode.data['level'],
          'class': className,
          'entryCount': classEntries.length,
        },
      );

      subjectNode.children.add(classId);
      _addTopicNodes(nodes, classEntries, classId);
    }
  }

  static void _addTopicNodes(
    Map<String, NavigationNode> nodes,
    List<SyllabusEntry> entries,
    String classNodeId,
  ) {
    final classNode = nodes[classNodeId];
    if (classNode == null) return;

    for (final entry in entries) {
      final topicId = '${classNodeId}_${entry.topic.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}';

      nodes[topicId] = NavigationNode(
        id: topicId,
        title: entry.topic,
        type: NavigationType.topic,
        parentId: classNodeId,
        children: [],
        data: {
          'subject': classNode.data['subject'],
          'level': classNode.data['level'],
          'class': classNode.data['class'],
          'topic': entry.topic,
          'strand': entry.strand,
          'suggestedPeriods': entry.suggestedPeriods,
          'entry': entry,
        },
      );

      classNode.children.add(topicId);
    }
  }
}

enum NavigationType { root, level, subject, class_, topic }

class NavigationNode {
  final String id;
  final String title;
  final NavigationType type;
  final String? parentId;
  final List<String> children;
  final Map<String, dynamic> data;

  NavigationNode({
    required this.id,
    required this.title,
    required this.type,
    this.parentId,
    required this.children,
    required this.data,
  });
}

/// Search service
class SearchService {
  static List<SearchResult> search(String query, List<SyllabusEntry> entries) {
    final queryLower = query.toLowerCase();
    final results = <SearchResult>[];

    for (final entry in entries) {
      final score = _calculateRelevance(queryLower, entry);
      if (score > 0) {
        results.add(SearchResult(
          entry: entry,
          relevanceScore: score,
          matchedFields: _getMatchedFields(queryLower, entry),
        ));
      }
    }

    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  static double _calculateRelevance(String queryLower, SyllabusEntry entry) {
    double score = 0.0;

    if (entry.topic.toLowerCase().contains(queryLower)) score += 3.0;
    if (entry.subject.toLowerCase().contains(queryLower)) score += 2.0;
    if (entry.strand.toLowerCase().contains(queryLower)) score += 1.5;

    for (final competence in entry.competences) {
      if (competence.text.toLowerCase().contains(queryLower)) score += 1.5;
      for (final outcome in competence.learningOutcomes) {
        if (outcome.text.toLowerCase().contains(queryLower)) score += 1.0;
      }
    }

    return score;
  }

  static List<String> _getMatchedFields(String queryLower, SyllabusEntry entry) {
    final matched = <String>[];

    if (entry.topic.toLowerCase().contains(queryLower)) matched.add('topic');
    if (entry.subject.toLowerCase().contains(queryLower)) matched.add('subject');
    if (entry.strand.toLowerCase().contains(queryLower)) matched.add('strand');

    return matched;
  }
}

class SearchResult {
  final SyllabusEntry entry;
  final double relevanceScore;
  final List<String> matchedFields;

  SearchResult({
    required this.entry,
    required this.relevanceScore,
    required this.matchedFields,
  });
}


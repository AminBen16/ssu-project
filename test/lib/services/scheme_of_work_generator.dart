import '../models/curriculum_models.dart';
import 'ncdc_curriculum_parser.dart';

/// O-Level Scheme of Work Generator using real NCDC curriculum data
class SchemeOfWorkGenerator {
  final NCDCCurriculumParser _curriculumParser = NCDCCurriculumParser();
  
  static final SchemeOfWorkGenerator _instance = SchemeOfWorkGenerator._internal();
  factory SchemeOfWorkGenerator() => _instance;
  SchemeOfWorkGenerator._internal();

  /// Generate complete scheme of work for a subject and class
  Future<SchemeOfWork> generateSchemeOfWork({
    required String subjectName,
    required String className,
    required String academicYear,
    required int weeksPerTerm,
    required int periodsPerWeek,
    Map<String, dynamic>? customSettings,
  }) async {
    
    // Ensure curriculum data is parsed
    await _curriculumParser.parseAllSyllabusFiles();
    
    // Get curriculum data
    final subjects = _curriculumParser.getSubjects(subjectName);
    
    if (subjects.isEmpty) {
      throw Exception('No curriculum data found for subject: $subjectName');
    }
    
    final subject = subjects.first;
    
    // Create scheme of work structure
    final schemeOfWork = SchemeOfWork(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: subject.id ?? 0,
      subjectName: subjectName,
      className: className,
      academicYear: academicYear,
      weeksPerTerm: weeksPerTerm,
      periodsPerWeek: periodsPerWeek,
      totalPeriods: weeksPerTerm * 3 * periodsPerWeek, // 3 terms
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Generate weekly breakdown
    final weeklyBreakdown = await _generateWeeklyBreakdown(
      subjectName,
      className,
      weeksPerTerm,
      periodsPerWeek,
      schemeOfWork.id,
    );
    
    // Add weekly breakdown to scheme
    schemeOfWork.weeklyBreakdown = weeklyBreakdown;
    
    return schemeOfWork;
  }

  /// Generate weekly breakdown based on NCDC curriculum
  Future<List<WeeklyBreakdown>> _generateWeeklyBreakdown(
    String subjectName,
    String className,
    int weeksPerTerm,
    int periodsPerWeek,
    String schemeId,
  ) async {
    
    final weeklyBreakdown = <WeeklyBreakdown>[];
    final strands = _curriculumParser.getStrands(subjectName);
    final topics = _curriculumParser.getTopics(subjectName);
    
    int currentWeek = 1;
    int currentTerm = 1;
    
    // Process each strand
    for (final strand in strands) {
      final strandTopics = topics.where((topic) => topic.strandId == (strand.id ?? 0)).toList();
      
      for (final topic in strandTopics) {
        // Get learning outcomes and activities for this topic
        final outcomes = _curriculumParser.getOutcomesByTopic(subjectName, topic.id ?? 0);
        final activities = _curriculumParser.getActivitiesByTopic(subjectName, topic.id ?? 0);
        final assessments = _curriculumParser.getAssessmentsByTopic(subjectName, topic.id ?? 0);
        
        // Calculate weeks needed for this topic
        final suggestedPeriods = topic.suggestedPeriods ?? 6; // Default 6 periods
        final weeksNeeded = (suggestedPeriods / periodsPerWeek).ceil();
        
        // Create weekly breakdown for this topic
        for (int week = 0; week < weeksNeeded; week++) {
          if (currentWeek > weeksPerTerm) {
            currentWeek = 1;
            currentTerm++;
          }
          
          final weeklyPlan = WeeklyBreakdown(
            id: DateTime.now().millisecondsSinceEpoch + week,
            schemeId: schemeId,
            term: 'Term $currentTerm',
            week: currentWeek,
            strandName: strand.name,
            topicName: topic.name,
            learningOutcomes: outcomes.map((o) => o.outcome).toList(),
            teachingActivities: activities.map((a) => a.activity).toList(),
            assessmentMethods: assessments.map((a) => a.strategy).toList(),
            resources: _generateResources(topic, activities),
            notes: _generateNotes(topic, strand),
            suggestedPeriods: periodsPerWeek,
          );
          
          weeklyBreakdown.add(weeklyPlan);
          currentWeek++;
        }
      }
    }
    
    return weeklyBreakdown;
  }

  /// Generate resources list based on topic and activities
  List<String> _generateResources(Topic topic, List<SuggestedActivity> activities) {
    final resources = <String>[];
    
    // Add standard resources
    resources.addAll([
      'NCDC $topic.name syllabus',
      'Textbook for $topic.name',
      'Teacher\'s guide',
      'Whiteboard/Smartboard',
      'Markers/Chalk',
    ]);
    
    // Add activity-specific resources
    for (final activity in activities) {
      if (activity.activityText.toLowerCase().contains('demonstration')) {
        resources.add('Laboratory equipment');
        resources.add('Demonstration materials');
      } else if (activity.activityText.toLowerCase().contains('research')) {
        resources.add('Library resources');
        resources.add('Internet access');
        resources.add('Research materials');
      } else if (activity.activityText.toLowerCase().contains('collaborative')) {
        resources.add('Group work materials');
        resources.add('Discussion guides');
      } else if (activity.activityText.toLowerCase().contains('practical')) {
        resources.add('Practical equipment');
        resources.add('Work materials');
        resources.add('Instructions sheets');
      }
    }
    
    // Remove duplicates
    return resources.toSet().toList();
  }

  /// Generate notes for topic
  String _generateNotes(Topic topic, Strand strand) {
    final notes = <String>[];
    
    notes.add('Strand: ${strand.name}');
    notes.add('Topic: ${topic.name}');
    
    if (topic.competency?.isNotEmpty == true) {
      notes.add('Competency: ${topic.competency}');
    }
    
    if (topic.term?.isNotEmpty == true) {
      notes.add('Term: ${topic.term}');
    }
    
    if (topic.className?.isNotEmpty == true) {
      notes.add('Class Level: ${topic.className}');
    }
    
    notes.add('Based on NCDC official syllabus');
    
    return notes.join('\n');
  }

  /// Generate scheme of work for specific term
  Future<SchemeOfWork> generateTermSchemeOfWork({
    required String subjectName,
    required String className,
    required String academicYear,
    required int termNumber,
    required int weeksPerTerm,
    required int periodsPerWeek,
  }) async {
    
    final fullScheme = await generateSchemeOfWork(
      subjectName: subjectName,
      className: className,
      academicYear: academicYear,
      weeksPerTerm: weeksPerTerm,
      periodsPerWeek: periodsPerWeek,
    );
    
    // Filter for specific term
    final termWeeklyBreakdown = fullScheme.weeklyBreakdown
        .where((week) => week.term == 'Term $termNumber')
        .toList();
    
    // Create term-specific scheme
    final termScheme = SchemeOfWork(
      id: '${fullScheme.id}_term$termNumber',
      subjectId: fullScheme.subjectId,
      subjectName: subjectName,
      className: className,
      academicYear: academicYear,
      term: termNumber,
      weeksPerTerm: weeksPerTerm,
      periodsPerWeek: periodsPerWeek,
      totalPeriods: weeksPerTerm * periodsPerWeek,
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    termScheme.weeklyBreakdown = termWeeklyBreakdown;
    
    return termScheme;
  }

  /// Get available subjects for scheme generation
  Future<List<String>> getAvailableSubjects() async {
    await _curriculumParser.parseAllSyllabusFiles();
    return _curriculumParser.getAllSubjectNames();
  }

  /// Get subject information
  Future<Subject?> getSubjectInfo(String subjectName) async {
    await _curriculumParser.parseAllSyllabusFiles();
    final subjects = _curriculumParser.getSubjects(subjectName);
    return subjects.isNotEmpty ? subjects.first : null;
  }

  /// Get curriculum overview for subject
  Future<Map<String, dynamic>> getCurriculumOverview(String subjectName) async {
    await _curriculumParser.parseAllSyllabusFiles();
    
    final strands = _curriculumParser.getStrands(subjectName);
    final topics = _curriculumParser.getTopics(subjectName);
    final outcomes = _curriculumParser.getLearningOutcomes(subjectName);
    final activities = _curriculumParser.getActivities(subjectName);
    final assessments = _curriculumParser.getAssessments(subjectName);
    
    return {
      'subject': subjectName,
      'totalStrands': strands.length,
      'totalTopics': topics.length,
      'totalOutcomes': outcomes.length,
      'totalActivities': activities.length,
      'totalAssessments': assessments.length,
      'strands': strands.map((s) => {
        'name': s.name,
        'topicsCount': topics.where((t) => t.strandId == s.id).length,
      }).toList(),
    };
  }

  /// Export scheme of work to various formats
  Future<String> exportSchemeOfWork(SchemeOfWork scheme, String format) async {
    switch (format.toLowerCase()) {
      case 'markdown':
        return _exportToMarkdown(scheme);
      case 'pdf':
        return _exportToPDF(scheme);
      case 'word':
        return _exportToWord(scheme);
      default:
        return _exportToMarkdown(scheme);
    }
  }

  String _exportToMarkdown(SchemeOfWork scheme) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Scheme of Work');
    buffer.writeln();
    buffer.writeln('**Subject:** ${scheme.subjectName}');
    buffer.writeln('**Class:** ${scheme.className}');
    buffer.writeln('**Academic Year:** ${scheme.academicYear}');
    buffer.writeln('**Periods per Week:** ${scheme.periodsPerWeek}');
    buffer.writeln('**Weeks per Term:** ${scheme.weeksPerTerm}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Group by term
    final groupedByTerm = <String, List<WeeklyBreakdown>>{};
    for (final week in scheme.weeklyBreakdown) {
      if (!groupedByTerm.containsKey(week.term)) {
        groupedByTerm[week.term] = [];
      }
      groupedByTerm[week.term]!.add(week);
    }
    
    for (final term in groupedByTerm.keys) {
      buffer.writeln('## $term');
      buffer.writeln();
      
      final weeks = groupedByTerm[term]!;
      for (final week in weeks) {
        buffer.writeln('### Week ${week.week}: ${week.topicName}');
        buffer.writeln();
        buffer.writeln('**Strand:** ${week.strandName}');
        buffer.writeln();
        
        buffer.writeln('#### Learning Outcomes:');
        for (final outcome in week.learningOutcomes) {
          buffer.writeln('- $outcome');
        }
        buffer.writeln();
        
        buffer.writeln('#### Teaching Activities:');
        for (final activity in week.teachingActivities) {
          buffer.writeln('- $activity');
        }
        buffer.writeln();
        
        buffer.writeln('#### Assessment Methods:');
        for (final assessment in week.assessmentMethods) {
          buffer.writeln('- $assessment');
        }
        buffer.writeln();
        
        buffer.writeln('#### Resources:');
        for (final resource in week.resources) {
          buffer.writeln('- $resource');
        }
        buffer.writeln();
        
        if (week.notes.isNotEmpty) {
          buffer.writeln('#### Notes:');
          buffer.writeln(week.notes);
          buffer.writeln();
        }
        
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  String _exportToPDF(SchemeOfWork scheme) {
    // Placeholder for PDF export
    // In a real implementation, you would use a PDF generation library
    return 'PDF export not yet implemented';
  }

  String _exportToWord(SchemeOfWork scheme) {
    // Placeholder for Word export
    // In a real implementation, you would use a Word document generation library
    return 'Word export not yet implemented';
  }
}

/// Scheme of Work Model
class SchemeOfWork {
  String id;
  int subjectId;
  String subjectName;
  String className;
  String academicYear;
  int? term;
  int weeksPerTerm;
  int periodsPerWeek;
  int totalPeriods;
  String status;
  DateTime createdAt;
  DateTime updatedAt;
  List<WeeklyBreakdown> weeklyBreakdown;

  SchemeOfWork({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.className,
    required this.academicYear,
    this.term,
    required this.weeksPerTerm,
    required this.periodsPerWeek,
    required this.totalPeriods,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.weeklyBreakdown = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'className': className,
      'academicYear': academicYear,
      'term': term,
      'weeksPerTerm': weeksPerTerm,
      'periodsPerWeek': periodsPerWeek,
      'totalPeriods': totalPeriods,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'weeklyBreakdown': weeklyBreakdown.map((w) => w.toMap()).toList(),
    };
  }
}

/// Weekly Breakdown Model
class WeeklyBreakdown {
  int id;
  String schemeId;
  String term;
  int week;
  String strandName;
  String topicName;
  List<String> learningOutcomes;
  List<String> teachingActivities;
  List<String> assessmentMethods;
  List<String> resources;
  String notes;
  int suggestedPeriods;

  WeeklyBreakdown({
    required this.id,
    required this.schemeId,
    required this.term,
    required this.week,
    required this.strandName,
    required this.topicName,
    required this.learningOutcomes,
    required this.teachingActivities,
    required this.assessmentMethods,
    required this.resources,
    required this.notes,
    required this.suggestedPeriods,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schemeId': schemeId,
      'term': term,
      'week': week,
      'strandName': strandName,
      'topicName': topicName,
      'learningOutcomes': learningOutcomes,
      'teachingActivities': teachingActivities,
      'assessmentMethods': assessmentMethods,
      'resources': resources,
      'notes': notes,
      'suggestedPeriods': suggestedPeriods,
    };
  }
}

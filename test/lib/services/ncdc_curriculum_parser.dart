import 'dart:async';
import 'dart:io';
import '../models/curriculum_models.dart';

/// NCDC Curriculum Parser - Extracts structured data from markdown syllabus files
class NCDCCurriculumParser {
  static final NCDCCurriculumParser _instance = NCDCCurriculumParser._internal();
  factory NCDCCurriculumParser() => _instance;
  NCDCCurriculumParser._internal();

  final Map<String, List<Subject>> _parsedSubjects = {};
  final Map<String, List<Strand>> _parsedStrands = {};
  final Map<String, List<Topic>> _parsedTopics = {};
  final Map<String, List<LearningOutcome>> _parsedOutcomes = {};
  final Map<String, List<SuggestedActivity>> _parsedActivities = {};
  final Map<String, List<AssessmentStrategy>> _parsedAssessments = {};

  /// Parse all markdown syllabus files in the extracted directory
  Future<void> parseAllSyllabusFiles() async {
    final syllabusDir = Directory(r'C:\Users\user\SSU\extracted_syllabi');
    
    if (!await syllabusDir.exists()) {
      throw Exception('Syllabus directory not found: ${syllabusDir.path}');
    }

    final files = await syllabusDir.list().where((f) => f.path.endsWith('.md')).toList();
    
    for (final file in files) {
      await parseSyllabusFile(file.path);
    }
  }

  /// Parse a single syllabus markdown file
  Future<void> parseSyllabusFile(String filePath) async {
    final file = File(filePath);
    final fileName = file.path.split('\\').last;
    final subjectName = _extractSubjectName(fileName);
    
    if (!await file.exists()) {
      print('File not found: $filePath');
      return;
    }

    final content = await file.readAsString();
    final lines = content.split('\n');
    
    final subjects = <Subject>[];
    final strands = <Strand>[];
    final topics = <Topic>[];
    final outcomes = <LearningOutcome>[];
    final activities = <SuggestedActivity>[];
    final assessments = <AssessmentStrategy>[];

    Subject? currentSubject;
    Strand? currentStrand;
    Topic? currentTopic;
    
    String currentSection = '';
    int currentPage = 1;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Track page numbers
      if (line.startsWith('--- PAGE')) {
        final pageMatch = RegExp(r'PAGE (\d+)').firstMatch(line);
        if (pageMatch != null) {
          currentPage = int.parse(pageMatch.group(1)!);
        }
        continue;
      }
      
      // Identify sections
      if (line.startsWith('# ') || line.startsWith('## ')) {
        currentSection = line.replaceAll('#', '').trim();
        continue;
      }
      
      // Parse subject metadata
      if (_isSubjectSection(line)) {
        currentSubject = _parseSubject(line, subjectName, currentPage);
        if (currentSubject != null) {
          subjects.add(currentSubject);
        }
        continue;
      }
      
      // Parse strands
      if (_isStrandSection(line)) {
        currentStrand = _parseStrand(line, currentSubject?.id ?? 0, currentPage);
        if (currentStrand != null) {
          strands.add(currentStrand);
        }
        continue;
      }
      
      // Parse topics
      if (_isTopicSection(line)) {
        currentTopic = _parseTopic(line, currentStrand?.id ?? 0, currentPage);
        if (currentTopic != null) {
          topics.add(currentTopic);
        }
        continue;
      }
      
      // Parse learning outcomes
      if (_isLearningOutcomeSection(line)) {
        final outcome = _parseLearningOutcome(line, currentTopic?.id ?? 0, currentPage);
        if (outcome != null) {
          outcomes.add(outcome);
        }
        continue;
      }
      
      // Parse activities
      if (_isActivitySection(line)) {
        final activity = _parseActivity(line, currentTopic?.id ?? 0, currentPage);
        if (activity != null) {
          activities.add(activity);
        }
        continue;
      }
      
      // Parse assessments
      if (_isAssessmentSection(line)) {
        final assessment = _parseAssessment(line, currentTopic?.id ?? 0, currentPage);
        if (assessment != null) {
          assessments.add(assessment);
        }
        continue;
      }
    }
    
    // Store parsed data
    _parsedSubjects[subjectName] = subjects;
    _parsedStrands[subjectName] = strands;
    _parsedTopics[subjectName] = topics;
    _parsedOutcomes[subjectName] = outcomes;
    _parsedActivities[subjectName] = activities;
    _parsedAssessments[subjectName] = assessments;
    
    print('Parsed $subjectName: ${subjects.length} subjects, ${strands.length} strands, ${topics.length} topics');
  }

  String _extractSubjectName(String fileName) {
    return fileName
        .replaceAll('.md', '')
        .replaceAll('_compressed', '')
        .replaceAll('_', ' ')
        .replaceAll('SYLLABUS', '')
        .replaceAll('syllabus', '')
        .trim();
  }

  bool _isSubjectSection(String line) {
    return line.toLowerCase().contains('subject') ||
           line.toLowerCase().contains('education level') ||
           line.toLowerCase().contains('class') ||
           line.toLowerCase().contains('period');
  }

  bool _isStrandSection(String line) {
    return line.toLowerCase().contains('strand') ||
           line.toLowerCase().contains('theme') ||
           line.toLowerCase().contains('unit') ||
           (line.length > 10 && !line.contains('.') && !line.contains('?'));
  }

  bool _isTopicSection(String line) {
    return line.toLowerCase().contains('topic') ||
           line.toLowerCase().contains('sub-topic') ||
           (line.startsWith('•') && line.length > 15);
  }

  bool _isLearningOutcomeSection(String line) {
    return line.toLowerCase().contains('outcome') ||
           line.toLowerCase().contains('objective') ||
           line.toLowerCase().contains('learner should') ||
           line.toLowerCase().contains('able to');
  }

  bool _isActivitySection(String line) {
    return line.toLowerCase().contains('activity') ||
           line.toLowerCase().contains('teaching') ||
           line.toLowerCase().contains('learning') ||
           line.toLowerCase().contains('demonstration');
  }

  bool _isAssessmentSection(String line) {
    return line.toLowerCase().contains('assessment') ||
           line.toLowerCase().contains('evaluation') ||
           line.toLowerCase().contains('test') ||
           line.toLowerCase().contains('examination');
  }

  Subject? _parseSubject(String line, String subjectName, int page) {
    // Extract subject information from line
    final educationLevel = _extractField(line, ['education level', 'level']);
    final className = _extractField(line, ['class', 'grade']);
    final periodDuration = _extractIntField(line, ['period duration', 'duration']);
    final periodsPerWeek = _extractIntField(line, ['periods per week', 'periods']);
    
    return Subject(
      id: DateTime.now().millisecondsSinceEpoch + page,
      name: subjectName,
      educationLevel: educationLevel.isNotEmpty ? educationLevel : 'O-Level',
      className: className.isNotEmpty ? className : 'Senior 1-4',
      periodDuration: periodDuration > 0 ? periodDuration : 40,
      periodsPerWeek: periodsPerWeek > 0 ? periodsPerWeek : 5,
    );
  }

  Strand? _parseStrand(String line, int subjectId, int page) {
    return Strand(
      id: DateTime.now().millisecondsSinceEpoch + page,
      subjectId: subjectId,
      name: line.trim(),
      code: 'STR${DateTime.now().millisecondsSinceEpoch % 1000}',
      description: line.trim(),
      orderIndex: page,
    );
  }

  Topic? _parseTopic(String line, int strandId, int page) {
    // Extract suggested periods if mentioned
    final suggestedPeriods = _extractIntField(line, ['periods', 'weeks']);
    
    return Topic(
      id: DateTime.now().millisecondsSinceEpoch + page,
      strandId: strandId,
      name: line.replaceAll('•', '').trim(),
      code: 'TOP${DateTime.now().millisecondsSinceEpoch % 1000}',
      description: line.replaceAll('•', '').trim(),
      competency: '',
      durationPeriods: suggestedPeriods,
      term: _extractTerm(line),
      className: _extractClassLevel(line),
      orderIndex: page,
    );
  }

  LearningOutcome? _parseLearningOutcome(String line, int topicId, int page) {
    return LearningOutcome(
      id: DateTime.now().millisecondsSinceEpoch + page,
      topicId: topicId,
      subTopicId: null,
      outcomeText: line.trim(),
      outcomeType: _determineOutcomeType(line),
      orderIndex: page,
    );
  }

  SuggestedActivity? _parseActivity(String line, int topicId, int page) {
    return SuggestedActivity(
      id: DateTime.now().millisecondsSinceEpoch + page,
      learningOutcomeId: topicId,
      activityText: line.trim(),
      orderIndex: page,
    );
  }

  AssessmentStrategy? _parseAssessment(String line, int topicId, int page) {
    return AssessmentStrategy(
      id: DateTime.now().millisecondsSinceEpoch + page,
      learningOutcomeId: topicId,
      strategyText: line.trim(),
      orderIndex: page,
    );
  }

  String _extractField(String line, List<String> keywords) {
    for (final keyword in keywords) {
      final pattern = RegExp('$keyword[:\\s]*([^\\n]+)', caseSensitive: false);
      final match = pattern.firstMatch(line);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    return '';
  }

  int _extractIntField(String line, List<String> keywords) {
    final value = _extractField(line, keywords);
    final numberMatch = RegExp(r'(\d+)').firstMatch(value);
    return numberMatch != null ? int.parse(numberMatch.group(1)!) : 0;
  }

  String _extractTerm(String line) {
    if (line.toLowerCase().contains('term 1')) return 'Term 1';
    if (line.toLowerCase().contains('term 2')) return 'Term 2';
    if (line.toLowerCase().contains('term 3')) return 'Term 3';
    return '';
  }

  String _extractClassLevel(String line) {
    if (line.toLowerCase().contains('senior 1')) return 'Senior 1';
    if (line.toLowerCase().contains('senior 2')) return 'Senior 2';
    if (line.toLowerCase().contains('senior 3')) return 'Senior 3';
    if (line.toLowerCase().contains('senior 4')) return 'Senior 4';
    if (line.toLowerCase().contains('s.1')) return 'Senior 1';
    if (line.toLowerCase().contains('s.2')) return 'Senior 2';
    if (line.toLowerCase().contains('s.3')) return 'Senior 3';
    if (line.toLowerCase().contains('s.4')) return 'Senior 4';
    return '';
  }

  String _determineOutcomeType(String line) {
    if (line.toLowerCase().contains('understand') || line.toLowerCase().contains('know')) {
      return 'knowledge';
    } else if (line.toLowerCase().contains('apply') || line.toLowerCase().contains('demonstrate')) {
      return 'skill';
    } else if (line.toLowerCase().contains('appreciate') || line.toLowerCase().contains('value')) {
      return 'attitude';
    }
    return 'knowledge';
  }

  String _determineActivityType(String line) {
    if (line.toLowerCase().contains('group') || line.toLowerCase().contains('discussion')) {
      return 'collaborative';
    } else if (line.toLowerCase().contains('demonstration') || line.toLowerCase().contains('practical')) {
      return 'demonstration';
    } else if (line.toLowerCase().contains('research') || line.toLowerCase().contains('investigation')) {
      return 'research';
    }
    return 'individual';
  }

  String _determineAssessmentType(String line) {
    if (line.toLowerCase().contains('formative') || line.toLowerCase().contains('continuous')) {
      return 'formative';
    } else if (line.toLowerCase().contains('summative') || line.toLowerCase().contains('exam')) {
      return 'summative';
    } else if (line.toLowerCase().contains('observation') || line.toLowerCase().contains('practical')) {
      return 'performance';
    }
    return 'formative';
  }

  // Getters for accessing parsed data
  List<Subject> getSubjects(String subjectName) {
    return _parsedSubjects[subjectName] ?? [];
  }

  List<Strand> getStrands(String subjectName) {
    return _parsedStrands[subjectName] ?? [];
  }

  List<Topic> getTopics(String subjectName) {
    return _parsedTopics[subjectName] ?? [];
  }

  List<LearningOutcome> getLearningOutcomes(String subjectName) {
    return _parsedOutcomes[subjectName] ?? [];
  }

  List<SuggestedActivity> getActivities(String subjectName) {
    return _parsedActivities[subjectName] ?? [];
  }

  List<AssessmentStrategy> getAssessments(String subjectName) {
    return _parsedAssessments[subjectName] ?? [];
  }

  /// Get all available subject names
  List<String> getAllSubjectNames() {
    return _parsedSubjects.keys.toList();
  }

  /// Get topics by strand ID
  List<Topic> getTopicsByStrand(String subjectName, int strandId) {
    return getTopics(subjectName).where((topic) => topic.strandId == strandId).toList();
  }

  /// Get learning outcomes by topic ID
  List<LearningOutcome> getOutcomesByTopic(String subjectName, int topicId) {
    return getLearningOutcomes(subjectName).where((outcome) => outcome.topicId == topicId).toList();
  }

  /// Get activities by topic ID
  List<SuggestedActivity> getActivitiesByTopic(String subjectName, int topicId) {
    return getActivities(subjectName).where((activity) => activity.learningOutcomeId == topicId).toList();
  }

  /// Get assessments by topic ID
  List<AssessmentStrategy> getAssessmentsByTopic(String subjectName, int topicId) {
    return getAssessments(subjectName).where((assessment) => assessment.learningOutcomeId == topicId).toList();
  }
}

import 'dart:async';
import '../models/curriculum_models.dart';
import 'ncdc_curriculum_parser.dart';
import '../models/lesson_plan_model.dart';

/// NCDC-Based Lesson Plan Generator using real curriculum data
class NCDCLessonPlanGenerator {
  final NCDCCurriculumParser _curriculumParser = NCDCCurriculumParser();
  
  static final NCDCLessonPlanGenerator _instance = NCDCLessonPlanGenerator._internal();
  factory NCDCLessonPlanGenerator() => _instance;
  NCDCLessonPlanGenerator._internal();

  /// Generate lesson plan based on NCDC curriculum data
  Future<LessonPlan> generateLessonPlan({
    required String subjectName,
    required String topicName,
    required String className,
    required String duration,
    required DateTime date,
    required DateTime startTime,
    List<String>? customObjectives,
    List<String>? availableResources,
    String? teachingStyle,
    int? studentCount,
  }) async {
    
    // Ensure curriculum data is parsed
    await _curriculumParser.parseAllSyllabusFiles();
    
    // Find the specific topic
    final topics = _curriculumParser.getTopics(subjectName);
    final targetTopic = topics.firstWhere(
      (topic) => topic.name.toLowerCase().contains(topicName.toLowerCase()),
      orElse: () => topics.first, // Fallback to first topic
    );
    
    // Get curriculum data for this topic
    final outcomes = _curriculumParser.getOutcomesByTopic(subjectName, targetTopic.id ?? 0);
    final activities = _curriculumParser.getActivitiesByTopic(subjectName, targetTopic.id ?? 0);
    final assessments = _curriculumParser.getAssessmentsByTopic(subjectName, targetTopic.id ?? 0);
    
    // Get strand information
    final strands = _curriculumParser.getStrands(subjectName);
    final strand = strands.firstWhere(
      (s) => s.id == targetTopic.strandId,
      orElse: () => strands.first,
    );
    
    // Generate lesson structure
    final lessonStructure = _generateLessonStructure(duration);
    
    // Create learning activities based on NCDC data
    final lessonActivities = await _generateLessonActivities(
      activities,
      outcomes,
      lessonStructure,
      teachingStyle ?? 'mixed',
    );
    
    // Generate assessment methods
    final lessonAssessments = _generateAssessments(assessments, outcomes);
    
    // Generate materials list
    final materials = _generateMaterials(targetTopic, activities, availableResources);
    
    // Generate homework
    final homework = _generateHomework(targetTopic, outcomes);
    
    // Create the lesson plan
    final lessonPlan = LessonPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teacherId: '', // Will be set by caller
      schoolId: '', // Will be set by caller
      subjectId: targetTopic.id.toString(),
      topicId: targetTopic.id.toString(),
      className: className,
      title: 'Lesson: ${targetTopic.name}',
      date: date,
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: _parseDuration(duration))),
      duration: duration,
      learningObjectives: customObjectives ?? outcomes.map((o) => o.outcomeText).toList(),
      teachingMethods: _generateTeachingMethods(teachingStyle),
      activities: lessonActivities,
      assessments: lessonAssessments,
      materials: materials,
      homework: homework,
      notes: _generateLessonNotes(targetTopic, strand, outcomes, studentCount),
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return lessonPlan;
  }

  /// Generate lesson structure based on duration
  Map<String, int> _generateLessonStructure(String duration) {
    final minutes = _parseDuration(duration);
    
    if (minutes <= 40) {
      return {
        'introduction': 5,
        'mainActivity': 25,
        'assessment': 5,
        'conclusion': 5,
      };
    } else if (minutes <= 60) {
      return {
        'introduction': 8,
        'mainActivity1': 25,
        'mainActivity2': 15,
        'assessment': 7,
        'conclusion': 5,
      };
    } else if (minutes <= 80) {
      return {
        'introduction': 10,
        'mainActivity1': 25,
        'mainActivity2': 25,
        'assessment': 10,
        'conclusion': 10,
      };
    } else {
      return {
        'introduction': 15,
        'mainActivity1': 30,
        'mainActivity2': 30,
        'mainActivity3': 25,
        'assessment': 15,
        'conclusion': 10,
      };
    }
  }

  /// Generate lesson activities from NCDC curriculum data
  Future<List<Map<String, dynamic>>> _generateLessonActivities(
    List<SuggestedActivity> ncdcActivities,
    List<LearningOutcome> outcomes,
    Map<String, int> structure,
    String teachingStyle,
  ) async {
    
    final activities = <Map<String, dynamic>>[];
    
    // Introduction activity
    activities.add({
      'name': 'Introduction & Hook',
      'description': 'Engage students with the topic using NCDC-recommended approaches',
      'duration': structure['introduction'],
      'type': 'introduction',
      'ncdcBased': true,
      'resources': ['Whiteboard', 'NCDC syllabus reference'],
      'instructions': _generateIntroductionInstructions(outcomes),
    });
    
    // Main activities based on NCDC suggestions
    if (ncdcActivities.isNotEmpty) {
      for (int i = 0; i < ncdcActivities.length && i < 3; i++) {
        final activity = ncdcActivities[i];
        final durationKey = i == 0 ? 'mainActivity1' : 
                          i == 1 ? 'mainActivity2' : 'mainActivity3';
        
        if (structure.containsKey(durationKey)) {
          activities.add({
            'name': activity.activityText,
            'description': activity.activityText,
            'duration': structure[durationKey],
            'type': 'general',
            'ncdcBased': true,
            'resources': _getActivityResources(activity),
            'instructions': _generateActivityInstructions(activity, outcomes),
          });
        }
      }
    } else {
      // Fallback activities if no NCDC activities
      activities.addAll(_generateFallbackActivities(structure, teachingStyle));
    }
    
    // Assessment activity
    activities.add({
      'name': 'Assessment & Feedback',
      'description': 'Evaluate student understanding using NCDC assessment methods',
      'duration': structure['assessment'],
      'type': 'assessment',
      'ncdcBased': true,
      'resources': ['Assessment tools', 'Feedback forms'],
      'instructions': 'Use NCDC-recommended assessment strategies to evaluate learning outcomes',
    });
    
    // Conclusion activity
    activities.add({
      'name': 'Conclusion & Summary',
      'description': 'Summarize key learning points and assign homework',
      'duration': structure['conclusion'],
      'type': 'conclusion',
      'ncdcBased': true,
      'resources': ['Summary handout', 'Homework assignment'],
      'instructions': 'Review key concepts and connect to next lesson',
    });
    
    return activities;
  }

  /// Generate fallback activities if no NCDC activities available
  List<Map<String, dynamic>> _generateFallbackActivities(
    Map<String, int> structure,
    String teachingStyle,
  ) {
    
    final activities = <Map<String, dynamic>>[];
    
    if (structure.containsKey('mainActivity1')) {
      activities.add({
        'name': 'Direct Instruction',
        'description': 'Teacher-led presentation of key concepts',
        'duration': structure['mainActivity1'],
        'type': 'lecture',
        'ncdcBased': false,
        'resources': ['Presentation slides', 'Whiteboard'],
        'instructions': 'Present content with clear explanations and examples',
      });
    }
    
    if (structure.containsKey('mainActivity2')) {
      activities.add({
        'name': 'Guided Practice',
        'description': 'Students practice with teacher guidance',
        'duration': structure['mainActivity2'],
        'type': 'practice',
        'ncdcBased': false,
        'resources': ['Practice worksheets', 'Answer keys'],
        'instructions': 'Work through examples together as a class',
      });
    }
    
    if (structure.containsKey('mainActivity3')) {
      activities.add({
        'name': 'Independent Work',
        'description': 'Students work independently on tasks',
        'duration': structure['mainActivity3'],
        'type': 'independent',
        'ncdcBased': false,
        'resources': ['Individual worksheets', 'Reference materials'],
        'instructions': 'Students complete tasks independently',
      });
    }
    
    return activities;
  }

  /// Generate assessments from NCDC data
  List<Map<String, dynamic>> _generateAssessments(
    List<AssessmentStrategy> ncdcAssessments,
    List<LearningOutcome> outcomes,
  ) {
    
    final assessments = <Map<String, dynamic>>[];
    
    if (ncdcAssessments.isNotEmpty) {
      for (final assessment in ncdcAssessments) {
        assessments.add({
          'type': 'formative',
          'name': assessment.strategyText,
          'description': assessment.strategyText,
          'ncdcBased': true,
          'criteria': outcomes.map((o) => o.outcomeText).toList(),
          'weight': '10%', // Default weight
        });
      }
    } else {
      // Fallback assessments
      assessments.addAll([
        {
          'type': 'formative',
          'name': 'Class Participation',
          'description': 'Observe student engagement and participation',
          'ncdcBased': false,
          'criteria': ['Active listening', 'Question asking', 'Contribution to discussions'],
          'weight': '20%',
        },
        {
          'type': 'summative',
          'name': 'End of Lesson Quiz',
          'description': 'Short quiz to assess understanding',
          'ncdcBased': false,
          'criteria': outcomes.map((o) => o.outcomeText).toList(),
          'weight': '80%',
        },
      ]);
    }
    
    return assessments;
  }

  /// Generate materials list
  List<String> _generateMaterials(
    Topic topic,
    List<SuggestedActivity> activities,
    List<String>? availableResources,
  ) {
    
    final materials = <String>[];
    
    // Standard materials
    materials.addAll([
      'NCDC $topic.name syllabus',
      'Subject textbook',
      'Whiteboard/Smartboard',
      'Markers/Chalk',
      'Lesson plan handout',
    ]);
    
    // Activity-specific materials
    for (final activity in activities) {
      materials.addAll(_getActivityResources(activity));
    }
    
    // Available resources
    if (availableResources != null) {
      materials.addAll(availableResources);
    }
    
    // Remove duplicates
    return materials.toSet().toList();
  }

  /// Get resources for specific activity
  List<String> _getActivityResources(SuggestedActivity activity) {
    final resources = <String>[];
    
    switch ('general') {
      case 'demonstration':
        resources.addAll(['Laboratory equipment', 'Demonstration materials', 'Safety equipment']);
        break;
      case 'research':
        resources.addAll(['Library resources', 'Internet access', 'Research worksheets']);
        break;
      case 'collaborative':
        resources.addAll(['Group work sheets', 'Discussion guides', 'Collaboration tools']);
        break;
      case 'practical':
        resources.addAll(['Practical equipment', 'Work materials', 'Instructions sheets']);
        break;
      default:
        resources.addAll(['Worksheet', 'Reference materials']);
    }
    
    return resources;
  }

  /// Generate homework assignment
  Map<String, dynamic> _generateHomework(Topic topic, List<LearningOutcome> outcomes) {
    return {
      'assigned': true,
      'description': 'Complete exercises related to ${topic.name}',
      'tasks': outcomes.map((o) => 'Practice: ${o.outcomeText}').toList(),
      'dueDate': DateTime.now().add(Duration(days: 1)),
      'estimatedTime': '30 minutes',
      'resources': ['Textbook exercises', 'NCDC syllabus reference'],
      'ncdcBased': true,
    };
  }

  /// Generate teaching methods based on style
  List<String> _generateTeachingMethods(String? teachingStyle) {
    final style = teachingStyle?.toLowerCase() ?? 'mixed';
    
    switch (style) {
      case 'interactive':
        return ['Interactive Discussion', 'Group Work', 'Hands-on Activities', 'Peer Teaching'];
      case 'lecture':
        return ['Direct Instruction', 'Demonstration', 'Guided Practice', 'Question-Answer'];
      case 'collaborative':
        return ['Collaborative Learning', 'Group Projects', 'Peer Discussion', 'Team Activities'];
      case 'practical':
        return ['Hands-on Learning', 'Practical Demonstration', 'Laboratory Work', 'Skill Practice'];
      default:
        return ['Mixed Methods', 'Interactive Lecture', 'Collaborative Practice', 'Guided Learning'];
    }
  }

  /// Generate introduction instructions
  String _generateIntroductionInstructions(List<LearningOutcome> outcomes) {
    final instructions = <String>[];
    
    instructions.add('Begin with a real-world connection to engage students');
    instructions.add('Clearly state the learning objectives for this lesson');
    
    for (final outcome in outcomes.take(2)) {
      instructions.add('Connect to: ${outcome.outcomeText}');
    }
    
    instructions.add('Use NCDC-recommended introduction strategies');
    
    return instructions.join('\n');
  }

  /// Generate activity instructions
  String _generateActivityInstructions(SuggestedActivity activity, List<LearningOutcome> outcomes) {
    final instructions = <String>[];
    
    instructions.add('Follow NCDC-recommended activity: ${activity.activityText}');
    instructions.add('Ensure alignment with learning outcomes:');
    
    for (final outcome in outcomes.take(2)) {
      instructions.add('- ${outcome.outcomeText}');
    }
    
    instructions.add('Use appropriate resources and materials');
    
    return instructions.join('\n');
  }

  /// Generate comprehensive lesson notes
  String _generateLessonNotes(
    Topic topic,
    Strand strand,
    List<LearningOutcome> outcomes,
    int? studentCount,
  ) {
    
    final notes = <String>[];
    
    notes.add('=== NCDC-BASED LESSON PLAN ===');
    notes.add('');
    notes.add('Subject: ${strand.name}');
    notes.add('Topic: ${topic.name}');
    notes.add('Topic Code: ${topic.code}');
    notes.add('');
    
    if (topic.competency?.isNotEmpty == true) {
      notes.add('Competency: ${topic.competency}');
    }
    
    if (topic.term?.isNotEmpty == true) {
      notes.add('Term: ${topic.term}');
    }
    
    if (topic.className?.isNotEmpty == true) {
      notes.add('Class Level: ${topic.className}');
    }
    
    if (topic.durationPeriods != null) {
      notes.add('Suggested Periods: ${topic.durationPeriods}');
    }
    
    notes.add('');
    notes.add('Learning Outcomes:');
    for (final outcome in outcomes) {
      notes.add('- ${outcome.outcomeText} (${outcome.outcomeType})');
    }
    
    if (studentCount != null) {
      notes.add('');
      notes.add('Class Size: $studentCount students');
      notes.add('Consider grouping strategies for optimal participation');
    }
    
    notes.add('');
    notes.add('This lesson plan is based on official NCDC curriculum data');
    notes.add('All activities and assessments align with NCDC guidelines');
    
    return notes.join('\n');
  }

  /// Parse duration string to minutes
  int _parseDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 40;
  }

  /// Get available topics for a subject
  Future<List<String>> getAvailableTopics(String subjectName) async {
    await _curriculumParser.parseAllSyllabusFiles();
    final topics = _curriculumParser.getTopics(subjectName);
    return topics.map((t) => t.name).toList();
  }

  /// Get available subjects
  Future<List<String>> getAvailableSubjects() async {
    await _curriculumParser.parseAllSyllabusFiles();
    return _curriculumParser.getAllSubjectNames();
  }

  /// Get topic details
  Future<Map<String, dynamic>> getTopicDetails(String subjectName, String topicName) async {
    await _curriculumParser.parseAllSyllabusFiles();
    
    final topics = _curriculumParser.getTopics(subjectName);
    final targetTopic = topics.firstWhere(
      (topic) => topic.name.toLowerCase().contains(topicName.toLowerCase()),
      orElse: () => topics.first,
    );
    
    final outcomes = _curriculumParser.getOutcomesByTopic(subjectName, targetTopic.id ?? 0);
    final activities = _curriculumParser.getActivitiesByTopic(subjectName, targetTopic.id ?? 0);
    final assessments = _curriculumParser.getAssessmentsByTopic(subjectName, targetTopic.id ?? 0);
    
    return {
      'topic': targetTopic,
      'outcomes': outcomes,
      'activities': activities,
      'assessments': assessments,
    };
  }
}

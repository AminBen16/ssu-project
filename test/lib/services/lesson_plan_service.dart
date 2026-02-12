import 'dart:developer' as developer;

import 'package:test/models/lesson_plan_model.dart';
import 'package:test/models/lesson_plan_template_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';
import 'package:test/services/curriculum_service.dart';
import 'package:test/services/ai_validation_service.dart';
import 'dart:convert';

class LessonPlanService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = OfflineService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final CurriculumService _curriculumService = CurriculumService();
  final LessonPlanTemplateService _templateService =
      LessonPlanTemplateService();
  final AIValidationService _aiValidationService = AIValidationService();

  /// Gets a stream of all lesson plans for a specific teacher.
  /// This is now a one-time fetch wrapped in a Stream for compatibility.
  Stream<List<LessonPlan>> getLessonPlansStream(
      {required String teacherId, Map<String, String>? queryParams}) {
    return Stream.fromFuture(
        getLessonPlans(teacherId: teacherId, queryParams: queryParams));
  }

  /// Fetches all lesson plans for a teacher.
  Future<List<LessonPlan>> getLessonPlans(
      {required String teacherId, Map<String, String>? queryParams}) async {
    final cacheKey = 'lesson_plans_$teacherId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
            '/api/teachers/$teacherId/lesson-plans',
            queryParameters: queryParams);
        final List<dynamic> planList = response['lesson_plans'] as List;
        return planList
            .map((json) => LessonPlan.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      offlineFallback: () async {
        // Try to get cached lesson plans
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> planList = cached as List<dynamic>;
          return planList
              .map((json) => LessonPlan.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }

  /// Generate lesson plan from template
  Future<LessonPlan> generateFromTemplate({
    required String teacherId,
    required String templateId,
    required String subjectId,
    required String topicId,
    required String className,
    required String title,
    required DateTime date,
    required DateTime startTime,
    required List<String> customLearningObjectives,
    List<String>? availableResources,
    Map<String, dynamic>? customNotes,
  }) async {
    try {
      // Get template
      final template = _templateService.getTemplateById(templateId);
      if (template == null) {
        throw Exception('Template not found');
      }

      // Get curriculum data
      final curriculumData = await _getCurriculumData(topicId);

      // Merge template learning objectives with custom ones
      final learningObjectives = <String>[
        ...template.learningObjectives,
        ...customLearningObjectives,
      ];

      // Create lesson plan from template
      final lessonPlan = LessonPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teacherId: teacherId,
        schoolId: '', // Will be set when saving to database
        subjectId: subjectId,
        topicId: topicId,
        className: className,
        title: title.isNotEmpty ? title : _generateLessonTitle(curriculumData),
        date: date,
        startTime: startTime,
        endTime:
            startTime.add(Duration(minutes: _parseDuration(template.duration))),
        duration: template.duration,
        learningObjectives: learningObjectives,
        teachingMethods: [template.teachingStyle],
        activities: template.activities,
        assessments: [template.assessment],
        materials:
            _mergeMaterials(template.materials, availableResources ?? []),
        homework: _generateHomework(curriculumData, learningObjectives),
        notes: _generateTemplateNotes(template, curriculumData, customNotes),
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Auto-save the generated lesson plan
      await saveLessonPlan(lessonPlan);

      return lessonPlan;
    } catch (e) {
      throw Exception('Failed to generate lesson plan from template: $e');
    }
  }

  /// Get available templates
  List<LessonPlanTemplate> getAvailableTemplates(
      {String? subject, String? category}) {
    if (subject != null) {
      return _templateService.getTemplatesBySubject(subject);
    } else if (category != null) {
      return _templateService.getTemplatesByCategory(category);
    } else {
      return _templateService.getTemplates();
    }
  }

  /// Auto-save draft lesson plans periodically
  Future<void> autoSaveDraft(LessonPlan lessonPlan) async {
    try {
      // Add auto-save timestamp to notes
      final updatedPlan = LessonPlan(
        id: lessonPlan.id,
        teacherId: lessonPlan.teacherId,
        schoolId: lessonPlan.schoolId,
        subjectId: lessonPlan.subjectId,
        topicId: lessonPlan.topicId,
        className: lessonPlan.className,
        title: lessonPlan.title,
        date: lessonPlan.date,
        startTime: lessonPlan.startTime,
        endTime: lessonPlan.endTime,
        duration: lessonPlan.duration,
        learningObjectives: lessonPlan.learningObjectives,
        teachingMethods: lessonPlan.teachingMethods,
        activities: lessonPlan.activities,
        assessments: lessonPlan.assessments,
        materials: lessonPlan.materials,
        homework: lessonPlan.homework,
        notes:
            '${lessonPlan.notes}\n\nAuto-saved: ${DateTime.now().toString()}',
        status: 'draft',
        createdAt: lessonPlan.createdAt,
        updatedAt: DateTime.now(),
      );

      await saveLessonPlan(updatedPlan);
    } catch (e) {
      // Log error but don't throw to avoid disrupting user experience
      developer.log('Auto-save failed: $e');
    }
  }

  /// Merge template materials with available resources
  List<String> _mergeMaterials(
      List<String> templateMaterials, List<String> availableResources) {
    final allMaterials = <String>{...templateMaterials, ...availableResources};
    return allMaterials.toList();
  }

  /// Generate notes from template and custom notes
  String _generateTemplateNotes(LessonPlanTemplate template,
      Map<String, dynamic> curriculumData, Map<String, dynamic>? customNotes) {
    final notes = <String>[];

    notes.add('Generated from template: ${template.name}');
    notes.add('Template duration: ${template.duration}');
    notes.add('Teaching style: ${template.teachingStyle}');
    notes.add('Category: ${template.category}');

    if (curriculumData.containsKey('topic')) {
      notes.add('Topic: ${curriculumData['topic']}');
    }

    if (customNotes != null && customNotes.isNotEmpty) {
      notes.add('\nCustom Notes:');
      customNotes.forEach((key, value) {
        notes.add('$key: $value');
      });
    }

    return notes.join('\n');
  }

  /// AUTOMATIC LESSON PLAN GENERATION
  /// Generates a complete lesson plan based on curriculum topic and teacher preferences
  Future<LessonPlan> generateAutoLessonPlan({
    required String teacherId,
    required String subjectId,
    required String topicId,
    required String className,
    required String duration, // e.g., "40 minutes", "80 minutes"
    required List<String> learningObjectives,
    String? preferredTeachingStyle,
    List<String>? availableResources,
    int? studentCount,
  }) async {
    try {
      // Get curriculum data for the topic
      final curriculumData = await _getCurriculumData(topicId);

      // Generate lesson structure based on duration
      final lessonStructure = _generateLessonStructure(duration);

      // Create learning activities based on curriculum and preferences
      final activities = await _generateLearningActivities(
        curriculumData,
        learningObjectives,
        preferredTeachingStyle,
        availableResources ?? [],
        lessonStructure,
      );

      // Generate assessment methods
      final assessments =
          _generateAssessments(learningObjectives, lessonStructure);

      // Create teaching materials list
      final materials =
          _generateMaterials(curriculumData, availableResources ?? []);

      // Generate homework assignment
      final homework = _generateHomework(curriculumData, learningObjectives);

      // Create the lesson plan
      final lessonPlan = LessonPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teacherId: teacherId,
        schoolId: '', // Will be set when saving to database
        subjectId: subjectId,
        topicId: topicId,
        className: className,
        title: _generateLessonTitle(curriculumData),
        date: DateTime.now(),
        startTime: DateTime.now(),
        endTime:
            DateTime.now().add(Duration(minutes: _parseDuration(duration))),
        duration: duration,
        learningObjectives: learningObjectives,
        teachingMethods: _generateTeachingMethods(preferredTeachingStyle),
        activities: activities,
        assessments: assessments,
        materials: materials,
        homework: homework,
        notes: _generateLessonNotes(curriculumData, studentCount),
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Auto-save the generated lesson plan
      await saveLessonPlan(lessonPlan);

      return lessonPlan;
    } catch (e) {
      throw Exception('Failed to generate lesson plan: $e');
    }
  }

  /// Get curriculum data for a specific topic with enhanced validation
  Future<Map<String, dynamic>> _getCurriculumData(String topicId) async {
    try {
      // Validate topic ID format
      if (!RegExp(r'^\d+$').hasMatch(topicId)) {
        throw Exception('Invalid topic ID format');
      }

      // Try to get from curriculum service
      final topics =
          await _curriculumService.getTopicsByStrand(int.parse(topicId));
      if (topics.isEmpty) {
        throw Exception('Topic not found in NCDC curriculum database');
      }

      final topic = topics.first;

      // Validate topic has required fields
      if (topic.name.isEmpty) {
        throw Exception('Topic name is missing in curriculum data');
      }

      final learningOutcomes = await _curriculumService
          .getLearningOutcomesByTopic(int.parse(topicId));
      final activities =
          await _curriculumService.getActivitiesByOutcome(int.parse(topicId));

      // Validate learning outcomes exist
      if (learningOutcomes.isEmpty) {
        throw Exception(
            'No learning outcomes found for this topic in NCDC curriculum');
      }

      // Validate activities exist
      if (activities.isEmpty) {
        // Log warning but don't fail - some topics may not have predefined activities
        developer.log(
            'Warning: No predefined activities found for topic ${topic.name}');
      }

      return {
        'topic': topic.name,
        'competency': '',
        'learningOutcomes': learningOutcomes.map((lo) => lo.outcome).toList(),
        'activities': activities.map((a) => a.description).toList(),
        'materials': [], // Would fetch from curriculum service if available
        'validated': true,
        'source': 'NCDC_Curriculum_Database',
      };
    } catch (e) {
      // Enhanced error handling for hallucination prevention
      developer.log('Error fetching curriculum data for topic $topicId: $e');

      // Return structured fallback data instead of random data
      return {
        'topic': 'NCDC Curriculum Topic',
        'competency':
            'Students understand the topic according to NCDC standards',
        'learningOutcomes': ['Understand key concepts as defined by NCDC'],
        'activities': ['Teacher-led discussion following NCDC guidelines'],
        'materials': ['NCDC approved textbooks', 'NCDC curriculum guide'],
        'validated': false,
        'source': 'Fallback_Data',
        'error': 'Curriculum data unavailable: $e',
      };
    }
  }

  /// Generate lesson structure based on duration
  Map<String, dynamic> _generateLessonStructure(String duration) {
    final minutes = _parseDuration(duration);

    if (minutes <= 40) {
      return {
        'introduction': 5,
        'mainActivity': 25,
        'assessment': 5,
        'conclusion': 5,
      };
    } else if (minutes <= 80) {
      return {
        'introduction': 10,
        'mainActivity1': 30,
        'mainActivity2': 25,
        'assessment': 10,
        'conclusion': 5,
      };
    } else {
      return {
        'introduction': 15,
        'mainActivity1': 40,
        'mainActivity2': 35,
        'mainActivity3': 30,
        'assessment': 15,
        'conclusion': 10,
      };
    }
  }

  /// Generate learning activities based on curriculum and preferences
  Future<List<Map<String, dynamic>>> _generateLearningActivities(
    Map<String, dynamic> curriculumData,
    List<String> learningObjectives,
    String? preferredTeachingStyle,
    List<String> availableResources,
    Map<String, dynamic> lessonStructure,
  ) async {
    final activities = <Map<String, dynamic>>[];

    // Introduction activity
    activities.add({
      'name': 'Introduction & Hook',
      'description': 'Engage students with the topic using real-world examples',
      'duration': lessonStructure['introduction'],
      'type': 'introduction',
      'resources': ['Whiteboard', 'Presentation slides'],
      'instructions':
          _generateIntroductionInstructions(curriculumData['topic']),
    });

    // Main activities based on teaching style
    final style = preferredTeachingStyle?.toLowerCase() ?? 'mixed';

    if (style.contains('interactive') || style.contains('collaborative')) {
      activities.addAll(_generateInteractiveActivities(curriculumData,
          learningObjectives, availableResources, lessonStructure));
    } else if (style.contains('lecture') || style.contains('direct')) {
      activities.addAll(_generateDirectInstructionActivities(curriculumData,
          learningObjectives, availableResources, lessonStructure));
    } else {
      activities.addAll(_generateMixedActivities(curriculumData,
          learningObjectives, availableResources, lessonStructure));
    }

    // Assessment activity
    activities.add({
      'name': 'Assessment & Feedback',
      'description': 'Evaluate student understanding and provide feedback',
      'duration': lessonStructure['assessment'],
      'type': 'assessment',
      'resources': ['Quiz papers', 'Answer keys'],
      'instructions': 'Administer assessment and provide immediate feedback',
    });

    // Conclusion activity
    activities.add({
      'name': 'Conclusion & Summary',
      'description': 'Summarize key points and assign homework',
      'duration': lessonStructure['conclusion'],
      'type': 'conclusion',
      'resources': ['Summary handout'],
      'instructions': 'Review key concepts and preview next lesson',
    });

    return activities;
  }

  /// Generate interactive learning activities
  List<Map<String, dynamic>> _generateInteractiveActivities(
    Map<String, dynamic> curriculumData,
    List<String> learningObjectives,
    List<String> availableResources,
    Map<String, dynamic> lessonStructure,
  ) {
    return [
      {
        'name': 'Group Investigation',
        'description':
            'Students work in groups to investigate ${curriculumData['topic']}',
        'duration': lessonStructure['mainActivity1'] ?? 30,
        'type': 'group_work',
        'resources': ['Worksheet', 'Research materials'],
        'instructions':
            'Divide students into groups of 4-5. Each group investigates different aspects of the topic and presents findings.',
      },
      if (lessonStructure.containsKey('mainActivity2'))
        {
          'name': 'Hands-on Activity',
          'description': 'Practical application of concepts',
          'duration': lessonStructure['mainActivity2'],
          'type': 'practical',
          'resources': availableResources.isNotEmpty
              ? availableResources
              : ['Activity materials'],
          'instructions':
              'Students engage in hands-on activities to reinforce learning',
        }
    ];
  }

  /// Generate direct instruction activities
  List<Map<String, dynamic>> _generateDirectInstructionActivities(
    Map<String, dynamic> curriculumData,
    List<String> learningObjectives,
    List<String> availableResources,
    Map<String, dynamic> lessonStructure,
  ) {
    return [
      {
        'name': 'Direct Instruction',
        'description':
            'Teacher-led presentation of ${curriculumData['topic']} concepts',
        'duration': lessonStructure['mainActivity1'] ?? 30,
        'type': 'lecture',
        'resources': ['Presentation slides', 'Whiteboard'],
        'instructions':
            'Present key concepts with clear explanations and examples',
      },
      if (lessonStructure.containsKey('mainActivity2'))
        {
          'name': 'Guided Practice',
          'description': 'Teacher-guided practice exercises',
          'duration': lessonStructure['mainActivity2'],
          'type': 'guided_practice',
          'resources': ['Practice worksheets'],
          'instructions': 'Work through examples together as a class',
        }
    ];
  }

  /// Generate mixed teaching style activities
  List<Map<String, dynamic>> _generateMixedActivities(
    Map<String, dynamic> curriculumData,
    List<String> learningObjectives,
    List<String> availableResources,
    Map<String, dynamic> lessonStructure,
  ) {
    return [
      {
        'name': 'Interactive Presentation',
        'description': 'Engaging presentation with student participation',
        'duration': lessonStructure['mainActivity1'] ?? 30,
        'type': 'interactive_lecture',
        'resources': ['Presentation slides', 'Clickers'],
        'instructions':
            'Present content with frequent student questions and participation',
      },
      if (lessonStructure.containsKey('mainActivity2'))
        {
          'name': 'Collaborative Practice',
          'description': 'Students work together on practice problems',
          'duration': lessonStructure['mainActivity2'],
          'type': 'collaborative',
          'resources': ['Worksheet', 'Answer keys'],
          'instructions':
              'Students work in pairs to complete practice exercises',
        }
    ];
  }

  /// Generate assessment methods
  List<Map<String, dynamic>> _generateAssessments(
      List<String> learningObjectives, Map<String, dynamic> lessonStructure) {
    return [
      {
        'type': 'formative',
        'name': 'Quick Quiz',
        'description': 'Short quiz to check understanding',
        'duration': 5,
        'questions': learningObjectives
            .map((obj) => {
                  'question': 'How well can you $obj?',
                  'type': 'self_assessment'
                })
            .toList(),
      },
      {
        'type': 'observation',
        'name': 'Class Participation',
        'description': 'Observe student engagement and participation',
        'duration': 5,
        'criteria': [
          'Active listening',
          'Question asking',
          'Contribution to discussions'
        ],
      }
    ];
  }

  /// Generate teaching materials list
  List<String> _generateMaterials(
      Map<String, dynamic> curriculumData, List<String> availableResources) {
    final materials = <String>[];

    // Add standard materials
    materials.addAll(
        ['Whiteboard/Smartboard', 'Marker pens', 'Lesson plan handout']);

    // Add curriculum-specific materials
    if (curriculumData.containsKey('materials')) {
      materials.addAll(List<String>.from(curriculumData['materials']));
    }

    // Add available resources
    materials.addAll(availableResources);

    // Add digital resources
    materials.addAll(['Presentation slides', 'Video clips (if applicable)']);

    return materials.toSet().toList(); // Remove duplicates
  }

  /// Generate homework assignment
  Map<String, dynamic> _generateHomework(
      Map<String, dynamic> curriculumData, List<String> learningObjectives) {
    return {
      'assigned': true,
      'description':
          'Complete practice exercises on ${curriculumData['topic']}',
      'tasks': learningObjectives
          .map((obj) => 'Practice problems related to: $obj')
          .toList(),
      'dueDate': DateTime.now().add(Duration(days: 1)),
      'estimatedTime': '30 minutes',
      'resources': ['Textbook exercises', 'Online practice platform'],
    };
  }

  /// Generate lesson title
  String _generateLessonTitle(Map<String, dynamic> curriculumData) {
    final topic = curriculumData['topic'] as String;
    return 'Lesson: Understanding $topic';
  }

  /// Generate teaching methods based on preference
  List<String> _generateTeachingMethods(String? preferredTeachingStyle) {
    final style = preferredTeachingStyle?.toLowerCase() ?? 'mixed';

    if (style.contains('interactive')) {
      return [
        'Interactive Discussion',
        'Group Work',
        'Hands-on Activities',
        'Peer Teaching'
      ];
    } else if (style.contains('lecture')) {
      return [
        'Direct Instruction',
        'Demonstration',
        'Guided Practice',
        'Question-Answer'
      ];
    } else {
      return [
        'Mixed Methods',
        'Interactive Lecture',
        'Collaborative Learning',
        'Practice Activities'
      ];
    }
  }

  /// Generate introduction instructions
  String _generateIntroductionInstructions(String? topic) {
    return 'Start with a real-world example or question related to $topic to engage students. '
        'Connect the topic to students\' prior knowledge and experiences. '
        'Clearly state the learning objectives for the lesson.';
  }

  /// Generate lesson notes
  String _generateLessonNotes(
      Map<String, dynamic> curriculumData, int? studentCount) {
    final notes = <String>[];

    notes.add('Topic: ${curriculumData['topic']}');
    notes.add('Competency: ${curriculumData['competency']}');

    if (studentCount != null) {
      notes.add('Class size: $studentCount students');
      notes.add('Consider grouping strategies for optimal participation');
    }

    notes.add('Key points to emphasize:');
    if (curriculumData.containsKey('learningOutcomes')) {
      final outcomes = List<String>.from(curriculumData['learningOutcomes']);
      for (final outcome in outcomes.take(3)) {
        notes.add('- $outcome');
      }
    }

    notes.add('Differentiation strategies available for diverse learners');
    notes.add('Have extension activities ready for advanced students');

    return notes.join('\n');
  }

  /// Parse duration string to minutes
  int _parseDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 40;
  }

  /// Creates or updates a lesson plan with offline support.
  Future<void> saveLessonPlan(LessonPlan lessonPlan) async {
    final isOnline = await _offlineService.isOnline;

    if (isOnline) {
      try {
        await _apiClient.post(
            '/api/schools/${lessonPlan.schoolId}/lesson-plans',
            body: lessonPlan.toMap());
      } catch (e) {
        // If online save fails, cache for later sync
        await _localDb.setCache(
          'lesson_plan_${lessonPlan.id}',
          jsonEncode(lessonPlan.toMap()),
        );
      }
    } else {
      // Cache for later sync when online
      await _localDb.setCache(
        'lesson_plan_${lessonPlan.id}',
        jsonEncode(lessonPlan.toMap()),
      );
    }
  }

  /// Deletes a lesson plan by its ID with offline support.
  Future<void> deleteLessonPlan({required int planId}) async {
    final isOnline = await _offlineService.isOnline;
    if (isOnline) {
      try {
        await _apiClient.delete('/api/lesson-plans/$planId');
        // Remove from local cache
        await _localDb.deleteData('lesson_plan', planId.toString());
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('delete', {
          'table': 'lesson_plan',
          'id': planId,
        });
        rethrow;
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('delete', {
        'table': 'lesson_plan',
        'id': planId,
      });
      // Mark for deletion in local cache
      await _localDb.saveData('lesson_plan', planId.toString(), {
        'deleted': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Generates dynamic exams based on curriculum topics and learning outcomes
  Future<Map<String, dynamic>> generateDynamicExam({
    required String subjectId,
    required String topicId,
    required String className,
    required int numberOfQuestions,
    required List<String>
        questionTypes, // ['multiple_choice', 'short_answer', 'essay']
    required int durationMinutes,
  }) async {
    try {
      // Validate question types against NCDC guidelines
      final typesValid =
          await _aiValidationService.validateQuestionTypes(questionTypes);
      if (!typesValid) {
        throw Exception(
            'Some question types are not approved by NCDC guidelines');
      }

      // Validate curriculum data exists
      final validation = await _validateCurriculumData(topicId);
      if (!validation['isValid']) {
        throw Exception(
            'Topic not found in NCDC curriculum or insufficient data');
      }

      final curriculumData =
          validation['curriculumData'] as Map<String, dynamic>;
      final learningOutcomes =
          curriculumData['learningOutcomes'] as List<String>;
      final topic = curriculumData['topic'] as String;

      final questions = <Map<String, dynamic>>[];
      final random = DateTime.now().millisecondsSinceEpoch;

      // Generate questions based on approved types
      for (int i = 0; i < numberOfQuestions; i++) {
        final questionType = questionTypes[random % questionTypes.length];
        final outcome = learningOutcomes[random % learningOutcomes.length];

        Map<String, dynamic> question;
        switch (questionType) {
          case 'multiple_choice':
            question = _generateMultipleChoiceQuestion(topic, outcome, i);
            break;
          case 'short_answer':
            question = _generateShortAnswerQuestion(topic, outcome, i);
            break;
          case 'essay':
            question = _generateEssayQuestion(topic, outcome, i);
            break;
          case 'true_false':
            question = _generateTrueFalseQuestion(topic, outcome, i);
            break;
          case 'matching':
            question = _generateMatchingQuestion(topic, outcome, i);
            break;
          default:
            throw Exception('Unsupported question type: $questionType');
        }

        questions.add(question);
      }

      final examData = {
        'examId': 'exam_${DateTime.now().millisecondsSinceEpoch}',
        'subjectId': subjectId,
        'topicId': topicId,
        'className': className,
        'title': 'Exam: $topic',
        'duration': durationMinutes,
        'totalMarks': questions.length * 20, // 20 marks per question
        'questions': questions,
        'instructions': _generateExamInstructions(questionTypes),
        'createdAt': DateTime.now().toIso8601String(),
        'validatedAgainstNCDC': true,
      };

      // Validate the generated exam
      final validationResult =
          await _aiValidationService.validateAIGeneratedContent(
        contentType: 'exam',
        topicId: topicId,
        generatedContent: examData,
      );

      if (!validationResult['isValid']) {
        throw Exception(
            'Generated exam failed validation: ${validationResult['errors']}');
      }

      return examData;
    } catch (e) {
      throw Exception('Failed to generate dynamic exam: $e');
    }
  }

  /// Validates curriculum data to prevent AI hallucination
  Future<Map<String, dynamic>> _validateCurriculumData(String topicId) async {
    try {
      final topics =
          await _curriculumService.getTopicsByStrand(int.parse(topicId));
      if (topics.isEmpty) {
        return {'isValid': false, 'error': 'Topic not found in curriculum'};
      }

      final topic = topics.first;
      final learningOutcomes = await _curriculumService
          .getLearningOutcomesByTopic(int.parse(topicId));

      if (learningOutcomes.isEmpty) {
        return {
          'isValid': false,
          'error': 'No learning outcomes found for topic'
        };
      }

      return {
        'isValid': true,
        'curriculumData': {
          'topic': topic.name,
          'competency': '',
          'learningOutcomes': learningOutcomes.map((lo) => lo.outcome).toList(),
        },
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Failed to validate curriculum data: $e'
      };
    }
  }

  /// Validates question types against approved NCDC assessment methods
  Future<bool> validateQuestionTypes(List<String> questionTypes) async {
    final approvedTypes = [
      'multiple_choice',
      'short_answer',
      'essay',
      'true_false',
      'matching'
    ];

    for (final type in questionTypes) {
      if (!approvedTypes.contains(type.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _generateMultipleChoiceQuestion(
      String topic, String outcome, int index) {
    final options = [
      'Option A related to $topic',
      'Option B related to $topic',
      'Option C related to $topic',
      'Option D related to $topic',
    ];

    return {
      'id': 'q_${index + 1}',
      'type': 'multiple_choice',
      'question':
          'Based on the learning outcome: $outcome, which of the following best describes the key concept in $topic?',
      'options': options,
      'correctAnswer': options[
          0], // In real implementation, this would be intelligently generated
      'marks': 20,
      'outcome': outcome,
    };
  }

  Map<String, dynamic> _generateShortAnswerQuestion(
      String topic, String outcome, int index) {
    return {
      'id': 'q_${index + 1}',
      'type': 'short_answer',
      'question':
          'Based on the learning outcome: $outcome, briefly explain the importance of $topic in your own words.',
      'expectedAnswer':
          'Student should demonstrate understanding of $topic and its relevance to $outcome',
      'marks': 20,
      'outcome': outcome,
    };
  }

  Map<String, dynamic> _generateEssayQuestion(
      String topic, String outcome, int index) {
    return {
      'id': 'q_${index + 1}',
      'type': 'essay',
      'question':
          'Based on the learning outcome: $outcome, write a comprehensive essay discussing the principles and applications of $topic.',
      'guidelines': [
        'Introduction: Define $topic and state its importance',
        'Body: Discuss key principles and provide examples',
        'Conclusion: Summarize and relate to real-world applications',
      ],
      'wordLimit': '300-500 words',
      'marks': 20,
      'outcome': outcome,
    };
  }

  String _generateExamInstructions(List<String> questionTypes) {
    final instructions = <String>[];
    instructions.add('Read all questions carefully before answering.');
    instructions.add('Manage your time wisely.');

    if (questionTypes.contains('multiple_choice')) {
      instructions
          .add('For multiple choice questions, select the best answer.');
    }
    if (questionTypes.contains('short_answer')) {
      instructions.add(
          'For short answer questions, provide concise but complete responses.');
    }
    if (questionTypes.contains('essay')) {
      instructions.add(
          'For essay questions, organize your thoughts and write clearly.');
    }

    return instructions.join('\n');
  }

  Map<String, dynamic> _generateTrueFalseQuestion(
      String topic, String outcome, int index) {
    return {
      'id': 'q_${index + 1}',
      'type': 'true_false',
      'question':
          'Based on the learning outcome: $outcome, the following statement about $topic is true or false: $topic is fundamental to understanding this concept.',
      'correctAnswer':
          true, // In real implementation, this would be intelligently generated
      'marks': 20,
      'outcome': outcome,
    };
  }

  Map<String, dynamic> _generateMatchingQuestion(
      String topic, String outcome, int index) {
    return {
      'id': 'q_${index + 1}',
      'type': 'matching',
      'question':
          'Based on the learning outcome: $outcome, match the following terms related to $topic with their definitions.',
      'items': [
        {'term': 'Term 1', 'definition': 'Definition 1 related to $topic'},
        {'term': 'Term 2', 'definition': 'Definition 2 related to $topic'},
        {'term': 'Term 3', 'definition': 'Definition 3 related to $topic'},
      ],
      'marks': 20,
      'outcome': outcome,
    };
  }
}

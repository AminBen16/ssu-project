import 'package:test/services/curriculum_service.dart';

class AIValidationService {
  final CurriculumService _curriculumService = CurriculumService();

  /// Validates AI-generated content against NCDC standards
  Future<Map<String, dynamic>> validateAIGeneratedContent({
    required String contentType, // 'lesson_plan' or 'exam'
    required String topicId,
    required Map<String, dynamic> generatedContent,
  }) async {
    try {
      // Validate topic exists in NCDC curriculum
      final topicValidation = await _validateTopicExists(topicId);
      if (!topicValidation['isValid']) {
        return {
          'isValid': false,
          'errors': ['Topic not found in NCDC curriculum database'],
          'confidence': 0.0,
        };
      }

      // Content-specific validation
      switch (contentType) {
        case 'lesson_plan':
          return await _validateLessonPlan(topicId, generatedContent);
        case 'exam':
          return await _validateExam(topicId, generatedContent);
        default:
          return {
            'isValid': false,
            'errors': ['Unsupported content type: $contentType'],
            'confidence': 0.0,
          };
      }
    } catch (e) {
      return {
        'isValid': false,
        'errors': ['Validation failed: $e'],
        'confidence': 0.0,
      };
    }
  }

  /// Validates that topic exists in NCDC curriculum
  Future<Map<String, dynamic>> _validateTopicExists(String topicId) async {
    try {
      // Validate topic ID format
      if (!RegExp(r'^\d+$').hasMatch(topicId)) {
        return {'isValid': false, 'error': 'Invalid topic ID format'};
      }

      final topics = await _curriculumService.getTopicsByStrand(int.parse(topicId));
      if (topics.isEmpty) {
        return {'isValid': false, 'error': 'Topic not found in NCDC curriculum'};
      }

      final topic = topics.first;
      if (topic.name.isEmpty) {
        return {'isValid': false, 'error': 'Topic name is missing'};
      }

      final learningOutcomes = await _curriculumService.getLearningOutcomesByTopic(int.parse(topicId));
      if (learningOutcomes.isEmpty) {
        return {'isValid': false, 'error': 'No learning outcomes found for topic'};
      }

      return {
        'isValid': true,
        'topic': topic.name,
        'learningOutcomes': learningOutcomes.map((lo) => lo.outcome).toList(),
      };
    } catch (e) {
      return {'isValid': false, 'error': 'Failed to validate topic: $e'};
    }
  }

  /// Validates AI-generated lesson plan
  Future<Map<String, dynamic>> _validateLessonPlan(String topicId, Map<String, dynamic> lessonPlan) async {
    final errors = <String>[];
    final warnings = <String>[];
    double confidence = 1.0;

    // Get curriculum data for comparison
    final curriculumData = await _validateTopicExists(topicId);
    if (!curriculumData['isValid']) {
      return {
        'isValid': false,
        'errors': ['Invalid topic reference'],
        'confidence': 0.0,
      };
    }

    final learningOutcomes = curriculumData['learningOutcomes'] as List<String>;
    final topicName = curriculumData['topic'] as String;

    // Validate learning objectives alignment
    final objectives = lessonPlan['learningObjectives'] as List<dynamic>? ?? [];
    if (objectives.isEmpty) {
      errors.add('No learning objectives provided');
      confidence -= 0.3;
    } else {
      final alignmentScore = _calculateAlignment(objectives.cast<String>(), learningOutcomes);
      if (alignmentScore < 0.7) {
        warnings.add('Learning objectives not well aligned with NCDC outcomes');
        confidence -= 0.2;
      }
    }

    // Validate activities
    final activities = lessonPlan['activities'] as List<dynamic>? ?? [];
    if (activities.isEmpty) {
      errors.add('No learning activities provided');
      confidence -= 0.2;
    } else {
      // Check for appropriate activity types
      final hasInteractive = activities.any((activity) {
        final activityStr = activity.toString().toLowerCase();
        return activityStr.contains('group') || 
               activityStr.contains('discussion') || 
               activityStr.contains('practical');
      });

      if (!hasInteractive) {
        warnings.add('Consider adding interactive learning activities');
        confidence -= 0.1;
      }
    }

    // Validate assessment methods
    final assessments = lessonPlan['assessments'] as List<dynamic>? ?? [];
    if (assessments.isEmpty) {
      errors.add('No assessment methods provided');
      confidence -= 0.2;
    }

    // Validate materials
    final materials = lessonPlan['materials'] as List<dynamic>? ?? [];
    if (materials.isEmpty) {
      warnings.add('No teaching materials specified');
      confidence -= 0.1;
    }

    // Check for inappropriate content
    final contentString = _flattenContent(lessonPlan);
    final inappropriateContent = _checkInappropriateContent(contentString);
    if (inappropriateContent.isNotEmpty) {
      errors.addAll(inappropriateContent);
      confidence -= 0.5;
    }

    // Validate duration
    final duration = lessonPlan['duration']?.toString() ?? '';
    if (duration.isEmpty) {
      warnings.add('No lesson duration specified');
      confidence -= 0.1;
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'confidence': confidence.clamp(0.0, 1.0),
      'topic': topicName,
      'alignmentScore': _calculateAlignment(objectives.cast<String>(), learningOutcomes),
    };
  }

  /// Validates AI-generated exam
  Future<Map<String, dynamic>> _validateExam(String topicId, Map<String, dynamic> exam) async {
    final errors = <String>[];
    final warnings = <String>[];
    double confidence = 1.0;

    // Get curriculum data
    final curriculumData = await _validateTopicExists(topicId);
    if (!curriculumData['isValid']) {
      return {
        'isValid': false,
        'errors': ['Invalid topic reference'],
        'confidence': 0.0,
      };
    }

    final learningOutcomes = curriculumData['learningOutcomes'] as List<String>;
    final topicName = curriculumData['topic'] as String;

    // Validate questions
    final questions = exam['questions'] as List<dynamic>? ?? [];
    List<String> questionTypes = [];
    
    if (questions.isEmpty) {
      errors.add('No questions provided');
      confidence -= 0.5;
    } else {
      // Validate each question
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i] as Map<String, dynamic>;
        final questionErrors = _validateQuestion(question, learningOutcomes, i + 1);
        errors.addAll(questionErrors);
        
        if (questionErrors.isNotEmpty) {
          confidence -= 0.1;
        }
      }

      // Check question variety
      questionTypes = questions.map((q) => q['type']?.toString() ?? '').toSet().toList();
      if (questionTypes.length < 2 && questions.length > 3) {
        warnings.add('Consider using different question types for variety');
        confidence -= 0.1;
      }
    }

    // Validate total marks
    final totalMarks = exam['totalMarks'] as int? ?? 0;
    if (totalMarks == 0) {
      warnings.add('Total marks not specified or zero');
      confidence -= 0.1;
    }

    // Validate duration
    final duration = exam['duration'] as int? ?? 0;
    if (duration == 0) {
      warnings.add('Exam duration not specified');
      confidence -= 0.1;
    }

    // Check for inappropriate content
    final contentString = _flattenContent(exam);
    final inappropriateContent = _checkInappropriateContent(contentString);
    if (inappropriateContent.isNotEmpty) {
      errors.addAll(inappropriateContent);
      confidence -= 0.5;
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'confidence': confidence.clamp(0.0, 1.0),
      'topic': topicName,
      'questionCount': questions.length,
      'questionTypes': questionTypes,
    };
  }

  /// Validates individual question
  List<String> _validateQuestion(Map<String, dynamic> question, List<String> learningOutcomes, int questionNumber) {
    final errors = <String>[];

    // Check question text
    final questionText = question['question']?.toString() ?? '';
    if (questionText.isEmpty) {
      errors.add('Question $questionNumber: No question text provided');
    }

    // Check question type
    final questionType = question['type']?.toString() ?? '';
    if (questionType.isEmpty) {
      errors.add('Question $questionNumber: No question type specified');
    }

    // Validate based on question type
    switch (questionType.toLowerCase()) {
      case 'multiple_choice':
        final options = question['options'] as List<dynamic>? ?? [];
        if (options.length < 2) {
          errors.add('Question $questionNumber: Multiple choice needs at least 2 options');
        }
        final correctAnswer = question['correctAnswer'];
        if (correctAnswer == null) {
          errors.add('Question $questionNumber: No correct answer specified');
        }
        break;

      case 'short_answer':
        final expectedAnswer = question['expectedAnswer']?.toString() ?? '';
        if (expectedAnswer.isEmpty) {
          errors.add('Question $questionNumber: No expected answer provided');
        }
        break;

      case 'essay':
        final wordLimit = question['wordLimit']?.toString() ?? '';
        if (wordLimit.isEmpty) {
          errors.add('Question $questionNumber: No word limit specified for essay');
        }
        break;
    }

    // Check marks
    final marks = question['marks'] as int? ?? 0;
    if (marks <= 0) {
      errors.add('Question $questionNumber: Invalid or missing marks');
    }

    return errors;
  }

  /// Calculates alignment between objectives and outcomes
  double _calculateAlignment(List<String> objectives, List<String> outcomes) {
    if (objectives.isEmpty || outcomes.isEmpty) return 0.0;

    int matches = 0;
    for (final objective in objectives) {
      final objectiveLower = objective.toLowerCase();
      for (final outcome in outcomes) {
        final outcomeLower = outcome.toLowerCase();
        
        // Check for keyword overlap
        final objectiveWords = objectiveLower.split(' ');
        final outcomeWords = outcomeLower.split(' ');
        
        final commonWords = objectiveWords.where((word) => 
          word.length > 3 && outcomeWords.contains(word)
        ).length;
        
        if (commonWords >= 2) {
          matches++;
          break;
        }
      }
    }

    return matches / objectives.length;
  }

  /// Checks for inappropriate content
  List<String> _checkInappropriateContent(String content) {
    final inappropriate = <String>[];
    final contentLower = content.toLowerCase();

    // List of inappropriate keywords (educational context)
    final inappropriateKeywords = [
      'violence', 'weapon', 'drug', 'alcohol', 'gambling',
      'discrimination', 'racist', 'sexist', 'bullying',
    ];

    for (final keyword in inappropriateKeywords) {
      if (contentLower.contains(keyword)) {
        inappropriate.add('Contains inappropriate content: $keyword');
      }
    }

    return inappropriate;
  }

  /// Flattens nested content for analysis
  String _flattenContent(Map<String, dynamic> content) {
    final buffer = StringBuffer();
    
    void flatten(dynamic value) {
      if (value is Map) {
        value.forEach((key, val) {
          buffer.write('$key: ');
          flatten(val);
          buffer.write(' ');
        });
      } else if (value is List) {
        for (final item in value) {
          flatten(item);
          buffer.write(' ');
        }
      } else {
        buffer.write(value.toString());
      }
    }

    flatten(content);
    return buffer.toString();
  }

  /// Generates NCDC-compliant learning objectives
  Future<List<String>> generateLearningObjectives(String topicId) async {
    try {
      final curriculumData = await _validateTopicExists(topicId);
      if (!curriculumData['isValid']) {
        return [];
      }

      final learningOutcomes = curriculumData['learningOutcomes'] as List<String>;
      final topicName = curriculumData['topic'] as String;

      // Transform outcomes into actionable learning objectives
      final objectives = <String>[];
      
      for (final outcome in learningOutcomes) {
        // Convert outcome statements to learning objectives
        if (outcome.toLowerCase().startsWith('students will be able to')) {
          objectives.add(outcome);
        } else {
          objectives.add('Students will be able to $outcome');
        }
      }

      // Add topic-specific objectives
      objectives.add('Understand the key concepts of $topicName');
      objectives.add('Apply knowledge of $topicName in practical situations');

      return objectives.take(5).toList(); // Limit to 5 objectives
    } catch (e) {
      print('Error generating learning objectives: $e');
      return [];
    }
  }

  /// Validates question types against NCDC assessment guidelines
  Future<bool> validateQuestionTypes(List<String> questionTypes) async {
    final approvedTypes = [
      'multiple_choice',
      'short_answer', 
      'essay',
      'true_false',
      'matching',
      'fill_in_the_blank',
      'practical',
      'oral'
    ];

    for (final type in questionTypes) {
      if (!approvedTypes.contains(type.toLowerCase())) {
        return false;
      }
    }
    return true;
  }
}

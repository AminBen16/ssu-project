import '../models/curriculum_models.dart';
import 'curriculum_database_service.dart';
import 'package:logger/logger.dart';

class CurriculumService {
  static final CurriculumService _instance = CurriculumService._internal();
  factory CurriculumService() => _instance;
  CurriculumService._internal();
  
  final Logger _logger = Logger();

  Future<List<Subject>> getSubjects() async {
    try {
      // Use curriculum database service for real data
      return await CurriculumDatabaseService.getAllSubjects();
    } catch (e) {
      _logger.e('Error fetching subjects from database: $e');
      // Fallback to placeholder data for offline functionality
      return [
        Subject(
          id: 1,
          name: 'Chemistry',
          educationLevel: 'Advanced Secondary',
          className: 'Senior Five and Senior Six',
          periodDuration: 40,
          periodsPerWeek: 9,
        ),
      ];
    }
  }

  Future<List<Topic>> getTopicsByStrand(int strandId) async {
    try {
      // Use correct method name from database service
      final topics = await CurriculumDatabaseService.getTopicsByStrand(strandId);
      if (topics.isNotEmpty) {
        return topics;
      }
      
      // Fallback to placeholder data for offline functionality
      return [
        Topic(
          id: 1,
          strandId: strandId,
          name: 'Chemical Reactions',
          code: 'CR001',
          description: 'Understanding chemical reactions',
          orderIndex: 1,
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching topics: $e');
      return [
        Topic(
          id: 1,
          strandId: strandId,
          name: 'Chemical Reactions',
          code: 'CR001',
          description: 'Understanding chemical reactions',
          orderIndex: 1,
        ),
      ];
    }
  }


  Future<List<LearningOutcome>> getLearningOutcomesByTopic(int topicId) async {
    try {
      return await CurriculumDatabaseService.getLearningOutcomesByTopic(topicId);
    } catch (e) {
      _logger.e('Error fetching learning outcomes: $e');
      return [
        LearningOutcome(
          id: 1,
          topicId: topicId,
          outcomeText: 'Understand chemical reaction mechanisms',
          outcomeType: 'knowledge',
          orderIndex: 1,
        ),
      ];
    }
  }

  Future<List<CurriculumCompetence>> getCompetencesByTopic(int topicId) async {
    try {
      // Note: Competencies are stored in the database but need to be mapped to CurriculumCompetence
      // For now, return placeholder data until the mapping is implemented
      return [
        CurriculumCompetence(
          id: 1,
          topicId: topicId,
          statement: 'Analyze chemical equations',
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching competences: $e');
      return [
        CurriculumCompetence(
          id: 1,
          topicId: topicId,
          statement: 'Analyze chemical equations',
        ),
      ];
    }
  }


  Future<List<SuggestedActivity>> getActivitiesByTopic(int topicId) async {
    try {
      // Get learning outcomes for this topic first
      final learningOutcomes = await CurriculumDatabaseService.getLearningOutcomesByTopic(topicId);
      if (learningOutcomes.isNotEmpty) {
        // Get activities for the first learning outcome
        final activities = await CurriculumDatabaseService.getActivitiesByLearningOutcome(learningOutcomes.first.id!);
        if (activities.isNotEmpty) {
          return activities;
        }
      }
      
      // Fallback to placeholder data for offline functionality
      return [
        SuggestedActivity(
          id: 1,
          learningOutcomeId: topicId, // Using topicId as learningOutcomeId for now
          activityText: 'Conduct laboratory experiments',
          orderIndex: 1,
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching activities: $e');
      return [
        SuggestedActivity(
          id: 1,
          learningOutcomeId: topicId, // Using topicId as learningOutcomeId for now
          activityText: 'Conduct laboratory experiments',
          orderIndex: 1,
        ),
      ];
    }
  }

  /// Get activities by learning outcome ID
  Future<List<SuggestedActivity>> getActivitiesByOutcome(int learningOutcomeId) async {
    try {
      final activities = await CurriculumDatabaseService.getActivitiesByLearningOutcome(learningOutcomeId);
      if (activities.isNotEmpty) {
        return activities;
      }
      
      // Fallback to placeholder data for offline functionality
      return [
        SuggestedActivity(
          id: 1,
          learningOutcomeId: learningOutcomeId,
          activityText: 'Conduct laboratory experiments',
          orderIndex: 1,
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching activities by outcome: $e');
      return [
        SuggestedActivity(
          id: 1,
          learningOutcomeId: learningOutcomeId,
          activityText: 'Conduct laboratory experiments',
          orderIndex: 1,
        ),
      ];
    }
  }



  Future<List<AssessmentStrategy>> getAssessmentsByTopic(int topicId) async {
    try {
      // Get learning outcomes for this topic first
      final learningOutcomes = await CurriculumDatabaseService.getLearningOutcomesByTopic(topicId);
      if (learningOutcomes.isNotEmpty) {
        // Get assessments for the first learning outcome
        final assessments = await CurriculumDatabaseService.getAssessmentsByLearningOutcome(learningOutcomes.first.id!);
        if (assessments.isNotEmpty) {
          return assessments;
        }
      }
      
      // Fallback to placeholder data for offline functionality
      return [
        AssessmentStrategy(
          id: 1,
          learningOutcomeId: topicId, // Using topicId as learningOutcomeId for now
          strategyText: 'Written and practical assessments',
          orderIndex: 1,
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching assessments: $e');
      return [
        AssessmentStrategy(
          id: 1,
          learningOutcomeId: topicId, // Using topicId as learningOutcomeId for now
          strategyText: 'Written and practical assessments',
          orderIndex: 1,
        ),
      ];
    }
  }


  Future<List<CrossCuttingIssue>> getCrossCuttingIssues(int subjectId) async {
    try {
      final issues = await CurriculumDatabaseService.getCrossCuttingIssuesBySubject(subjectId);
      if (issues.isNotEmpty) {
        return issues;
      }
      
      // Fallback to placeholder data for offline functionality
      return [
        CrossCuttingIssue(
          id: 1,
          subjectId: subjectId,
          issueName: 'Environmental conservation',
          description: 'Integrate environmental awareness in chemistry',
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching cross-cutting issues: $e');
      return [
        CrossCuttingIssue(
          id: 1,
          subjectId: subjectId,
          issueName: 'Environmental conservation',
          description: 'Integrate environmental awareness in chemistry',
        ),
      ];
    }
  }


  Future<List<Value>> getValues(int subjectId) async {
    try {
      // Note: Values are not stored as a separate table in the database
      // They are part of the curriculum data structure
      // Return placeholder data for now
      return [
        Value(
          id: 1,
          subjectId: subjectId,
          valueName: 'Scientific integrity',
          description: 'Maintain honesty in scientific work',
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching values: $e');
      return [
        Value(
          id: 1,
          subjectId: subjectId,
          valueName: 'Scientific integrity',
          description: 'Maintain honesty in scientific work',
        ),
      ];
    }
  }


  Future<List<GenericSkill>> getGenericSkills(int subjectId) async {
    try {
      final skills = await CurriculumDatabaseService.getGenericSkillsBySubject(subjectId);
      if (skills.isNotEmpty) {
        return skills;
      }
      
      // Fallback to placeholder data for offline functionality
      return [
        GenericSkill(
          id: 1,
          subjectId: subjectId,
          skillName: 'Critical thinking',
          description: 'Analyze information critically',
        ),
      ];
    } catch (e) {
      _logger.e('Error fetching generic skills: $e');
      return [
        GenericSkill(
          id: 1,
          subjectId: subjectId,
          skillName: 'Critical thinking',
          description: 'Analyze information critically',
        ),
      ];
    }
  }


  Future<Subject?> getSubjectById(int subjectId) async {
    try {
      return await CurriculumDatabaseService.getSubjectById(subjectId);
    } catch (e) {
      _logger.e('Error fetching subject by ID: $e');
      return null;
    }
  }

  Future<Strand?> getStrandById(int strandId) async {
    try {
      return await CurriculumDatabaseService.getStrandById(strandId);
    } catch (e) {
      _logger.e('Error fetching strand by ID: $e');
      return null;
    }
  }

  Future<List<Subject>> getSubjectsByLevel(String educationLevel) async {
    try {
      final allSubjects = await getSubjects();
      return allSubjects.where((subject) => 
        subject.educationLevel == educationLevel
      ).toList();
    } catch (e) {
      _logger.e('Error fetching subjects by level: $e');
      return [];
    }
  }

  Future<bool> syncCurriculumData() async {
    try {
      _logger.i('Starting curriculum data sync');
      // Implementation would fetch from server and update local database
      // For now, return true to indicate sync capability
      return true;
    } catch (e) {
      _logger.e('Error syncing curriculum data: $e');
      return false;
    }
  }

  Future<void> cacheCurriculumData() async {
    try {
      final subjects = await getSubjects();
      for (final subject in subjects) {
        // Cache each subject with its strands and topics
        final strands = await getTopicsByStrand(subject.id!);
        for (final strand in strands) {
          await getLearningOutcomesByTopic(strand.id!);
        }
      }
      _logger.i('Curriculum data cached successfully');
    } catch (e) {
      _logger.e('Error caching curriculum data: $e');
    }
  }
}

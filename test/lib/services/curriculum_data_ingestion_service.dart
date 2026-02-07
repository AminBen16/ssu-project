import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/enhanced_curriculum_models.dart';
import '../models/curriculum_models.dart';
import 'curriculum_database_service.dart';

/// Service for ingesting NCDC curriculum data from cleaned markdown files
class CurriculumDataIngestionService {
  static const String _alevelDir = 'cleaned_alevel_syllabi';
  static const String _olevelDir = 'cleaned_olevel_syllabi';
  
  /// Ingest all curriculum data from markdown files
  static Future<Map<String, dynamic>> ingestAllCurriculumData({
    bool forceRebuild = false,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Starting curriculum data ingestion...');
      
      if (forceRebuild) {
        await CurriculumDatabaseService.clearAllData();
        onProgress?.call('Cleared existing curriculum data');
      }

      final results = <String, dynamic>{
        'subjects': 0,
        'strands': 0,
        'topics': 0,
        'learningOutcomes': 0,
        'activities': 0,
        'materials': 0,
        'assessments': 0,
        'errors': <String>[],
        'warnings': <String>[],
        'processedFiles': <String>[],
      };

      // Get documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      
      // Process A-Level files
      final alevelPath = path.join(documentsDir.path, _alevelDir);
      if (await Directory(alevelPath).exists()) {
        onProgress?.call('Processing A-Level curriculum files...');
        await _processCurriculumDirectory(
          alevelPath, 
          'Advanced Secondary', 
          results, 
          onProgress
        );
      }

      // Process O-Level files
      final olevelPath = path.join(documentsDir.path, _olevelDir);
      if (await Directory(olevelPath).exists()) {
        onProgress?.call('Processing O-Level curriculum files...');
        await _processCurriculumDirectory(
          olevelPath, 
          'Lower Secondary', 
          results, 
          onProgress
        );
      }

      onProgress?.call('Curriculum data ingestion completed!');
      return results;
    } catch (e) {
      onProgress?.call('Error during ingestion: $e');
      return {
        'error': e.toString(),
        'subjects': 0,
        'strands': 0,
        'topics': 0,
        'learningOutcomes': 0,
        'activities': 0,
        'materials': 0,
        'assessments': 0,
        'errors': [e.toString()],
        'warnings': <String>[],
        'processedFiles': <String>[],
      };
    }
  }

  /// Process all markdown files in a directory
  static Future<void> _processCurriculumDirectory(
    String directoryPath,
    String educationLevel,
    Map<String, dynamic> results,
    Function(String)? onProgress,
  ) async {
    final dir = Directory(directoryPath);
    final files = await dir.list().where((entity) => 
      entity is File && entity.path.endsWith('.md')
    ).cast<File>().toList();

    for (final file in files) {
      try {
        onProgress?.call('Processing: ${path.basename(file.path)}');
        await _processMarkdownFile(file, educationLevel, results);
        results['processedFiles'].add(file.path);
      } catch (e) {
        results['errors'].add('Error processing ${file.path}: $e');
      }
    }
  }

  /// Process a single markdown file
  static Future<void> _processMarkdownFile(
    File file,
    String educationLevel,
    Map<String, dynamic> results,
  ) async {
    final content = await file.readAsString();
    final fileName = path.basenameWithoutExtension(file.path);
    
    // Parse subject from filename
    final subjectName = _extractSubjectName(fileName);
    
    // Create subject
    final subject = EnhancedSubject(
      name: subjectName,
      educationLevel: educationLevel,
      description: _extractDescription(content),
      rationale: _extractRationale(content),
      periodDuration: _extractPeriodDuration(content),
      periodsPerWeek: _extractPeriodsPerWeek(content),
      classNames: _extractClassNames(content, educationLevel),
    );
    
    final subjectId = await CurriculumDatabaseService.insertEnhancedSubject(subject);
    results['subjects'] = (results['subjects'] as int) + 1;
    
    // Parse and create strands, topics, and learning outcomes
    await _processCurriculumContent(content, subjectId, educationLevel, results);
  }

  /// Extract subject name from filename
  static String _extractSubjectName(String fileName) {
    // Remove common prefixes and suffixes
    String cleanName = fileName
        .replaceAll('ALEVEL_', '')
        .replaceAll('_clean', '')
        .replaceAll('_compressed', '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');
    
    // Capitalize words
    return cleanName.split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  /// Extract description from markdown content
  static String? _extractDescription(String content) {
    final overviewMatch = RegExp(r'## OVERVIEW\s*\n\s*([\s\S]*?)(?=\n##|\n---|\n#|$)').firstMatch(content);
    if (overviewMatch != null) {
      return overviewMatch.group(1)?.trim();
    }
    return null;
  }

  /// Extract rationale from markdown content
  static String? _extractRationale(String content) {
    final rationaleMatch = RegExp(r'### RATIONALE\s*\n\s*([\s\S]*?)(?=\n##|\n---|\n###|$)').firstMatch(content);
    if (rationaleMatch != null) {
      return rationaleMatch.group(1)?.trim();
    }
    return null;
  }

  /// Extract period duration from content
  static int? _extractPeriodDuration(String content) {
    final durationMatch = RegExp(r'(\d+)\s*minutes?').firstMatch(content);
    if (durationMatch != null) {
      return int.tryParse(durationMatch.group(1)!);
    }
    return null;
  }

  /// Extract periods per week from content
  static int? _extractPeriodsPerWeek(String content) {
    final periodsMatch = RegExp(r'(\d+)\s*periods?\s*per\s*week').firstMatch(content);
    if (periodsMatch != null) {
      return int.tryParse(periodsMatch.group(1)!);
    }
    return null;
  }

  /// Extract class names based on education level
  static List<String> _extractClassNames(String content, String educationLevel) {
    if (educationLevel == 'Advanced Secondary') {
      return ['Senior 5', 'Senior 6'];
    } else {
      return ['Senior 1', 'Senior 2', 'Senior 3', 'Senior 4'];
    }
  }

  /// Process main curriculum content (strands, topics, learning outcomes)
  static Future<void> _processCurriculumContent(
    String content,
    int subjectId,
    String educationLevel,
    Map<String, dynamic> results,
  ) async {
    // Find all term/strand sections
    final termSections = RegExp(r'###?\s*(TERM\s+\d+|[^#\n]+)\s*\((\d+)\s*periods?\)').allMatches(content);
    
    int strandOrder = 0;
    for (final termMatch in termSections) {
      final strandName = termMatch.group(1)!.trim();
      final durationPeriods = int.tryParse(termMatch.group(2)!) ?? 0;
      
      // Extract term and senior level
      final term = _extractTermFromStrandName(strandName);
      final seniorLevel = _extractSeniorLevelFromStrandName(strandName);
      
      // Create strand
      final strand = EnhancedStrand(
        subjectId: subjectId,
        name: strandName,
        term: term,
        seniorLevel: seniorLevel,
        durationPeriods: durationPeriods,
        orderIndex: strandOrder++,
      );
      
      final strandId = await CurriculumDatabaseService.insertEnhancedStrand(strand);
      results['strands'] = (results['strands'] as int) + 1;
      
      // Process topics within this strand
      await _processTopicsInSection(content, strandId, strandName, results);
    }
  }

  /// Extract term from strand name
  static String? _extractTermFromStrandName(String strandName) {
    final termMatch = RegExp(r'TERM\s+(\d+)').firstMatch(strandName);
    return termMatch != null ? 'TERM ${termMatch.group(1)}' : null;
  }

  /// Extract senior level from strand name
  static String? _extractSeniorLevelFromStrandName(String strandName) {
    final levelMatch = RegExp(r'(SENIOR\s+[A-Z]+\d*)').firstMatch(strandName);
    return levelMatch?.group(1);
  }

  /// Process topics within a strand section
  static Future<void> _processTopicsInSection(
    String content,
    int strandId,
    String strandName,
    Map<String, dynamic> results,
  ) async {
    // Find the section content for this strand
    final sectionStart = content.indexOf(strandName);
    if (sectionStart == -1) return;
    
    // Find next section or end of content
    int sectionEnd = content.indexOf('###', sectionStart + strandName.length);
    if (sectionEnd == -1) sectionEnd = content.length;
    
    final sectionContent = content.substring(sectionStart, sectionEnd);
    
    // Find all topics
    final topicMatches = RegExp(r'####\s*Topic\s+([^:]+):\s*([^#\n]*)\s*\n\s*\*\*Competency:\*\*\s*([^#\n]*)').allMatches(sectionContent);
    
    int topicOrder = 0;
    for (final topicMatch in topicMatches) {
      final topicName = topicMatch.group(2)!.trim();
      final competency = topicMatch.group(3)!.trim();
      
      // Create topic
      final topic = EnhancedTopic(
        strandId: strandId,
        name: topicName,
        competency: competency,
        orderIndex: topicOrder++,
      );
      
      final topicId = await CurriculumDatabaseService.insertEnhancedTopic(topic);
      results['topics'] = (results['topics'] as int) + 1;
      
      // Process learning outcomes for this topic
      await _processLearningOutcomes(sectionContent, topicName, topicId, results);
    }
  }

  /// Process learning outcomes for a topic
  static Future<void> _processLearningOutcomes(
    String sectionContent,
    String topicName,
    int topicId,
    Map<String, dynamic> results,
  ) async {
    // Find the topic section
    final topicStart = sectionContent.indexOf(topicName);
    if (topicStart == -1) return;
    
    // Find next topic or end of section
    int topicEnd = sectionContent.indexOf('#### Topic', topicStart + topicName.length);
    if (topicEnd == -1) topicEnd = sectionContent.length;
    
    final topicContent = sectionContent.substring(topicStart, topicEnd);
    
    // Extract learning outcomes
    final outcomesMatch = RegExp(r'\*\*Learning Outcomes:\*\*\s*\n([\s\S]*?)(?=\n---|\n####|\n###|$)').firstMatch(topicContent);
    if (outcomesMatch != null) {
      final outcomesText = outcomesMatch.group(1)!;
      final outcomeLines = outcomesText.split('\n').where((line) => line.trim().startsWith('-')).toList();
      
      int outcomeOrder = 0;
      for (final outcomeLine in outcomeLines) {
        final outcomeText = outcomeLine.replaceFirst(RegExp(r'^-\s*'), '').trim();
        
        if (outcomeText.isNotEmpty) {
          // Create learning outcome
          final learningOutcome = EnhancedLearningOutcome(
            topicId: topicId,
            outcomeText: outcomeText,
            outcomeType: _determineOutcomeType(outcomeText),
            orderIndex: outcomeOrder++,
            activities: _extractActivitiesFromText(outcomeText),
            materials: _extractMaterialsFromText(outcomeText),
            teachingStrategies: _extractTeachingStrategiesFromText(outcomeText),
            ictIntegration: _extractICTIntegrationFromText(outcomeText),
            crossCuttingIssues: _extractCrossCuttingIssuesFromText(outcomeText),
            genericSkills: _extractGenericSkillsFromText(outcomeText),
            assessment: EnhancedAssessment(),
          );
          
          final outcomeId = await CurriculumDatabaseService.insertEnhancedLearningOutcome(learningOutcome);
          results['learningOutcomes'] = (results['learningOutcomes'] as int) + 1;
          
          // Create activities, materials, and assessments
          await _createRelatedEntities(outcomeId, learningOutcome, results);
        }
      }
    }
  }

  /// Determine outcome type from text
  static String _determineOutcomeType(String text) {
    if (text.toLowerCase().contains('analyse') || text.toLowerCase().contains('explain')) {
      return 'Knowledge';
    } else if (text.toLowerCase().contains('operate') || text.toLowerCase().contains('use')) {
      return 'Skills';
    } else if (text.toLowerCase().contains('develop') || text.toLowerCase().contains('design')) {
      return 'Attitudes';
    }
    return 'Values';
  }

  /// Extract activities from outcome text
  static List<String> _extractActivitiesFromText(String text) {
    // Simple extraction - can be enhanced with more sophisticated parsing
    final activities = <String>[];
    if (text.toLowerCase().contains('operate')) activities.add('Operate equipment');
    if (text.toLowerCase().contains('prepare')) activities.add('Prepare materials');
    if (text.toLowerCase().contains('analyse')) activities.add('Analyze data');
    return activities;
  }

  /// Extract materials from outcome text
  static List<String> _extractMaterialsFromText(String text) {
    final materials = <String>[];
    if (text.toLowerCase().contains('microscope')) materials.add('Light microscope');
    if (text.toLowerCase().contains('slides')) materials.add('Microscope slides');
    if (text.toLowerCase().contains('tissues')) materials.add('Plant and animal tissues');
    return materials;
  }

  /// Extract teaching strategies from outcome text
  static List<String> _extractTeachingStrategiesFromText(String text) {
    final strategies = <String>[];
    strategies.add('Demonstration');
    strategies.add('Group work');
    strategies.add('Discussion');
    if (text.toLowerCase().contains('investigation')) strategies.add('Scientific investigation');
    return strategies;
  }

  /// Extract ICT integration from outcome text
  static List<String> _extractICTIntegrationFromText(String text) {
    final ictTools = <String>[];
    if (text.toLowerCase().contains('research')) ictTools.add('Internet research');
    if (text.toLowerCase().contains('calculate')) ictTools.add('Calculator/Software');
    if (text.toLowerCase().contains('present')) ictTools.add('Presentation software');
    return ictTools;
  }

  /// Extract cross-cutting issues from outcome text
  static List<String> _extractCrossCuttingIssuesFromText(String text) {
    final issues = <String>[];
    if (text.toLowerCase().contains('environment')) issues.add('Environmental conservation');
    if (text.toLowerCase().contains('health')) issues.add('Health education');
    if (text.toLowerCase().contains('gender')) issues.add('Gender equality');
    return issues;
  }

  /// Extract generic skills from outcome text
  static List<String> _extractGenericSkillsFromText(String text) {
    final skills = <String>[];
    skills.add('Critical thinking');
    skills.add('Problem solving');
    if (text.toLowerCase().contains('communicate')) skills.add('Communication');
    if (text.toLowerCase().contains('collaborate')) skills.add('Collaboration');
    return skills;
  }

  /// Create related entities (activities, materials, assessments)
  static Future<void> _createRelatedEntities(
    int outcomeId,
    EnhancedLearningOutcome learningOutcome,
    Map<String, dynamic> results,
  ) async {
    // Create activities
    for (int i = 0; i < (learningOutcome.activities?.length ?? 0); i++) {
      final activity = EnhancedActivity(
        learningOutcomeId: outcomeId,
        activityText: learningOutcome.activities![i],
        orderIndex: i,
      );
      await CurriculumDatabaseService.insertEnhancedActivity(activity);
      results['activities'] = (results['activities'] as int) + 1;
    }
    
    // Create materials
    for (int i = 0; i < (learningOutcome.materials?.length ?? 0); i++) {
      final material = EnhancedMaterial(
        learningOutcomeId: outcomeId,
        materialName: learningOutcome.materials![i],
        materialType: learningOutcome.materials![i],
        orderIndex: i,
      );
      await CurriculumDatabaseService.insertMaterial(material);
      results['materials'] = (results['materials'] as int) + 1;
    }
    
    // Create assessment
    final assessment = EnhancedAssessment(
      method: 'Formative assessment',
      guidance: 'Observe student performance and provide feedback',
    );
    final assessmentStrategy = AssessmentStrategy(
      learningOutcomeId: outcomeId,
      strategyText: assessment.method ?? 'Formative assessment',
      orderIndex: 0,
    );
    await CurriculumDatabaseService.insertAssessment(assessmentStrategy);
    results['assessments'] = (results['assessments'] as int) + 1;
  }

  /// Validate ingested data integrity
  static Future<Map<String, dynamic>> validateDataIntegrity() async {
    final validationResults = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
      'statistics': <String, dynamic>{},
    };
    
    try {
      // Get statistics
      validationResults['statistics'] = await CurriculumDatabaseService.getCurriculumStatistics();
      
      // Check for empty subjects
      final subjects = await CurriculumDatabaseService.getAllSubjects();
      for (final subject in subjects) {
        final strands = await CurriculumDatabaseService.getStrandsBySubject(subject.id!);
        if (strands.isEmpty) {
          validationResults['warnings'].add('Subject "${subject.name}" has no strands');
        }
        
        for (final strand in strands) {
          final topics = await CurriculumDatabaseService.getTopicsByStrand(strand.id!);
          if (topics.isEmpty) {
            validationResults['warnings'].add('Strand "${strand.name}" has no topics');
          }
          
          for (final topic in topics) {
            final outcomes = await CurriculumDatabaseService.getLearningOutcomesByTopic(topic.id!);
            if (outcomes.isEmpty) {
              validationResults['warnings'].add('Topic "${topic.name}" has no learning outcomes');
            }
          }
        }
      }
      
      validationResults['isValid'] = validationResults['errors'].isEmpty;
    } catch (e) {
      validationResults['isValid'] = false;
      validationResults['errors'].add('Validation error: $e');
    }
    
    return validationResults;
  }

  /// Get ingestion progress and status
  static Future<Map<String, dynamic>> getIngestionStatus() async {
    try {
      final statistics = await CurriculumDatabaseService.getCurriculumStatistics();
      return {
        'isComplete': statistics['subjects'] > 0,
        'statistics': statistics,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isComplete': false,
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}

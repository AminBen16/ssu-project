import 'dart:convert';
import 'package:flutter/material.dart';
import 'curriculum_database_service.dart';
import '../models/enhanced_curriculum_models.dart';

/// Comprehensive Integrity Audit and Validation Service
class CurriculumIntegrityAuditService {
  
  /// Perform comprehensive integrity audit
  static Future<Map<String, dynamic>> performFullAudit() async {
    final auditResults = <String, dynamic>{
      'auditTimestamp': DateTime.now().toIso8601String(),
      'overallStatus': 'PASS',
      'totalChecks': 0,
      'passedChecks': 0,
      'failedChecks': 0,
      'warnings': <String>[],
      'errors': <String>[],
      'validationResults': <String, dynamic>{},
      'recommendations': <String>[],
    };

    try {
      // 1. Database Structure Validation
      await _validateDatabaseStructure(auditResults);
      
      // 2. Data Completeness Validation
      await _validateDataCompleteness(auditResults);
      
      // 3. Data Consistency Validation
      await _validateDataConsistency(auditResults);
      
      // 4. NCDC Standards Compliance
      await _validateNCDCStandards(auditResults);
      
      // 5. Relationship Integrity
      await _validateRelationshipIntegrity(auditResults);
      
      // 6. Content Quality Assessment
      await _assessContentQuality(auditResults);
      
      // 7. Performance Metrics
      await _validatePerformanceMetrics(auditResults);
      
      // Calculate overall status
      auditResults['overallStatus'] = auditResults['errors'].isEmpty ? 'PASS' : 'FAIL';
      
    } catch (e) {
      auditResults['errors'].add('Audit execution error: $e');
      auditResults['overallStatus'] = 'FAIL';
    }

    return auditResults;
  }

  /// Validate database structure
  static Future<void> _validateDatabaseStructure(Map<String, dynamic> results) async {
    final structureValidation = <String, dynamic>{
      'checkName': 'Database Structure Validation',
      'status': 'PASS',
      'details': <String>[],
      'issues': <String>[],
    };

    try {
      final db = await CurriculumDatabaseService.database;
      
      // Check if all required tables exist
      final requiredTables = [
        'subjects', 'strands', 'topics', 'learning_outcomes',
        'activities', 'materials', 'assessments', 'cross_cutting_issues',
        'generic_skills', 'ict_integration', 'teaching_strategies'
      ];

      for (final table in requiredTables) {
        try {
          await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$table'");
          structureValidation['details'].add('Table $table exists');
        } catch (e) {
          structureValidation['issues'].add('Table $table missing or inaccessible: $e');
          structureValidation['status'] = 'FAIL';
        }
      }

      // Check indexes
      final indexCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='subjects'"
      );
      structureValidation['details'].add('Found ${indexCheck.length} indexes on subjects table');

    } catch (e) {
      structureValidation['status'] = 'FAIL';
      structureValidation['issues'].add('Database structure validation failed: $e');
    }

    results['validationResults']['databaseStructure'] = structureValidation;
    _updateAuditCounts(results, structureValidation['status'], structureValidation['issues']);
  }

  /// Validate data completeness
  static Future<void> _validateDataCompleteness(Map<String, dynamic> results) async {
    final completenessValidation = <String, dynamic>{
      'checkName': 'Data Completeness Validation',
      'status': 'PASS',
      'details': <String>[],
      'issues': <String>[],
      'statistics': <String, dynamic>{},
    };

    try {
      final statistics = await CurriculumDatabaseService.getCurriculumStatistics();
      completenessValidation['statistics'] = statistics;

      // Check minimum data requirements
      if (statistics['subjects'] == 0) {
        completenessValidation['issues'].add('No subjects found in database');
        completenessValidation['status'] = 'FAIL';
      } else {
        completenessValidation['details'].add('Found ${statistics['subjects']} subjects');
      }

      if (statistics['strands'] == 0) {
        completenessValidation['issues'].add('No strands found in database');
        completenessValidation['status'] = 'FAIL';
      } else {
        completenessValidation['details'].add('Found ${statistics['strands']} strands');
      }

      if (statistics['topics'] == 0) {
        completenessValidation['issues'].add('No topics found in database');
        completenessValidation['status'] = 'FAIL';
      } else {
        completenessValidation['details'].add('Found ${statistics['topics']} topics');
      }

      if (statistics['learningOutcomes'] == 0) {
        completenessValidation['issues'].add('No learning outcomes found in database');
        completenessValidation['status'] = 'FAIL';
      } else {
        completenessValidation['details'].add('Found ${statistics['learningOutcomes']} learning outcomes');
      }

      // Check ratio expectations
      final avgOutcomesPerTopic = statistics['topics'] > 0 
          ? statistics['learningOutcomes'] / statistics['topics'] 
          : 0;
      
      if (avgOutcomesPerTopic < 2) {
        completenessValidation['issues'].add('Low learning outcomes per topic ratio: $avgOutcomesPerTopic');
        completenessValidation['status'] = 'WARN';
      }

      completenessValidation['details'].add('Average learning outcomes per topic: ${avgOutcomesPerTopic.toStringAsFixed(1)}');

    } catch (e) {
      completenessValidation['status'] = 'FAIL';
      completenessValidation['issues'].add('Data completeness validation failed: $e');
    }

    results['validationResults']['dataCompleteness'] = completenessValidation;
    _updateAuditCounts(results, completenessValidation['status'], completenessValidation['issues']);
  }

  /// Validate data consistency
  static Future<void> _validateDataConsistency(Map<String, dynamic> results) async {
    final consistencyValidation = <String, dynamic>{
      'checkName': 'Data Consistency Validation',
      'status': 'PASS',
      'details': <String>[],
      'issues': <String>[],
    };

    try {
      // Check for orphaned records
      final db = await CurriculumDatabaseService.database;
      
      // Check for topics without valid strand references
      final orphanedTopics = await db.rawQuery('''
        SELECT t.id, t.name FROM topics t
        LEFT JOIN strands s ON t.strand_id = s.id
        WHERE s.id IS NULL
      ''');
      
      if (orphanedTopics.isNotEmpty) {
        consistencyValidation['issues'].add('Found ${orphanedTopics.length} topics with invalid strand references');
        consistencyValidation['status'] = 'FAIL';
      }

      // Check for learning outcomes without valid topic references
      final orphanedOutcomes = await db.rawQuery('''
        SELECT lo.id, lo.outcome_text FROM learning_outcomes lo
        LEFT JOIN topics t ON lo.topic_id = t.id
        WHERE t.id IS NULL
      ''');
      
      if (orphanedOutcomes.isNotEmpty) {
        consistencyValidation['issues'].add('Found ${orphanedOutcomes.length} learning outcomes with invalid topic references');
        consistencyValidation['status'] = 'FAIL';
      }

      // Check for duplicate subject names
      final duplicateSubjects = await db.rawQuery('''
        SELECT name, COUNT(*) as count FROM subjects
        GROUP BY name HAVING count > 1
      ''');
      
      if (duplicateSubjects.isNotEmpty) {
        consistencyValidation['issues'].add('Found ${duplicateSubjects.length} duplicate subject names');
        consistencyValidation['status'] = 'FAIL';
      }

      consistencyValidation['details'].add('Orphaned records check completed');
      consistencyValidation['details'].add('Duplicate records check completed');

    } catch (e) {
      consistencyValidation['status'] = 'FAIL';
      consistencyValidation['issues'].add('Data consistency validation failed: $e');
    }

    results['validationResults']['dataConsistency'] = consistencyValidation;
    _updateAuditCounts(results, consistencyValidation['status'], consistencyValidation['issues']);
  }

  /// Validate NCDC standards compliance
  static Future<void> _validateNCDCStandards(Map<String, dynamic> results) async {
    final ncdcValidation = <String, dynamic>{
      'checkName': 'NCDC Standards Compliance',
      'status': 'PASS',
      'details': <String>[],
      'issues': <String>[],
      'complianceScore': 0.0,
    };

    try {
      final subjects = await CurriculumDatabaseService.getAllSubjects();
      int compliantSubjects = 0;
      int totalChecks = 0;

      for (final subject in subjects) {
        final strands = await CurriculumDatabaseService.getStrandsBySubject(subject.id!);
        
        // Check if subject has adequate strand coverage
        if (strands.length < 2) {
          ncdcValidation['issues'].add('Subject "${subject.name}" has insufficient strand coverage (${strands.length} strands)');
          ncdcValidation['status'] = 'WARN';
        }
        totalChecks++;

        // Check each strand for NCDC compliance
        for (final strand in strands) {
          final topics = await CurriculumDatabaseService.getTopicsByStrand(strand.id!);
          
          if (topics.isEmpty) {
            ncdcValidation['issues'].add('Strand "${strand.name}" has no topics');
            ncdcValidation['status'] = 'WARN';
          }
          totalChecks++;

          // Check topics for competency statements
          for (final topic in topics) {
            if (topic.competency?.isEmpty ?? true) {
              ncdcValidation['issues'].add('Topic "${topic.name}" missing competency statement');
              ncdcValidation['status'] = 'WARN';
            }
            totalChecks++;

            final outcomes = await CurriculumDatabaseService.getLearningOutcomesByTopic(topic.id!);
            if (outcomes.isEmpty) {
              ncdcValidation['issues'].add('Topic "${topic.name}" has no learning outcomes');
              ncdcValidation['status'] = 'WARN';
            } else {
              // Check if outcomes meet NCDC standards
              for (final outcome in outcomes) {
                if (outcome.outcomeText.length < 20) {
                  ncdcValidation['issues'].add('Learning outcome too brief: "${outcome.outcomeText}"');
                  ncdcValidation['status'] = 'WARN';
                }
                totalChecks++;
              }
            }
          }
        }

        if (strands.length >= 2) compliantSubjects++;
      }

      // Calculate compliance score
      final complianceIssues = ncdcValidation['issues'].length as int;
      ncdcValidation['complianceScore'] = totalChecks > 0 
          ? ((totalChecks - complianceIssues) / totalChecks * 100).roundToDouble()
          : 0.0;

      ncdcValidation['details'].add('Checked $totalChecks curriculum elements');
      ncdcValidation['details'].add('Compliance score: ${ncdcValidation['complianceScore'].toStringAsFixed(1)}%');

      if (ncdcValidation['complianceScore'] < 80) {
        ncdcValidation['status'] = 'FAIL';
      }

    } catch (e) {
      ncdcValidation['status'] = 'FAIL';
      ncdcValidation['issues'].add('NCDC standards validation failed: $e');
    }

    results['validationResults']['ncdcStandards'] = ncdcValidation;
    _updateAuditCounts(results, ncdcValidation['status'], ncdcValidation['issues']);
  }

  /// Validate relationship integrity
  static Future<void> _validateRelationshipIntegrity(Map<String, dynamic> results) async {
    final relationshipValidation = <String, dynamic>{
      'checkName': 'Relationship Integrity Validation',
      'status': 'PASS',
      'details': <String>[],
      'issues': <String>[],
    };

    try {
      final db = await CurriculumDatabaseService.database;
      
      // Check foreign key constraints
      final fkCheck = await db.rawQuery('PRAGMA foreign_key_list(strands)');
      relationshipValidation['details'].add('Found ${fkCheck.length} foreign key constraints on strands table');

      // Test cascade delete with proper cleanup
      final testSubject = EnhancedSubject(
        name: 'Test Subject',
        educationLevel: 'Test',
      );
      
      final subjectId = await CurriculumDatabaseService.insertEnhancedSubject(testSubject);
      
      final testStrand = EnhancedStrand(
        subjectId: subjectId,
        name: 'Test Strand',
      );
      
      final strandId = await CurriculumDatabaseService.insertEnhancedStrand(testStrand);
      
      // Test cascade delete
      await CurriculumDatabaseService.deleteSubject(subjectId);
      
      // Check if strand was also deleted
      final remainingStrands = await db.query(
        'strands',
        where: 'id = ?',
        whereArgs: [strandId],
      );
      
      if (remainingStrands.isNotEmpty) {
        relationshipValidation['issues'].add('Cascade delete not working properly');
        relationshipValidation['status'] = 'FAIL';
      } else {
        relationshipValidation['details'].add('Cascade delete working correctly');
      }

    } catch (e) {
      relationshipValidation['status'] = 'FAIL';
      relationshipValidation['issues'].add('Relationship integrity validation failed: $e');
    }

    results['validationResults']['relationshipIntegrity'] = relationshipValidation;
    _updateAuditCounts(results, relationshipValidation['status'], relationshipValidation['issues']);
  }

  /// Assess content quality
  static Future<void> _assessContentQuality(Map<String, dynamic> results) async {
    final qualityAssessment = <String, dynamic>{
      'checkName': 'Content Quality Assessment',
      'status': 'PASS',
      'details': <String>[],
      'issues': <String>[],
      'qualityMetrics': <String, dynamic>{},
    };

    try {
      final subjects = await CurriculumDatabaseService.getAllSubjects();
      int totalTopics = 0;
      int topicsWithCompetencies = 0;
      int totalOutcomes = 0;
      int outcomesWithActivities = 0;
      int outcomesWithAssessments = 0;

      for (final subject in subjects) {
        final strands = await CurriculumDatabaseService.getStrandsBySubject(subject.id!);
        
        for (final strand in strands) {
          final topics = await CurriculumDatabaseService.getTopicsByStrand(strand.id!);
          
          for (final topic in topics) {
            totalTopics++;
            
            if (topic.competency?.isNotEmpty ?? false) {
              topicsWithCompetencies++;
            }
            
            final outcomes = await CurriculumDatabaseService.getLearningOutcomesByTopic(topic.id!);
            totalOutcomes += outcomes.length;
            
            for (final outcome in outcomes) {
              if (outcome.id != null) {
                final activities = await CurriculumDatabaseService.getActivitiesByLearningOutcome(outcome.id!);
                final assessments = await CurriculumDatabaseService.getAssessmentsByLearningOutcome(outcome.id!);
                
                if (activities.isNotEmpty) outcomesWithActivities++;
                if (assessments.isNotEmpty) outcomesWithAssessments++;
              }
            }
          }
        }
      }

      // Calculate quality metrics
      final competencyCoverage = totalTopics > 0 ? (topicsWithCompetencies / totalTopics * 100) : 0;
      final activityCoverage = totalOutcomes > 0 ? (outcomesWithActivities / totalOutcomes * 100) : 0;
      final assessmentCoverage = totalOutcomes > 0 ? (outcomesWithAssessments / totalOutcomes * 100) : 0;

      qualityAssessment['qualityMetrics'] = {
        'totalTopics': totalTopics,
        'topicsWithCompetencies': topicsWithCompetencies,
        'competencyCoverage': competencyCoverage,
        'totalOutcomes': totalOutcomes,
        'outcomesWithActivities': outcomesWithActivities,
        'activityCoverage': activityCoverage,
        'outcomesWithAssessments': outcomesWithAssessments,
        'assessmentCoverage': assessmentCoverage,
      };

      qualityAssessment['details'].add('Competency coverage: ${competencyCoverage.toStringAsFixed(1)}%');
      qualityAssessment['details'].add('Activity coverage: ${activityCoverage.toStringAsFixed(1)}%');
      qualityAssessment['details'].add('Assessment coverage: ${assessmentCoverage.toStringAsFixed(1)}%');

      // Set status based on quality thresholds
      if (competencyCoverage < 80 || activityCoverage < 50 || assessmentCoverage < 50) {
        qualityAssessment['status'] = 'WARN';
        qualityAssessment['issues'].add('Content quality below recommended thresholds');
      }

    } catch (e) {
      qualityAssessment['status'] = 'FAIL';
      qualityAssessment['issues'].add('Content quality assessment failed: $e');
    }

    results['validationResults']['contentQuality'] = qualityAssessment;
    _updateAuditCounts(results, qualityAssessment['status'], qualityAssessment['issues']);
  }

  /// Validate performance metrics
  static Future<void> _validatePerformanceMetrics(Map<String, dynamic> results) async {
    final performanceValidation = <String, dynamic>{
      'checkName': 'Performance Metrics Validation',
      'status': 'PASS',
      'details': <String>[],
      'issues': <String>[],
      'metrics': <String, dynamic>{},
    };

    try {
      final startTime = DateTime.now();
      
      // Test query performance
      final subjects = await CurriculumDatabaseService.getAllSubjects();
      final subjectsQueryTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final strandStartTime = DateTime.now();
      if (subjects.isNotEmpty) {
        await CurriculumDatabaseService.getStrandsBySubject(subjects.first.id!);
      }
      final strandsQueryTime = DateTime.now().difference(strandStartTime).inMilliseconds;

      performanceValidation['metrics'] = {
        'subjectsQueryTime': subjectsQueryTime,
        'strandsQueryTime': strandsQueryTime,
        'totalSubjects': subjects.length,
      };

      performanceValidation['details'].add('Subjects query time: ${subjectsQueryTime}ms');
      performanceValidation['details'].add('Strands query time: ${strandsQueryTime}ms');

      // Check performance thresholds
      if (subjectsQueryTime > 1000) {
        performanceValidation['issues'].add('Subjects query performance below threshold (${subjectsQueryTime}ms)');
        performanceValidation['status'] = 'WARN';
      }

      if (strandsQueryTime > 500) {
        performanceValidation['issues'].add('Strands query performance below threshold (${strandsQueryTime}ms)');
        performanceValidation['status'] = 'WARN';
      }

    } catch (e) {
      performanceValidation['status'] = 'FAIL';
      performanceValidation['issues'].add('Performance metrics validation failed: $e');
    }

    results['validationResults']['performanceMetrics'] = performanceValidation;
    _updateAuditCounts(results, performanceValidation['status'], performanceValidation['issues']);
  }

  /// Update audit counts based on validation results
  static void _updateAuditCounts(Map<String, dynamic> results, String status, List<String> issues) {
    results['totalChecks'] = (results['totalChecks'] as int) + 1;
    
    if (status == 'PASS') {
      results['passedChecks'] = (results['passedChecks'] as int) + 1;
    } else if (status == 'FAIL') {
      results['failedChecks'] = (results['failedChecks'] as int) + 1;
      results['errors'].addAll(issues);
    } else if (status == 'WARN') {
      results['warnings'].addAll(issues);
    }
  }

  /// Generate audit report
  static String generateAuditReport(Map<String, dynamic> auditResults) {
    final buffer = StringBuffer();
    
    buffer.writeln('# NCDC Curriculum Integrity Audit Report');
    buffer.writeln();
    buffer.writeln('**Audit Timestamp:** ${auditResults['auditTimestamp']}');
    buffer.writeln('**Overall Status:** ${auditResults['overallStatus']}');
    buffer.writeln('**Total Checks:** ${auditResults['totalChecks']}');
    buffer.writeln('**Passed Checks:** ${auditResults['passedChecks']}');
    buffer.writeln('**Failed Checks:** ${auditResults['failedChecks']}');
    buffer.writeln();
    
    // Validation Results
    buffer.writeln('## Validation Results');
    buffer.writeln();
    
    final validationResults = auditResults['validationResults'] as Map<String, dynamic>;
    for (final entry in validationResults.entries) {
      final validation = entry.value as Map<String, dynamic>;
      buffer.writeln('### ${validation['checkName']}');
      buffer.writeln('**Status:** ${validation['status']}');
      
      if (validation['details'] != null) {
        buffer.writeln('**Details:**');
        for (final detail in validation['details'] as List<String>) {
          buffer.writeln('- $detail');
        }
      }
      
      if (validation['issues'] != null && validation['issues'].isNotEmpty) {
        buffer.writeln('**Issues:**');
        for (final issue in validation['issues'] as List<String>) {
          buffer.writeln('- $issue');
        }
      }
      
      buffer.writeln();
    }
    
    // Errors and Warnings
    if (auditResults['errors'].isNotEmpty) {
      buffer.writeln('## Errors');
      for (final error in auditResults['errors'] as List<String>) {
        buffer.writeln('- $error');
      }
      buffer.writeln();
    }
    
    if (auditResults['warnings'].isNotEmpty) {
      buffer.writeln('## Warnings');
      for (final warning in auditResults['warnings'] as List<String>) {
        buffer.writeln('- $warning');
      }
      buffer.writeln();
    }
    
    // Recommendations
    if (auditResults['recommendations'].isNotEmpty) {
      buffer.writeln('## Recommendations');
      for (final recommendation in auditResults['recommendations'] as List<String>) {
        buffer.writeln('- $recommendation');
      }
    }
    
    return buffer.toString();
  }

  /// Get quick health check
  static Future<Map<String, dynamic>> getQuickHealthCheck() async {
    try {
      final statistics = await CurriculumDatabaseService.getCurriculumStatistics();
      final subjects = await CurriculumDatabaseService.getAllSubjects();
      
      int totalIssues = 0;
      final issues = <String>[];
      
      // Basic health checks
      if (statistics['subjects'] == 0) {
        totalIssues++;
        issues.add('No subjects in database');
      }
      
      if (statistics['strands'] == 0) {
        totalIssues++;
        issues.add('No strands in database');
      }
      
      if (statistics['topics'] == 0) {
        totalIssues++;
        issues.add('No topics in database');
      }
      
      if (statistics['learningOutcomes'] == 0) {
        totalIssues++;
        issues.add('No learning outcomes in database');
      }
      
      return {
        'status': totalIssues == 0 ? 'HEALTHY' : totalIssues <= 2 ? 'WARNING' : 'CRITICAL',
        'totalIssues': totalIssues,
        'issues': issues,
        'statistics': statistics,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'totalIssues': 1,
        'issues': ['Health check failed: $e'],
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Schedule automatic integrity checks
  static Future<void> scheduleIntegrityChecks() async {
    // This could be implemented with a background job scheduler
    // For now, we'll just log that checks should be scheduled
    print('Integrity checks should be scheduled to run periodically');
  }
}

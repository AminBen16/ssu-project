import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Enhanced scheme of work generator with real PDF generation
/// Replaces placeholder implementation with actual curriculum-based generation
class SchemeOfWorkGeneratorService {
  /// Generate comprehensive scheme of work with PDF output
  static Future<Map<String, dynamic>> generateSchemeOfWork({
    required String subject,
    required String gradeLevel,
    required String term,
    required int weeksCount,
    required Map<String, dynamic> curriculumData,
    required String schoolName,
    required String teacherName,
  }) async {
    developer.log('Generating scheme of work for $subject - Grade $gradeLevel');

    try {
      // Validate input parameters
      final validationErrors = _validateSchemeParameters(
          subject, gradeLevel, term, weeksCount, curriculumData);

      if (validationErrors.isNotEmpty) {
        return {
          'success': false,
          'errors': validationErrors,
        };
      }

      // Generate scheme structure
      final schemeStructure = await _generateSchemeStructure(
        subject: subject,
        gradeLevel: gradeLevel,
        term: term,
        weeksCount: weeksCount,
        curriculumData: curriculumData,
        schoolName: schoolName,
        teacherName: teacherName,
      );

      // Generate PDF document
      final pdfBytes = await _generateSchemePDF(schemeStructure);

      return {
        'success': true,
        'scheme_data': schemeStructure,
        'pdf_bytes': pdfBytes,
        'generated_at': DateTime.now().toIso8601String(),
        'total_weeks': weeksCount,
        'total_topics': schemeStructure['topics'].length,
      };
    } catch (e) {
      developer.log('Error generating scheme of work: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Validate scheme of work parameters
  static Map<String, String> _validateSchemeParameters(
    String subject,
    String gradeLevel,
    String term,
    int weeksCount,
    Map<String, dynamic> curriculumData,
  ) {
    final errors = <String, String>{};

    // Validate required fields
    if (subject.trim().isEmpty) {
      errors['subject'] = 'Subject name is required';
    }
    if (gradeLevel.trim().isEmpty) {
      errors['gradeLevel'] = 'Grade level is required';
    }
    if (term.trim().isEmpty) {
      errors['term'] = 'Term is required';
    }
    if (weeksCount <= 0) {
      errors['weeksCount'] = 'Weeks count must be greater than 0';
    }
    if (curriculumData.isEmpty) {
      errors['curriculumData'] = 'Curriculum data is required';
    }

    // Validate curriculum structure
    if (!curriculumData.containsKey('topics') ||
        !curriculumData.containsKey('learning_objectives') ||
        !curriculumData.containsKey('assessment_methods')) {
      errors['curriculumData'] = 'Invalid curriculum data structure';
    }

    return errors;
  }

  /// Generate scheme structure based on curriculum
  static Future<Map<String, dynamic>> _generateSchemeStructure({
    required String subject,
    required String gradeLevel,
    required String term,
    required int weeksCount,
    required Map<String, dynamic> curriculumData,
    required String schoolName,
    required String teacherName,
  }) async {
    final topics = curriculumData['topics'] as List<dynamic>? ?? [];
    final learningObjectives =
        curriculumData['learning_objectives'] as List<dynamic>? ?? [];
    final assessmentMethods =
        curriculumData['assessment_methods'] as List<dynamic>? ?? [];

    // Distribute topics across weeks
    final weeks = <Map<String, dynamic>>[];
    final topicsPerWeek = (topics.length / weeksCount).ceil();

    for (int week = 0; week < weeksCount; week++) {
      final startIndex = week * topicsPerWeek;
      final endIndex = math.min(startIndex + topicsPerWeek, topics.length);
      final weekTopics = topics.sublist(startIndex, endIndex);

      weeks.add({
        'week_number': week + 1,
        'week_start_date': _calculateWeekStartDate(week, term),
        'week_end_date': _calculateWeekEndDate(week, term),
        'topics': weekTopics,
        'learning_objectives':
            _extractLearningObjectives(weekTopics, learningObjectives),
        'assessment_methods':
            _extractAssessmentMethods(weekTopics, assessmentMethods),
        'activities': _generateActivities(weekTopics),
        'resources': _generateResources(weekTopics),
      });
    }

    return {
      'subject': subject,
      'grade_level': gradeLevel,
      'term': term,
      'school_name': schoolName,
      'teacher_name': teacherName,
      'generated_date': DateTime.now().toIso8601String(),
      'total_weeks': weeksCount,
      'weeks': weeks,
      'topics': topics,
      'learning_objectives': learningObjectives,
      'assessment_methods': assessmentMethods,
    };
  }

  /// Calculate week start date
  static String _calculateWeekStartDate(int week, String term) {
    final now = DateTime.now();
    final termStart =
        DateTime(now.year, now.month, 1); // Assume term starts on 1st
    final weekStart = termStart.add(Duration(days: (week - 1) * 7));
    return weekStart.toIso8601String().split('T')[0];
  }

  /// Calculate week end date
  static String _calculateWeekEndDate(int week, String term) {
    final now = DateTime.now();
    final termStart =
        DateTime(now.year, now.month, 1); // Assume term starts on 1st
    final weekEnd = termStart.add(Duration(days: week * 7));
    return weekEnd.toIso8601String().split('T')[0];
  }

  /// Extract relevant learning objectives for week
  static List<dynamic> _extractLearningObjectives(
    List<dynamic> weekTopics,
    List<dynamic> allObjectives,
  ) {
    final weekObjectives = <dynamic>[];

    for (final topic in weekTopics) {
      if (topic is Map && topic.containsKey('objectives')) {
        final topicObjectives = topic['objectives'] as List<dynamic>;
        weekObjectives.addAll(topicObjectives);
      }
    }

    return weekObjectives;
  }

  /// Extract relevant assessment methods for week
  static List<dynamic> _extractAssessmentMethods(
    List<dynamic> weekTopics,
    List<dynamic> allMethods,
  ) {
    final weekMethods = <dynamic>[];

    for (final topic in weekTopics) {
      if (topic is Map && topic.containsKey('assessment')) {
        final topicMethods = topic['assessment'] as List<dynamic>;
        weekMethods.addAll(topicMethods);
      }
    }

    return weekMethods;
  }

  /// Generate activities for topics
  static List<dynamic> _generateActivities(List<dynamic> topics) {
    final activities = <dynamic>[];

    for (final topic in topics) {
      if (topic is Map) {
        final topicActivities = <String>[];

        // Add standard activities based on topic type
        if (topic.containsKey('type')) {
          final topicType = topic['type'] as String;

          switch (topicType.toLowerCase()) {
            case 'theory':
              topicActivities.addAll([
                'Classroom discussion',
                'Note-taking',
                'Reading assignment',
                'Group work',
              ]);
              break;
            case 'practical':
              topicActivities.addAll([
                'Hands-on practice',
                'Laboratory work',
                'Field work',
                'Demonstration',
              ]);
              break;
            case 'assessment':
              topicActivities.addAll([
                'Quiz',
                'Written test',
                'Practical exam',
                'Project work',
              ]);
              break;
            default:
              topicActivities.addAll([
                'Classroom instruction',
                'Student participation',
                'Practice exercises',
              ]);
          }
        }

        activities.add({
          'topic': topic['title'] ?? 'Unknown Topic',
          'activities': topicActivities,
        });
      }
    }

    return activities;
  }

  /// Generate resources for topics
  static List<dynamic> _generateResources(List<dynamic> topics) {
    final resources = <dynamic>[];

    for (final topic in topics) {
      if (topic is Map) {
        final topicResources = <String>[];

        // Add standard resources based on topic requirements
        if (topic.containsKey('resources')) {
          final requiredResources = topic['resources'] as List<dynamic>;
          topicResources.addAll(requiredResources.map((r) => r.toString()));
        } else {
          // Default resources
          topicResources.addAll([
            'Textbook',
            'Workbook',
            'Teaching aids',
            'Audio-visual materials',
          ]);
        }

        resources.add({
          'topic': topic['title'] ?? 'Unknown Topic',
          'resources': topicResources,
        });
      }
    }

    return resources;
  }

  /// Generate PDF document for scheme of work
  static Future<Uint8List> _generateSchemePDF(
      Map<String, dynamic> schemeStructure) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();

    // Add title page
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'SCHEME OF WORK',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // School and subject info
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'School: ${schemeStructure['school_name']}',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Subject: ${schemeStructure['subject']}',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Grade: ${schemeStructure['grade_level']}',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Term: ${schemeStructure['term']}',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Teacher: ${schemeStructure['teacher_name']}',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Generated: ${schemeStructure['generated_date']}',
                      style: pw.TextStyle(
                          font: font, fontSize: 12, color: PdfColors.grey),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Weeks content
              ...schemeStructure['weeks'].map<pw.Widget>((week) {
                return _buildWeekSection(week as Map<String, dynamic>, font);
              }).toList(),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Build week section for PDF
  static pw.Widget _buildWeekSection(Map<String, dynamic> week, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Week header
          pw.Text(
            'Week ${week['week_number']} (${week['week_start_date']} - ${week['week_end_date']})',
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          // Topics
          pw.Text(
            'Topics:',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          ...week['topics'].map((topic) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Text(
                '• ${topic is Map ? topic['title'] : topic}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            );
          }).toList(),

          pw.SizedBox(height: 10),

          // Learning objectives
          if (week['learning_objectives'].isNotEmpty) ...[
            pw.Text(
              'Learning Objectives:',
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            ...week['learning_objectives'].map((objective) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10),
                child: pw.Text(
                  '• $objective',
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              );
            }).toList(),
            pw.SizedBox(height: 10),
          ],

          // Assessment methods
          if (week['assessment_methods'].isNotEmpty) ...[
            pw.Text(
              'Assessment Methods:',
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            ...week['assessment_methods'].map((method) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10),
                child: pw.Text(
                  '• $method',
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

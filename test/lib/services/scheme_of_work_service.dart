import 'package:test/models/scheme_of_work_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';
import 'package:test/services/ncdc_curriculum_service.dart';
import 'dart:typed_data';

class SchemeOfWorkService {
  final ApiClient _apiClient;
  final OfflineService _offlineService = OfflineService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final NCDCurriculumService _ncdcService = NCDCurriculumService();

  SchemeOfWorkService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Gets all schemes of work for a specific school.
  Future<List<SchemeOfWork>> getSchemesOfWork(String schoolId,
      {Map<String, String>? queryParams}) async {
    final response = await _apiClient.get(
        '/api/schools/$schoolId/schemes-of-work',
        queryParameters: queryParams);
    final schemes = response['schemes_of_work'] as List<dynamic>;

    return schemes.map((schemeData) {
      final data = schemeData as Map<String, dynamic>;
      return SchemeOfWork.fromMap(data);
    }).toList();
  }

  /// Gets a specific scheme of work.
  Future<Map<String, dynamic>> getSchemeOfWork(String schoolId, String subject,
      String className, String term, int year) async {
    final response = await _apiClient.get(
        '/api/schools/$schoolId/schemes-of-work/$subject/$className/$term/$year');
    return response as Map<String, dynamic>;
  }

  /// Creates or updates a scheme of work with offline support.
  Future<void> saveSchemeOfWork(
      String schoolId, Map<String, dynamic> schemeData) async {
    final isOnline = await _offlineService.isOnline;
    final subject = schemeData['subject'] as String;
    final className = schemeData['className'] as String;
    final term = schemeData['term'] as String;
    final year = schemeData['year'] as int;

    if (isOnline) {
      try {
        await _apiClient.post('/api/schools/$schoolId/schemes-of-work',
            body: schemeData);
        // Cache the saved scheme locally
        await _localDb.saveData('scheme_of_work',
            '${schoolId}_${subject}_${className}_${term}_$year', {
          'scheme': schemeData,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('insert', {
          'table': 'scheme_of_work',
          'schoolId': schoolId,
          'subject': subject,
          'className': className,
          'term': term,
          'year': year,
          ...schemeData,
        });
        // Cache locally for immediate display
        await _localDb.saveData('scheme_of_work',
            '${schoolId}_${subject}_${className}_${term}_$year', {
          'scheme': schemeData,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
        rethrow;
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('insert', {
        'table': 'scheme_of_work',
        'schoolId': schoolId,
        'subject': subject,
        'className': className,
        'term': term,
        'year': year,
        ...schemeData,
      });
      // Cache locally for immediate display
      await _localDb.saveData('scheme_of_work',
          '${schoolId}_${subject}_${className}_${term}_$year', {
        'scheme': schemeData,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Deletes a scheme of work by its ID with offline support.
  Future<void> deleteSchemeOfWork(String schemeId) async {
    final isOnline = await _offlineService.isOnline;
    if (isOnline) {
      try {
        await _apiClient.delete('/api/schemes-of-work/$schemeId');
        // Remove from local cache
        await _localDb.deleteData('scheme_of_work', schemeId);
      } catch (e) {
        // Queue for offline sync
        await _offlineService.queueForSync('delete', {
          'table': 'scheme_of_work',
          'id': schemeId,
        });
        rethrow;
      }
    } else {
      // Queue for offline sync
      await _offlineService.queueForSync('delete', {
        'table': 'scheme_of_work',
        'id': schemeId,
      });
      // Mark for deletion in local cache
      await _localDb.saveData('scheme_of_work', schemeId, {
        'deleted': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Validates scheme of work against NCDC curriculum
  Future<Map<String, dynamic>> validateCurriculumAlignment({
    required String schoolId,
    required String subject,
    required String className,
    required String term,
    required int year,
  }) async {
    try {
      // Get scheme of work
      final scheme =
          await getSchemeOfWork(schoolId, subject, className, term, year);
      final schemeTopics = scheme['topics'] as List<dynamic>? ?? [];

      // Use NCDC service for validation
      return await _ncdcService.validateSchemeOfWork(
        subject: subject,
        className: className,
        schemeTopics: schemeTopics.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      throw Exception('Failed to validate curriculum alignment: $e');
    }
  }

  /// Exports scheme of work to PDF
  Future<Uint8List> exportToPDF({
    required String schoolId,
    required String subject,
    required String className,
    required String term,
    required int year,
  }) async {
    try {
      final scheme =
          await getSchemeOfWork(schoolId, subject, className, term, year);

      // Simple PDF generation without external dependencies
      final pdfData =
          'Scheme of Work - $subject\nClass: $className\nTerm: $term, Year: $year\n\nTopics:\n${((scheme['topics'] as List<dynamic>?) ?? []).map((topic) => '- ${topic['name'] ?? 'Unknown Topic'}').join('\n')}';

      return Uint8List.fromList(pdfData.codeUnits);
    } catch (e) {
      throw Exception('Failed to export to PDF: $e');
    }
  }

  /// Exports scheme of work to Excel format (simplified)
  Future<String> exportToExcel({
    required String schoolId,
    required String subject,
    required String className,
    required String term,
    required int year,
  }) async {
    try {
      final scheme =
          await getSchemeOfWork(schoolId, subject, className, term, year);
      final csvData = <List<String>>[];

      // Add header
      csvData.add(
          ['Week', 'Topic', 'Learning Outcomes', 'Activities', 'Assessment']);

      // Add topics
      final topics = scheme['topics'] as List<dynamic>? ?? [];
      for (int i = 0; i < topics.length; i++) {
        final topic = topics[i];
        final outcomesList = topic['outcomes'] as List<dynamic>?;
        final activitiesList = topic['activities'] as List<dynamic>?;

        csvData.add([
          'Week ${i + 1}',
          topic['name']?.toString() ?? '',
          outcomesList?.join('; ') ?? '',
          activitiesList?.join('; ') ?? '',
          topic['assessment']?.toString() ?? '',
        ]);
      }

      // Convert to CSV string
      final csvString = csvData
          .map((row) => row
              .map((cell) => '"${cell.toString().replaceAll('"', '""')}"')
              .join(','))
          .join('\n');

      return csvString;
    } catch (e) {
      throw Exception('Failed to export to Excel: $e');
    }
  }

  /// Exports scheme of work to Word format (simplified HTML)
  Future<String> exportToWord({
    required String schoolId,
    required String subject,
    required String className,
    required String term,
    required int year,
  }) async {
    try {
      final scheme =
          await getSchemeOfWork(schoolId, subject, className, term, year);
      final topics = scheme['topics'] as List<dynamic>? ?? [];

      final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Scheme of Work - $subject</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .header { margin-bottom: 30px; }
        .topic { margin-bottom: 20px; padding: 10px; border-left: 3px solid #007bff; }
        .topic-title { font-weight: bold; font-size: 16px; }
        .outcomes { margin-top: 10px; }
        .activities { margin-top: 10px; }
        .assessment { margin-top: 10px; }
    </style>
</head>
<body>
    <h1>Scheme of Work - $subject</h1>
    <div class="header">
        <p><strong>Class:</strong> $className</p>
        <p><strong>Term:</strong> $term, $year</p>
    </div>
    ${topics.asMap().entries.map((entry) {
        final topic = entry.value;
        final outcomesList = topic['outcomes'] as List<dynamic>?;
        final activitiesList = topic['activities'] as List<dynamic>?;

        return '''
    <div class="topic">
        <div class="topic-title">Week ${entry.key + 1}: ${topic['name'] ?? 'Unknown Topic'}</div>
        <div class="outcomes">
            <strong>Learning Outcomes:</strong><br>
            ${outcomesList?.join('<br>') ?? 'N/A'}
        </div>
        <div class="activities">
            <strong>Activities:</strong><br>
            ${activitiesList?.join('<br>') ?? 'N/A'}
        </div>
        <div class="assessment">
            <strong>Assessment:</strong><br>
            ${topic['assessment'] ?? 'N/A'}
        </div>
    </div>
    ''';
      }).join('')}
</body>
</html>
      ''';

      return html;
    } catch (e) {
      throw Exception('Failed to export to Word: $e');
    }
  }
}

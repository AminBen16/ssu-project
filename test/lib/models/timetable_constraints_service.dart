import 'dart:developer' as developer;

import 'package:test/services/api_client.dart';

class TimetableConstraintsService {
  final ApiClient _apiClient;

  TimetableConstraintsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<void> saveConstraints(
    String schoolId,
    Map<String, (int?, int?)> constraints,
  ) async {
    final Map<String, dynamic> dataToSave = {};
    constraints.forEach((subjectCode, values) {
      dataToSave[subjectCode] = {'min': values.$1, 'max': values.$2};
    });

    await _apiClient.post('/api/schools/$schoolId/constraints',
        body: {'subjectConstraints': dataToSave});
  }

  Future<Map<String, (int?, int?)>> getConstraints(String schoolId) async {
    try {
      final response =
          await _apiClient.get('/api/schools/$schoolId/constraints');
      final data =
          response['subjectConstraints'] as Map<String, dynamic>? ?? {};
      return data.map((subjectCode, values) {
        final valuesMap = values as Map<String, dynamic>;
        return MapEntry(subjectCode, (
          valuesMap['min'] as int?,
          valuesMap['max'] as int?,
        ));
      });
    } catch (e) {
      developer.log('Error fetching constraints: $e');
      return {};
    }
  }
}

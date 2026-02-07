import 'package:test/models/student_application_model.dart';
import 'package:test/services/api_client.dart';

class StudentApplicationService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches all student applications for a given school.
  Future<List<StudentApplication>> getApplications(String schoolId) async {
    // The endpoint assumes a structure like /api/schools/{schoolId}/applications
    final response =
        await _apiClient.get('/api/schools/$schoolId/applications');

    if (response != null) {
      final List<dynamic> applicationList = response['applications'] as List<dynamic>;
      return applicationList
          .map((json) =>
              StudentApplication.fromMap(json as Map<String, dynamic>))
          .toList();
    } else {
      // Return an empty list or throw an exception if the response is null
      return [];
    }
  }

  /// Updates the status of a specific application.
  Future<void> updateApplicationStatus({
    required String schoolId,
    required String applicationId,
    required String status, // 'approved' or 'rejected'
  }) async {
    // The endpoint assumes a PATCH or PUT request to update the status.
    // e.g., PATCH /api/schools/{schoolId}/applications/{applicationId}
    await _apiClient.put(
      '/api/schools/$schoolId/applications/$applicationId',
      body: {'status': status},
    );
    // The ApiClient is expected to throw an exception on failure,
    // so no explicit status code check is needed here.
  }
}

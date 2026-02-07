import 'package:test/models/user_profile.dart';
import 'package:test/services/api_client.dart';

class ParentEnrollmentService {
  final ApiClient _apiClient = ApiClient();

  Future<UserProfile> enrollParent(
      Map<String, dynamic> parentData, String schoolId) async {
    final response = await _apiClient.post('/api/schools/$schoolId/users', body: parentData);
    final data = response['user'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Registration failed');
    final createdUid = data['id'].toString();
    return UserProfile.fromMap(data, createdUid);
  }

  Future<void> approveApplication(String applicationId) async {
    await _apiClient.post('/api/applications/$applicationId/approve');
  }

  Future<void> rejectApplication(String applicationId, String reason) async {
    await _apiClient.post(
      '/api/applications/$applicationId/reject',
      body: {'reason': reason},
    );
  }
}

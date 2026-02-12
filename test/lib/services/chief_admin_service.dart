import 'dart:developer' as developer;

import 'package:test/services/api_client.dart';

class ChiefAdminService {
  final ApiClient _apiClient = ApiClient();

  /// Calls the local API to create a new school and its admin.
  /// Can only be called by a user with the 'chiefAdmin' role.
  Future<void> createSchoolAndAdmin({
    required String schoolName,
    required String adminFirstName,
    required String adminLastName,
    required String email,
    required String password,
  }) async {
    try {
      await _apiClient.post('/schools', body: {
        'schoolName': schoolName,
        'adminFirstName': adminFirstName,
        'adminLastName': adminLastName,
        'email': email,
        'password': password,
        'classification': 'Primary', // Default classification
      });
    } catch (e) {
      developer.log('API Error: $e');
      throw Exception('Failed to create school and admin: $e');
    }
  }
}


import 'dart:developer' as developer;

import 'package:test/services/api_client.dart';

import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

/// A service for handling student enrollment through the backend API with offline support.
class EnrollmentService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Enrolls a new student by calling the self-hosted backend.
  Future<Map<String, dynamic>> enrollStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required DateTime dateOfBirth,
    required String className,
    required String parentName,
    required String parentNin,
    required List<String> subjectCodes,
    required String sex,
    String? religion,
    String? address,
    String? phoneNumber,
    String? parentContact,
    String? specialNeeds,
  }) async {
    try {
      final payload = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(), // The backend will create a user account
        'password': password,
        'dateOfBirth': dateOfBirth.millisecondsSinceEpoch,
        'className': className,
        'parentName': parentName.trim(),
        'parentNin': parentNin.trim(),
        'subjectCodes': subjectCodes,
        'sex': sex,
        if (religion != null) 'religion': religion,
        if (address != null && address.isNotEmpty) 'address': address,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
        if (parentContact != null && parentContact.isNotEmpty)
          'parentContact': parentContact,
        if (specialNeeds != null && specialNeeds.isNotEmpty)
          'specialNeeds': specialNeeds,
      };

      final response = await _apiClient.post(
        '/api/students',
        body: payload,
      );

      // ApiClient throws on non-2xx status, so if we get here, it was successful.
      // The response is already a decoded Map.
      return response;
    } catch (e) {
      developer.log('An error occurred during enrollment: $e');
      // Re-throw the exception to be handled by the UI.
      rethrow;
    }
  }

  /// Fetches all available classes combining configured streams and existing student classes with offline support
  Future<List<String>> getAllAvailableClasses(String schoolId) async {
    final cacheKey = 'available_classes_$schoolId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get('/api/schools/$schoolId/classes');
        if (response != null && response['classes'] is List) {
          final classes = List<String>.from(response['classes']);

          // Cache classes locally
          await _localDb.saveData('available_classes', schoolId, {
            'classes': classes,
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          return classes;
        }
        return [];
      },
      offlineFallback: () async {
        // Try to get cached classes
        final cached = await _localDb.getData('available_classes', schoolId);
        if (cached != null && cached['classes'] != null) {
          return List<String>.from(cached['classes']);
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }
}

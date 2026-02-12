import 'package:test/models/school.dart'; // Correct import
import 'package:test/services/base_service.dart';

/// A service for interacting with the school-related endpoints on the backend.
class SchoolService extends BaseService {
  SchoolService({super.apiClient});

  /// Creates a new school.
  Future<School> createSchool({
    required String name,
    required String classification,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? website,
    String? motto,
    String? country,
    String? mission,
    String? vision,
    String? anthem,
    String? uniformDetails,
    List<String>? classLevels,
    Map<String, List<String>>? streams,
  }) async {
    final response = await apiClient.post(
      '/api/schools',
      body: {
        'name': name,
        'classification': classification,
        'address': address,
        'phone': phone,
        'email': email,
        'logoUrl': logoUrl,
        'website': website,
        'motto': motto,
        'country': country,
        'mission': mission,
        'vision': vision,
        'anthem': anthem,
        'uniformDetails': uniformDetails,
        'classLevels': classLevels,
        'streams': streams,
      },
    );
    return School.fromMap(response); // Use fromMap for the new School model
  }

  /// Fetches all schools from the backend.
  Future<List<School>> getAllSchools() async {
    final response = await apiClient.get('/api/schools');
    if (response != null && response['schools'] != null) {
      final List<dynamic> schoolsList = response['schools'];
      return schoolsList
          .map((schoolJson) => School.fromMap(schoolJson)) // Use fromMap
          .toList();
    }
    return [];
  }

  /// Fetches a single school by its ID.
  Future<School> getSchool(String? schoolId) async {
    validateId(schoolId, 'School');
    final response = await apiClient.get('/api/schools/$schoolId');
    final schoolData = response['school'] ??
        response; // API might return {'school': {}} or just {}
    return School.fromMap(schoolData); // Use fromMap
  }

  /// Updates a school's general information.
  Future<void> updateSchool(
      String schoolId, Map<String, dynamic> updateData) async {
    validateId(schoolId, 'School');
    await apiClient.put(
      '/api/schools/$schoolId',
      body: updateData,
    );
  }

  /// Deletes a school.
  Future<void> deleteSchool(String schoolId) async {
    validateId(schoolId, 'School');
    await apiClient.delete('/api/schools/$schoolId');
  }

  /// Updates the class streams for a given school.
  Future<void> updateClassStreams(
      String schoolId, Map<String, List<String>> streams) async {
    validateId(schoolId, 'School');
    await apiClient.put(
      '/api/schools/$schoolId/streams',
      body: {'streams': streams},
    );
  }

  /// Fetches all available classes combining configured streams and existing student classes
  Future<List<String>> getAllAvailableClasses(String schoolId) async {
    validateId(schoolId, 'School');
    final response = await apiClient.get('/api/schools/$schoolId/classes');
    if (response != null && response['classes'] != null) {
      final List<dynamic> classesList = response['classes'];
      // The backend now returns actual Class objects, so we need to map them correctly.
      // For now, it returns a list of maps, we will return the "name" of the class.
      // A more robust solution would be to return a List<Class> object.
      return classesList
          .map((classJson) => classJson['name'].toString())
          .toList();
    }
    return [];
  }
}

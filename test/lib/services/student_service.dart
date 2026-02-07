import 'package:test/models/student_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class StudentService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Searches for students based on various criteria.
  Future<List<Student>> searchStudents({
    required String schoolId,
    String? nameQuery,
    String? regIdQuery,
    String? className,
    String? stream,
    String? sex,
    String? feesStatus,
    String? admissionYear,
  }) async {
    final queryParameters = <String, String>{
      'schoolId': schoolId,
    };
    if (nameQuery != null && nameQuery.isNotEmpty) {
      queryParameters['name'] = nameQuery;
    }
    if (regIdQuery != null && regIdQuery.isNotEmpty) {
      queryParameters['regId'] = regIdQuery;
    }
    if (className != null) queryParameters['className'] = className;
    if (stream != null) queryParameters['stream'] = stream;
    if (sex != null) queryParameters['sex'] = sex;
    if (feesStatus != null) queryParameters['feesStatus'] = feesStatus;
    if (admissionYear != null) queryParameters['admissionYear'] = admissionYear;

    final cacheKey =
        'students_search_${schoolId}_${nameQuery ?? ''}_${regIdQuery ?? ''}_${className ?? ''}_${stream ?? ''}_${sex ?? ''}_${feesStatus ?? ''}_${admissionYear ?? ''}';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get('/api/students/search',
            queryParameters: queryParameters);
        final List<dynamic> data = response as List<dynamic>;
        return data
            .map((json) => Student.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      offlineFallback: () async {
        // Try to get cached search results
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = cached as List<dynamic>;
          return data
              .map((json) => Student.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }

  Future<List<Student>> getStudentsByClass(
      {required String schoolId, required String className}) async {
    final cacheKey = 'students_class_${schoolId}_$className';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/students',
          queryParameters: {'className': className},
        );

        // The response body is a JSON object with 'students' key
        final Map<String, dynamic> data = response as Map<String, dynamic>;
        final List<dynamic> studentsList = data['students'] as List<dynamic>;
        return studentsList
            .map((json) => Student.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      offlineFallback: () async {
        // Try to get cached class students
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = cached as List<dynamic>;
          return data
              .map((json) => Student.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }

  Future<List<Student>> getStudentsBySchool(String schoolId) async {
    final cacheKey = 'students_school_$schoolId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/schools/$schoolId/students');

        // The response body is a JSON object with 'students' key
        final Map<String, dynamic> data = response as Map<String, dynamic>;
        final List<dynamic> studentsList = data['students'] as List<dynamic>;
        return studentsList
            .map((json) => Student.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      offlineFallback: () async {
        // Try to get cached school students
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = cached as List<dynamic>;
          return data
              .map((json) => Student.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }

  Future<Student> getStudent(String studentId) async {
    final cacheKey = 'student_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get('/api/students/$studentId');
        final Map<String, dynamic> data = response as Map<String, dynamic>;
        return Student.fromMap(data);
      },
      offlineFallback: () async {
        // Try to get cached student data
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final Map<String, dynamic> data = cached as Map<String, dynamic>;
          return Student.fromMap(data);
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }

  Future<List<Student>> getStudents() async {
    final response = await _apiClient.get('/api/students');
    // The response body is a JSON object with 'students' key
    final Map<String, dynamic> data = response as Map<String, dynamic>;
    final List<dynamic> studentData = data['students'] as List<dynamic>;
    return studentData
        .map((data) => Student.fromMap(data as Map<String, dynamic>))
        .toList();
  }

  Future<List<Student>> getStudentsByParentId(
      {required String schoolId, required String parentId}) async {
    final cacheKey = 'students_by_parent_${schoolId}_$parentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/students',
        );
        final List<dynamic> data = response as List<dynamic>;
        return data
            .map((json) => Student.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      offlineFallback: () async {
        // Try to get cached parent students
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = cached as List<dynamic>;
          return data
              .map((json) => Student.fromMap(json as Map<String, dynamic>))
              .toList();
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }
}

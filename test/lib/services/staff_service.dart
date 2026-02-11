import 'package:test/services/api_client.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/models/staff.dart';

class StaffService {
  final ApiClient _apiClient = ApiClient();

  /// Generic method to fetch staff based on query parameters.
  Future<List<Staff>> _fetchStaff(
      String schoolId, Map<String, String> queryParams) async {
    final response = await _apiClient.get(
      '/api/schools/$schoolId/staff',
      queryParameters: queryParams,
    );

    if (response != null) {
      final List<dynamic> staffList = response as List<dynamic>;
      return staffList
          .map((json) => Staff.fromMap(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches all teaching staff for a given school.
  Future<List<Staff>> getTeachingStaff(String schoolId) async {
    return _fetchStaff(schoolId, {
      'roles': UserRole.allTeachingRoles.map((r) => r.name).join(','),
    });
  }

  /// Fetches the class teacher for a specific class.
  Future<Staff?> getClassTeacherForClass(
    String schoolId,
    String className,
  ) async {
    final staff = await _fetchStaff(schoolId, {
      'role': UserRole.classTeacher.name,
      'className': className,
      'limit': '1',
    });

    return staff.isNotEmpty ? staff.first : null;
  }

  /// Fetches the head teacher for the school.
  Future<Staff?> getHeadTeacher(String schoolId) async {
    final staff = await _fetchStaff(schoolId, {
      'role': UserRole.headTeacher.name,
      'limit': '1',
    });
    return staff.isNotEmpty ? staff.first : null;
  }

  /// Fetches all staff members for a school.
  /// This replaces the previous stream-based approach.
  Future<List<Staff>> getAllStaff(String schoolId) async {
    return _fetchStaff(schoolId,
        {'roles': UserRole.allStaffRoles.map((r) => r.name).join(',')});
  }
}

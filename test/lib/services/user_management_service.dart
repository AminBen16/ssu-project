import 'package:bcrypt/bcrypt.dart';
import 'package:test/services/api_client.dart';

/// A service for managing user registration and role assignment by school administrators
class UserManagementService {
  final ApiClient _apiClient = ApiClient();

  /// Creates a new user with role-based validation for school admins
  Future<Map<String, dynamic>> createUser({
    required String schoolId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
    String? address,
    String? className,
    String? stream,
  }) async {
    // Validate that school admin can create this role
    final allowedRoles = ['teacher', 'student', 'parent', 'non_teaching_staff'];
    
    if (!allowedRoles.contains(role)) {
      throw Exception('School admin can only create roles: ${allowedRoles.join(', ')}');
    }

    // Hash password
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    // Create user data
    final userData = {
      'email': email,
      'password_hash': hashedPassword,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'school_id': int.tryParse(schoolId) ?? 0,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (address != null) 'address': address,
      if (className != null) 'class': className,
      if (stream != null) 'stream': stream,
    };

    final response = await _apiClient.post('/api/schools/$schoolId/users', body: userData);
    
    if (response == null) {
      throw Exception('Failed to create user');
    }

    return response;
  }

  /// Gets users in the school with optional filtering
  Future<List<Map<String, dynamic>>> getUsers({
    required String schoolId,
    String? role,
    String? search,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    
    if (role != null) queryParams['role'] = role;
    if (search != null) queryParams['search'] = search;
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get('/api/schools/$schoolId/users', queryParameters: queryParams);
    
    if (response == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response);
  }

  /// Updates user role (school admin only)
  Future<void> updateUserRole(String userId, String schoolId, Map<String, dynamic> updateData) async {
    final response = await _apiClient.put('/api/schools/$schoolId/users/$userId', body: updateData);
    
    if (response == null) {
      throw Exception('Failed to update user role');
    }
  }

  /// Deletes a user (school admin only)
  Future<void> deleteUser(String userId, String schoolId) async {
    final response = await _apiClient.delete('/api/schools/$schoolId/users/$userId');
    
    if (response == null) {
      throw Exception('Failed to delete user');
    }
  }

  /// Bulk user creation from CSV/Excel data
  Future<Map<String, dynamic>> createBulkUsers({
    required String schoolId,
    required List<Map<String, dynamic>> users,
  }) async {
    final response = await _apiClient.post('/api/schools/$schoolId/users/bulk', body: {'users': users});
    
    if (response == null) {
      throw Exception('Failed to create bulk users');
    }

    return response;
  }

  /// Gets available classes for user assignment
  Future<List<Map<String, dynamic>>> getClasses(String schoolId) async {
    final response = await _apiClient.get('/api/schools/$schoolId/streams');
    
    if (response == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response);
  }

  /// Assigns users to classes
  Future<void> assignUsersToClasses({
    required String schoolId,
    required Map<String, List<String>> assignments,
  }) async {
    final response = await _apiClient.post('/api/schools/$schoolId/users/assignments', body: assignments);
    
    if (response == null) {
      throw Exception('Failed to assign users to classes');
    }
  }
}

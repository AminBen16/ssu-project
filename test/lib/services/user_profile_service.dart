import 'dart:developer' as developer;

import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/models/user_roles.dart';
import 'package:flutter/material.dart' show Color, ThemeMode, debugPrint;
import 'package:test/services/api_client.dart';

/// A service class for managing user profile data in Firestore.
class UserProfileService {
  final _apiClient = ApiClient();

  /// Fetches a single user profile once.
  Future<UserProfile?> getUser(String uid) async {
    final response = await _apiClient.get('/users/$uid');

    if (response != null) {
      developer.log('User profile response: $response');
      try {
        final userProfile =
            UserProfile.fromMap(response as Map<String, dynamic>, uid);
        developer.log(
            'Parsed userProfile - isFirstTimeSetupComplete: ${userProfile.isFirstTimeSetupComplete}');
        developer.log('Parsed userProfile - role: ${userProfile.role}');
        return userProfile;
      } catch (e, stackTrace) {
        developer.log('=== DETAILED ERROR DEBUGGING ===');
        developer.log('Error type: ${e.runtimeType}');
        developer.log('Error message: $e');
        developer.log('Stack trace: $stackTrace');
        developer.log('Response data: $response');
        developer.log('Response type: ${response.runtimeType}');
        developer.log('Response keys: ${(response as Map).keys}');

        // Try to identify which field is causing the issue
        final responseMap = response as Map<String, dynamic>;
        responseMap.forEach((key, value) {
          developer.log('Field "$key": $value (type: ${value.runtimeType})');
        });

        return null;
      }
    }
    return null;
  }

  /// Returns a stream of the user's profile.
  ///
  /// Currently implemented as a one-time fetch wrapped in a stream for compatibility.
  /// Real-time updates would require WebSocket implementation in the backend.
  Stream<UserProfile?> streamUserProfile(String uid) {
    // One-time fetch wrapped in a stream for UI compatibility
    // Real-time updates would require WebSocket connection here
    return Stream.fromFuture(getUser(uid));
  }

  /// Updates a user's profile data in Firestore.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _apiClient.put('/users/$uid', body: data);
  }

  /// Updates user settings, including profile picture, theme, etc.
  /// Now properly handles multipart file uploads for profile pictures.
  Future<void> updateUserSettings({
    required String userId,
    Uint8List? profileImageBytes,
    bool isPictureRemoved = false,
    Color? themeColor,
    ThemeMode? themeMode,
    bool? isFirstTimeSetupComplete,
    String? firstName,
    String? lastName,
    String? title,
    String? phoneNumber,
    String? address,
    String? qualification,
  }) async {
    // Log the start of the update process
    developer.log('Starting updateUserSettings for user: $userId');

    final settingsData = <String, dynamic>{};

    // Add text fields for settings
    if (themeColor != null) {
      settingsData['themeColor'] = themeColor.toARGB32().toString();
    }
    if (themeMode != null) {
      settingsData['themeMode'] = themeMode.name;
    }
    if (isFirstTimeSetupComplete == true) {
      settingsData['isFirstTimeSetupComplete'] = true;
    }
    if (isPictureRemoved) {
      settingsData['isPictureRemoved'] = 'true';
    }
    if (firstName != null) settingsData['firstName'] = firstName;
    if (lastName != null) settingsData['lastName'] = lastName;
    if (title != null) settingsData['title'] = title;
    if (phoneNumber != null) settingsData['phoneNumber'] = phoneNumber;
    if (address != null) settingsData['address'] = address;
    if (qualification != null) settingsData['qualification'] = qualification;

    developer.log('Settings Data: $settingsData');

    try {
      // Create multipart request using ApiClient
      await _apiClient.sendMultipartRequest(
        '/users/$userId/profile-picture',
        fields: settingsData.isNotEmpty
            ? {'settings': jsonEncode(settingsData)}
            : null,
        files: profileImageBytes != null && profileImageBytes.isNotEmpty
            ? [
                http.MultipartFile.fromBytes(
                  'profile_picture',
                  profileImageBytes,
                  filename: 'profile_picture.jpg',
                  contentType: MediaType('image', 'jpeg'),
                ),
              ]
            : null,
      );

      developer.log('Profile settings updated successfully');
    } catch (e) {
      developer.log('Error updating user settings: $e');
      rethrow;
    }
  }

  /// Changes the current user's password.
  ///
  /// This now sends the current and new password to a secure backend endpoint.
  Future<void> changeUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post('/api/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });

    // ApiClient should throw an exception on failure, so no need to check status code here.
  }

  /// Deletes the currently authenticated user's own account.
  /// This calls a secure backend endpoint that verifies the user via their JWT.
  Future<void> deleteOwnUserAccount(String uid) async {
    // This endpoint is for a user to delete themselves.
    // The server will use the JWT to authorize the action.
    await _apiClient.delete('/users/$uid');
  }

  /// Deletes any user's account by their UID.
  ///
  /// This is an administrative action and requires admin privileges.
  Future<void> deleteUser(String uid) async {
    // This endpoint is now admin-only.
    await _apiClient.delete('/admin/users/$uid');
  }

  /// Creates a new user (staff member) in the system.
  /// This is an administrative action and requires admin privileges.
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    String? title,
    String? phoneNumber,
    String? address,
    String? nin,
    String? qualification,
    String? schoolId,
    List<String>? subjectCodes,
    List<String>? teachingClasses,
    List<String>? teachingDays,
  }) async {
    try {
      // Hash password like UserManagementService does
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      final userData = {
        'email': email,
        'password_hash':
            hashedPassword, // Use hashed password like UserManagementService
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        'school_id': int.tryParse(schoolId ?? '') ??
            0, // Convert to integer like UserManagementService
        if (title != null) 'title': title,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (address != null) 'address': address,
        if (nin != null) 'nin': nin,
        if (qualification != null) 'qualification': qualification,
        // Add teaching-related fields if provided
        if (subjectCodes != null && subjectCodes.isNotEmpty)
          'subject_codes': subjectCodes.join(','),
        if (teachingClasses != null && teachingClasses.isNotEmpty)
          'teaching_classes': teachingClasses.join(','),
        if (teachingDays != null && teachingDays.isNotEmpty)
          'teaching_days': teachingDays.join(','),
      };

      developer.log('Sending user data: ${userData.keys.toList()}');
      developer.log('School ID type: ${userData['school_id'].runtimeType}');
      developer.log('Making API call to: /api/schools/$schoolId/users');

      try {
        final response = await _apiClient
            .post('/api/schools/$schoolId/users', body: userData)
            .timeout(const Duration(seconds: 30));

        developer.log('API response received: $response');
        developer.log('Response type: ${response.runtimeType}');

        if (response != null) {
          developer.log('Staff creation successful');
          developer.log(
              'Response keys: ${response is Map ? response.keys.toList() : 'Not a map'}');
          return response;
        } else {
          developer.log('Server returned null response');
          throw Exception('Server returned no response');
        }
      } on TimeoutException {
        developer.log('Request timed out after 30 seconds');
        throw Exception(
            'Request timed out. Please check your connection and try again.');
      }
    } catch (e) {
      // Re-throw with more context
      if (e.toString().contains('403')) {
        throw Exception(
            'Access denied. You may not have permission to create this type of user.');
      } else if (e.toString().contains('401')) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.toString().contains('400')) {
        throw Exception('Invalid data provided. Please check all fields.');
      } else if (e.toString().contains('500')) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to create user: ${e.toString()}');
      }
    }
  }

  /// Fetches a list of all users. This is an admin-only action.
  Future<(List<UserProfile> users, int totalCount)> getAllUsers({
    int page = 1,
    int limit = 20,
    String? searchQuery,
  }) async {
    final queryParameters = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
    };

    final response =
        await _apiClient.get('/admin/users', queryParameters: queryParameters);

    if (response != null) {
      final List<dynamic> userList = response['users'] ?? [];
      final int totalCount = response['totalCount'] ?? 0;

      // Create basic user objects for admin list (avoiding full UserProfile complexity)
      final users = userList.map((json) {
        final userJson = json as Map<String, dynamic>;
        return UserProfile(
          id: userJson['id']?.toString() ?? '',
          uid: userJson['id']?.toString() ?? '',
          email: userJson['email']?.toString() ?? '',
          firstName: userJson['first_name']?.toString() ?? '',
          lastName: userJson['last_name']?.toString() ?? '',
          role: UserRole.fromString(userJson['role']?.toString() ?? 'pending'),
          // Set defaults for other fields to avoid parsing issues
          isFirstTimeSetupComplete:
              userJson['is_first_time_setup_complete']?.toString() == '1',
          preferredLanguage: userJson['preferred_language']?.toString() ?? '',
          schoolId: userJson['school_id']?.toString() ?? '',
          themeMode: userJson['theme_mode']?.toString() ?? '',
          themeColor: userJson['theme_color'] is int
              ? userJson['theme_color'] as int
              : int.tryParse(userJson['theme_color']?.toString() ?? ''),
          profilePictureUrl: userJson['profile_picture_url']?.toString() ?? '',
          qualification: userJson['qualification']?.toString() ?? '',
          title: userJson['title']?.toString() ?? '',
          phoneNumber: userJson['phone_number']?.toString() ?? '',
          address: userJson['address']?.toString() ?? '',
          nin: userJson['nin']?.toString() ?? '',
          dateOfBirth: null,
          sex: userJson['sex']?.toString() ?? '',
          maritalStatus: userJson['marital_status']?.toString() ?? '',
          subjectCodes: null,
          teachingClasses: null,
          teachingDays: null,
          userRegId: userJson['user_reg_id']?.toString() ?? '',
          salary: null,
          allowances: null,
          plan: userJson['plan']?.toString() ?? '',
        );
      }).toList();

      return (users, totalCount);
    } else {
      throw Exception('Failed to fetch users.');
    }
  }

  /// Check if a user exists by email (for verification purposes)
  Future<bool> checkUserExists(String email) async {
    try {
      final response =
          await _apiClient.get('/admin/users?search=$email&limit=1');
      if (response != null && response['users'] != null) {
        final List<dynamic> users = response['users'];
        return users.isNotEmpty;
      }
      return false;
    } catch (e) {
      developer.log('Error checking user existence: $e');
      return false;
    }
  }
}

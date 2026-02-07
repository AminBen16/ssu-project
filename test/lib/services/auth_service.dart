import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/custom_exceptions.dart';
import 'package:test/services/api_client.dart';

/// A service class to handle all authentication and user data logic.
class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();

  // JWT Token Keys
  static const _jwtTokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';

  /// Creates a new user account via the backend.
  Future<void> createAccount({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? role,
  }) async {
    final body = {'email': email, 'password': password};
    if (firstName != null && firstName.isNotEmpty) {
      body['firstName'] = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      body['lastName'] = lastName;
    }
    if (role != null && role.isNotEmpty) {
      body['role'] = role;
    }

    final responseData = await _apiClient.post(
      '/auth/register',
      body: body,
    );

    // Account created. The backend auto-logs in the user and returns tokens.
    await _storeTokensFromResponse(responseData);
  }

  /// Signs in a user with email and password via the backend.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final responseData = await _apiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      await _storeTokensFromResponse(responseData);
    } on ApiException {
      // Example of handling a specific error type if ApiClient provides it
      // For now, we rethrow a more specific exception for the UI to handle.
      throw UserProfileNotFoundException();
    }
  }

  /// Signs in an admin user with email and password via the dedicated admin endpoint.
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final responseData = await _apiClient.post(
        '/auth/admin-login',
        body: {'email': email, 'password': password},
      );
      await _storeTokensFromResponse(responseData);
    } on ApiException {
      throw UserProfileNotFoundException();
    }
  }

  /// Sends a password reset request to the backend.
  Future<void> resetPassword({required String email}) async {
    await _apiClient.post('/auth/forgot-password', body: {'email': email});
  }

  /// Signs out the current user and clears all local tokens.
  Future<void> signOut({bool clearRememberMe = false}) async {
    // Clear JWTs and any other sensitive stored credentials.
    await _secureStorage.delete(key: _jwtTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    
    // Optionally clear remember me preference
    if (clearRememberMe) {
      await _secureStorage.delete(key: 'remember_me');
    }

    // Optionally, notify the backend to invalidate the refresh token.
    // This is a good security practice but can be ignored for simplicity.
    // final token = await _secureStorage.read(key: _refreshTokenKey);
    // if (token != null) {
    //   await http.post(Uri.parse('$_baseUrl/auth/logout'), ...);
    // }
  }

  /// Verifies the user's current password against the backend for re-authentication.
  /// Returns `true` if the password is correct, `false` otherwise.
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      // ApiClient will throw on non-2xx status codes.
      // If this line completes without an exception, it was successful.
      await _apiClient
          .post('/api/verify-password', body: {'password': password});
      return true;
    } catch (e) {
      debugPrint('Re-authentication failed: $e');
      return false;
    }
  }

  /// Checks if a valid JWT token exists.
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: _jwtTokenKey);
    // In a real app, you would also check if the token is expired.
    // For now, we just check for presence.
    return token != null;
  }

  /// Helper to parse and store tokens from a backend response.
  Future<void> _storeTokensFromResponse(dynamic responseData) async {
    try {
      final String? token = responseData['token'];
      final String? refreshToken = responseData['refreshToken'];

      if (token == null) {
        throw Exception('No access token received from server');
      }
      
      await _secureStorage.write(key: _jwtTokenKey, value: token);
      
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (e) {
      debugPrint('Could not parse or store tokens: $e');
      // Re-throw the exception so the UI can handle it properly
      throw Exception('Failed to store authentication tokens: ${e.toString()}');
    }
  }
}

import 'dart:convert';
import 'package:test/services/api_client.dart';

class EmailVerificationService {
  final ApiClient _apiClient = ApiClient();

  /// Verify email using token
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await _apiClient.post(
        '/auth/verify-email',
        body: {'token': token},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Email verification failed');
      }
    } catch (e) {
      throw Exception('Failed to verify email: ${e.toString()}');
    }
  }

  /// Resend verification email
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/resend-verification',
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to resend verification email');
      }
    } catch (e) {
      throw Exception('Failed to resend verification email: ${e.toString()}');
    }
  }
}

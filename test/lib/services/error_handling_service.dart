import 'package:flutter/foundation.dart';
import 'package:test/services/platform_channels.dart';

/// Centralized error handling service for SSU system
/// Provides consistent error reporting and user feedback
class ErrorHandlingService {
  final MeshPlatformChannels _meshChannels;

  ErrorHandlingService(this._meshChannels);

  /// Handles API errors with user-friendly messages
  static String getErrorMessage(String errorCode,
      {Map<String, dynamic>? context = const {}}) {
    switch (errorCode) {
      case 'NETWORK_ERROR':
        return 'Network connection failed. Please check your internet connection and try again.';
      case 'AUTHENTICATION_FAILED':
        return 'Invalid username or password. Please check your credentials and try again.';
      case 'PERMISSION_DENIED':
        return 'Permission denied. Please grant the required permissions and try again.';
      case 'VALIDATION_ERROR':
        final field = context?['field'] ?? 'field';
        return 'Invalid $field. Please correct the error and try again.';
      case 'SERVER_ERROR':
        return 'Server error occurred. Please try again later.';
      case 'DATABASE_ERROR':
        return 'Database error occurred. Please restart the app and try again.';
      case 'FILE_NOT_FOUND':
        return 'Requested file or resource not found.';
      case 'INVALID_ROLE':
        return 'You do not have permission to perform this action.';
      case 'OFFLINE_MODE':
        return 'This action requires an internet connection. Please connect to the internet and try again.';
      case 'SYNC_CONFLICT':
        return 'Data synchronization conflict. Please refresh and try again.';
      case 'QUOTA_EXCEEDED':
        return 'Storage quota exceeded. Please free up space and try again.';
      case 'BIOMETRIC_FAILED':
        return 'Biometric authentication failed. Please use your password to login.';
      case 'TOKEN_EXPIRED':
        return 'Your session has expired. Please log in again.';
      case 'UNKNOWN_ERROR':
        return 'An unexpected error occurred. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Logs error for debugging
  static void logError(String error,
      {String? stackTrace, Map<String, dynamic>? context = const {}}) {
    debugPrint('ERROR: $error');
    if (context != null && context.isNotEmpty) {
      debugPrint('Context: $context');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Returns error dialog data for UI layer to display
  /// This method returns data instead of showing UI directly (services should not contain UI logic)
  static Map<String, dynamic> getErrorDialogData(
    String title,
    String message, {
    String action = 'OK',
  }) {
    return {
      'title': title,
      'message': message,
      'action': action,
    };
  }

  /// Handles API response errors consistently
  static bool handleApiError(dynamic response, {Function(String)? onError}) {
    if (response is Map && response.containsKey('error')) {
      final errorMessage = getErrorMessage(
        response['error'] as String,
        context: (response['context'] as Map<dynamic, dynamic>?)
            ?.cast<String, dynamic>(),
      );
      logError('API Error: $errorMessage',
          context: response.cast<String, dynamic>());

      if (onError != null) {
        onError(errorMessage);
      }
      return true; // Error handled
    }
    return false; // No error to handle
  }

  /// Validates network connectivity before API calls
  static Future<bool> checkConnectivity() async {
    try {
      // TODO: Integrate with connectivity_plus package for real connectivity checking
      // For now, simulate connectivity check - this should be replaced with actual implementation
      // Example: final result = await Connectivity().checkConnectivity();
      // return result != ConnectivityResult.none;

      // Simulate failure to indicate this needs real implementation
      return false;
    } catch (e) {
      logError('Connectivity check failed: $e');
      return false; // Return false on error instead of suppressing
    }
  }
}

/// Custom exception for when a user is authenticated but their Firestore profile is missing.
class UserProfileNotFoundException implements Exception {
  final String message =
      'User profile not found. Please contact an administrator.';
  @override
  String toString() => message;
}

/// Custom exception for API-related errors.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

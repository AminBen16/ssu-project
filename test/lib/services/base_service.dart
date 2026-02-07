import 'package:test/services/api_client.dart';
import 'package:test/custom_exceptions.dart';

/// Base service class that provides common functionality for all API services.
/// This eliminates duplicate code across service classes.
abstract class BaseService {
  final ApiClient _apiClient;

  BaseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Gets the ApiClient instance for making HTTP requests
  ApiClient get apiClient => _apiClient;

  /// Helper method to handle common API response patterns
  /// Returns the data from a successful response or throws an exception
  dynamic handleResponse(dynamic response, {String? dataKey}) {
    if (response == null) {
      return null;
    }

    if (dataKey != null && response is Map<String, dynamic>) {
      return response[dataKey];
    }

    return response;
  }

  /// Helper method to parse list responses
  List<T> parseListResponse<T>(
    dynamic response,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = handleResponse(response, dataKey: listKey);
    if (data is List) {
      return data
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Helper method to parse single object responses
  T? parseObjectResponse<T>(
    dynamic response,
    String objectKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = handleResponse(response, dataKey: objectKey);
    if (data is Map<String, dynamic>) {
      return fromJson(data);
    }
    return null;
  }

  /// Helper method for common error handling patterns
  void handleCommonErrors(dynamic error) {
    if (error is ApiException) {
      // Re-throw ApiException as-is
      throw error;
    }

    // Handle other common error types
    if (error.toString().contains('403')) {
      throw ApiException(
          'Access denied. You may not have permission to perform this action.');
    } else if (error.toString().contains('401')) {
      throw ApiException('Authentication failed. Please log in again.');
    } else if (error.toString().contains('400')) {
      throw ApiException('Invalid data provided. Please check all fields.');
    } else if (error.toString().contains('500')) {
      throw ApiException('Server error. Please try again later.');
    } else if (error.toString().contains('404')) {
      throw ApiException('Resource not found.');
    } else {
      throw ApiException('An unexpected error occurred: ${error.toString()}');
    }
  }

  /// Validates that required parameters are not null or empty
  void validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw ArgumentError('$fieldName cannot be null or empty');
    }
  }

  /// Validates that an ID parameter is valid
  void validateId(String? id, String entityName) {
    if (id == null || id.trim().isEmpty) {
      throw ArgumentError('$entityName ID cannot be null or empty');
    }
  }
}

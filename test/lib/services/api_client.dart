import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/custom_exceptions.dart';

class ApiClient {
  // Read base URL from compile-time environment variable API_BASE_URL.
  // This allows passing --dart-define=API_BASE_URL=https://api.example.com when building.
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:8080');

  final String _serverBaseUrl;
  final _secureStorage = const FlutterSecureStorage();
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient, String? baseUrl})
      : _httpClient = httpClient ?? http.Client(),
        // Priority: explicit constructor baseUrl -> compile-time API_BASE_URL -> default localhost
        _serverBaseUrl = baseUrl ?? _envBaseUrl;

  /// Public getter for the configured server base URL.
  String get baseUrl => _serverBaseUrl;

  /// Expose token getter for use by other services
  Future<String?> getToken() async {
    return await _getToken();
  }

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Performs a GET request. [path] may be a String path or a full Uri string.
  Future<dynamic> get(String path,
      {Map<String, String>? headers,
      Map<String, String>? queryParameters}) async {
    var uri = Uri.parse('$_serverBaseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final mergedHeaders = await _mergeHeaders(headers);
    final response = await _httpClient.get(uri, headers: mergedHeaders);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      Map<String, String>? queryParameters}) async {
    var uri = Uri.parse('$_serverBaseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final mergedHeaders = await _mergeHeaders(headers);
    final response = await _httpClient.post(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      Map<String, String>? queryParameters}) async {
    var uri = Uri.parse('$_serverBaseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final mergedHeaders = await _mergeHeaders(headers);
    final response = await _httpClient.put(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path,
      {Map<String, String>? headers,
      Map<String, String>? queryParameters}) async {
    var uri = Uri.parse('$_serverBaseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final mergedHeaders = await _mergeHeaders(headers);
    final response = await _httpClient.delete(uri, headers: mergedHeaders);
    return _handleResponse(response);
  }

  /// Merge provided headers with default headers (including auth if available).
  Future<Map<String, String>> _mergeHeaders(
      Map<String, String>? headers) async {
    final defaultHeaders = await _getHeaders();
    if (headers == null || headers.isEmpty) return defaultHeaders;
    final merged = <String, String>{};
    merged.addAll(defaultHeaders);
    merged.addAll(headers);
    return merged;
  }

  Future<String> uploadImage(
      String path, Uint8List imageBytes, String filename) async {
    final uri = Uri.parse('$_serverBaseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    final token = await _getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'image', // This field name must match the one on the server
      imageBytes,
      filename: filename,
    ));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseData = jsonDecode(response.body);
      return responseData['url'];
    } else {
      final errorBody = jsonDecode(response.body);
      throw ApiException(errorBody['message'] ?? 'Failed to upload image');
    }
  }

  /// Sends a multipart request. Accepts optional fields and files.
  /// Returns decoded JSON response or raw string on failure to decode.
  Future<dynamic> sendMultipartRequest(String path,
      {Map<String, String>? fields,
      List<http.MultipartFile>? files,
      Map<String, String>? headers,
      Map<String, String>? queryParameters}) async {
    var uri = Uri.parse('$_serverBaseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final request = http.MultipartRequest('POST', uri);
    final mergedHeaders = await _mergeHeaders(headers);
    mergedHeaders.remove('Content-Type');
    mergedHeaders.remove('content-type');
    request.headers.addAll(mergedHeaders);

    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    } else {
      final errorBody =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw ApiException(errorBody['message'] ?? 'Multipart request failed');
    }
  }

  /// Backwards-compatible alias used by older callers.
  Future<dynamic> sendMultipart(String path,
          {Map<String, String>? fields,
          List<http.MultipartFile>? files,
          Map<String, String>? headers,
          Map<String, String>? queryParameters}) =>
      sendMultipartRequest(path,
          fields: fields,
          files: files,
          headers: headers,
          queryParameters: queryParameters);

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'An unknown API error occurred';
        throw ApiException(message);
      } catch (_) {
        // If the body is not JSON, use the body itself as the message.
        throw ApiException(response.body.isNotEmpty
            ? response.body
            : 'An unknown API error occurred');
      }
    }
  }
}

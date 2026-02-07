import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Centralized authentication middleware to eliminate duplicate auth logic
class AuthMiddleware {
  // JWT Secret - In production, this should be from environment variable
  static const String _jwtSecret = 'your-secret-key-change-in-production';

  /// Validates JWT token and extracts user information
  /// Returns a map with 'userId' and 'userRole' if valid, null if invalid
  static Map<String, String>? validateToken(String? authHeader) {
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }

    final token = authHeader.substring(7);

    try {
      final decoded = JWT.verify(token, SecretKey(_jwtSecret));
      final userId = decoded.subject;
      final userRole = decoded.payload['role'] as String?;

      if (userId == null || userRole == null) {
        return null;
      }

      return {
        'userId': userId,
        'userRole': userRole,
      };
    } catch (e) {
      return null;
    }
  }

  /// Creates middleware that requires valid authentication
  static Middleware requireAuth() {
    return (Handler innerHandler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];
        final userInfo = validateToken(authHeader);

        if (userInfo == null) {
          return Response(401,
              body: jsonEncode({'message': 'Authorization token required'}));
        }

        // Add user info to request context
        final updatedRequest = request.change(
          context: {
            'userId': userInfo['userId']!,
            'userRole': userInfo['userRole']!,
            ...request.context,
          },
        );

        return innerHandler(updatedRequest);
      };
    };
  }

  /// Creates middleware that requires specific roles
  static Middleware requireRole(List<String> allowedRoles) {
    return (Handler innerHandler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];
        final userInfo = validateToken(authHeader);

        if (userInfo == null) {
          return Response(401,
              body: jsonEncode({'message': 'Authorization token required'}));
        }

        final userRole = userInfo['userRole']!;
        if (!allowedRoles.contains(userRole)) {
          return Response(403,
              body: jsonEncode(
                  {'message': 'Access denied. Insufficient privileges.'}));
        }

        // Add user info to request context
        final updatedRequest = request.change(
          context: {
            'userId': userInfo['userId']!,
            'userRole': userInfo['userRole']!,
            ...request.context,
          },
        );

        return await innerHandler(updatedRequest);
      };
    };
  }

  /// Validates JWT token and returns decoded payload (for refresh token logic)
  static Map<String, dynamic>? validateTokenDetailed(String token) {
    try {
      final decoded = JWT.verify(token, SecretKey(_jwtSecret));
      return decoded.payload;
    } catch (e) {
      return null;
    }
  }

  /// Generates a JWT token with the given payload
  static String generateToken(String userId, String email, String role,
      {Duration? expiresIn}) {
    final jwt = JWT({
      'sub': userId,
      'email': email,
      'role': role,
    });
    return jwt.sign(SecretKey(_jwtSecret), expiresIn: expiresIn);
  }

  /// Generates a refresh token
  static String generateRefreshToken(String userId, {Duration? expiresIn}) {
    final jwt = JWT({
      'sub': userId,
      'type': 'refresh',
      'jti': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    return jwt.sign(SecretKey(_jwtSecret), expiresIn: expiresIn);
  }

  /// Gets the JWT secret (for backward compatibility with existing code)
  static String get jwtSecret => _jwtSecret;
}

/// Helper functions for common API responses and utilities
class ApiResponses {
  // Authentication responses
  static Response unauthorized(
      [String message = 'Authorization token required']) {
    return Response(401, body: jsonEncode({'message': message}));
  }

  static Response forbidden(
      [String message = 'Access denied. Insufficient privileges.']) {
    return Response(403, body: jsonEncode({'message': message}));
  }

  static Response invalidToken([String message = 'Invalid or expired token']) {
    return Response(401, body: jsonEncode({'message': message}));
  }

  // General API responses
  static Response badRequest([String message = 'Bad request']) {
    return Response(400, body: jsonEncode({'error': message}));
  }

  static Response notFound([String message = 'Resource not found']) {
    return Response(404, body: jsonEncode({'error': message}));
  }

  static Response internalServerError(
      [String message = 'Internal server error']) {
    return Response(500, body: jsonEncode({'error': message}));
  }

  static Response ok(dynamic data, [String message = 'Success']) {
    return Response.ok(jsonEncode({'message': message, 'data': data}));
  }

  static Response created(dynamic data,
      [String message = 'Created successfully']) {
    return Response(201, body: jsonEncode({'message': message, 'data': data}));
  }
}

/// Helper functions for request processing
class RequestHelpers {
  /// Parses JSON body from request
  static Future<Map<String, dynamic>> parseJsonBody(Request request) async {
    try {
      final bodyString = await request.readAsString();
      return jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON body');
    }
  }

  /// Validates that required fields are present in the request body
  static void validateRequiredFields(
      Map<String, dynamic> body, List<String> requiredFields) {
    final missingFields = requiredFields
        .where((field) => !body.containsKey(field) || body[field] == null)
        .toList();
    if (missingFields.isNotEmpty) {
      throw ArgumentError(
          'Missing required fields: ${missingFields.join(', ')}');
    }
  }
}

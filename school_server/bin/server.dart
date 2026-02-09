import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as path;
import '../lib/database_service.dart';
import '../lib/auth_middleware.dart';
import '../services/real_email_service.dart';
import 'package:dotenv/dotenv.dart';

late final DatabaseService dbService;
late final MessagingWebSocketServer
    wsServer; // Declare wsServer for WebSocket server

// Simple in-memory session store (in production, use Redis or database)
final Map<String, String> _activeSessions = {};

// Simple in-memory rate limiting middleware
Middleware _rateLimit(
    {int maxRequests = 5, Duration window = const Duration(minutes: 1)}) {
  final Map<String, List<DateTime>> _requests = {};

  return (Handler innerHandler) {
    return (Request request) async {
      final clientIp = request.requestedUri.host;
      final now = DateTime.now();

      // Clean old requests
      _requests[clientIp] = (_requests[clientIp] ?? [])
          .where((time) => now.difference(time) < window)
          .toList();

      // Check rate limit
      if ((_requests[clientIp]?.length ?? 0) >= maxRequests) {
        return Response(429,
            body: jsonEncode(
                {'message': 'Too many requests. Please try again later.'}));
      }

      // Add current request
      _requests[clientIp] = [...(_requests[clientIp] ?? []), now];

      return innerHandler(request);
    };
  };
}

// Handler declarations
Future<Response> _registerHandler(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final firstName = body['firstName'] as String?;
    final lastName = body['lastName'] as String?;

    if (email == null || password == null) {
      return Response(400,
          body: jsonEncode({'error': 'Email and password are required'}));
    }

    // Check if a user already exists.
    final userCount = await dbService.getTotalUserCount();
    if (userCount > 0) {
      return Response(403,
          body: jsonEncode({
            'error':
                'An administrator account already exists. Public registration is not available.'
          }));
    }

    // If we're here, it's the first user. They become chief_admin.
    const assignedRole = 'chief_admin';

    // Hash password
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    // Create user
    final userData = {
      'role': assignedRole,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    };

    final newUser = await dbService.createUser(
      email: email,
      hashedPassword: hashedPassword,
      otherData: userData,
    );

    // Generate JWT token
    final token = AuthMiddleware.generateToken(
      newUser['id'].toString(),
      newUser['email'].toString(),
      newUser['role'].toString(),
    );

    return Response.ok(jsonEncode({
      'token': token,
      'user': {
        'id': newUser['id'],
        'email': newUser['email'],
        'firstName': (newUser['first_name'] ?? '') as String,
        'lastName': (newUser['last_name'] ?? '') as String,
        'role': newUser['role'],
      }
    }));
  } catch (e) {
    print('Registration error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _loginHandler(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response(400,
          body: jsonEncode({'message': 'Email and password are required'}));
    }

    // Find user
    final user = await dbService.findUserByEmail(email);
    if (user == null) {
      return Response(401,
          body: jsonEncode(
              {'message': 'No account found with this email address'}));
    }

    // Check if email is verified (skip for system admin and chief_admin)
    final isEmailVerified =
        await dbService.isUserEmailVerified(user['id'].toString());
    final userRole = user['role'] as String;
    if (!isEmailVerified &&
        !['system_admin', 'chief_admin'].contains(userRole)) {
      return Response(401,
          body: jsonEncode({
            'message':
                'Please verify your email address before logging in. Check your inbox for the verification email.',
            'requiresEmailVerification': true,
            'email': user['email']
          }));
    }

    // Verify password
    final isValidPassword = BCrypt.checkpw(password, user['password_hash']);
    if (!isValidPassword) {
      return Response(401, body: jsonEncode({'message': 'Incorrect password'}));
    }

    // Generate JWT token
    final jwt = JWT({
      'sub': user['id'],
      'email': user['email'],
      'role': user['role'],
    });
    final token = jwt.sign(SecretKey(AuthMiddleware.jwtSecret),
        expiresIn: Duration(hours: 1));

    // Generate refresh token (longer-lived)
    final refreshJwt = JWT({
      'sub': user['id'],
      'type': 'refresh',
      'jti':
          DateTime.now().millisecondsSinceEpoch.toString(), // Unique identifier
    });
    final refreshToken = refreshJwt.sign(SecretKey(AuthMiddleware.jwtSecret),
        expiresIn: Duration(days: 30));

    // Store session (in production, use proper session store)
    _activeSessions[user['id'].toString()] = refreshToken;

    return Response.ok(jsonEncode({
      'token': token,
      'refreshToken': refreshToken,
      'user': {
        'id': user['id'],
        'email': user['email'],
        'firstName': user['first_name'],
        'lastName': user['last_name'],
        'role': user['role'],
      }
    }));
  } catch (e) {
    print('Login error: $e');
    return Response(500,
        body: jsonEncode({'message': 'Internal server error'}));
  }
}

Future<Response> _refreshTokenHandler(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    final refreshToken = body['refreshToken'] as String?;

    if (refreshToken == null) {
      return Response(400,
          body: jsonEncode({'message': 'Refresh token is required'}));
    }

    try {
      final decoded =
          JWT.verify(refreshToken, SecretKey(AuthMiddleware.jwtSecret));

      if (decoded.payload['type'] != 'refresh') {
        return Response(401,
            body: jsonEncode({'message': 'Invalid refresh token'}));
      }

      final userId = decoded.payload['sub'] as String?;

      if (userId == null) {
        return Response(401,
            body: jsonEncode({'message': 'Invalid refresh token'}));
      }

      // Get user from database
      final user = await dbService.findUserById(userId);
      if (user == null) {
        return Response(401, body: jsonEncode({'message': 'User not found'}));
      }

      // Check if this refresh token has been used before (implement token blacklist)
      final isBlacklisted = await dbService.isTokenBlacklisted(refreshToken);
      if (isBlacklisted) {
        return Response(401,
            body:
                jsonEncode({'message': 'Refresh token has been invalidated'}));
      }

      // Invalidate old session by blacklisting the old refresh token
      await dbService.blacklistToken(refreshToken, 'refresh', userId);
      _activeSessions.remove(userId);

      // Generate new access token
      final jwt = JWT({
        'sub': user['id'],
        'email': user['email'],
        'role': user['role'],
      });
      final newToken = jwt.sign(SecretKey(AuthMiddleware.jwtSecret),
          expiresIn: Duration(hours: 1));

      // Generate new refresh token (rotation)
      final newRefreshJwt = JWT({
        'sub': user['id'],
        'type': 'refresh',
        'jti': DateTime.now()
            .millisecondsSinceEpoch
            .toString(), // Unique identifier
      });
      final newRefreshToken = newRefreshJwt.sign(
          SecretKey(AuthMiddleware.jwtSecret),
          expiresIn: Duration(days: 30));

      // Store new session
      _activeSessions[user['id'].toString()] = newRefreshToken;

      return Response.ok(jsonEncode({
        'token': newToken,
        'refreshToken': newRefreshToken, // Return new refresh token
      }));
    } catch (e) {
      return Response(401,
          body: jsonEncode({'message': 'Invalid or expired refresh token'}));
    }
  } catch (e) {
    print('Refresh token error: $e');
    return Response(500,
        body: jsonEncode({'message': 'Internal server error'}));
  }
}

Future<Response> _adminLoginHandler(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response(400,
          body: jsonEncode({'message': 'Email and password are required'}));
    }

    // Find user
    final user = await dbService.findUserByEmail(email);
    if (user == null) {
      return Response(401,
          body: jsonEncode(
              {'message': 'No account found with this email address'}));
    }

    // Verify password
    final isValidPassword = BCrypt.checkpw(password, user['password_hash']);
    if (!isValidPassword) {
      return Response(401, body: jsonEncode({'message': 'Incorrect password'}));
    }

    // Check if user has admin role
    final userRole = user['role'] as String?;
    final adminRoles = ['chief_admin', 'system_admin', 'school_admin'];
    if (userRole == null || !adminRoles.contains(userRole)) {
      return Response(403,
          body: jsonEncode(
              {'message': 'Access denied. Admin privileges required.'}));
    }

    // Generate JWT token
    final jwt = JWT({
      'sub': user['id'],
      'email': user['email'],
      'role': user['role'],
    });
    final token = jwt.sign(SecretKey(AuthMiddleware.jwtSecret),
        expiresIn: Duration(hours: 1));

    // Generate refresh token (longer-lived)
    final refreshJwt = JWT({
      'sub': user['id'],
      'type': 'refresh',
      'jti':
          DateTime.now().millisecondsSinceEpoch.toString(), // Unique identifier
    });
    final refreshToken = refreshJwt.sign(SecretKey(AuthMiddleware.jwtSecret),
        expiresIn: Duration(days: 30));

    // Store session (in production, use proper session store)
    _activeSessions[user['id'].toString()] = refreshToken;

    return Response.ok(jsonEncode({
      'token': token,
      'refreshToken': refreshToken,
      'user': {
        'id': user['id'],
        'email': user['email'],
        'firstName': user['first_name'],
        'lastName': user['last_name'],
        'role': user['role'],
      }
    }));
  } catch (e) {
    print('Admin login error: $e');
    return Response(500,
        body: jsonEncode({'message': 'Internal server error'}));
  }
}

Future<Response> _forgotPasswordHandler(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    final email = body['email'] as String?;

    if (email == null) {
      return Response(400, body: jsonEncode({'message': 'Email is required'}));
    }

    // Find user
    final user = await dbService.findUserByEmail(email);
    if (user == null) {
      // Don't reveal if email exists for security
      return Response.ok(jsonEncode({
        'message':
            'If an account with this email exists, a password reset link has been sent.'
      }));
    }

    // Generate password reset token and send email
    final resetToken =
        await dbService.createPasswordResetToken(user['email'], user['id']);

    // In a real implementation, you would send an email here
    // For now, we'll return the token in the response for testing
    print('Password reset token generated for email: $email');
    print('Reset token: $resetToken');

    return Response.ok(jsonEncode({
      'message':
          'If an account with this email exists, a password reset link has been sent.',
      'resetToken': resetToken, // Only for development/testing
    }));
  } catch (e) {
    print('Forgot password error: $e');
    return Response(500,
        body: jsonEncode({'message': 'Internal server error'}));
  }
}

Future<Response> _verifyPasswordHandler(Request request) async {
  try {
    final authHeader = request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'error': 'Authorization required'}));
    }

    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(AuthMiddleware.jwtSecret));
    final userId = jwt.payload['userId'] ?? jwt.payload['sub'];

    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Invalid token'}));
    }

    final body = jsonDecode(await request.readAsString());
    final password = body['password'] as String?;

    if (password == null) {
      return Response(400, body: jsonEncode({'error': 'Password required'}));
    }

    final user = await dbService.findUserById(userId.toString());
    if (user == null) {
      return Response(404, body: jsonEncode({'error': 'User not found'}));
    }

    final isValidPassword = BCrypt.checkpw(password, user['password_hash']);
    if (!isValidPassword) {
      return Response(401, body: jsonEncode({'error': 'Incorrect password'}));
    }

    return Response.ok(
        jsonEncode({'message': 'Password verified successfully'}));
  } catch (e) {
    print('Password verification error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _resetPasswordHandler(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    final token = body['token'] as String?;
    final newPassword = body['newPassword'] as String?;

    if (token == null || newPassword == null) {
      return Response(400,
          body: jsonEncode({'message': 'Token and new password are required'}));
    }

    // Find the reset token
    final resetTokenData = await dbService.findPasswordResetToken(token);
    if (resetTokenData == null) {
      return Response(400,
          body: jsonEncode({'message': 'Invalid or expired reset token'}));
    }

    // Mark token as used
    await dbService.markPasswordResetTokenAsUsed(token);

    // Hash the new password
    final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

    // Update user password
    await dbService.updateUserSettings(resetTokenData['user_id'].toString(), {
      'password_hash': hashedPassword,
    });

    return Response.ok(jsonEncode({'message': 'Password reset successfully'}));
  } catch (e) {
    print('Reset password error: $e');
    return Response(500,
        body: jsonEncode({'message': 'Internal server error'}));
  }
}

Future<Response> _deleteHandler(Request request) async {
  try {
    final itemType = request.params['itemType']!;
    final itemId = int.parse(request.params['itemId']!);

    await dbService.delete(itemType, itemId);

    return Response.ok(jsonEncode({'message': 'Item deleted successfully'}));
  } catch (e) {
    print('Delete error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateUserSettingsHandler(Request request) async {
  try {
    final userId = request.params['userId'];
    if (userId == null) {
      return Response(400, body: jsonEncode({'error': 'User ID is required'}));
    }

    // --- Authorization Check ---
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'error': 'Authorization required'}));
    }
    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(AuthMiddleware.jwtSecret));
    final requesterId = (jwt.payload['sub'] ?? '0').toString();

    // A user can only update their own settings.
    if (requesterId != userId) {
      return Response(403,
          body: jsonEncode({'error': 'Insufficient permissions.'}));
    }

    final settingsToUpdate = <String, dynamic>{};

    // Check if this is a multipart request (file upload)
    final contentType = request.headers['content-type'] ?? '';
    if (contentType.startsWith('multipart/form-data')) {
      // Handle file upload using proper binary handling
      final boundary = contentType.split('boundary=')[1];
      final boundaryBytes = '--$boundary'.codeUnits;
      final bodyBytes = await request.read().expand((bytes) => bytes).toList();

      String? profilePictureUrl;

      // Find the start of the profile picture part
      final profilePictureHeader = 'name="profile_picture"'.codeUnits;
      final headerIndex = _findBytes(bodyBytes, profilePictureHeader);

      if (headerIndex != -1) {
        // Find the end of headers (double CRLF)
        final crlfCrlf = '\r\n\r\n'.codeUnits;
        final headerEndIndex =
            _findBytes(bodyBytes, crlfCrlf, startIndex: headerIndex);

        if (headerEndIndex != -1) {
          // Find the start of the next boundary
          final nextBoundaryIndex = _findBytes(bodyBytes, boundaryBytes,
              startIndex: headerEndIndex + 4);

          // Extract binary image data
          final imageDataStart = headerEndIndex + 4;
          final imageDataEnd = nextBoundaryIndex != -1
              ? nextBoundaryIndex - 2
              : bodyBytes.length;

          if (imageDataStart < imageDataEnd) {
            final fileBytes = bodyBytes.sublist(imageDataStart, imageDataEnd);

            if (fileBytes.isNotEmpty) {
              // Create uploads directory if it doesn't exist
              final uploadsDir = Directory('public/uploads');
              if (!await uploadsDir.exists()) {
                await uploadsDir.create(recursive: true);
              }

              // Generate unique filename
              final uniqueFilename =
                  '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final filePath = path.join(uploadsDir.path, uniqueFilename);

              // Save file as binary bytes
              final file = File(filePath);
              await file.writeAsBytes(fileBytes);

              // Generate URL for the uploaded file
              profilePictureUrl =
                  'http://localhost:8080/uploads/$uniqueFilename';
              print(
                  'Profile picture saved: $filePath (${fileBytes.length} bytes)');
            }
          }
        }
      }

      // Parse settings from the remaining data
      final settingsHeader = 'name="settings"'.codeUnits;
      final settingsIndex = _findBytes(bodyBytes, settingsHeader);

      if (settingsIndex != -1) {
        final crlfCrlf = '\r\n\r\n'.codeUnits;
        final settingsHeaderEnd =
            _findBytes(bodyBytes, crlfCrlf, startIndex: settingsIndex);

        if (settingsHeaderEnd != -1) {
          final nextBoundaryIndex = _findBytes(bodyBytes, boundaryBytes,
              startIndex: settingsHeaderEnd + 4);
          final settingsDataStart = settingsHeaderEnd + 4;
          final settingsDataEnd = nextBoundaryIndex != -1
              ? nextBoundaryIndex - 2
              : bodyBytes.length;

          if (settingsDataStart < settingsDataEnd) {
            final settingsBytes =
                bodyBytes.sublist(settingsDataStart, settingsDataEnd);
            final settingsStr = String.fromCharCodes(settingsBytes);
            try {
              final settingsJson =
                  jsonDecode(settingsStr) as Map<String, dynamic>;
              settingsToUpdate.addAll(settingsJson);
            } catch (e) {
              print('Error parsing settings: $e');
            }
          }
        }
      }

      // Update profile picture URL if uploaded
      if (profilePictureUrl != null) {
        settingsToUpdate['profilePictureUrl'] = profilePictureUrl;
      }
    } else {
      // Handle regular JSON request (for non-file updates)
      final body = jsonDecode(await request.readAsString());
      print('Received settings data: $body');
      settingsToUpdate.addAll(body as Map<String, dynamic>);
    }

    if (settingsToUpdate.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'No settings provided to update'}));
    }

    // Update database
    await dbService.updateUserSettings(userId, settingsToUpdate);

    return Response.ok(jsonEncode({
      'message': 'Settings updated successfully',
      'profilePictureUrl': settingsToUpdate['profilePictureUrl'],
    }));
  } catch (e) {
    print('Update user settings error: $e');
    if (e is JWTExpiredException || e is JWTInvalidException) {
      return Response(401,
          body: jsonEncode({'error': 'Invalid or expired token.'}));
    }
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getUsersHandler(Request request) async {
  try {
    // --- Authorization Check ---
    final authHeader = request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'error': 'Authorization required'}));
    }
    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(AuthMiddleware.jwtSecret));
    final requesterId = (jwt.payload['sub'] ?? '0').toString();

    // Get requester's profile to check if they're admin
    final requesterProfile = await dbService.findUserById(requesterId);
    if (requesterProfile == null) {
      return Response(404, body: jsonEncode({'error': 'User not found'}));
    }

    // Check if user is admin
    final role = requesterProfile['role'] as String?;
    if (role != 'chief_admin' && role != 'school_admin') {
      return Response(403,
          body: jsonEncode({'error': 'Admin access required'}));
    }

    // Parse pagination parameters
    final url = request.requestedUri;
    final page = int.tryParse(url.queryParameters['page'] ?? '1') ?? 1;
    final limit = int.tryParse(url.queryParameters['limit'] ?? '20') ?? 20;
    final offset = (page - 1) * limit;

    // Get users from database
    final users = await dbService.getAllUsers(limit, offset);
    final totalCount = await dbService.getTotalUserCount();

    final response = jsonEncode({
      'users': users,
      'totalCount': totalCount,
    });
    print('Sending response: $response');
    return Response.ok(response);
  } catch (e) {
    print('Get users error: $e');
    if (e is JWTExpiredException || e is JWTInvalidException) {
      return Response(401,
          body: jsonEncode({'error': 'Invalid or expired token.'}));
    }
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getAllSchoolsHandler(Request request) async {
  try {
    final schools = await dbService.getAllSchools();
    print('Schools data: $schools');
    return Response.ok(jsonEncode({
      'schools': schools,
    }));
  } catch (e) {
    print('Get all schools error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getSchoolHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final school = await dbService.findSchoolById(schoolId);
    if (school == null) {
      return Response(404, body: jsonEncode({'error': 'School not found'}));
    }

    return Response.ok(jsonEncode({
      'school': school,
    }));
  } catch (e) {
    print('Get school error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getUserHandler(Request request) async {
  print('Get user handler called');
  try {
    final userId = request.params['userId'];
    if (userId == null) {
      return Response(400, body: jsonEncode({'error': 'User ID is required'}));
    }

    final user = await dbService.findUserById(userId);

    if (user == null) {
      return Response(404, body: jsonEncode({'error': 'User not found'}));
    }

    // Remove sensitive information before sending the response
    user.remove('password_hash');

    return Response.ok(jsonEncode(user));
  } catch (e) {
    print('Get user error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getTeacherConstraintsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final teacherId = request.params['teacherId']!;
    final constraints =
        await dbService.getTeacherConstraints(schoolId, teacherId);
    return Response.ok(jsonEncode(constraints));
  } catch (e) {
    print('Get teacher constraints error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _setTimetableConstraintHandler(Request request) async {
  try {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.setTimetableConstraint(body);
    return Response.ok(jsonEncode({'message': 'Constraint set successfully'}));
  } catch (e) {
    print('Set constraint error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getSchemeOfWorkHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final subject = request.params['subject']!;
    final className = request.params['className']!;
    final term = request.params['term']!;
    final year = int.parse(request.params['year']!);
    final scheme = await dbService.getSchemeOfWork(
        schoolId, subject, className, term, year);
    final schemes = scheme['schemes'];
    if (schemes == null || (schemes is List && schemes.isEmpty)) {
      return Response(404,
          body: jsonEncode({'error': 'Scheme of work not found'}));
    }
    return Response.ok(jsonEncode(scheme));
  } catch (e) {
    print('Get scheme of work error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _saveSchemeOfWorkHandler(Request request) async {
  try {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.saveSchemeOfWork(body);
    return Response.ok(
        jsonEncode({'message': 'Scheme of work saved successfully'}));
  } catch (e) {
    print('Save scheme of work error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _saveFullClassTimetableHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final className = request.params['className']!;
    final rawBody = jsonDecode(await request.readAsString());
    if (rawBody is! List) {
      return Response(400,
          body: jsonEncode({'error': 'Expected list of lessons'}));
    }
    final body = rawBody as List<dynamic>;
    final lessons = body.map((e) => e as Map<String, dynamic>).toList();
    await dbService.saveFullClassTimetable(schoolId, className, lessons);
    return Response.ok(jsonEncode({'message': 'Timetable saved successfully'}));
  } catch (e) {
    print('Save full timetable error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _removeTimetableLessonHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final className = request.params['className']!;
    final day = request.params['day']!;
    final slotId = request.params['slotId']!;
    await dbService.removeTimetableLesson(schoolId, className, day, slotId);
    return Response.ok(jsonEncode({'message': 'Lesson removed successfully'}));
  } catch (e) {
    print('Remove lesson error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getTeacherTimetableHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final teacherId = request.params['teacherId']!;
    final lessons =
        await dbService.getTeacherTimetableLessons(schoolId, teacherId);
    return Response.ok(jsonEncode(lessons));
  } catch (e) {
    print('Get teacher timetable error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getClassTimetableHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final className = request.params['className']!;
    final lessons =
        await dbService.getClassTimetableLessons(schoolId, className);
    return Response.ok(jsonEncode(lessons));
  } catch (e) {
    print('Get class timetable error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _setTimetableLessonHandler(Request request) async {
  try {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.setTimetableLesson(body);
    return Response.ok(jsonEncode({'message': 'Lesson set successfully'}));
  } catch (e) {
    print('Set lesson error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getTimetableConstraintsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final constraints = await dbService.getSubjectConstraints(schoolId);
    return Response.ok(jsonEncode(constraints));
  } catch (e) {
    print('Get constraints error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _saveTimetableConstraintsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId']!;
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.saveSubjectConstraints(schoolId, body);
    return Response.ok(
        jsonEncode({'message': 'Constraints saved successfully'}));
  } catch (e) {
    print('Save constraints error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateSchoolSettingsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final authHeader = request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'error': 'Authorization required'}));
    }

    try {
      final token = authHeader.substring(7);
      JWT.verify(token, SecretKey(AuthMiddleware.jwtSecret));
      // In a real application, you would verify the user's role and school association here.
    } catch (e) {
      return Response(401, body: jsonEncode({'error': 'Invalid token'}));
    }

    final body = jsonDecode(await request.readAsString());
    final selfRegistrationEnabled = body['selfRegistrationEnabled'];

    if (selfRegistrationEnabled is! bool) {
      return Response(400,
          body: jsonEncode(
              {'error': 'selfRegistrationEnabled must be a boolean'}));
    }

    await dbService.updateSchoolSettings(schoolId,
        selfRegistrationEnabled: selfRegistrationEnabled);

    return Response.ok(
        jsonEncode({'message': 'School settings updated successfully'}));
  } catch (e) {
    print('Update school settings error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _createSchoolHandler(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    print('School creation request body: $body');

    final schoolName = body['schoolName'] as String?;
    final adminFirstName = body['adminFirstName'] as String?;
    final adminLastName = body['adminLastName'] as String?;
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final classification = body['classification'] as String?;

    print(
        'Parsed fields: schoolName=$schoolName, adminFirstName=$adminFirstName, adminLastName=$adminLastName, email=$email, classification=$classification');

    if (schoolName == null ||
        adminFirstName == null ||
        adminLastName == null ||
        email == null ||
        password == null) {
      print('Missing required fields');
      return Response(400,
          body: jsonEncode({'error': 'All fields are required'}));
    }

    // Check if any users exist. If so, only Chief Admin can create schools.
    final userCount = await dbService.getTotalUserCount();
    print('Current user count: $userCount');

    if (userCount > 0) {
      final authHeader = request.headers['Authorization'];
      print('Auth header: $authHeader');

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        print('No auth header found');
        return Response(403,
            body: jsonEncode(
                {'error': 'Only the Chief Admin can create schools.'}));
      }
      try {
        final token = authHeader.substring(7);
        final jwt = JWT.verify(token, SecretKey(AuthMiddleware.jwtSecret));
        if (jwt.payload['role'] != 'chief_admin') {
          return Response(403,
              body: jsonEncode({'error': 'Insufficient permissions.'}));
        }
      } catch (e) {
        return Response(403, body: jsonEncode({'error': 'Invalid token.'}));
      }
    }

    // Check if school already exists
    print('Checking if school already exists: $schoolName');
    final existingSchool = await dbService.findSchoolByName(schoolName);
    if (existingSchool != null) {
      print('School already exists: ${existingSchool['name']}');
      return Response(409,
          body: jsonEncode({'error': 'School already exists'}));
    }
    print('School name is available');

    // Check if admin email already exists
    print('Checking if admin email already exists: $email');
    final existingUser = await dbService.findUserByEmail(email);
    if (existingUser != null) {
      print('Admin email already exists: ${existingUser['email']}');
      return Response(409,
          body: jsonEncode({'error': 'Admin email already exists'}));
    }
    print('Admin email is available');

    // Hash password
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    // Create school
    final newSchool = await dbService.createSchool(
      name: schoolName,
      classification: body['classification'] ?? 'Primary',
    );

    // Create admin user
    final adminData = {
      'email': email,
      'password_hash': hashedPassword,
      'first_name': adminFirstName,
      'last_name': adminLastName,
      'role': 'school_admin',
      'school_id': newSchool['id'],
    };

    final newUser = await dbService.createUser(
      email: email,
      hashedPassword: hashedPassword,
      otherData: adminData,
    );

    // Generate verification token
    final verificationToken = RealEmailService.generateSecureTokenWithSignature(
      newUser['id'].toString(),
      email,
    );

    // Store verification token in database
    final expiresAt = DateTime.now().add(Duration(hours: 24));
    await dbService.createEmailVerificationToken(
        newUser['id'].toString(), verificationToken, expiresAt);

    // Send verification email (async, don't block response)
    RealEmailService.sendEmailVerification(
      email: email,
      firstName: adminFirstName,
      verificationToken: verificationToken,
    ).then((success) {
      if (success) {
        print('Verification email sent to $email');
      } else {
        print('Failed to send verification email to $email');
      }
    });

    // Generate JWT token
    final jwt = JWT({
      'sub': newUser['id'],
      'email': newUser['email'],
      'role': newUser['role'],
    });
    final token = jwt.sign(SecretKey(AuthMiddleware.jwtSecret));

    return Response.ok(jsonEncode({
      'message':
          'School created successfully. Please check your email for verification.',
      'requiresEmailVerification': true,
      'school': {
        'id': newSchool['id'],
        'name': newSchool['name'],
      },
      'token': token,
      'user': {
        'id': newUser['id'],
        'email': newUser['email'],
        'firstName': newUser['first_name'],
        'lastName': newUser['last_name'],
        'role': newUser['role'],
      }
    }));
  } catch (e) {
    print('School creation error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Helper function to find a byte pattern in a byte array
int _findBytes(List<int> haystack, List<int> needle, {int startIndex = 0}) {
  if (needle.isEmpty || haystack.isEmpty || startIndex >= haystack.length) {
    return -1;
  }

  for (int i = startIndex; i <= haystack.length - needle.length; i++) {
    bool found = true;
    for (int j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        found = false;
        break;
      }
    }
    if (found) {
      return i;
    }
  }
  return -1;
}

Future<Response> _uploadSchoolLogoHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    // Handle multipart form data
    final contentType = request.headers['content-type'] ?? '';
    if (!contentType.startsWith('multipart/form-data')) {
      return Response(400,
          body: jsonEncode({'error': 'Multipart form data required'}));
    }

    final boundary = contentType.split('boundary=')[1];
    final boundaryBytes = '--$boundary'.codeUnits;
    final bodyBytes = await request.read().expand((bytes) => bytes).toList();

    // Find the logo file part
    final logoHeader = 'name="logo"'.codeUnits;
    final headerIndex = _findBytes(bodyBytes, logoHeader);

    if (headerIndex == -1) {
      return Response(400,
          body: jsonEncode({'error': 'Logo file is required'}));
    }

    // Find the end of headers (double CRLF)
    final crlfCrlf = '\r\n\r\n'.codeUnits;
    final headerEndIndex =
        _findBytes(bodyBytes, crlfCrlf, startIndex: headerIndex);

    if (headerEndIndex == -1) {
      return Response(400, body: jsonEncode({'error': 'Invalid file format'}));
    }

    // Find the start of the next boundary
    final nextBoundaryIndex =
        _findBytes(bodyBytes, boundaryBytes, startIndex: headerEndIndex + 4);

    // Extract binary image data
    final imageDataStart = headerEndIndex + 4;
    final imageDataEnd =
        nextBoundaryIndex != -1 ? nextBoundaryIndex - 2 : bodyBytes.length;

    if (imageDataStart >= imageDataEnd) {
      return Response(400, body: jsonEncode({'error': 'Empty file'}));
    }

    final fileBytes = bodyBytes.sublist(imageDataStart, imageDataEnd);

    if (fileBytes.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Empty file'}));
    }

    // Create uploads directory if it doesn't exist
    final uploadsDir = Directory('public/uploads');
    if (!await uploadsDir.exists()) {
      await uploadsDir.create(recursive: true);
    }

    // Generate unique filename
    final uniqueFilename =
        'school_${schoolId}_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = path.join(uploadsDir.path, uniqueFilename);

    // Save file as binary bytes
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    // Generate URL for the uploaded file
    final logoUrl = 'http://localhost:8080/uploads/$uniqueFilename';

    // Update school record with logo URL
    await dbService.updateSchoolLogoUrl(schoolId, logoUrl);

    print('School logo saved: $filePath (${fileBytes.length} bytes)');

    return Response.ok(jsonEncode({
      'message': 'Logo uploaded successfully',
      'url': logoUrl,
    }));
  } catch (e) {
    print('Upload school logo error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateSchoolGeneralSettingsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    await dbService.updateSchoolGeneralSettings(schoolId, body);

    return Response.ok(
        jsonEncode({'message': 'School settings updated successfully'}));
  } catch (e) {
    print('Update school settings error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getFeesSummaryHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    // For now, return dummy data since we don't have fee tables yet
    final summary = {
      'totalExpected': 0.0,
      'totalCollected': 0.0,
      'totalPending': 0.0,
      'studentCount': 0,
    };

    return Response.ok(jsonEncode(summary));
  } catch (e) {
    print('Get fees summary error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateSchoolHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    // Here we need to update the school using the more comprehensive update method.
    // For simplicity, reusing updateSchoolGeneralSettings, but a dedicated method
    // in dbService might be better for full school object updates.
    await dbService.updateSchoolGeneralSettings(schoolId, body);
    return Response.ok(jsonEncode({'message': 'School updated successfully'}));
  } catch (e) {
    print('Update school error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _deleteSchoolHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    await dbService.delete('schools', int.parse(schoolId));
    return Response.ok(jsonEncode({'message': 'School deleted successfully'}));
  } catch (e) {
    print('Delete school error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Class management handlers
Future<Response> _createClassHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final newClass = await dbService.createClass(
      schoolId: schoolId,
      name: body['name'],
      gradeLevel: body['gradeLevel'],
    );
    return Response(201, body: jsonEncode(newClass));
  } catch (e) {
    print('Create class error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getClassesBySchoolHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    final classes = await dbService.getClassesBySchool(schoolId);
    return Response.ok(jsonEncode({'classes': classes}));
  } catch (e) {
    print('Get classes by school error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getClassHandler(Request request) async {
  try {
    final classId = request.params['classId'];
    if (classId == null) {
      return Response(400, body: jsonEncode({'error': 'Class ID is required'}));
    }
    final classData = await dbService.findClassById(classId);
    if (classData == null) {
      return Response(404, body: jsonEncode({'error': 'Class not found'}));
    }
    return Response.ok(jsonEncode(classData));
  } catch (e) {
    print('Get class error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateClassHandler(Request request) async {
  try {
    final classId = request.params['classId'];
    if (classId == null) {
      return Response(400, body: jsonEncode({'error': 'Class ID is required'}));
    }
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.updateClass(classId, body);
    return Response.ok(jsonEncode({'message': 'Class updated successfully'}));
  } catch (e) {
    print('Update class error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _deleteClassHandler(Request request) async {
  try {
    final classId = request.params['classId'];
    if (classId == null) {
      return Response(400, body: jsonEncode({'error': 'Class ID is required'}));
    }
    await dbService.deleteClass(classId);
    return Response.ok(jsonEncode({'message': 'Class deleted successfully'}));
  } catch (e) {
    print('Delete class error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Subject management handlers
Future<Response> _createSubjectHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final newSubject = await dbService.createSubject(
      schoolId: schoolId,
      name: body['name'],
      description: body['description'],
    );
    return Response(201, body: jsonEncode(newSubject));
  } catch (e) {
    print('Create subject error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getSubjectsBySchoolHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    final subjects = await dbService.getSubjectsBySchool(schoolId);
    return Response.ok(jsonEncode({'subjects': subjects}));
  } catch (e) {
    print('Get subjects by school error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getSubjectHandler(Request request) async {
  try {
    final subjectId = request.params['subjectId'];
    if (subjectId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Subject ID is required'}));
    }
    final subjectData = await dbService.findSubjectById(subjectId);
    if (subjectData == null) {
      return Response(404, body: jsonEncode({'error': 'Subject not found'}));
    }
    return Response.ok(jsonEncode(subjectData));
  } catch (e) {
    print('Get subject error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateSubjectHandler(Request request) async {
  try {
    final subjectId = request.params['subjectId'];
    if (subjectId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Subject ID is required'}));
    }
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.updateSubject(subjectId, body);
    return Response.ok(jsonEncode({'message': 'Subject updated successfully'}));
  } catch (e) {
    print('Update subject error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _deleteSubjectHandler(Request request) async {
  try {
    final subjectId = request.params['subjectId'];
    if (subjectId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Subject ID is required'}));
    }
    await dbService.deleteSubject(subjectId);
    return Response.ok(jsonEncode({'message': 'Subject deleted successfully'}));
  } catch (e) {
    print('Delete subject error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Exam Results management handlers
Future<Response> _createExamResultHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final newResult = await dbService.createExamResult(
      schoolId: schoolId,
      examId: body['examId'].toString(),
      studentId: body['studentId'].toString(),
      subjectId: body['subjectId'].toString(),
      marksObtained: body['marksObtained'],
      totalMarks: body['totalMarks'],
      recordedBy: body['recordedBy'].toString(),
      grade: body['grade'],
      comments: body['comments'],
    );
    return Response(201, body: jsonEncode(newResult));
  } catch (e) {
    print('Create exam result error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getExamResultHandler(Request request) async {
  try {
    final resultId = request.params['resultId'];
    if (resultId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Result ID is required'}));
    }
    final resultData = await dbService.getExamResultById(resultId);
    if (resultData == null) {
      return Response(404,
          body: jsonEncode({'error': 'Exam result not found'}));
    }
    return Response.ok(jsonEncode(resultData));
  } catch (e) {
    print('Get exam result error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getExamResultsByExamHandler(Request request) async {
  try {
    final examId = request.params['examId'];
    if (examId == null) {
      return Response(400, body: jsonEncode({'error': 'Exam ID is required'}));
    }
    final results = await dbService.getExamResultsByExam(examId);
    return Response.ok(jsonEncode({'results': results}));
  } catch (e) {
    print('Get exam results by exam error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getExamResultsByStudentHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    if (studentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Student ID is required'}));
    }
    final results = await dbService.getExamResultsByStudent(studentId);
    return Response.ok(jsonEncode({'results': results}));
  } catch (e) {
    print('Get exam results by student error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateExamResultHandler(Request request) async {
  try {
    final resultId = request.params['resultId'];
    if (resultId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Result ID is required'}));
    }
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.updateExamResult(resultId, body);
    return Response.ok(
        jsonEncode({'message': 'Exam result updated successfully'}));
  } catch (e) {
    print('Update exam result error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _deleteExamResultHandler(Request request) async {
  try {
    final resultId = request.params['resultId'];
    if (resultId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Result ID is required'}));
    }
    await dbService.deleteExamResult(resultId);
    return Response.ok(
        jsonEncode({'message': 'Exam result deleted successfully'}));
  } catch (e) {
    print('Delete exam result error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Individual student retrieval handler
Future<Response> _getStudentHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    if (studentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Student ID is required'}));
    }

    // Get student from database
    final studentRows = await dbService.query('''
      SELECT s.*, u.first_name, u.last_name, u.email, u.role,
             c.name as class_name, sch.name as school_name,
             GROUP_CONCAT(DISTINCT sp.parent_user_id) as parent_ids,
             GROUP_CONCAT(DISTINCT CONCAT(pu.first_name, ' ', pu.last_name)) as parent_names,
             GROUP_CONCAT(DISTINCT s.subject_codes) as subject_codes,
             GROUP_CONCAT(DISTINCT subj.name) as subject_names
      FROM students s
      LEFT JOIN users u ON s.user_id = u.id
      LEFT JOIN classes c ON s.class_id = c.id
      LEFT JOIN schools sch ON s.school_id = sch.id
      LEFT JOIN student_parents sp ON s.id = sp.student_id
      LEFT JOIN users pu ON sp.parent_user_id = pu.id
      LEFT JOIN subjects subj ON FIND_IN_SET(subj.code, s.subject_codes)
      WHERE s.id = ?
      GROUP BY s.id
    ''', [int.tryParse(studentId) ?? 0]);

    if (studentRows.isEmpty) {
      return Response(404, body: jsonEncode({'error': 'Student not found'}));
    }

    final student = studentRows.first;

    // Transform to Student model format
    final studentData = {
      'id': student['id'].toString(),
      'first_name': student['first_name'] ?? '',
      'last_name': student['last_name'] ?? '',
      'student_reg_id': student['admission_number']?.toString() ?? '',
      'class_name': student['class_name'] ?? 'N/A',
      'school_id': student['school_id'].toString(),
      'parent_ids': student['parent_ids']?.split(',') ?? [],
      'parent_names': student['parent_names']?.split(',') ?? [],
      'subject_codes': student['subject_codes']?.split(',') ?? [],
      'subject_names': student['subject_names']?.split(',') ?? [],
      'email': student['email'] ?? '',
      'date_of_birth': student['date_of_birth'],
      'sex': student['sex'],
      'religion': student['religion'],
      'phone_number': student['phone_number'],
      'address': student['address'],
      'parent_name': student['parent_name'],
      'parent_nin': student['parent_nin'],
      'parent_contact': student['parent_contact'],
      'special_needs': student['special_needs'],
      'admission_number': student['admission_number']?.toString() ?? '',
    };

    return Response.ok(jsonEncode({'student': studentData}));
  } catch (e) {
    print('Get student error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Student search handler with advanced filtering
Future<Response> _searchStudentsHandler(Request request) async {
  try {
    final uri = request.requestedUri;
    final queryParams = uri.queryParameters;

    // Build search conditions
    final whereConditions = <String>[];
    final values = <dynamic>[];

    // Text search (name, email, admission number)
    if (queryParams.containsKey('q') && queryParams['q']!.isNotEmpty) {
      final searchTerm = '%${queryParams['q']}%';
      whereConditions.add('''
        (u.first_name LIKE ? OR u.last_name LIKE ? OR u.email LIKE ? OR s.admission_number LIKE ?)
      ''');
      values.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
    }

    // Class filter
    if (queryParams.containsKey('class') && queryParams['class']!.isNotEmpty) {
      whereConditions.add('c.name = ?');
      values.add(queryParams['class']);
    }

    // School filter
    final schoolIdStr = queryParams['schoolId'];
    if (schoolIdStr != null && schoolIdStr.isNotEmpty) {
      final schoolId = int.tryParse(schoolIdStr);
      if (schoolId != null) {
        whereConditions.add('s.school_id = ?');
        values.add(schoolId);
      }
    }

    // Sex filter
    if (queryParams.containsKey('sex') && queryParams['sex']!.isNotEmpty) {
      whereConditions.add('s.sex = ?');
      values.add(queryParams['sex']);
    }

    // Religion filter
    if (queryParams.containsKey('religion') &&
        queryParams['religion']!.isNotEmpty) {
      whereConditions.add('s.religion = ?');
      values.add(queryParams['religion']);
    }

    // Build query
    String sql = '''
      SELECT s.*, u.first_name, u.last_name, u.email, u.role,
             c.name as class_name, sch.name as school_name,
             GROUP_CONCAT(DISTINCT sp.parent_user_id) as parent_ids,
             GROUP_CONCAT(DISTINCT s.subject_codes) as subject_codes
      FROM students s
      LEFT JOIN users u ON s.user_id = u.id
      LEFT JOIN classes c ON s.class_id = c.id
      LEFT JOIN schools sch ON s.school_id = sch.id
      LEFT JOIN student_parents sp ON s.id = sp.student_id
    ''';

    if (whereConditions.isNotEmpty) {
      sql += ' WHERE ${whereConditions.join(' AND ')}';
    }

    sql += ' GROUP BY s.id ORDER BY u.first_name, u.last_name';

    // Add pagination
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
    final offset = (page - 1) * limit;

    sql += ' LIMIT ? OFFSET ?';
    values.addAll([limit, offset]);

    final studentRows = await dbService.query(sql, values);

    // Transform results
    final students = studentRows
        .map((student) => {
              'id': student['id'].toString(),
              'first_name': student['first_name'] ?? '',
              'last_name': student['last_name'] ?? '',
              'student_reg_id': student['admission_number'],
              'class_name': student['class_name'] ?? 'N/A',
              'school_id': student['school_id'].toString(),
              'parent_ids': student['parent_ids']?.split(',') ?? [],
              'subject_codes': student['subject_codes']?.split(',') ?? [],
              'email': student['email'] ?? '',
              'date_of_birth': student['date_of_birth'],
              'sex': student['sex'],
              'religion': student['religion'],
              'phone_number': student['phone_number'],
              'address': student['address'],
              'parent_name': student['parent_name'],
              'parent_nin': student['parent_nin'],
              'parent_contact': student['parent_contact'],
              'special_needs': student['special_needs'],
              'admission_number': student['admission_number'],
            })
        .toList();

    // Get total count for pagination
    String countSql =
        'SELECT COUNT(DISTINCT s.id) as total FROM students s LEFT JOIN users u ON s.user_id = u.id LEFT JOIN classes c ON s.class_id = c.id';
    if (whereConditions.isNotEmpty) {
      countSql += ' WHERE ${whereConditions.join(' AND ')}';
    }
    final countResult = await dbService.query(
        countSql, values.sublist(0, values.length - 2)); // Remove limit/offset
    final totalCount = countResult.first['total'] as int? ?? 0;

    return Response.ok(jsonEncode({
      'students': students,
      'totalCount': totalCount,
      'page': page,
      'limit': limit,
      'totalPages': (totalCount / limit).ceil(),
    }));
  } catch (e) {
    print('Search students error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Students by class handler
Future<Response> _getStudentsByClassHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final className = request.params['className'];

    if (schoolId == null || className == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID and Class Name are required'}));
    }

    final uri = request.requestedUri;
    final queryParams = uri.queryParameters;

    // Build query
    String sql = '''
      SELECT s.*, u.first_name, u.last_name, u.email, u.role,
             c.name as class_name, sch.name as school_name,
             GROUP_CONCAT(DISTINCT sp.parent_user_id) as parent_ids,
             GROUP_CONCAT(DISTINCT s.subject_codes) as subject_codes
      FROM students s
      LEFT JOIN users u ON s.user_id = u.id
      LEFT JOIN classes c ON s.class_id = c.id
      LEFT JOIN schools sch ON s.school_id = sch.id
      LEFT JOIN student_parents sp ON s.id = sp.student_id
      WHERE s.school_id = ? AND c.name = ?
      GROUP BY s.id
      ORDER BY u.first_name, u.last_name
    ''';

    final values = [int.tryParse(schoolId) ?? 0, className];

    // Add pagination
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final limit = int.tryParse(queryParams['limit'] ?? '50') ?? 50;
    final offset = (page - 1) * limit;

    sql += ' LIMIT ? OFFSET ?';
    values.addAll([limit, offset]);

    final studentRows = await dbService.query(sql, values);

    // Transform results
    final students = studentRows
        .map((student) => {
              'id': student['id'].toString(),
              'first_name': student['first_name'] ?? '',
              'last_name': student['last_name'] ?? '',
              'student_reg_id': student['admission_number'],
              'class_name': student['class_name'] ?? 'N/A',
              'school_id': student['school_id'].toString(),
              'parent_ids': student['parent_ids']?.split(',') ?? [],
              'subject_codes': student['subject_codes']?.split(',') ?? [],
              'email': student['email'] ?? '',
              'date_of_birth': student['date_of_birth'],
              'sex': student['sex'],
              'religion': student['religion'],
              'phone_number': student['phone_number'],
              'address': student['address'],
              'parent_name': student['parent_name'],
              'parent_nin': student['parent_nin'],
              'parent_contact': student['parent_contact'],
              'special_needs': student['special_needs'],
              'admission_number': student['admission_number'],
            })
        .toList();

    // Get total count
    final countResult = await dbService.query('''
      SELECT COUNT(*) as total FROM students s
      LEFT JOIN classes c ON s.class_id = c.id
      WHERE s.school_id = ? AND c.name = ?
    ''', [int.tryParse(schoolId) ?? 0, className]);
    final totalCount = countResult.first['total'] as int? ?? 0;

    return Response.ok(jsonEncode({
      'students': students,
      'totalCount': totalCount,
      'page': page,
      'limit': limit,
      'totalPages': (totalCount / limit).ceil(),
      'className': className,
    }));
  } catch (e) {
    print('Get students by class error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Students by parent handler
Future<Response> _getStudentsByParentHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final parentId = request.params['parentId'];

    if (schoolId == null || parentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID and Parent ID are required'}));
    }

    final uri = request.requestedUri;
    final queryParams = uri.queryParameters;

    // Build query
    String sql = '''
      SELECT s.*, u.first_name, u.last_name, u.email, u.role,
             c.name as class_name, sch.name as school_name,
             GROUP_CONCAT(DISTINCT sp.parent_user_id) as parent_ids,
             GROUP_CONCAT(DISTINCT s.subject_codes) as subject_codes
      FROM students s
      LEFT JOIN users u ON s.user_id = u.id
      LEFT JOIN classes c ON s.class_id = c.id
      LEFT JOIN schools sch ON s.school_id = sch.id
      LEFT JOIN student_parents sp ON s.id = sp.student_id
      WHERE s.school_id = ? AND sp.parent_user_id = ?
      GROUP BY s.id
      ORDER BY u.first_name, u.last_name
    ''';

    final values = [int.tryParse(schoolId) ?? 0, int.tryParse(parentId) ?? 0];

    // Add pagination
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final limit = int.tryParse(queryParams['limit'] ?? '50') ?? 50;
    final offset = (page - 1) * limit;

    sql += ' LIMIT ? OFFSET ?';
    values.addAll([limit, offset]);

    final studentRows = await dbService.query(sql, values);

    // Transform results
    final students = studentRows
        .map((student) => {
              'id': student['id'].toString(),
              'first_name': student['first_name'] ?? '',
              'last_name': student['last_name'] ?? '',
              'student_reg_id': student['admission_number'],
              'class_name': student['class_name'] ?? 'N/A',
              'school_id': student['school_id'].toString(),
              'parent_ids': student['parent_ids']?.split(',') ?? [],
              'subject_codes': student['subject_codes']?.split(',') ?? [],
              'email': student['email'] ?? '',
              'date_of_birth': student['date_of_birth'],
              'sex': student['sex'],
              'religion': student['religion'],
              'phone_number': student['phone_number'],
              'address': student['address'],
              'parent_name': student['parent_name'],
              'parent_nin': student['parent_nin'],
              'parent_contact': student['parent_contact'],
              'special_needs': student['special_needs'],
              'admission_number': student['admission_number'],
            })
        .toList();

    // Get total count
    final countResult = await dbService.query('''
      SELECT COUNT(*) as total FROM students s
      LEFT JOIN student_parents sp ON s.id = sp.student_id
      WHERE s.school_id = ? AND sp.parent_user_id = ?
    ''', [int.tryParse(schoolId) ?? 0, int.tryParse(parentId) ?? 0]);
    final totalCount = countResult.first['total'] as int? ?? 0;

    return Response.ok(jsonEncode({
      'students': students,
      'totalCount': totalCount,
      'page': page,
      'limit': limit,
      'totalPages': (totalCount / limit).ceil(),
      'parentId': parentId,
    }));
  } catch (e) {
    print('Get students by parent error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Student enrollment handler for comprehensive student registration
Future<Response> _enrollStudentHandler(Request request) async {
  try {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    // Extract and validate required fields
    final requiredFields = [
      'firstName',
      'lastName',
      'email',
      'password',
      'dateOfBirth',
      'className'
    ];
    for (final field in requiredFields) {
      if (!body.containsKey(field) || body[field] == null) {
        return Response(400,
            body: jsonEncode({'error': 'Missing required field: $field'}));
      }
    }

    // Convert dateOfBirth to proper format if it's in milliseconds
    String dateOfBirth;
    if (body['dateOfBirth'] is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(body['dateOfBirth']);
      dateOfBirth = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    } else {
      dateOfBirth = body['dateOfBirth'].toString();
    }

    // Extract subject codes if present
    List<String>? subjectCodes;
    if (body.containsKey('subjectCodes') && body['subjectCodes'] is List) {
      subjectCodes = List<String>.from(body['subjectCodes']);
    }

    final result = await dbService.enrollStudent(
      schoolId: body['schoolId']?.toString() ?? '0',
      firstName: body['firstName'].toString().trim(),
      lastName: body['lastName'].toString().trim(),
      email: body['email'].toString().trim(),
      password: body['password'].toString(), // Already hashed from frontend
      dateOfBirth: dateOfBirth,
      className: body['className'].toString().trim(),
      stream: body['stream']?.toString().trim() ?? '',
      sex: body['sex']?.toString(),
      religion: body['religion']?.toString(),
      address: body['address']?.toString().trim(),
      phoneNumber: body['phoneNumber']?.toString().trim(),
      parentName: body['parentName']?.toString().trim(),
      parentNin: body['parentNin']?.toString().trim(),
      parentContact: body['parentContact']?.toString().trim(),
      specialNeeds: body['specialNeeds']?.toString().trim(),
      subjectCodes: subjectCodes,
      admissionNumber: body['admissionNumber']?.toString().trim(),
    );

    // Generate secure verification token and send email for student
    if (result['user_id'] != null) {
      final verificationToken =
          RealEmailService.generateSecureTokenWithSignature(
              result['user_id'].toString(), body['email'].toString().trim());
      final expiresAt = DateTime.now().add(Duration(hours: 24));

      await dbService.createEmailVerificationToken(
          result['user_id'].toString(), verificationToken, expiresAt);

      // Get school name for email
      final school =
          await dbService.findSchoolById(body['schoolId']?.toString() ?? '0');

      // Send secure verification email (async, don't block response)
      final success = await RealEmailService.sendEmailVerification(
        email: body['email'].toString().trim(),
        firstName: body['firstName'].toString().trim(),
        verificationToken: verificationToken,
      );
      if (success) {
        print('Student secure verification email sent to ${body['email']}');
      } else {
        print(
            'Failed to send student secure verification email to ${body['email']}');
      }

      // Update response to indicate email verification required
      result['emailVerified'] = false;
      result['message'] =
          'Student enrolled successfully. Please check email for verification link.';
    }

    return Response(201, body: jsonEncode(result));
  } catch (e) {
    print('Student enrollment error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getClassesHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }
    final classes = await dbService.getClassesBySchool(schoolId);
    return Response.ok(jsonEncode({'classes': classes}));
  } catch (e) {
    print('Get classes error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getStudentsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    // Parse query parameters
    final queryParams = <String, String>{};
    final uri = request.requestedUri;
    if (uri.hasQuery) {
      uri.queryParameters.forEach((key, value) {
        queryParams[key] = value;
      });
    }

    final students = await dbService.getStudentsBySchool(schoolId, queryParams);

    return Response.ok(jsonEncode({
      'students': students,
    }));
  } catch (e) {
    print('Get students error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateSchoolStreamsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final streams = <String, List<String>>{};
    final rawStreams = body['streams'] as Map<String, dynamic>?;

    if (rawStreams == null) {
      return Response(400,
          body: jsonEncode({'error': 'Streams data is required'}));
    }

    // Convert dynamic values to List<String>
    rawStreams.forEach((key, value) {
      if (value is List) {
        streams[key] = value.map((e) => e.toString()).toList();
      }
    });

    await dbService.updateClassStreams(schoolId, streams);

    return Response.ok(jsonEncode(
        {'message': 'Class streams updated successfully', 'streams': streams}));
  } catch (e) {
    print('Update school streams error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// User management handlers for school admins
Future<Response> _createUserHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    // Validate that school admin can create this role
    final requestedRole = body['role'] as String?;
    final allowedRoles = [
      'teacher', 'student', 'parent', 'non_teaching_staff',
      'class_teacher', 'head_teacher', 'director', 'deputy_head_teacher',
      'system_admin', 'head_of_department', 'director_of_studies',
      // Ugandan School Non-Teaching Roles
      'bursar', 'school_secretary', 'librarian', 'lab_technician',
      'computer_lab_attendant', 'school_nurse', 'counselor',
      'security_guard', 'caretaker', 'cook', 'driver',
      'store_keeper', 'boarding_master'
    ];

    if (requestedRole == null || !allowedRoles.contains(requestedRole)) {
      return Response(403,
          body: jsonEncode({
            'error':
                'School admin can only create roles: ${allowedRoles.join(', ')}'
          }));
    }

    // Hash the password before storing
    final password = body['password'] as String;
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    final createdUser = await dbService.createUser(
      email: body['email'] as String,
      hashedPassword: hashedPassword,
      otherData: {
        'role': requestedRole,
        'school_id': int.tryParse(schoolId) ?? 0,
        'first_name': body['first_name'] ?? body['firstName'],
        'last_name': body['last_name'] ?? body['lastName'],
        'email_verified': false, // New users start as unverified
        // Add other fields as needed
        if (body.containsKey('phone') || body.containsKey('phone_number'))
          'phone_number': body['phone'] ?? body['phone_number'],
        if (body.containsKey('address')) 'address': body['address'],
        if (body.containsKey('teaching_classes'))
          'teaching_classes': (body['teaching_classes'] is List)
              ? (body['teaching_classes'] as List).join(',')
              : body['teaching_classes'],
        if (body.containsKey('teaching_days'))
          'teaching_days': (body['teaching_days'] is List)
              ? (body['teaching_days'] as List).join(',')
              : body['teaching_days'],
      },
    );

    // Generate secure verification token and send email
    final verificationToken = RealEmailService.generateSecureTokenWithSignature(
        createdUser['id'].toString(), body['email'] as String);
    final expiresAt = DateTime.now().add(Duration(hours: 24)); // 24 hour expiry

    await dbService.createEmailVerificationToken(
        createdUser['id'].toString(), verificationToken, expiresAt);

    // Get school name for email
    final school = await dbService.findSchoolById(schoolId);
    final schoolName = school?['name'] ?? 'Our School';

    // Send secure verification email (async, don't block response)
    final success = await RealEmailService.sendEmailVerification(
      email: body['email'] as String,
      firstName: body['first_name'] ?? body['firstName'] ?? 'User',
      verificationToken: verificationToken,
    );
    if (success) {
      print('Secure verification email sent to ${body['email']}');
    } else {
      print('Failed to send secure verification email to ${body['email']}');
    }

    return Response.ok(jsonEncode({
      'message':
          'User created successfully. Please check your email for a verification link.',
      'user': {
        'id': createdUser['id'].toString(),
        'email': body['email'],
        'role': requestedRole,
        'firstName': (createdUser['first_name'] ??
            body['first_name'] ??
            body['firstName'] ??
            '') as String,
        'lastName': (createdUser['last_name'] ??
            body['last_name'] ??
            body['lastName'] ??
            '') as String,
        'emailVerified': false,
      }
    }));
  } catch (e) {
    print('Create user error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Web verification endpoint for email links
Future<Response> _webVerifyEmailHandler(Request request) async {
  try {
    final token = request.url.queryParameters['token'];

    if (token == null || token.isEmpty) {
      return _renderVerificationPage(
        title: 'Verification Failed',
        message:
            'Invalid verification link. Please check your email and try again.',
        isSuccess: false,
      );
    }

    // Find user by verification token
    print('Looking for user with token: $token');
    final user = await dbService.findUserByVerificationToken(token);
    print('Found user: $user');

    if (user == null) {
      print('User not found for token: $token');
      return _renderVerificationPage(
        title: 'Verification Failed',
        message:
            'This verification link is invalid or has expired. Please request a new verification email.',
        isSuccess: false,
      );
    }

    // Verify the user's email
    await dbService.verifyUserEmail(user['id'].toString());

    // Get school name for welcome email
    final school = await dbService.findSchoolById(user['school_id'].toString());
    final schoolName = school?['name'] ?? 'Our School';

    // Send welcome email (async)
    final success = await RealEmailService.sendWelcomeEmail(
      email: user['email'],
      firstName: user['first_name'] ?? 'User',
      schoolName: schoolName,
    );
    if (success) {
      print('Welcome email sent to ${user['email']}');
    } else {
      print('Failed to send welcome email to ${user['email']}');
    }

    return _renderVerificationPage(
      title: 'Email Verified Successfully!',
      message:
          'Your email has been verified and your account is now active. You can now log in to your account.',
      isSuccess: true,
      userEmail: user['email'],
    );
  } catch (e) {
    print('Web email verification error: $e');
    return _renderVerificationPage(
      title: 'Verification Error',
      message:
          'An error occurred during verification. Please try again or contact support.',
      isSuccess: false,
    );
  }
}

// Render HTML verification page
Response _renderVerificationPage({
  required String title,
  required String message,
  required bool isSuccess,
  String? userEmail,
}) {
  final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 500px;
            margin: 20px;
        }
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        .success { color: #28a745; }
        .error { color: #dc3545; }
        h1 { color: #333; margin-bottom: 20px; }
        p { color: #666; line-height: 1.6; margin-bottom: 30px; }
        .btn {
            display: inline-block;
            padding: 12px 30px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 500;
            transition: background 0.3s;
        }
        .btn:hover { background: #0056b3; }
        .email-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
            border-left: 4px solid #007bff;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon ${isSuccess ? 'success' : 'error'}">
            ${isSuccess ? '✅' : '❌'}
        </div>
        <h1>$title</h1>
        <p>$message</p>
        ${isSuccess && userEmail != null ? '''
        <div class="email-info">
            <strong>Email verified:</strong> $userEmail
        </div>
        ''' : ''}
        ${isSuccess ? '''
        <a href="http://localhost:3000/login" class="btn">Go to Login</a>
        ''' : '''
        <a href="javascript:history.back()" class="btn">Go Back</a>
        '''}
    </div>
</body>
</html>
  ''';

  return Response.ok(html, headers: {'content-type': 'text/html'});
}

// Email verification handlers
Future<Response> _verifyEmailHandler(Request request) async {
  try {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final token = body['token'] as String?;

    if (token == null || token.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Verification token is required'}));
    }

    // Find user by verification token
    final user = await dbService.findUserByVerificationToken(token);

    if (user == null) {
      return Response(400,
          body: jsonEncode({'error': 'Invalid or expired verification token'}));
    }

    // Verify the user's email
    await dbService.verifyUserEmail(user['id'].toString());

    // Get school name for welcome email
    final school = await dbService.findSchoolById(user['school_id'].toString());
    final schoolName = school?['name'] ?? 'Our School';

    // Send welcome email (async)
    final success = await RealEmailService.sendWelcomeEmail(
      email: user['email'],
      firstName: user['first_name'] ?? 'User',
      schoolName: schoolName,
    );
    if (success) {
      print('Welcome email sent to ${user['email']}');
    } else {
      print('Failed to send welcome email to ${user['email']}');
    }

    return Response.ok(jsonEncode({
      'message': 'Email verified successfully! Your account is now active.',
      'user': {
        'id': user['id'].toString(),
        'email': user['email'],
        'firstName': user['first_name'],
        'lastName': user['last_name'],
        'emailVerified': true,
      }
    }));
  } catch (e) {
    print('Email verification error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _resendVerificationHandler(Request request) async {
  try {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final email = body['email'] as String?;

    if (email == null || email.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Email is required'}));
    }

    // Find user by email
    final user = await dbService.findUserByEmail(email);

    if (user == null) {
      return Response(404, body: jsonEncode({'error': 'User not found'}));
    }

    // Check if already verified
    final isVerified =
        await dbService.isUserEmailVerified(user['id'].toString());
    if (isVerified) {
      return Response(400,
          body: jsonEncode({'error': 'Email is already verified'}));
    }

    // Generate new secure verification token
    final verificationToken = RealEmailService.generateSecureTokenWithSignature(
        user['id'].toString(), user['email']);
    final expiresAt = DateTime.now().add(Duration(hours: 24));

    await dbService.createEmailVerificationToken(
        user['id'].toString(), verificationToken, expiresAt);

    // Get school name for email
    final school = await dbService.findSchoolById(user['school_id'].toString());
    final schoolName = school?['name'] ?? 'Our School';

    // Send secure verification email
    final emailSent = await RealEmailService.sendEmailVerification(
      email: email,
      firstName: user['first_name'] ?? 'User',
      verificationToken: verificationToken,
    );

    if (!emailSent) {
      return Response(500,
          body: jsonEncode({'error': 'Failed to send verification email'}));
    }

    return Response.ok(jsonEncode({
      'message':
          'Verification email sent successfully. Please check your inbox and click the verification link.',
    }));
  } catch (e) {
    print('Resend verification error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Student fee balance handler
Future<Response> _getStudentFeeBalanceHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    if (studentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Student ID is required'}));
    }

    final feeBalance = await dbService.getStudentFeeBalance(studentId);
    return Response.ok(jsonEncode(feeBalance));
  } catch (e) {
    print('Get student fee balance error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Student notifications handlers
Future<Response> _getStudentNotificationsHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    if (studentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Student ID is required'}));
    }

    final notifications = await dbService.getStudentNotifications(studentId);
    return Response.ok(jsonEncode({'notifications': notifications}));
  } catch (e) {
    print('Get student notifications error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _markNotificationAsReadHandler(Request request) async {
  try {
    final notificationId = request.params['notificationId'];
    if (notificationId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Notification ID is required'}));
    }

    await dbService.markNotificationAsRead(notificationId);
    return Response.ok(jsonEncode({'message': 'Notification marked as read'}));
  } catch (e) {
    print('Mark notification as read error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getUnreadNotificationCountHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    if (studentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Student ID is required'}));
    }

    final count = await dbService.getUnreadNotificationCount(studentId);
    return Response.ok(jsonEncode({'count': count}));
  } catch (e) {
    print('Get unread notification count error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateUserHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final userId = request.params['userId'];
    if (schoolId == null || userId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID and User ID are required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    // Only school admin can update user roles in their school
    await dbService.updateUserRole(userId, body);

    return Response.ok(jsonEncode({'message': 'User updated successfully'}));
  } catch (e) {
    print('Update user error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _deleteUserHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final userId = request.params['userId'];
    if (schoolId == null || userId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID and User ID are required'}));
    }

    await dbService.deleteUser(userId);

    return Response.ok(jsonEncode({'message': 'User deleted successfully'}));
  } catch (e) {
    print('Delete user error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Exam management handlers
Future<Response> _getExamsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final exams = await dbService.getExamsBySchool(schoolId);
    return Response.ok(jsonEncode({'exams': exams}));
  } catch (e) {
    print('Get exams error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _createExamHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    // Validate required fields
    final requiredFields = [
      'title',
      'examType',
      'totalMarks',
      'examDate',
      'created_by',
      'classId',
      'subjectId'
    ];
    for (final field in requiredFields) {
      if (!body.containsKey(field) || body[field] == null) {
        return Response(400,
            body: jsonEncode({'error': 'Missing required field: $field'}));
      }
    }

    await dbService.createExam(schoolId, {
      'title': body['title'],
      'exam_type': body['examType'],
      'total_marks': body['totalMarks'],
      'exam_date': body['examDate'],
      'created_by': body['created_by'],
      'class_id': body['classId'],
      'subject_id': body['subjectId'],
    });

    return Response(201,
        body: jsonEncode({'message': 'Exam created successfully'}));
  } catch (e) {
    print('Create exam error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateExamHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final examId = request.params['examId'];
    if (schoolId == null || examId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID and Exam ID are required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    // Construct update data, mapping API fields to database fields
    final updateData = <String, dynamic>{};
    if (body.containsKey('title')) updateData['title'] = body['title'];
    if (body.containsKey('examType'))
      updateData['exam_type'] = body['examType'];
    if (body.containsKey('totalMarks'))
      updateData['total_marks'] = body['totalMarks'];
    if (body.containsKey('examDate'))
      updateData['exam_date'] = body['examDate'];
    if (body.containsKey('classId')) updateData['class_id'] = body['classId'];
    if (body.containsKey('subjectId'))
      updateData['subject_id'] = body['subjectId'];

    if (updateData.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'No update data provided'}));
    }

    await dbService.updateExam(schoolId, examId, updateData);

    return Response.ok(jsonEncode({'message': 'Exam updated successfully'}));
  } catch (e) {
    print('Update exam error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _deleteExamHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final examId = request.params['examId'];
    if (schoolId == null || examId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID and Exam ID are required'}));
    }

    await dbService.deleteExam(schoolId, examId);

    return Response.ok(jsonEncode({'message': 'Exam deleted successfully'}));
  } catch (e) {
    print('Delete exam error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getTeacherExamsHandler(Request request) async {
  try {
    final teacherId = request.params['teacherId'];
    if (teacherId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Teacher ID is required'}));
    }

    // Get teacher's school ID
    final teacher = await dbService.findUserById(teacherId);
    if (teacher == null) {
      return Response(404, body: jsonEncode({'error': 'Teacher not found'}));
    }

    final exams = await dbService.getExamsByTeacher(
        teacher['school_id'].toString(), teacherId);
    return Response.ok(jsonEncode({'exams': exams}));
  } catch (e) {
    print('Get teacher exams error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Fee management handlers
Future<Response> _getFeeStructuresHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final structures = await dbService.getFeeStructures(schoolId);
    return Response.ok(jsonEncode({'fee_structures': structures}));
  } catch (e) {
    print('Get fee structures error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _createFeeStructureHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.createFeeStructure(schoolId, body);

    return Response(201,
        body: jsonEncode({'message': 'Fee structure created successfully'}));
  } catch (e) {
    print('Create fee structure error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateFeeStructureHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final structureId = request.params['structureId'];
    if (schoolId == null || structureId == null) {
      return Response(400,
          body:
              jsonEncode({'error': 'School ID and Structure ID are required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.updateFeeStructure(schoolId, structureId, body);

    return Response.ok(
        jsonEncode({'message': 'Fee structure updated successfully'}));
  } catch (e) {
    print('Update fee structure error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _deleteFeeStructureHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final structureId = request.params['structureId'];
    if (schoolId == null || structureId == null) {
      return Response(400,
          body:
              jsonEncode({'error': 'School ID and Structure ID are required'}));
    }

    await dbService.deleteFeeStructure(schoolId, structureId);

    return Response.ok(
        jsonEncode({'message': 'Fee structure deleted successfully'}));
  } catch (e) {
    print('Delete fee structure error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _recordFeePaymentHandler(Request request) async {
  try {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.recordFeePayment(body);

    return Response(201,
        body: jsonEncode({'message': 'Fee payment recorded successfully'}));
  } catch (e) {
    print('Record fee payment error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Student application handlers
Future<Response> _getStudentApplicationsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final applications = await dbService.getStudentApplications(schoolId);
    return Response.ok(jsonEncode({'applications': applications}));
  } catch (e) {
    print('Get student applications error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _createStudentApplicationHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.createStudentApplication(schoolId, body);

    return Response(201,
        body: jsonEncode({'message': 'Application submitted successfully'}));
  } catch (e) {
    print('Create student application error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateStudentApplicationHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final applicationId = request.params['applicationId'];
    if (schoolId == null || applicationId == null) {
      return Response(400,
          body: jsonEncode(
              {'error': 'School ID and Application ID are required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.updateStudentApplication(schoolId, applicationId, body);

    return Response.ok(
        jsonEncode({'message': 'Application updated successfully'}));
  } catch (e) {
    print('Update student application error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Salary management handlers
Future<Response> _getSalaryRecordsHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final records = await dbService.getSalaryRecords(schoolId, null);
    return Response.ok(jsonEncode({'salary_records': records}));
  } catch (e) {
    print('Get salary records error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _createSalaryRecordHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.createSalaryRecord(schoolId, body);

    return Response(201,
        body: jsonEncode({'message': 'Salary record created successfully'}));
  } catch (e) {
    print('Create salary record error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _updateSalaryRecordHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final recordId = request.params['recordId'];
    if (schoolId == null || recordId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID and Record ID are required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.updateSalaryRecord(schoolId, recordId, body);

    return Response.ok(
        jsonEncode({'message': 'Salary record updated successfully'}));
  } catch (e) {
    print('Update salary record error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getStaffSalaryRecordsHandler(Request request) async {
  try {
    final staffId = request.params['staffId'];
    if (staffId == null) {
      return Response(400, body: jsonEncode({'error': 'Staff ID is required'}));
    }

    // Get staff's school ID
    final staff = await dbService.findUserById(staffId);
    if (staff == null) {
      return Response(404, body: jsonEncode({'error': 'Staff not found'}));
    }

    final records = await dbService.getSalaryRecords(
        staff['school_id'].toString(), staffId);
    return Response.ok(jsonEncode({'salary_records': records}));
  } catch (e) {
    print('Get staff salary records error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Report card handlers
Future<Response> _getStudentReportCardsHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    if (studentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Student ID is required'}));
    }

    // Get student's school ID
    final student = await dbService.findUserById(studentId);
    if (student == null) {
      return Response(404, body: jsonEncode({'error': 'Student not found'}));
    }

    final reportCards = await dbService.getStudentReportCards(
        student['school_id'].toString(), studentId);
    return Response.ok(jsonEncode({'report_cards': reportCards}));
  } catch (e) {
    print('Get student report cards error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _createReportCardHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.createReportCard(schoolId, body);

    return Response(201,
        body: jsonEncode({'message': 'Report card created successfully'}));
  } catch (e) {
    print('Create report card error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getReportCardHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    final term = request.params['term'];
    final year = request.params['year'];
    if (studentId == null || term == null || year == null) {
      return Response(400,
          body:
              jsonEncode({'error': 'Student ID, Term, and Year are required'}));
    }

    // Get student's school ID
    final student = await dbService.findUserById(studentId);
    if (student == null) {
      return Response(404, body: jsonEncode({'error': 'Student not found'}));
    }

    final reportCard = await dbService.getReportCard(
        student['school_id'].toString(), studentId, term, year);
    return Response.ok(jsonEncode(reportCard));
  } catch (e) {
    print('Get report card error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Library management handlers
Future<Response> _getBooksHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final books = await dbService.getBooks(schoolId);
    return Response.ok(jsonEncode({'books': books}));
  } catch (e) {
    print('Get books error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _addBookHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.addBook(schoolId, body);

    return Response(201,
        body: jsonEncode({'message': 'Book added successfully'}));
  } catch (e) {
    print('Add book error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _borrowBookHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await dbService.borrowBook(schoolId, body);

    return Response(201,
        body: jsonEncode({'message': 'Book borrowed successfully'}));
  } catch (e) {
    print('Borrow book error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _returnBookHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    final borrowingId = request.params['borrowingId'];
    if (schoolId == null || borrowingId == null) {
      return Response(400,
          body:
              jsonEncode({'error': 'School ID and Borrowing ID are required'}));
    }

    await dbService.returnBook(schoolId, borrowingId);

    return Response.ok(jsonEncode({'message': 'Book returned successfully'}));
  } catch (e) {
    print('Return book error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getBorrowedBooksHandler(Request request) async {
  try {
    final studentId = request.params['studentId'];
    if (studentId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Student ID is required'}));
    }

    // Get student's school ID
    final student = await dbService.findUserById(studentId);
    if (student == null) {
      return Response(404, body: jsonEncode({'error': 'Student not found'}));
    }

    final books = await dbService.getBorrowedBooks(
        student['school_id'].toString(), studentId);
    return Response.ok(jsonEncode({'borrowed_books': books}));
  } catch (e) {
    print('Get borrowed books error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Scheme of work handlers
Future<Response> _getSchemesOfWorkHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final queryParams = <String, String>{};
    request.url.queryParameters.forEach((key, value) {
      queryParams[key] = value;
    });

    final schemes = await dbService.getSchemesOfWork(schoolId, queryParams);
    return Response.ok(jsonEncode({'schemes_of_work': schemes}));
  } catch (e) {
    print('Get schemes of work error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Lesson plan handlers
Future<Response> _getLessonPlansHandler(Request request) async {
  try {
    final teacherId = request.params['teacherId'];
    if (teacherId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Teacher ID is required'}));
    }

    // Get teacher's school ID
    final teacher = await dbService.findUserById(teacherId);
    if (teacher == null) {
      return Response(404, body: jsonEncode({'error': 'Teacher not found'}));
    }

    final queryParams = <String, String>{};
    request.url.queryParameters.forEach((key, value) {
      queryParams[key] = value;
    });

    final lessonPlans = await dbService.getLessonPlans(
        teacher['school_id'].toString(), teacherId, queryParams);
    return Response.ok(jsonEncode({'lesson_plans': lessonPlans}));
  } catch (e) {
    print('Get lesson plans error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _saveLessonPlanHandler(Request request) async {
  try {
    final schoolId = request.params['schoolId'];
    if (schoolId == null) {
      return Response(400,
          body: jsonEncode({'error': 'School ID is required'}));
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    body['school_id'] = schoolId;
    await dbService.saveLessonPlan(schoolId, body);

    return Response(201,
        body: jsonEncode({'message': 'Lesson plan saved successfully'}));
  } catch (e) {
    print('Save lesson plan error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Curriculum handlers
Future<Response> _getSubjectsHandler(Request request) async {
  try {
    final subjects = await dbService.getSubjects();
    return Response.ok(jsonEncode({'subjects': subjects}));
  } catch (e) {
    print('Get subjects error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getStrandsHandler(Request request) async {
  try {
    final subjectId = request.params['subjectId'];
    if (subjectId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Subject ID is required'}));
    }

    final strands = await dbService.getStrandsBySubject(int.parse(subjectId));
    return Response.ok(jsonEncode({'strands': strands}));
  } catch (e) {
    print('Get strands error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getTopicsHandler(Request request) async {
  try {
    final strandId = request.params['strandId'];
    if (strandId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Strand ID is required'}));
    }

    final topics = await dbService.getTopicsByStrand(int.parse(strandId));
    return Response.ok(jsonEncode({'topics': topics}));
  } catch (e) {
    print('Get topics error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getLearningOutcomesHandler(Request request) async {
  try {
    final topicId = request.params['topicId'];
    if (topicId == null) {
      return Response(400, body: jsonEncode({'error': 'Topic ID is required'}));
    }

    final outcomes =
        await dbService.getLearningOutcomesByTopic(int.parse(topicId));
    return Response.ok(jsonEncode({'learning_outcomes': outcomes}));
  } catch (e) {
    print('Get learning outcomes error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getActivitiesHandler(Request request) async {
  try {
    final outcomeId = request.params['outcomeId'];
    if (outcomeId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Outcome ID is required'}));
    }

    final activities =
        await dbService.getActivitiesByOutcome(int.parse(outcomeId));
    return Response.ok(jsonEncode({'activities': activities}));
  } catch (e) {
    print('Get activities error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _getStrategiesHandler(Request request) async {
  try {
    final outcomeId = request.params['outcomeId'];
    if (outcomeId == null) {
      return Response(400,
          body: jsonEncode({'error': 'Outcome ID is required'}));
    }

    final strategies =
        await dbService.getStrategiesByOutcome(int.parse(outcomeId));
    return Response.ok(jsonEncode({'strategies': strategies}));
  } catch (e) {
    print('Get strategies error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

Future<Response> _ingestChemistryHandler(Request request) async {
  try {
    await dbService.ingestChemistryCurriculum();
    return Response.ok(
        jsonEncode({'message': 'Chemistry curriculum ingested successfully'}));
  } catch (e) {
    print('Ingest chemistry curriculum error: $e');
    return Response(500, body: jsonEncode({'error': 'Internal server error'}));
  }
}

// Missing handlers for report cards and fees
Future<Response> _getAvailableReportTermsHandler(Request request) async {
  return Response.ok(jsonEncode({'terms': []}));
}

Future<Response> _getStudentReportCardHandler(Request request) async {
  return Response.ok(jsonEncode({'reportCard': {}}));
}

Future<Response> _generateReportCardPDFHandler(Request request) async {
  return Response.ok(jsonEncode({'pdfUrl': ''}));
}

Future<Response> _generateClassReportCardsHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Generated'}));
}

Future<Response> _addAICommentsHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Comments added'}));
}

Future<Response> _getClassPerformanceSummaryHandler(Request request) async {
  return Response.ok(jsonEncode({'summary': {}}));
}

Future<Response> _submitForApprovalHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Submitted'}));
}

Future<Response> _getPendingReportCardsHandler(Request request) async {
  return Response.ok(jsonEncode({'pending': []}));
}

Future<Response> _approveReportCardHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Approved'}));
}

Future<Response> _rejectReportCardHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Rejected'}));
}

Future<Response> _archiveOldReportCardsHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Archived'}));
}

Future<Response> _getReportCardStatisticsHandler(Request request) async {
  return Response.ok(jsonEncode({'statistics': {}}));
}

Future<Response> _getPaymentHistoryHandler(Request request) async {
  return Response.ok(jsonEncode({'payments': []}));
}

Future<Response> _recordPaymentHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Recorded'}));
}

Future<Response> _generateReceiptHandler(Request request) async {
  return Response.ok(jsonEncode({'receiptUrl': ''}));
}

Future<Response> _getStudentFeeStructureHandler(Request request) async {
  return Response.ok(jsonEncode({'structure': {}}));
}

Future<Response> _getChildFeeBalanceHandler(Request request) async {
  return Response.ok(jsonEncode({'balance': 0.0}));
}

Future<Response> _getAllChildrenFeeBalancesHandler(Request request) async {
  return Response.ok(jsonEncode({'balances': []}));
}

Future<Response> _makeFeePaymentHandler(Request request) async {
  return Response.ok(jsonEncode({'message': 'Payment made'}));
}

Future<Response> _getAllChildrenPaymentHistoryHandler(Request request) async {
  return Response.ok(jsonEncode({'history': []}));
}

Future<Response> _getFeePaymentStatsHandler(Request request) async {
  return Response.ok(jsonEncode({'stats': {}}));
}

Future<Response> _getUpcomingFeeDuesHandler(Request request) async {
  return Response.ok(jsonEncode({'dues': []}));
}

Future<Response> _getAvailablePaymentMethodsHandler(Request request) async {
  return Response.ok(jsonEncode({'methods': []}));
}

void main(List<String> args) async {
  // Load environment variables
  DotEnv(includePlatformEnvironment: true).load();

  // Initialize email service
  RealEmailService.initialize();

  // Initialize database service
  dbService = DatabaseService();
  await dbService.initialize();

  // No need to instantiate AuthMiddleware as it's a static utility class
  // final authMiddleware = AuthMiddleware(); // REMOVE THIS LINE IF IT EXISTS

  // Initialize WebSocket server
  // Pass dbService only, as AuthMiddleware methods are static
  wsServer = MessagingWebSocketServer(dbService);
  await wsServer.start(); // Start the WebSocket server

  // Start periodic cleanup of expired tokens
  Timer.periodic(Duration(hours: 1), (timer) async {
    await dbService.cleanupExpiredTokens();
    await dbService.cleanupExpiredPasswordResetTokens();
    print('Cleaned up expired tokens');
  });

  // Create router
  final router = Router();

  // Add routes here
  router.get('/', (Request request) {
    return Response.ok('Hello, World!');
  });

  // Authentication routes (with rate limiting)
  router.post('/auth/register', _rateLimit()(_registerHandler));
  router.post('/auth/login', _rateLimit()(_loginHandler));
  router.post('/auth/admin-login', _rateLimit()(_adminLoginHandler));
  router.post('/auth/refresh', _rateLimit()(_refreshTokenHandler));
  router.post('/auth/forgot-password', _rateLimit()(_forgotPasswordHandler));
  router.post('/auth/verify-password', _rateLimit()(_verifyPasswordHandler));
  router.post('/auth/reset-password', _rateLimit()(_resetPasswordHandler));

  // Email verification routes (with rate limiting)
  router.post('/auth/verify-email', _rateLimit()(_verifyEmailHandler));
  router.post(
      '/auth/resend-verification', _rateLimit()(_resendVerificationHandler));

  // Web verification route (no auth required - public link)
  router.get('/verify-email', _webVerifyEmailHandler);

  // School creation route
  router.post('/schools', _createSchoolHandler);
  router.put('/schools/<schoolId>', _updateSchoolSettingsHandler);
  router.put(
      '/api/schools/<schoolId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_updateSchoolHandler));
  router.delete(
      '/api/schools/<schoolId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_deleteSchoolHandler));

  // Class management routes
  router.post(
      '/api/schools/<schoolId>/classes',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_createClassHandler));
  router.get(
      '/api/schools/<schoolId>/classes',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher',
        'student'
      ])(_getClassesBySchoolHandler));
  router.get(
      '/api/classes/<classId>', AuthMiddleware.requireAuth()(_getClassHandler));
  router.put(
      '/api/classes/<classId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_updateClassHandler));
  router.delete(
      '/api/classes/<classId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_deleteClassHandler));

  // Subject management routes
  router.post(
      '/api/schools/<schoolId>/subjects',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_createSubjectHandler));
  router.get(
      '/api/schools/<schoolId>/subjects',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher',
        'student'
      ])(_getSubjectsBySchoolHandler));
  router.get('/api/subjects/<subjectId>',
      AuthMiddleware.requireAuth()(_getSubjectHandler));
  router.put(
      '/api/subjects/<subjectId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_updateSubjectHandler));
  router.delete(
      '/api/subjects/<subjectId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_deleteSubjectHandler));

  // Exam Result routes
  router.post(
      '/api/schools/<schoolId>/exam-results',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_createExamResultHandler));
  router.get('/api/exam-results/<resultId>',
      AuthMiddleware.requireAuth()(_getExamResultHandler));
  router.get('/api/exams/<examId>/results',
      AuthMiddleware.requireAuth()(_getExamResultsByExamHandler));
  router.get('/api/students/<studentId>/exam-results',
      AuthMiddleware.requireAuth()(_getExamResultsByStudentHandler));
  router.put(
      '/api/exam-results/<resultId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_updateExamResultHandler));
  router.delete(
      '/api/exam-results/<resultId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_deleteExamResultHandler));

  // Schools listing route (admin and school admin access)
  router.get(
      '/api/schools',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_getAllSchoolsHandler));
  router.get('/api/schools/<schoolId>', _getSchoolHandler);
  router.post('/api/schools/<schoolId>/logo',
      AuthMiddleware.requireAuth()(_uploadSchoolLogoHandler));
  router.put('/api/schools/<schoolId>/settings',
      AuthMiddleware.requireAuth()(_updateSchoolGeneralSettingsHandler));
  router.put(
      '/api/schools/<schoolId>/streams',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_updateSchoolStreamsHandler));
  router.get(
      '/api/schools/<schoolId>/classes',
      AuthMiddleware.requireRole(
          ['chief_admin', 'system_admin', 'school_admin'])(_getClassesHandler));
  router.get('/api/schools/<schoolId>/fees/summary',
      AuthMiddleware.requireAuth()(_getFeesSummaryHandler));
  router.get(
      '/api/schools/<schoolId>/users',
      AuthMiddleware.requireRole(
          ['chief_admin', 'system_admin', 'school_admin'])(_getUsersHandler));
  router.post(
      '/api/schools/<schoolId>/users',
      AuthMiddleware.requireRole(
          ['chief_admin', 'system_admin', 'school_admin'])(_createUserHandler));
  router.put(
      '/api/schools/<schoolId>/users/<userId>',
      AuthMiddleware.requireRole(
          ['chief_admin', 'system_admin', 'school_admin'])(_updateUserHandler));
  router.delete(
      '/api/schools/<schoolId>/users/<userId>',
      AuthMiddleware.requireRole(
          ['chief_admin', 'system_admin', 'school_admin'])(_deleteUserHandler));

  // Student enrollment route (school admin access)
  router.post(
      '/api/students',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_enrollStudentHandler));

  // Individual student retrieval
  router.get('/api/students/<studentId>',
      AuthMiddleware.requireAuth()(_getStudentHandler));

  // Get all students (for general listing)
  Future<Response> _getAllStudentsHandler(Request request) async {
    try {
      final queryParams = <String, String>{};
      request.url.queryParameters.forEach((key, value) {
        queryParams[key] = value;
      });

      // Get all students from all schools (admin only)
      final students = await dbService.query(
          'SELECT * FROM students ORDER BY created_at DESC',
          queryParams.isEmpty
              ? null
              : queryParams.values.toList().cast<dynamic>());
      return Response.ok(jsonEncode({'students': students}));
    } catch (e) {
      print('Get all students error: $e');
      return Response(500,
          body: jsonEncode({'error': 'Internal server error'}));
    }
  }

  router.get(
      '/api/students', AuthMiddleware.requireAuth()(_getAllStudentsHandler));

  // Student search with advanced filtering
  router.get('/api/students/search',
      AuthMiddleware.requireAuth()(_searchStudentsHandler));

  // Students by class
  router.get('/api/schools/<schoolId>/students/class/<className>',
      AuthMiddleware.requireAuth()(_getStudentsByClassHandler));

  // Students by parent
  router.get('/api/schools/<schoolId>/parents/<parentId>/students',
      AuthMiddleware.requireAuth()(_getStudentsByParentHandler));

  // Students by school (with advanced filtering)
  router.get(
      '/api/schools/<schoolId>/students',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_getStudentsHandler));

  // Student-specific routes
  router.get('/api/students/<studentId>/fee-balance',
      AuthMiddleware.requireAuth()(_getStudentFeeBalanceHandler));
  router.get('/api/students/<studentId>/notifications',
      AuthMiddleware.requireAuth()(_getStudentNotificationsHandler));
  router.put('/api/notifications/<notificationId>/read',
      AuthMiddleware.requireAuth()(_markNotificationAsReadHandler));
  router.get('/api/students/<studentId>/notifications/unread-count',
      AuthMiddleware.requireAuth()(_getUnreadNotificationCountHandler));

  // Exam management routes
  router.get(
      '/api/schools/<schoolId>/exams',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_getExamsHandler));
  router.post(
      '/api/schools/<schoolId>/exams',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_createExamHandler));
  router.put(
      '/api/schools/<schoolId>/exams/<examId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_updateExamHandler));
  router.delete(
      '/api/schools/<schoolId>/exams/<examId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_deleteExamHandler));
  router.get(
      '/api/teachers/<teacherId>/exams',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_getTeacherExamsHandler));

  // Fee management routes
  router.get(
      '/api/schools/<schoolId>/fee-structures',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_getFeeStructuresHandler));
  router.post(
      '/api/schools/<schoolId>/fee-structures',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_createFeeStructureHandler));
  router.put(
      '/api/schools/<schoolId>/fee-structures/<structureId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_updateFeeStructureHandler));
  router.delete(
      '/api/schools/<schoolId>/fee-structures/<structureId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_deleteFeeStructureHandler));
  router.post('/api/fee-payments',
      AuthMiddleware.requireAuth()(_recordFeePaymentHandler));
  router.get(
      '/api/schools/<schoolId>/fees/summary',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_getFeesSummaryHandler));

  // Student application routes
  router.get(
      '/api/schools/<schoolId>/applications',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_getStudentApplicationsHandler));
  router.post('/api/schools/<schoolId>/applications',
      AuthMiddleware.requireAuth()(_createStudentApplicationHandler));
  router.put(
      '/api/schools/<schoolId>/applications/<applicationId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_updateStudentApplicationHandler));

  // Salary management routes
  router.get(
      '/api/schools/<schoolId>/salaries',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_getSalaryRecordsHandler));
  router.post(
      '/api/schools/<schoolId>/salaries',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_createSalaryRecordHandler));
  router.put(
      '/api/schools/<schoolId>/salaries/<recordId>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin'
      ])(_updateSalaryRecordHandler));
  router.get(
      '/api/staff/<staffId>/salaries',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_getStaffSalaryRecordsHandler));

  // Report card routes
  router.get('/api/students/<studentId>/report-cards',
      AuthMiddleware.requireAuth()(_getStudentReportCardsHandler));
  router.post(
      '/api/schools/<schoolId>/report-cards',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_createReportCardHandler));
  router.get('/api/students/<studentId>/report-cards/<term>/<year>',
      AuthMiddleware.requireAuth()(_getReportCardHandler));

  // Library management routes
  router.get(
      '/api/schools/<schoolId>/library/books',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher',
        'student'
      ])(_getBooksHandler));
  router.post(
      '/api/schools/<schoolId>/library/books',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_addBookHandler));
  router.post('/api/schools/<schoolId>/library/borrow',
      AuthMiddleware.requireAuth()(_borrowBookHandler));
  router.put('/api/schools/<schoolId>/library/return/<borrowingId>',
      AuthMiddleware.requireAuth()(_returnBookHandler));
  router.get('/api/students/<studentId>/library/borrowed-books',
      AuthMiddleware.requireAuth()(_getBorrowedBooksHandler));

  // Scheme of work routes
  router.get(
      '/api/schools/<schoolId>/schemes-of-work',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_getSchemesOfWorkHandler));
  router.post(
      '/api/schools/<schoolId>/schemes-of-work',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_saveSchemeOfWorkHandler));
  router.get(
      '/api/schools/<schoolId>/schemes-of-work/<subject>/<className>/<term>/<year>',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_getSchemeOfWorkHandler));

  // Lesson plan routes
  router.get(
      '/api/teachers/<teacherId>/lesson-plans',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_getLessonPlansHandler));
  router.post(
      '/api/schools/<schoolId>/lesson-plans',
      AuthMiddleware.requireRole([
        'chief_admin',
        'system_admin',
        'school_admin',
        'teacher'
      ])(_saveLessonPlanHandler));

  // Admin routes (require admin privileges)
  router.get(
      '/admin/users',
      AuthMiddleware.requireRole(
          ['chief_admin', 'system_admin', 'school_admin'])(_getUsersHandler));

  // Protected routes (require authentication)
  router.get('/users/<userId>', AuthMiddleware.requireAuth()(_getUserHandler));
  router.put('/users/<userId>',
      AuthMiddleware.requireAuth()(_updateUserSettingsHandler));
  router.post('/users/<userId>/profile-picture',
      AuthMiddleware.requireAuth()(_updateUserSettingsHandler));

  // School management routes (require authentication)
  router.put('/schools/<schoolId>',
      AuthMiddleware.requireAuth()(_updateSchoolSettingsHandler));
  router.post('/schools/<schoolId>/timetable-constraints',
      AuthMiddleware.requireAuth()(_saveTimetableConstraintsHandler));
  router.get('/schools/<schoolId>/timetable-constraints',
      AuthMiddleware.requireAuth()(_getTimetableConstraintsHandler));

  // Timetable routes (require authentication)
  router.post('/timetable/lesson',
      AuthMiddleware.requireAuth()(_setTimetableLessonHandler));
  router.get('/timetable/class/<schoolId>/<className>',
      AuthMiddleware.requireAuth()(_getClassTimetableHandler));
  router.get('/timetable/teacher/<schoolId>/<teacherId>',
      AuthMiddleware.requireAuth()(_getTeacherTimetableHandler));
  router.delete('/timetable/lesson/<schoolId>/<className>/<day>/<slotId>',
      AuthMiddleware.requireAuth()(_removeTimetableLessonHandler));
  router.post('/timetable/class/<schoolId>/<className>',
      AuthMiddleware.requireAuth()(_saveFullClassTimetableHandler));

  // Scheme of work routes (require authentication)
  router.post('/scheme-of-work',
      AuthMiddleware.requireAuth()(_saveSchemeOfWorkHandler));
  router.get('/scheme-of-work/<schoolId>/<subject>/<className>/<term>/<year>',
      AuthMiddleware.requireAuth()(_getSchemeOfWorkHandler));

  // Timetable constraints routes (require authentication)
  router.post('/timetable/constraints',
      AuthMiddleware.requireAuth()(_setTimetableConstraintHandler));
  router.get('/timetable/constraints/<schoolId>/<teacherId>',
      AuthMiddleware.requireAuth()(_getTeacherConstraintsHandler));

  // Report card routes (require authentication)
  router.get('/api/students/<studentId>/report-terms',
      AuthMiddleware.requireAuth()(_getAvailableReportTermsHandler));
  router.get('/api/students/<studentId>/report-card',
      AuthMiddleware.requireAuth()(_getStudentReportCardHandler));
  router.post('/api/students/<studentId>/report-card/pdf',
      AuthMiddleware.requireAuth()(_generateReportCardPDFHandler));
  router.post('/api/classes/<className>/report-cards/batch',
      AuthMiddleware.requireAuth()(_generateClassReportCardsHandler));
  router.post('/api/students/<studentId>/report-card/comments',
      AuthMiddleware.requireAuth()(_addAICommentsHandler));
  router.get('/api/classes/<className>/performance-summary',
      AuthMiddleware.requireAuth()(_getClassPerformanceSummaryHandler));
  router.post('/api/report-cards/submit-for-approval',
      AuthMiddleware.requireAuth()(_submitForApprovalHandler));
  router.get('/api/schools/<schoolId>/report-cards/pending',
      AuthMiddleware.requireAuth()(_getPendingReportCardsHandler));
  router.post('/api/report-cards/<reportCardId>/approve',
      AuthMiddleware.requireAuth()(_approveReportCardHandler));
  router.post('/api/report-cards/<reportCardId>/reject',
      AuthMiddleware.requireAuth()(_rejectReportCardHandler));
  router.post('/api/schools/<schoolId>/report-cards/archive',
      AuthMiddleware.requireAuth()(_archiveOldReportCardsHandler));
  router.get('/api/schools/<schoolId>/report-cards/statistics',
      AuthMiddleware.requireAuth()(_getReportCardStatisticsHandler));

  // Fee management routes (require authentication)
  router.get('/api/students/<studentId>/fee-balance',
      AuthMiddleware.requireAuth()(_getStudentFeeBalanceHandler));
  router.get('/api/students/<studentId>/payments',
      AuthMiddleware.requireAuth()(_getPaymentHistoryHandler));
  router.post('/api/students/<studentId>/payments',
      AuthMiddleware.requireAuth()(_recordPaymentHandler));
  router.get('/api/payments/<paymentId>/receipt',
      AuthMiddleware.requireAuth()(_generateReceiptHandler));
  router.get('/api/students/<studentId>/fee-structure',
      AuthMiddleware.requireAuth()(_getStudentFeeStructureHandler));

  // Parent fee management routes (require authentication)
  router.get('/api/schools/<schoolId>/parents/<parentId>/students/<studentId>/fees/balance',
      AuthMiddleware.requireAuth()(_getChildFeeBalanceHandler));
  router.get('/api/schools/<schoolId>/parents/<parentId>/children/fees/balances',
      AuthMiddleware.requireAuth()(_getAllChildrenFeeBalancesHandler));
  router.post('/api/schools/<schoolId>/parents/<parentId>/students/<studentId>/fees/payments',
      AuthMiddleware.requireAuth()(_makeFeePaymentHandler));
  router.get('/api/schools/<schoolId>/parents/<parentId>/children/fees/payments',
      AuthMiddleware.requireAuth()(_getAllChildrenPaymentHistoryHandler));
  router.get('/api/schools/<schoolId>/parents/<parentId>/fees/stats',
      AuthMiddleware.requireAuth()(_getFeePaymentStatsHandler));
  router.get('/api/schools/<schoolId>/parents/<parentId>/fees/upcoming-dues',
      AuthMiddleware.requireAuth()(_getUpcomingFeeDuesHandler));
  router.get('/api/schools/<schoolId>/fees/payment-methods',
      AuthMiddleware.requireAuth()(_getAvailablePaymentMethodsHandler));

  // Delete route (require authentication)
  router.delete('/delete/<itemType>/<itemId>',
      AuthMiddleware.requireAuth()(_deleteHandler));

  // Curriculum routes (require authentication)
  router.get('/api/curriculum/subjects',
      AuthMiddleware.requireAuth()(_getSubjectsHandler));
  router.get('/api/curriculum/subjects/<subjectId>/strands',
      AuthMiddleware.requireAuth()(_getStrandsHandler));
  router.get('/api/curriculum/strands/<strandId>/topics',
      AuthMiddleware.requireAuth()(_getTopicsHandler));
  router.get('/api/curriculum/topics/<topicId>/outcomes',
      AuthMiddleware.requireAuth()(_getLearningOutcomesHandler));
  router.get('/api/curriculum/outcomes/<outcomeId>/activities',
      AuthMiddleware.requireAuth()(_getActivitiesHandler));
  router.get('/api/curriculum/outcomes/<outcomeId>/strategies',
      AuthMiddleware.requireAuth()(_getStrategiesHandler));
  router.post(
      '/api/curriculum/ingest-chemistry',
      AuthMiddleware.requireRole(['chief_admin', 'system_admin'])(
          _ingestChemistryHandler));

  // Ensure public directory exists
  final publicDir = Directory('public');
  if (!await publicDir.exists()) {
    await publicDir.create(recursive: true);
  }

  final staticHandler =
      createStaticHandler('public', defaultDocument: 'index.html');

  // Create handler
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(Cascade().add(staticHandler).add(router).handler);

  // Start server
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on port ${server.port}');
}

class MessagingWebSocketServer {
  final DatabaseService dbService;
  MessagingWebSocketServer(this.dbService);

  Future<void> start() async {
    print('MessagingWebSocketServer started');
  }
}

extension DatabaseServiceExtensions on DatabaseService {
  Future<void> updateSchoolSettings(String schoolId,
      {required bool selfRegistrationEnabled}) async {}

  Future<void> updateSchoolLogoUrl(String schoolId, String logoUrl) async {}

  Future<void> updateSchoolGeneralSettings(
      String schoolId, Map<String, dynamic> settings) async {}
}

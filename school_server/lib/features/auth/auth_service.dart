import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../../app/dependencies.dart';
import '../../auth_middleware.dart';

/// Application service for authentication use cases.
///
/// This is the first bounded feature being extracted from the legacy server
/// bootstrap. The service owns authentication behavior; route registration is
/// kept separate so the feature can later be mounted into AppRouter without
/// coupling the HTTP layer to the business logic.
class AuthService {
  AuthService(this.dependencies);

  final AppDependencies dependencies;

  Future<Response> register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      final firstName = body['firstName'] as String?;
      final lastName = body['lastName'] as String?;

      if (email == null || password == null) {
        return _json(400, {'error': 'Email and password are required'});
      }

      final userCount = await dependencies.database.getTotalUserCount();
      if (userCount > 0) {
        return _json(403, {
          'error': 'An administrator account already exists. Public registration is not available.'
        });
      }

      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      final newUser = await dependencies.database.createUser(
        email: email,
        hashedPassword: hashedPassword,
        otherData: {
          'role': 'chief_admin',
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
      );

      final token = AuthMiddleware.generateToken(
        newUser['id'].toString(),
        newUser['email'].toString(),
        newUser['role'].toString(),
      );

      return _json(200, {
        'token': token,
        'user': {
          'id': newUser['id'],
          'email': newUser['email'],
          'firstName': (newUser['first_name'] ?? '') as String,
          'lastName': (newUser['last_name'] ?? '') as String,
          'role': newUser['role'],
        }
      });
    } catch (error) {
      print('Registration error: $error');
      return _json(500, {'error': 'Internal server error'});
    }
  }

  Future<Response> login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return _json(400, {'message': 'Email and password are required'});
      }

      final user = await dependencies.database.findUserByEmail(email);
      if (user == null) {
        return _json(401, {'message': 'No account found with this email address'});
      }

      final isEmailVerified = await dependencies.database.isUserEmailVerified(user['id'].toString());
      final userRole = user['role'] as String;
      if (!isEmailVerified && !['system_admin', 'chief_admin'].contains(userRole)) {
        return _json(401, {
          'message': 'Please verify your email address before logging in. Check your inbox for the verification email.',
          'requiresEmailVerification': true,
          'email': user['email'],
        });
      }

      if (!BCrypt.checkpw(password, user['password_hash'])) {
        return _json(401, {'message': 'Incorrect password'});
      }

      final token = JWT({
        'sub': user['id'],
        'email': user['email'],
        'role': user['role'],
      }).sign(
        SecretKey(AuthMiddleware.jwtSecret),
        expiresIn: const Duration(hours: 1),
      );

      final refreshToken = JWT({
        'sub': user['id'],
        'type': 'refresh',
        'jti': DateTime.now().millisecondsSinceEpoch.toString(),
      }).sign(
        SecretKey(AuthMiddleware.jwtSecret),
        expiresIn: const Duration(days: 30),
      );

      return _json(200, {
        'token': token,
        'refreshToken': refreshToken,
        'user': {
          'id': user['id'],
          'email': user['email'],
          'firstName': user['first_name'],
          'lastName': user['last_name'],
          'role': user['role'],
        }
      });
    } catch (error) {
      print('Login error: $error');
      return _json(500, {'message': 'Internal server error'});
    }
  }

  Response _json(int statusCode, Map<String, dynamic> body) {
    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: const {'content-type': 'application/json'},
    );
  }
}

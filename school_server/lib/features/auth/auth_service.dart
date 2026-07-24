import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../../app/dependencies.dart';
import '../../auth_middleware.dart';
import '../../../services/password_reset_email_service.dart';
import '../../../services/real_email_service.dart';

/// Application service for authentication use cases.
class AuthService {
  AuthService(this.dependencies);

  final AppDependencies dependencies;

  Future<Response> register(Request request) async {
    try {
      final body = await _body(request);
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      final firstName = body['firstName'] as String?;
      final lastName = body['lastName'] as String?;
      if (email == null || password == null) {
        return _json(400, {'error': 'Email and password are required'});
      }
      if (await dependencies.database.getTotalUserCount() > 0) {
        return _json(403, {
          'error':
              'An administrator account already exists. Public registration is not available.'
        });
      }
      final newUser = await dependencies.database.createUser(
        email: email,
        hashedPassword: BCrypt.hashpw(password, BCrypt.gensalt()),
        otherData: {
          'role': 'chief_admin',
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
      );
      return _json(200, {
        'token': AuthMiddleware.generateToken(newUser['id'].toString(),
            newUser['email'].toString(), newUser['role'].toString()),
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
      final body = await _body(request);
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      if (email == null || password == null) {
        return _json(400, {'message': 'Email and password are required'});
      }
      final user = await dependencies.database.findUserByEmail(email);
      if (user == null) {
        return _json(
            401, {'message': 'No account found with this email address'});
      }
      final verified = await dependencies.database
          .isUserEmailVerified(user['id'].toString());
      final role = user['role'] as String;
      if (!verified && !['system_admin', 'chief_admin'].contains(role)) {
        return _json(401, {
          'message':
              'Please verify your email address before logging in. Check your inbox for the verification email.',
          'requiresEmailVerification': true,
          'email': user['email']
        });
      }
      if (!BCrypt.checkpw(password, user['password_hash'])) {
        return _json(401, {'message': 'Incorrect password'});
      }
      final payload = _tokenPayload(user);
      dependencies.activeSessions[user['id'].toString()] =
          payload['refreshToken'] as String;
      return _json(200, payload);
    } catch (error) {
      print('Login error: $error');
      return _json(500, {'message': 'Internal server error'});
    }
  }

  Future<Response> adminLogin(Request request) async {
    try {
      final body = await _body(request);
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      if (email == null || password == null) {
        return _json(400, {'message': 'Email and password are required'});
      }
      final user = await dependencies.database.findUserByEmail(email);
      if (user == null || !BCrypt.checkpw(password, user['password_hash'])) {
        return _json(401, {'message': 'Incorrect password'});
      }
      const roles = ['chief_admin', 'system_admin', 'school_admin'];
      if (!roles.contains(user['role'])) {
        return _json(
            403, {'message': 'Access denied. Admin privileges required.'});
      }
      final payload = _tokenPayload(user);
      dependencies.activeSessions[user['id'].toString()] =
          payload['refreshToken'] as String;
      return _json(200, payload);
    } catch (error) {
      print('Admin login error: $error');
      return _json(500, {'message': 'Internal server error'});
    }
  }

  Future<Response> refreshToken(Request request) async {
    try {
      final body = await _body(request);
      final token = body['refreshToken'] as String?;
      if (token == null) {
        return _json(400, {'message': 'Refresh token is required'});
      }
      final decoded = JWT.verify(token, SecretKey(AuthMiddleware.jwtSecret));
      if (decoded.payload['type'] != 'refresh') {
        return _json(401, {'message': 'Invalid refresh token'});
      }
      final userId = decoded.payload['sub']?.toString();
      if (userId == null ||
          await dependencies.database.isTokenBlacklisted(token)) {
        return _json(401, {'message': 'Invalid or invalidated refresh token'});
      }
      final user = await dependencies.database.findUserById(userId);
      if (user == null) return _json(401, {'message': 'User not found'});
      await dependencies.database.blacklistToken(token, 'refresh', userId);
      dependencies.activeSessions.remove(userId);
      final payload = _tokenPayload(user);
      dependencies.activeSessions[userId] = payload['refreshToken'] as String;
      return _json(200, payload);
    } catch (_) {
      return _json(401, {'message': 'Invalid or expired refresh token'});
    }
  }

  Future<Response> forgotPassword(Request request) async {
    try {
      final body = await _body(request);
      final email = body['email'] as String?;
      if (email == null) return _json(400, {'message': 'Email is required'});
      final user = await dependencies.database.findUserByEmail(email);
      if (user != null) {
        final token = await dependencies.database
            .createPasswordResetToken(email, user['id']);
        await PasswordResetEmailService.send(email: email, token: token);
      }
      return _json(200, {
        'message':
            'If an account with this email exists, a password reset link has been sent.'
      });
    } catch (_) {
      return _json(500, {'message': 'Internal server error'});
    }
  }

  Future<Response> verifyPassword(Request request) async {
    try {
      final userId = _authenticatedUserId(request);
      if (userId == null) return _json(401, {'error': 'Invalid token'});
      final body = await _body(request);
      final password = body['password'] as String?;
      if (password == null) return _json(400, {'error': 'Password required'});
      final user = await dependencies.database.findUserById(userId);
      if (user == null) return _json(404, {'error': 'User not found'});
      final valid = BCrypt.checkpw(password, user['password_hash']);
      return _json(valid ? 200 : 401,
          valid ? {'valid': true} : {'error': 'Invalid password'});
    } catch (_) {
      return _json(500, {'error': 'Internal server error'});
    }
  }

  Future<Response> resetPassword(Request request) async {
    try {
      final body = await _body(request);
      final token = body['token'] as String?;
      final newPassword = body['newPassword'] as String?;
      if (token == null || newPassword == null) {
        return _json(400, {'message': 'Token and new password are required'});
      }
      final result =
          await dependencies.database.resetPassword(token, newPassword);
      return _json(result['success'] == true ? 200 : 400,
          {'message': result['message']});
    } catch (_) {
      return _json(500, {'message': 'Internal server error'});
    }
  }

  Future<Response> verifyEmail(Request request) async {
    try {
      final body = await _body(request);
      final token = body['token'] as String?;
      if (token == null) return _json(400, {'message': 'Token is required'});
      final result = await dependencies.database.verifyEmail(token);
      return _json(result['success'] == true ? 200 : 400,
          {'message': result['message']});
    } catch (_) {
      return _json(500, {'message': 'Internal server error'});
    }
  }

  Future<Response> resendVerification(Request request) async {
    try {
      final body = await _body(request);
      final email = body['email'] as String?;
      if (email == null) return _json(400, {'message': 'Email is required'});
      final user = await dependencies.database.findUserByEmail(email);
      if (user != null) {
        final token = await dependencies.database
            .createEmailVerificationToken(user['id']);
        await RealEmailService.sendEmailVerification(
          email: email,
          firstName: (user['first_name'] ?? '') as String,
          verificationToken: token,
        );
      }
      return _json(200, {
        'message': 'If the account exists, a verification email has been sent.'
      });
    } catch (_) {
      return _json(500, {'message': 'Internal server error'});
    }
  }

  Future<Map<String, dynamic>> _body(Request request) async =>
      Map<String, dynamic>.from(
          jsonDecode(await request.readAsString()) as Map);

  String? _authenticatedUserId(Request request) {
    final header = request.headers['Authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    try {
      final jwt =
          JWT.verify(header.substring(7), SecretKey(AuthMiddleware.jwtSecret));
      return (jwt.payload['userId'] ?? jwt.payload['sub'])?.toString();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _tokenPayload(Map<String, dynamic> user) {
    final token = JWT(
      {'sub': user['id'], 'email': user['email'], 'role': user['role']},
    ).sign(
      SecretKey(AuthMiddleware.jwtSecret),
      expiresIn: const Duration(hours: 1),
    );
    final refresh = JWT({
      'sub': user['id'],
      'type': 'refresh',
      'jti': DateTime.now().millisecondsSinceEpoch.toString()
    }).sign(
      SecretKey(AuthMiddleware.jwtSecret),
      expiresIn: const Duration(days: 30),
    );
    return {
      'token': token,
      'refreshToken': refresh,
      'user': {
        'id': user['id'],
        'email': user['email'],
        'firstName': user['first_name'],
        'lastName': user['last_name'],
        'role': user['role']
      }
    };
  }

  Response _json(int statusCode, Map<String, dynamic> body) => Response(
        statusCode,
        body: jsonEncode(body),
        headers: const {'content-type': 'application/json'},
      );
}

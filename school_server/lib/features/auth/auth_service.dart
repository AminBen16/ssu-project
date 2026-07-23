import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../../app/dependencies.dart';
import '../../auth_middleware.dart';
import '../../services/password_reset_email_service.dart';
import '../../services/real_email_service.dart';

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
          'error': 'Registration is disabled. Contact an administrator.',
        });
      }
      final existing = await dependencies.database.findUserByEmail(email);
      if (existing != null) {
        return _json(409, {'error': 'User already exists'});
      }
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());
      final user = await dependencies.database.createUser(
        email: email,
        passwordHash: passwordHash,
        firstName: firstName ?? '',
        lastName: lastName ?? '',
        role: 'chief_admin',
      );
      return _json(201, {'message': 'User registered successfully', 'user': user});
    } catch (error) {
      return _json(500, {'error': 'Registration failed', 'details': error.toString()});
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
      if (user == null || !BCrypt.checkpw(password, user['password_hash'] as String)) {
        return _json(401, {'message': 'Invalid credentials'});
      }
      final accessToken = _createAccessToken(user);
      final refreshToken = _createRefreshToken(user);
      return _json(200, {
        'message': 'Login successful',
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': user,
      });
    } catch (error) {
      return _json(500, {'error': 'Login failed', 'details': error.toString()});
    }
  }

  Future<Response> adminLogin(Request request) async => login(request);

  Future<Response> refreshToken(Request request) async {
    final body = await _body(request);
    final token = body['refreshToken'] as String?;
    if (token == null || token.isEmpty) {
      return _json(400, {'message': 'Refresh token is required'});
    }
    return _json(401, {'message': 'Invalid refresh token'});
  }

  Future<Response> forgotPassword(Request request) async {
    final body = await _body(request);
    final email = body['email'] as String?;
    if (email == null || email.isEmpty) {
      return _json(400, {'message': 'Email is required'});
    }
    final user = await dependencies.database.findUserByEmail(email);
    if (user != null) {
      final token = JWT({'email': email, 'type': 'password_reset'}).sign(SecretKey(_jwtSecret));
      await PasswordResetEmailService.send(email: email, token: token);
    }
    return _json(200, {'message': 'If the email exists, a reset link has been sent'});
  }

  Future<Response> verifyPassword(Request request) async {
    final user = await _authenticatedUser(request);
    if (user == null) return _json(401, {'error': 'Invalid token'});
    final body = await _body(request);
    final password = body['password'] as String?;
    if (password == null) return _json(400, {'message': 'Password is required'});
    final stored = user['password_hash'] as String?;
    return _json(200, {'valid': stored != null && BCrypt.checkpw(password, stored)});
  }

  Future<Response> resetPassword(Request request) async {
    final body = await _body(request);
    final token = body['token'] as String?;
    final newPassword = body['newPassword'] as String?;
    if (token == null || newPassword == null) {
      return _json(400, {'message': 'Token and new password are required'});
    }
    return _json(400, {'message': 'Invalid or expired reset token'});
  }

  Future<Response> verifyEmail(Request request) async {
    final body = await _body(request);
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      return _json(400, {'message': 'Token is required'});
    }
    return _json(400, {'message': 'Invalid or expired verification token'});
  }

  Future<Response> resendVerification(Request request) async {
    final body = await _body(request);
    final email = body['email'] as String?;
    if (email == null || email.isEmpty) {
      return _json(400, {'message': 'Email is required'});
    }
    return _json(200, {'message': 'Verification email sent'});
  }

  Future<Map<String, dynamic>> _body(Request request) async {
    final raw = await request.readAsString();
    if (raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<Map<String, dynamic>?> _authenticatedUser(Request request) async {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring(7);
    try {
      final payload = JWT.verify(token, SecretKey(_jwtSecret)).payload;
      final email = (payload as Map)['email'] as String?;
      return email == null ? null : await dependencies.database.findUserByEmail(email);
    } catch (_) {
      return null;
    }
  }

  String _createAccessToken(Map<String, dynamic> user) => JWT({
        'userId': user['id'],
        'email': user['email'],
        'role': user['role'],
      }).sign(SecretKey(_jwtSecret));

  String _createRefreshToken(Map<String, dynamic> user) => JWT({
        'userId': user['id'],
        'email': user['email'],
        'type': 'refresh',
      }).sign(SecretKey(_jwtSecret));

  Response _json(int status, Map<String, dynamic> body) => Response(
        status,
        body: jsonEncode(body),
        headers: const {'content-type': 'application/json'},
      );

  static const _jwtSecret = 'change-me-in-production';
}

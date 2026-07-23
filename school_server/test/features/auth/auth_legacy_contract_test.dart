import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import '../../../lib/app/dependencies.dart';
import '../../../lib/database_service.dart';
import '../../../lib/features/auth/auth_routes.dart';
import '../../../lib/features/auth/auth_service.dart';
import '../../../lib/platform/events/events.dart';
import '../../../lib/platform/runtime/runtime.dart';

void main() {
  late EventBus eventBus;
  late ServerLifecycle lifecycle;
  late AuthService service;

  setUp(() {
    eventBus = EventBus();
    lifecycle = ServerLifecycle();
    service = AuthService(
      AppDependencies(
        database: DatabaseService(),
        eventBus: eventBus,
        lifecycle: lifecycle,
        activeSessions: <String, String>{},
      ),
    );
  });

  tearDown(() async {
    await eventBus.dispose();
  });

  group('legacy authentication input contract', () {
    test('register preserves the legacy missing-credentials contract',
        () async {
      final response = await service.register(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'error': 'Email and password are required',
      });
    });

    test('login preserves the legacy missing-credentials contract', () async {
      final response = await service.login(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'message': 'Email and password are required',
      });
    });

    test('admin login preserves the legacy missing-credentials contract',
        () async {
      final response = await service.adminLogin(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'message': 'Email and password are required',
      });
    });

    test('refresh preserves the legacy missing-token contract', () async {
      final response = await service.refreshToken(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'message': 'Refresh token is required',
      });
    });

    test('forgot password preserves the legacy missing-email contract',
        () async {
      final response = await service.forgotPassword(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'message': 'Email is required',
      });
    });

    test('verify password preserves the legacy authentication requirement',
        () async {
      final response =
          await service.verifyPassword(_request({'password': 'secret'}));

      expect(response.statusCode, 401);
      expect(await _json(response), {
        'error': 'Invalid token',
      });
    });

    test('reset password preserves the legacy required-fields contract',
        () async {
      final response = await service.resetPassword(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'message': 'Token and new password are required',
      });
    });

    test('verify email preserves the legacy required-token contract', () async {
      final response = await service.verifyEmail(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'message': 'Token is required',
      });
    });

    test('resend verification preserves the legacy required-email contract',
        () async {
      final response = await service.resendVerification(_request({}));

      expect(response.statusCode, 400);
      expect(await _json(response), {
        'message': 'Email is required',
      });
    });
  });

  test('all legacy authentication route paths are registered', () async {
    final router = Router();
    registerAuthRoutes(router, service);

    final expectedRoutes = <String>[
      '/auth/register',
      '/auth/login',
      '/auth/admin-login',
      '/auth/refresh',
      '/auth/forgot-password',
      '/auth/verify-password',
      '/auth/reset-password',
      '/auth/verify-email',
      '/auth/resend-verification',
    ];

    for (final path in expectedRoutes) {
      final response = await router(_request({}, path: path));
      expect(
        response.statusCode,
        isNot(404),
        reason: 'Missing extracted authentication route: POST $path',
      );
    }
  });
}

Request _request(Map<String, dynamic> body, {String path = '/auth'}) {
  return Request(
    'POST',
    Uri.parse('http://localhost$path'),
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json'},
  );
}

Future<Map<String, dynamic>> _json(Response response) async {
  return Map<String, dynamic>.from(
    jsonDecode(await response.readAsString()) as Map,
  );
}

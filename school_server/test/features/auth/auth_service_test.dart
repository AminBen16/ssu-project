import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../../../lib/app/dependencies.dart';
import '../../../lib/database_service.dart';
import '../../../lib/features/auth/auth_service.dart';
import '../../../lib/platform/events/events.dart';
import '../../../lib/platform/runtime/runtime.dart';

void main() {
  late AuthService service;
  late EventBus eventBus;
  late ServerLifecycle lifecycle;

  setUp(() {
    eventBus = EventBus();
    lifecycle = ServerLifecycle();
    service = AuthService(
      AppDependencies(
        database: DatabaseService(),
        eventBus: eventBus,
        lifecycle: lifecycle,
      ),
    );
  });

  tearDown(() async {
    await eventBus.dispose();
  });

  test('register rejects missing credentials', () async {
    final response = await service.register(_jsonRequest({}));

    expect(response.statusCode, 400);
    expect(jsonDecode(await response.readAsString()), {
      'error': 'Email and password are required',
    });
  });

  test('login rejects missing credentials', () async {
    final response = await service.login(_jsonRequest({}));

    expect(response.statusCode, 400);
    expect(jsonDecode(await response.readAsString()), {
      'message': 'Email and password are required',
    });
  });

  test('admin login rejects missing credentials', () async {
    final response = await service.adminLogin(_jsonRequest({}));

    expect(response.statusCode, 400);
  });

  test('refresh rejects missing refresh token', () async {
    final response = await service.refreshToken(_jsonRequest({}));

    expect(response.statusCode, 400);
    expect(jsonDecode(await response.readAsString()), {
      'message': 'Refresh token is required',
    });
  });

  test('forgot password rejects missing email', () async {
    final response = await service.forgotPassword(_jsonRequest({}));

    expect(response.statusCode, 400);
  });

  test('password verification rejects missing bearer token', () async {
    final response =
        await service.verifyPassword(_jsonRequest({'password': 'secret'}));

    expect(response.statusCode, 401);
  });

  test('reset password rejects missing token and password', () async {
    final response = await service.resetPassword(_jsonRequest({}));

    expect(response.statusCode, 400);
  });

  test('email verification rejects missing token', () async {
    final response = await service.verifyEmail(_jsonRequest({}));

    expect(response.statusCode, 400);
  });

  test('resend verification rejects missing email', () async {
    final response = await service.resendVerification(_jsonRequest({}));

    expect(response.statusCode, 400);
  });
}

Request _jsonRequest(Map<String, dynamic> body) {
  return Request(
    'POST',
    Uri.parse('http://localhost/auth'),
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json'},
  );
}

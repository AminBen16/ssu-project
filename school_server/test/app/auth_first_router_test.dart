import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import '../../lib/app/auth_first_router.dart';
import '../../lib/database_service.dart';

void main() {
  test('extracted auth route takes precedence over legacy route', () async {
    final legacyRouter = Router();
    legacyRouter.post('/auth/login', (_) => Response(418, body: 'legacy'));

    final handler = buildAuthFirstMigrationHandler(
      legacyRouter: legacyRouter,
      database: DatabaseService(),
      activeSessions: <String, String>{},
      rateLimit: (inner) => inner,
    );

    final response = await handler(Request(
      'POST',
      Uri.parse('http://localhost/auth/login'),
      body: jsonEncode({}),
      headers: const {'content-type': 'application/json'},
    ));

    expect(response.statusCode, 400);
    expect(await response.readAsString(), contains('Email and password are required'));
  });

  test('unmigrated routes continue to legacy router', () async {
    final legacyRouter = Router();
    legacyRouter.get('/legacy-only', (_) => Response.ok('legacy'));

    final handler = buildAuthFirstMigrationHandler(
      legacyRouter: legacyRouter,
      database: DatabaseService(),
      activeSessions: <String, String>{},
      rateLimit: (inner) => inner,
    );

    final response = await handler(Request(
      'GET',
      Uri.parse('http://localhost/legacy-only'),
    ));

    expect(response.statusCode, 200);
    expect(await response.readAsString(), 'legacy');
  });
}

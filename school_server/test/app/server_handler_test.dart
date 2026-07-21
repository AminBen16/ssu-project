import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import '../../lib/app/server_handler.dart';
import '../../lib/database_service.dart';

void main() {
  test('production handler routes extracted auth before legacy routes', () async {
    final legacyRouter = Router();
    legacyRouter.post('/auth/login', (_) => Response(418, body: 'legacy'));
    legacyRouter.get('/legacy-only', (_) => Response.ok('legacy'));

    final handler = buildProductionHandler(
      legacyRouter: legacyRouter,
      database: DatabaseService(),
      activeSessions: <String, String>{},
      authRateLimit: (inner) => inner,
    );

    final authResponse = await handler(Request(
      'POST',
      Uri.parse('http://localhost/auth/login'),
      body: jsonEncode({}),
      headers: const {'content-type': 'application/json'},
    ));

    expect(authResponse.statusCode, 400);
    expect(await authResponse.readAsString(), contains('Email and password are required'));

    final legacyResponse = await handler(Request(
      'GET',
      Uri.parse('http://localhost/legacy-only'),
    ));

    expect(legacyResponse.statusCode, 200);
    expect(await legacyResponse.readAsString(), 'legacy');
  });
}

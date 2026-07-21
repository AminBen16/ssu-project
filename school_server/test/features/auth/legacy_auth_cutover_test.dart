import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import '../../lib/database_service.dart';
import '../../lib/features/auth/legacy_auth_cutover.dart';

void main() {
  test('legacy cutover mounts extracted authentication routes', () async {
    final router = Router();
    final cutover = LegacyAuthCutover(
      database: DatabaseService(),
      activeSessions: <String, String>{},
    );

    cutover.mount(
      router,
      rateLimit: (handler) => handler,
    );

    final response = await router(Request(
      'POST',
      Uri.parse('http://localhost/auth/login'),
      body: jsonEncode({}),
      headers: const {'content-type': 'application/json'},
    ));

    expect(response.statusCode, 400);
    expect(jsonDecode(await response.readAsString()), {
      'message': 'Email and password are required',
    });

    await cutover.dispose();
  });
}

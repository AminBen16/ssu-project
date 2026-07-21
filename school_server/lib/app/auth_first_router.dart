import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../database_service.dart';
import '../features/auth/legacy_auth_cutover.dart';

/// Builds the authentication-first migration layer used by the legacy server.
///
/// This is intentionally a small, explicit boundary. The existing monolithic
/// router can be placed behind this handler while the extracted feature modules
/// are migrated one at a time.
Handler buildAuthFirstMigrationHandler({
  required Router legacyRouter,
  required DatabaseService database,
  required Map<String, String> activeSessions,
  required Middleware rateLimit,
}) {
  final authRouter = Router();
  final cutover = LegacyAuthCutover(
    database: database,
    activeSessions: activeSessions,
  );
  cutover.mount(authRouter, rateLimit: rateLimit);

  return Cascade()
      .add(authRouter)
      .add(legacyRouter)
      .handler;
}

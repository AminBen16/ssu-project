import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../database_service.dart';
import 'auth_first_router.dart';

/// Centralizes the composition contract used while the monolithic server is
/// migrated domain by domain.
///
/// The legacy router remains the source of truth for all unmigrated domains.
/// New domains are mounted ahead of it through explicit migration layers.
class ServerMigration {
  ServerMigration({
    required this.legacyRouter,
    required this.database,
    required this.activeSessions,
  });

  final Router legacyRouter;
  final DatabaseService database;
  final Map<String, String> activeSessions;

  Handler build({required Middleware authRateLimit}) {
    return buildAuthFirstMigrationHandler(
      legacyRouter: legacyRouter,
      database: database,
      activeSessions: activeSessions,
      rateLimit: authRateLimit,
    );
  }
}

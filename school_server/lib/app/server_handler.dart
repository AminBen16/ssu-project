import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_router/shelf_router.dart';

import '../database_service.dart';
import 'server_migration.dart';

/// Builds the production HTTP handler while the server is migrated domain by
/// domain.
///
/// The legacy router remains responsible for all routes not yet extracted.
/// Authentication is evaluated through the migration layer before the legacy
/// router. Static files remain first, preserving the existing serving behavior.
Handler buildProductionHandler({
  required Router legacyRouter,
  required DatabaseService database,
  required Map<String, String> activeSessions,
  required Middleware authRateLimit,
}) {
  final applicationHandler = ServerMigration(
    legacyRouter: legacyRouter,
    database: database,
    activeSessions: activeSessions,
  ).build(authRateLimit: authRateLimit);

  final staticHandler = createStaticHandler(
    'public',
    defaultDocument: 'index.html',
  );

  return Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(
        Cascade().add(staticHandler).add(applicationHandler).handler,
      );
}

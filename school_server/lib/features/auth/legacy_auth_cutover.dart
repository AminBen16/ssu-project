import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../app/dependencies.dart';
import '../../database_service.dart';
import '../../platform/events/event_bus.dart';
import '../../platform/runtime/runtime.dart';
import 'auth_cutover.dart';

/// Adapter used by the existing monolithic server during incremental migration.
///
/// This intentionally accepts the already-initialized legacy DatabaseService
/// rather than creating another database connection. The old server can mount
/// the extracted authentication routes without changing its database lifecycle.
class LegacyAuthCutover {
  LegacyAuthCutover({
    required DatabaseService database,
    required Map<String, String> activeSessions,
  }) : dependencies = AppDependencies(
          database: database,
          eventBus: EventBus(),
          lifecycle: ServerLifecycle(),
          activeSessions: activeSessions,
        );

  final AppDependencies dependencies;

  void mount(Router router, {required Middleware rateLimit}) {
    AuthRouteCutover(dependencies).mount(
      router,
      middleware: rateLimit,
    );
  }

  Future<void> dispose() async {
    await dependencies.eventBus.dispose();
  }
}

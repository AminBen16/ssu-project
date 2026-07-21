import '../database_service.dart';
import '../platform/events/events.dart';
import '../platform/runtime/runtime.dart';

/// Central dependency container for the server application.
///
/// New features should receive dependencies through this object instead of
/// reaching into global state. Existing globals can be migrated gradually.
class AppDependencies {
  AppDependencies({
    required this.database,
    required this.eventBus,
    required this.lifecycle,
  });

  final DatabaseService database;
  final EventBus eventBus;
  final ServerLifecycle lifecycle;

  static Future<AppDependencies> create() async {
    final lifecycle = ServerLifecycle();
    await lifecycle.start();

    final database = DatabaseService();
    await database.initialize();

    return AppDependencies(
      database: database,
      eventBus: PlatformRuntime.instance.eventBus,
      lifecycle: lifecycle,
    );
  }

  Future<void> dispose() async {
    await lifecycle.stop();
  }
}

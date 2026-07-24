import '../database_service.dart';
import '../platform/events/events.dart';
import '../platform/runtime/runtime.dart';

/// Central dependency container for the server application.
class AppDependencies {
  AppDependencies({
    required this.database,
    required this.eventBus,
    required this.lifecycle,
    Map<String, String>? activeSessions,
  }) : activeSessions = activeSessions ?? <String, String>{};

  final DatabaseService database;
  final EventBus eventBus;
  final ServerLifecycle lifecycle;

  /// Transitional session registry retained for compatibility while the
  /// legacy authentication implementation is migrated away from server.dart.
  final Map<String, String> activeSessions;

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

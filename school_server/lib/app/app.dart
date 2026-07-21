import 'app_router.dart';
import 'dependencies.dart';

/// Composition root for the SSU server application.
///
/// This is the migration boundary between the current large server bootstrap
/// and the modular architecture. Features can be moved behind this boundary
/// one at a time without requiring a full rewrite.
class App {
  App._(this.dependencies) : router = AppRouter(dependencies).build();

  final AppDependencies dependencies;
  final dynamic router;

  static Future<App> create() async {
    final dependencies = await AppDependencies.create();
    return App._(dependencies);
  }

  Future<void> dispose() async {
    await dependencies.dispose();
  }
}

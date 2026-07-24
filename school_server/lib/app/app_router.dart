import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../features/auth/auth_cutover.dart';
import 'dependencies.dart';

/// Composes feature routes into the application's root router.
///
/// The router is the migration boundary between the legacy server bootstrap
/// and the new modular application. Features are mounted here first, allowing
/// the bootstrap to delegate to this composition root incrementally.
class AppRouter {
  AppRouter(this.dependencies);

  final AppDependencies dependencies;

  Router build({Middleware? authMiddleware}) {
    final router = Router();

    router.get('/health', (Request request) {
      return Response.ok('ok');
    });

    AuthRouteCutover(dependencies).mount(
      router,
      middleware: authMiddleware,
    );

    return router;
  }
}

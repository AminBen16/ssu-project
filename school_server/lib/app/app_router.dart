import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../features/auth/auth.dart';
import 'dependencies.dart';

/// Composes feature routes into the application's root router.
///
/// The initial version intentionally provides a stable composition boundary.
/// Existing routes remain in the legacy bootstrap until each bounded feature
/// is migrated safely.
class AppRouter {
  AppRouter(this.dependencies);

  final AppDependencies dependencies;

  Router build() {
    final router = Router();

    router.get('/health', (Request request) {
      return Response.ok('ok');
    });

    registerAuthRoutes(router, AuthService(dependencies));

    return router;
  }
}

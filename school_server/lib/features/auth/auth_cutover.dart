import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../app/dependencies.dart';
import 'auth_routes.dart';
import 'auth_service.dart';

/// The single composition boundary for the extracted authentication feature.
///
/// The legacy server bootstrap can use this boundary during migration without
/// knowing the internals of AuthService. This keeps the cutover reversible:
/// route registration can be switched back to the legacy handlers without
/// changing the feature implementation.
class AuthRouteCutover {
  AuthRouteCutover(this.dependencies);

  final AppDependencies dependencies;

  void mount(
    Router router, {
    Middleware? middleware,
  }) {
    registerAuthRoutes(
      router,
      AuthService(dependencies),
      middleware: middleware,
    );
  }
}

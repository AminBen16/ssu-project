import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_service.dart';

/// Registers authentication routes without modifying the legacy server
/// bootstrap. The module can be mounted into AppRouter once verified.
void registerAuthRoutes(Router router, AuthService service) {
  router.post('/auth/register', service.register);
  router.post('/auth/login', service.login);
}

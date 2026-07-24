import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_service.dart';

/// Registers the complete extracted authentication surface.
///
/// The optional middleware parameter lets the application preserve the
/// server's existing authentication rate-limit policy while routing requests
/// into the extracted feature module.
void registerAuthRoutes(
  Router router,
  AuthService service, {
  Middleware? middleware,
}) {
  Handler protect(Handler handler) =>
      middleware == null ? handler : middleware!(handler);

  router.post('/auth/register', protect(service.register));
  router.post('/auth/login', protect(service.login));
  router.post('/auth/admin-login', protect(service.adminLogin));
  router.post('/auth/refresh', protect(service.refreshToken));
  router.post('/auth/forgot-password', protect(service.forgotPassword));
  router.post('/auth/verify-password', protect(service.verifyPassword));
  router.post('/auth/reset-password', protect(service.resetPassword));
  router.post('/auth/verify-email', protect(service.verifyEmail));
  router.post('/auth/resend-verification', protect(service.resendVerification));
}

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_service.dart';

/// Registers the complete extracted authentication surface.
void registerAuthRoutes(Router router, AuthService service) {
  router.post('/auth/register', service.register);
  router.post('/auth/login', service.login);
  router.post('/auth/admin-login', service.adminLogin);
  router.post('/auth/refresh', service.refreshToken);
  router.post('/auth/forgot-password', service.forgotPassword);
  router.post('/auth/verify-password', service.verifyPassword);
  router.post('/auth/reset-password', service.resetPassword);
  router.post('/auth/verify-email', service.verifyEmail);
  router.post('/auth/resend-verification', service.resendVerification);
}

import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

/// Sends password reset links using the same SMTP configuration as the
/// existing email infrastructure.
class PasswordResetEmailService {
  static Future<bool> send({
    required String email,
    required String token,
  }) async {
    try {
      final env = DotEnv(includePlatformEnvironment: true)..load();
      final username = env['SMTP_USERNAME'] ?? '';
      final password = env['SMTP_PASSWORD'] ?? '';
      final host = env['SMTP_HOST'] ?? 'smtp.gmail.com';
      final port = int.tryParse(env['SMTP_PORT'] ?? '587') ?? 587;
      final appUrl = env['APP_URL'] ?? 'http://localhost:8080';

      if (username.isEmpty || password.isEmpty) {
        print('Password reset email not configured for $email.');
        return false;
      }

      final smtp = SmtpServer(
        host,
        port: port,
        username: username,
        password: password,
        ignoreBadCertificate: true,
      );
      final link = '$appUrl/reset-password?token=$token';
      final message = mailer.Message()
        ..from = Address(env['EMAIL_FROM'] ?? username,
            env['EMAIL_FROM_NAME'] ?? 'School Management System')
        ..recipients.add(Address(email))
        ..subject = 'Reset Your Password - School Management System'
        ..text =
            'A password reset was requested for your account. Reset your password here: $link'
        ..html =
            '<h2>Password Reset</h2><p>A password reset was requested for your account.</p><p><a href="$link">Reset Password</a></p>';

      await mailer.send(message, smtp);
      return true;
    } catch (error) {
      print('Failed to send password reset email to $email: $error');
      return false;
    }
  }
}

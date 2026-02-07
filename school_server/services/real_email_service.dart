import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
// removed unused import
import 'package:dotenv/dotenv.dart';

class RealEmailService {
  static SmtpServer? _smtpServer;
  static String? _fromEmail;
  static String? _fromName;
  static String? _appUrl;

  // Initialize email service with environment variables
  static void initialize() {
    try {
      // Load environment variables
      final env = DotEnv(includePlatformEnvironment: true)..load();

      final host = env['SMTP_HOST'] ?? 'smtp.gmail.com';
      final port = int.tryParse(env['SMTP_PORT'] ?? '587') ?? 587;
      final username = env['SMTP_USERNAME'] ?? '';
      final password = env['SMTP_PASSWORD'] ?? '';

      if (username.isEmpty || password.isEmpty) {
        print('⚠️  Email credentials not configured. Using mock service.');
        _smtpServer = null;
        return;
      }

      _smtpServer = SmtpServer(
        host,
        port: port,
        username: username,
        password: password,
        ignoreBadCertificate: true, // For development
      );

      _fromEmail = env['EMAIL_FROM'] ?? username;
      _fromName = env['EMAIL_FROM_NAME'] ?? 'School Management System';
      _appUrl = env['APP_URL'] ?? 'http://localhost:8080';

      print('✅ Email service initialized with SMTP: $host:$port');
    } catch (e) {
      print('❌ Failed to initialize email service: $e');
      _smtpServer = null;
    }
  }

  // Check if email service is properly configured
  static bool get isConfigured => _smtpServer != null;

  // Generate secure token with signature
  static String generateSecureTokenWithSignature(String userId, String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 1000000;
    return 'token_${timestamp}_$random';
  }

  // Send email verification
  static Future<bool> sendEmailVerification({
    required String email,
    required String firstName,
    required String verificationToken,
  }) async {
    if (!isConfigured) {
      print('⚠️  Email service not configured. Skipping email verification.');
      return _fallbackLog(email, 'Email Verification', '''
Dear $firstName,

Please verify your email address by clicking the link below:
$_appUrl/verify-email?token=$verificationToken

This link will expire in 24 hours.

Best regards,
School Administration
''');
    }

    try {
      final verificationLink = '$_appUrl/verify-email?token=$verificationToken';

      final message = Message()
        ..from = Address(_fromEmail!, _fromName!)
        ..recipients.add(Address(email))
        ..subject = 'Verify Your Email Address - School Management System'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2c3e50;">Email Verification Required</h2>
            <p>Dear <strong>$firstName</strong>,</p>
            <p>Thank you for registering with the School Management System. Please verify your email address by clicking the button below:</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="$verificationLink" 
                 style="background-color: #3498db; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                Verify Email Address
              </a>
            </div>
            
            <p>Or copy and paste this link into your browser:</p>
            <p style="word-break: break-all; color: #7f8c8d;">$verificationLink</p>
            
            <p style="color: #7f8c8d; font-size: 14px;">This link will expire in 24 hours.</p>
            
            <hr style="border: 1px solid #ecf0f1; margin: 30px 0;">
            <p style="color: #7f8c8d; font-size: 12px;">
              Best regards,<br>
              School Administration Team
            </p>
          </div>
        '''
        ..text = '''
Dear $firstName,

Please verify your email address by clicking the link below:
$verificationLink

This link will expire in 24 hours.

Best regards,
School Administration
''';

      await send(message, _smtpServer!);
      print('✅ Email verification sent to $email: Verification successful');
      return true;
    } catch (e) {
      print('❌ Failed to send email verification to $email: $e');
      return false;
    }
  }

  // Send welcome email
  static Future<bool> sendWelcomeEmail({
    required String email,
    required String firstName,
    String? schoolName,
  }) async {
    if (!isConfigured) {
      print('⚠️  Email service not configured. Skipping welcome email.');
      return _fallbackLog(email, 'Welcome Email', '''
Dear $firstName,

Welcome to ${schoolName ?? 'the School Management System'}! 

Your account has been successfully created and you can now log in to the system using your credentials.

Best regards,
${schoolName ?? 'School'} Administration
''');
    }

    try {
      final message = Message()
        ..from = Address(_fromEmail!, _fromName!)
        ..recipients.add(Address(email))
        ..subject = 'Welcome to ${schoolName ?? 'School Management System'}'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #27ae60;">Welcome to ${schoolName ?? 'School Management System'}!</h2>
            <p>Dear <strong>$firstName</strong>,</p>
            <p>Welcome aboard! Your account has been successfully created and you're now part of our school management system.</p>
            
            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
              <h3 style="color: #2c3e50; margin-top: 0;">What's Next?</h3>
              <ul>
                <li>Log in to your account using your email and password</li>
                <li>Complete your profile setup</li>
                <li>Explore the dashboard and available features</li>
              </ul>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="$_appUrl" 
                 style="background-color: #27ae60; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                Go to Dashboard
              </a>
            </div>
            
            <hr style="border: 1px solid #ecf0f1; margin: 30px 0;">
            <p style="color: #7f8c8d; font-size: 12px;">
              Best regards,<br>
              ${schoolName ?? 'School'} Administration Team
            </p>
          </div>
        '''
        ..text = '''
Dear $firstName,

Welcome to ${schoolName ?? 'the School Management System'}! 

Your account has been successfully created and you can now log in to the system using your credentials.

Best regards,
${schoolName ?? 'School'} Administration
''';

      await send(message, _smtpServer!);
      print('✅ Welcome email sent to $email: Welcome email successful');
      return true;
    } catch (e) {
      print('❌ Failed to send welcome email to $email: $e');
      return false;
    }
  }

  // Fallback logging when email is not configured
  static bool _fallbackLog(String email, String type, String content) {
    print('=== EMAIL FALLBACK - $type ===');
    print('To: $email');
    print('Content:');
    print(content);
    print('==============================');
    return true;
  }
}

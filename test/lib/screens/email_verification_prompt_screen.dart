import 'package:flutter/material.dart';
import 'package:test/services/email_verification_service.dart';

class EmailVerificationPromptScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onVerificationSuccess;

  const EmailVerificationPromptScreen({
    super.key,
    required this.email,
    this.onVerificationSuccess,
  });

  @override
  State<EmailVerificationPromptScreen> createState() => _EmailVerificationPromptScreenState();
}

class _EmailVerificationPromptScreenState extends State<EmailVerificationPromptScreen> {
  final _verificationService = EmailVerificationService();
  bool _isResending = false;

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);

    try {
      final result = await _verificationService.resendVerificationEmail(widget.email);
      
      if (mounted) {
        _showSuccessSnackBar(result['message'] ?? 'Verification email sent successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            
            // Email icon
            Icon(
              Icons.email_outlined,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Check Your Email',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Text(
              'We\'ve sent a verification email to:\n\n${widget.email}\n\nPlease check your inbox and click the verification link to activate your account.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Success indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email sent successfully!',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Resend email button
            TextButton(
              onPressed: _isResending ? null : _resendVerificationEmail,
              child: _isResending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Resending...'),
                      ],
                    )
                  : const Text('Resend Verification Email'),
            ),
            
            const SizedBox(height: 24),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Check your inbox for the verification email\n'
                    '• Click the verification link in the email\n'
                    '• Return to the app after verification\n'
                    '• Try logging in with your credentials',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Done button
            ElevatedButton(
              onPressed: () {
                if (widget.onVerificationSuccess != null) {
                  widget.onVerificationSuccess!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('I\'ve Verified My Email'),
            ),
          ],
        ),
      ),
    );
  }
}

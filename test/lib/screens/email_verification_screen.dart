import 'package:flutter/material.dart';
import 'package:test/services/email_verification_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onVerificationSuccess;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.onVerificationSuccess,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _verificationService = EmailVerificationService();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (_tokenController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter the verification token');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _verificationService.verifyEmail(_tokenController.text.trim());
      
      if (mounted) {
        _showSuccessSnackBar(result['message'] ?? 'Email verified successfully!');
        
        // Navigate back or call success callback
        if (widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!();
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
        title: const Text('Verify Email'),
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
              'Verify Your Email',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Text(
              'We\'ve sent a verification email to:\n${widget.email}\n\nPlease check your inbox and enter the verification token below.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Verification token input
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Verification Token',
                hintText: 'Enter the token from your email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              textCapitalization: TextCapitalization.none,
            ),
            
            const SizedBox(height: 24),
            
            // Verify button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyEmail,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Verifying...'),
                      ],
                    )
                  : const Text('Verify Email'),
            ),
            
            const SizedBox(height: 16),
            
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
            
            const SizedBox(height: 32),
            
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
                          'Didn\'t receive the email?',
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
                    '• Check your spam/junk folder\n• Make sure the email address is correct\n• Wait a few minutes for delivery',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

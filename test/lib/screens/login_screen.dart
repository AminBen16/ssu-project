import 'dart:developer' as developer;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/screens/registration_screen.dart';
import 'package:test/screens/forgot_password_screen.dart';
import 'package:test/screens/email_verification_prompt_screen.dart';
import 'package:test/services/staff_auth_service.dart';
import 'package:test/widgets/base_auth_form.dart';
import 'package:test/widgets/form_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();
  final _staffAuthService = StaffAuthService();
  bool _isLoading = false;
  bool _rememberMe = true; // State for the "Remember Me" checkbox

  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  Future<void> _loadRememberMePreference() async {
    final rememberMeValue = await _secureStorage.read(key: 'remember_me');
    if (rememberMeValue != null) {
      setState(() {
        _rememberMe = rememberMeValue.toLowerCase() == 'true';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      developer.log(
          'LoginScreen: Starting authentication for ${_emailController.text.trim()}');

      // Simple authentication - just email/password, backend determines role
      await _staffAuthService.authenticateStaff(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        context: context,
      );

      developer.log('LoginScreen: Authentication completed successfully');
    } catch (e) {
      developer.log('LoginScreen: Authentication failed: $e');

      // Check if error requires email verification
      String errorMessage = e.toString();
      if (errorMessage.contains('requiresEmailVerification') ||
          errorMessage.contains('verify your email address')) {
        // Extract email from error message if available
        String email = _emailController.text.trim();

        if (mounted) {
          // Show dialog to navigate to email verification prompt
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Email Verification Required'),
              content: Text(
                'Please verify your email address before logging in.\n\n'
                'We\'ve sent a verification email to:\n$email\n\n'
                'Would you like to view the verification instructions?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EmailVerificationPromptScreen(
                          email: email,
                          onVerificationSuccess: () {
                            // Retry login after successful verification
                            _signInWithEmailAndPassword();
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('View Instructions'),
                ),
              ],
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseAuthForm(
      title: 'Welcome Back!',
      formFields: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              StandardizedEmailField(
                controller: _emailController,
                labelText: 'Email',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),
              StandardizedPasswordField(
                controller: _passwordController,
                labelText: 'Password',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your password' : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ));
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              CheckboxListTile(
                title: const Text('Remember Me'),
                value: _rememberMe,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _rememberMe = newValue;
                    });
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
      actionButton: StandardizedLoadingButton(
        isLoading: _isLoading,
        onPressed: _signInWithEmailAndPassword,
        text: _selectedRole != null ? 'Sign in as $_selectedRole' : 'Sign In',
        loadingText: 'Signing in...',
      ),
      additionalWidgets: [
        TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const RegistrationScreen(),
            ));
          },
          child: const Text("Don't have an account? Create one"),
        ),
      ],
    );
  }


}


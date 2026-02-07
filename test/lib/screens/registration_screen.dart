import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/custom_exceptions.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/auth_service.dart';
import 'package:test/widgets/auth_wrapper.dart';
import 'package:test/widgets/base_auth_form.dart';
import 'package:test/widgets/form_components.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  // Form field controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.createAccount(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      final userDataProvider =
          Provider.of<UserDataProvider>(context, listen: false);
      await userDataProvider.initialize();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AuthFormUtils.showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AuthFormUtils.showErrorSnackBar(
          context, 'An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseAuthForm(
      title: 'Create Your Account',
      formFields: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              StandardizedTextFormField(
                controller: _firstNameController,
                labelText: 'First Name',
                prefixIcon: Icons.person,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 16),
              StandardizedTextFormField(
                controller: _lastNameController,
                labelText: 'Last Name',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your last name' : null,
              ),
              const SizedBox(height: 16),
              StandardizedEmailField(
                controller: _emailController,
                labelText: 'Email',
                validator: (v) => (v == null || v.isEmpty || !v.contains('@'))
                    ? 'Please enter a valid email'
                    : null,
              ),
              const SizedBox(height: 16),
              StandardizedPasswordField(
                controller: _passwordController,
                labelText: 'Password',
                validator: (v) => (v?.length ?? 0) < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              StandardizedPasswordField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                validator: (v) => v != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ],
          ),
        ),
      ],
      actionButton: StandardizedLoadingButton(
        isLoading: _isLoading,
        onPressed: _register,
        text: 'Create Account',
        loadingText: 'Creating Account...',
      ),
      additionalWidgets: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Go back to login
          },
          child: const Text('Already have an account? Sign In'),
        ),
      ],
    );
  }
}

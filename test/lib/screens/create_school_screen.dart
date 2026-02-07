import 'package:flutter/material.dart';
import 'package:test/services/api_client.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/custom_exceptions.dart';

class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  bool _isLoading = false;

  // Controllers
  final _schoolNameController = TextEditingController();
  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _schoolNameController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    // Validate password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate password strength
    if (_passwordController.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters long'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiClient.post(
        '/schools',
        body: {
          'schoolName': _schoolNameController.text.trim(),
          'adminFirstName': _adminFirstNameController.text.trim(),
          'adminLastName': _adminLastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'classification': 'Primary', // Default classification
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School and admin created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true on success
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}'),
              backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create New School')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('School Details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolNameController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'School name is required' : null,
            ),
            const Divider(height: 32),
            Text('Initial Director Account',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adminFirstNameController,
              decoration: const InputDecoration(
                labelText: 'Director\'s First Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'First name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adminLastNameController,
              decoration: const InputDecoration(
                labelText: 'Director\'s Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Last name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Director\'s Email (for login)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || !v.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Initial Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) => (v?.length ?? 0) < 6
                  ? 'Password must be at least 6 characters'
                  : null, //
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 32),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _submitForm,
              text: 'Create School & Director',
            ),
          ],
        ),
      ),
    );
  }
}

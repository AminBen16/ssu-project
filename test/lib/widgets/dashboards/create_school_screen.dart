import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:test/constants.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/services/api_client.dart';

class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String _selectedClassification = AppConstants.schoolClassifications.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final apiClient = ApiClient();

    try {
      // Call the local API endpoint to create school
      await apiClient.post('/schools', body: <String, dynamic>{
        'schoolName': _schoolNameController.text.trim(),
        'adminFirstName': _adminFirstNameController.text.trim(),
        'adminLastName': _adminLastNameController.text.trim(),
        'email': _adminEmailController.text.trim(),
        'password': _adminPasswordController.text,
        'classification': _selectedClassification,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School created successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      developer.log('API Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create school: ${e.toString()}')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _schoolNameController,
                decoration: const InputDecoration(labelText: 'School Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a school name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedClassification,
                decoration:
                    const InputDecoration(labelText: 'School Classification'),
                items: AppConstants.schoolClassifications
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedClassification = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text('Initial Admin Account',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adminFirstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: TextFormField(
                          controller: _adminLastNameController,
                          decoration:
                              const InputDecoration(labelText: 'Last Name'),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adminEmailController,
                decoration: const InputDecoration(labelText: 'Admin Email'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an admin email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adminPasswordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 32),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _createSchool,
                text: 'Create School',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


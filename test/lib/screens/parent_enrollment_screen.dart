// ignore: file_names
import 'dart:async';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/student_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/student_service.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/custom_exceptions.dart';

class ParentEnrollmentScreen extends StatefulWidget {
  const ParentEnrollmentScreen({super.key});

  @override
  State<ParentEnrollmentScreen> createState() => _ParentEnrollmentScreenState();
}

class _ParentEnrollmentScreenState extends State<ParentEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentService = StudentService();
  final _apiClient = ApiClient(baseUrl: 'http://localhost:8080');
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;

  // Form field controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _searchController = TextEditingController();
  final _addressController = TextEditingController();
  final _ninController = TextEditingController();

  // State for student search and selection
  Timer? _debounce;
  List<Student> _searchResults = [];
  final List<Student> _selectedStudents = [];
  bool _isSearching = false;
  String? _searchClassFilter;
  String? _searchSexFilter;
  String _searchMode = 'name'; // 'name' or 'regId'
// The phone number from the input.
  // ignore: unused_field
  final bool _isPhoneNumberValid =
      true; // Phone number is optional, so default to true.

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _addressController.dispose();
    _ninController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      final queryText = _searchController.text.trim();
      // Don't search if the text is empty, unless filters are applied.
      if (queryText.isEmpty &&
          _searchClassFilter == null &&
          _searchSexFilter == null) {
        setState(() {
          _searchResults = [];
        });
        return;
      }

      setState(() => _isSearching = true);

      try {
        final schoolId =
            Provider.of<UserDataProvider>(context, listen: false).school!.id.toString();

        final results = await _studentService.searchStudents(
          schoolId: schoolId,
          nameQuery: _searchMode == 'name' ? queryText : null,
          regIdQuery: _searchMode == 'regId' ? queryText : null,
          className: _searchClassFilter,
          sex: _searchSexFilter,
        );
        if (mounted) setState(() => _searchResults = results);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Search Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _enrollParent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please link at least one student.')),
      );
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final schoolId =
          // ignore: use_build_context_synchronously
          Provider.of<UserDataProvider>(context, listen: false).school!.id;

      // Step 1: Register the user with email and password using ApiClient
      final regResponse = await _apiClient.post('/auth/register', body: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        // Pass other parent details to be saved in the users table
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'address': _addressController.text.trim(),
        'nin': _ninController.text.trim(),
        'schoolId': schoolId,
        // The role will be set to 'parent' by default on the server
        // for non-first-time registrations.
      });

      // The server returns tokens and created user info in `data`.
      final token = regResponse['token'] as String?;
      final userData = regResponse['data'] as Map<String, dynamic>?;
      final parentId = userData != null ? userData['id']?.toString() : null;

      if (token == null || parentId == null) {
        throw Exception('Registration did not return credentials');
      }

      // Persist the JWT so the subsequent linking call is authenticated.
      await _secureStorage.write(key: 'jwt_token', value: token);

      // Step 2: Link the selected students to the created parent account.
      final studentIds = _selectedStudents.map((s) => s.id).toList();
      await _apiClient
          .post('/api/schools/$schoolId/parents/$parentId/students', body: {
        'studentIds': studentIds,
      });

      if (mounted) {
        final navigator =
            Navigator.of(context); // Capture navigator before async gap.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Parent account created successfully! Next, complete the profile.'),
            backgroundColor: Colors.green,
          ),
        );
        // Re-initialize to update the user list or other relevant data.
        await Provider.of<UserDataProvider>(context, listen: false)
            .refreshUserProfile();
        navigator.pop(); // Go back after successful registration.
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
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = Provider.of<UserDataProvider>(context).school;
    final classNames = school?.allClassNamesWithStreams ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Enroll Parent/Guardian')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent Information',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address (for login)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Initial Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) =>
                    (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
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
              const SizedBox(height: 16),
              InternationalPhoneNumberInput(
                //
                onInputChanged: (PhoneNumber number) {},
                onInputValidated: (bool value) {},
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                ),
                ignoreBlank: true,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                selectorTextStyle: const TextStyle(color: Colors.black),
                initialValue: PhoneNumber(isoCode: 'UG'),
                formatInput: true,
                keyboardType: TextInputType.phone,
                inputDecoration: const InputDecoration(
                    labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ninController,
                decoration: const InputDecoration(
                  labelText: 'NIN (National ID Number)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Link Students',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // Display selected students
              Wrap(
                spacing: 8.0,
                children: _selectedStudents
                    .map(
                      (student) => Chip(
                        label: Text(student.fullName),
                        onDeleted: () {
                          setState(() => _selectedStudents.remove(student));
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Search Filters
              Text('Search Filters',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'name', label: Text('By Name')),
                  ButtonSegment(value: 'regId', label: Text('By ID')),
                ],
                selected: {_searchMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _searchMode = newSelection.first;
                    _searchController.clear();
                    _searchResults.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _searchClassFilter,
                      hint: const Text('All Classes'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Classes'),
                        ),
                        ...classNames.map((name) =>
                            DropdownMenuItem(value: name, child: Text(name))),
                      ],
                      onChanged: (value) {
                        setState(() => _searchClassFilter = value);
                        _onSearchChanged(); // Trigger search on filter change
                      },
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _searchSexFilter,
                      hint: const Text('All Genders'),
                      items: const [
                        DropdownMenuItem<String>(
                            value: null, child: Text('All Genders')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() => _searchSexFilter = value);
                        _onSearchChanged(); // Trigger search on filter change
                      },
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Student search field
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: _searchMode == 'name'
                      ? 'Search by student first name...'
                      : 'Search by student Registration ID...',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.search),
                ),
              ),
              // Search results
              if (_searchResults.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final student = _searchResults[index];
                      final isSelected = _selectedStudents.any(
                        (s) => s.id == student.id,
                      );
                      return ListTile(
                        title: Text(student.fullName),
                        subtitle: Text(student.className),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.add_circle_outline),
                        onTap: () {
                          setState(() {
                            if (!isSelected) {
                              _selectedStudents.add(student);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _enrollParent,
                text: 'Enroll Parent',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

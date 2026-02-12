import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/subjects.dart';
import 'package:test/services/user_profile_service.dart';
import 'package:test/screens/class_stream_management_screen.dart';
import 'package:test/widgets/login_details_dialog.dart';
import 'package:test/models/user_roles.dart';

class StaffEnrollmentScreen extends StatefulWidget {
  const StaffEnrollmentScreen({super.key});

  @override
  State<StaffEnrollmentScreen> createState() => _StaffEnrollmentScreenState();
}

class _StaffEnrollmentScreenState extends State<StaffEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userProfileService = UserProfileService();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // State for dropdowns and multi-select chips
  DateTime? _selectedDate;
  String? _selectedTitle;
  String? _selectedSex;
  String? _selectedMaritalStatus;
  String? _selectedQualification;
  UserRole? _selectedRole;
  final Set<Subject> _selectedSubjects = <Subject>{};
  final Set<String> _selectedTeachingDays = <String>{};
  final Set<String> _selectedTeachingClasses = <String>{};
  String? _phoneNumberString;
  bool _obscurePassword = true;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> _titles = ['Mr', 'Mrs', 'Miss', 'Dr', 'Prof', 'Eng'];
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  final List<String> _qualificationOptions = [
    'High School',
    'Diploma',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Professional Certification',
    'Other',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ninController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _enrollStaff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      final schoolId = userData.userProfile!.schoolId.toString();

      final result = await _userProfileService.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!.toServerRole(), // FIXED: Use toServerRole() instead of .name
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        title: _selectedTitle,
        phoneNumber: _phoneNumberString,
        address: _addressController.text.trim(),
        nin: _ninController.text.trim(),
        qualification: _selectedQualification,
        schoolId: schoolId,
        subjectCodes: _selectedSubjects.map((s) => s.code).toList(),
        teachingClasses: _selectedTeachingClasses.toList(),
        teachingDays: _selectedTeachingDays.toList(),
      );

      if (result['user'] != null) {
        final createdEmail = result['user']['email'] ?? _emailController.text.trim();
        final userExists = await _userProfileService.checkUserExists(createdEmail);
        developer.log('User verification check - Email: $createdEmail, Exists: $userExists');

        if (mounted) {
          // Show login details dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => LoginDetailsDialog(
              userName: '${result['user']['firstName']} ${result['user']['lastName']}',
              email: createdEmail,
              password: _passwordController.text,
              role: _selectedRole!.displayName,
              onCopyCredentials: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Return to admin dashboard
              },
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff creation completed, but verification failed'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enroll staff: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll New Staff Member'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              _buildSectionCard(
                title: 'Personal Information',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedTitle,
                          items: _titles.map((title) {
                            return DropdownMenuItem(value: title, child: Text(title));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedTitle = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter first name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter email address';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      _phoneNumberString = number.phoneNumber;
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.DIALOG,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    selectorTextStyle: const TextStyle(color: Colors.black),
                    initialValue: PhoneNumber(isoCode: 'UG'),
                    textFieldController: _phoneNumberController,
                    formatInput: false,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    inputBorder: const OutlineInputBorder(),
                    onSaved: (PhoneNumber number) {
                      _phoneNumberString = number.phoneNumber;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Sex',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedSex,
                          items: _sexOptions.map((sex) {
                            return DropdownMenuItem(value: sex, child: Text(sex));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedSex = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Marital Status',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedMaritalStatus,
                          items: _maritalStatusOptions.map((status) {
                            return DropdownMenuItem(value: status, child: Text(status));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedMaritalStatus = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Professional Information Section
              _buildSectionCard(
                title: 'Professional Information',
                children: [
                  DropdownButtonFormField<UserRole>(
                    decoration: InputDecoration(
                      labelText: 'Staff Role *',
                      border: const OutlineInputBorder(),
                      errorText: _selectedRole == null ? 'Please select a role' : null,
                    ),
                    initialValue: _selectedRole,
                    items: _getAvailableRoles().map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          '  ${role.displayName}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedRole = value),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a staff role';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Highest Qualification',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedQualification,
                    items: _qualificationOptions.map((qualification) {
                      return DropdownMenuItem(value: qualification, child: Text(qualification));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedQualification = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ninController,
                    decoration: const InputDecoration(
                      labelText: 'National ID Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),

              // Teaching-specific fields (only shown for teachers AND when classes are available)
              if (_shouldShowTeachingFields()) ...[
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Teaching Information',
                  children: [
                    Text(
                      'Subjects',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: AllSubjects.list.map((subject) {
                        final isSelected = _selectedSubjects.contains(subject);
                        return FilterChip(
                          label: Text(subject.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSubjects.add(subject);
                              } else {
                                _selectedSubjects.remove(subject);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Teaching Days',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _weekDays.map((day) {
                        final isSelected = _selectedTeachingDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTeachingDays.add(day);
                              } else {
                                _selectedTeachingDays.remove(day);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Teaching Classes *',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_getAvailableClasses().isEmpty)
                      const Text('No classes available. Please configure classes first.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _getAvailableClasses().map((className) {
                          final isSelected = _selectedTeachingClasses.contains(className);
                          return FilterChip(
                            label: Text(className),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTeachingClasses.add(className);
                                } else {
                                  _selectedTeachingClasses.remove(className);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ],

              // Warning message when no classes are available for teachers
              if (_isTeacherRole() && _getAvailableClasses().isEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Classes Not Configured',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Teaching staff cannot be enrolled until classes are configured. Please go to Class/Stream Management to set up classes first.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ClassStreamManagementScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.class_),
                          label: const Text('Configure Classes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Account Information Section
              _buildSectionCard(
                title: 'Account Information',
                children: [
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _enrollStaff,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enroll Staff Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 16)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  bool _shouldShowTeachingFields() {
    return _isTeacherRole() && _getAvailableClasses().isNotEmpty;
  }

  bool _isTeacherRole() {
    return _selectedRole != null && UserRole.allTeachingRoles.contains(_selectedRole!);
  }

  List<String> _getAvailableClasses() {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    return userData.school?.allClassNamesWithStreams ?? [];
  }

  List<UserRole> _getAvailableRoles() {
    // Filter roles to only show teaching roles for teachers
    if (_isTeacherRole()) {
      return UserRole.allTeachingRoles;
    }
    return UserRole.allStaffRoles;
  }
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/subjects.dart';
import 'package:test/services/enrollment_service.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/widgets/login_details_dialog.dart';

class StudentEnrollmentScreen extends StatefulWidget {
  const StudentEnrollmentScreen({super.key});

  @override
  State<StudentEnrollmentScreen> createState() =>
      _StudentEnrollmentScreenState();
}

class _StudentEnrollmentScreenState extends State<StudentEnrollmentScreen> {
  final _enrollmentService = EnrollmentService();
  bool _isLoading = false;
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(), // Step 1: Student Info
    GlobalKey<FormState>(), // Step 2: Subject Selection
    GlobalKey<FormState>(), // Step 3: Parent & Other Details
  ];

  // Controllers for form fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentNinController = TextEditingController();
  final _addressController = TextEditingController();
  final _specialNeedsController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedClass;
  String? _selectedSex;
  String? _selectedReligion;
  bool _hasSpecialNeeds = false;
  String? _studentPhoneNumberString;
  String? _parentPhoneNumberString;
// Optional, so default to true
// Phone number is now optional.
  final Set<Subject> _selectedPrincipalSubjects = {};
  final Set<Subject> _selectedOptionalSubsidiaries = {};

  final List<String> _religions = [
    'Christianity',
    'Islam', 
    'Hinduism',
    'Buddhism',
    'Sikhism',
    'Judaism',
    'Traditional African',
    'Other',
    'Prefer not to say',
  ];
  // ... add controllers for all other fields from your spec

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _parentNameController.dispose();
    _parentNinController.dispose();
    _addressController.dispose();
    _specialNeedsController.dispose();
    _selectedPrincipalSubjects.clear();
    _selectedOptionalSubsidiaries.clear();
    // ... dispose all other controllers
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2010),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _enrollStudent() async {
    // Final validation is handled by the stepper's continue logic.

    setState(() => _isLoading = true);

    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).userProfile?.schoolId;

    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: School ID not found.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Add explicit null checks for required fields to prevent crashes.
    if (_selectedClass == null ||
        _selectedDate == null ||
        _selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please ensure Class, Date of Birth, and Sex are selected.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final allSubjectsForLevel = _getSubjectsForLevel();
    final compulsorySubjects = allSubjectsForLevel.where((s) => s.isCompulsory);
    final allSelectedSubjects = {
      ...compulsorySubjects,
      ..._selectedPrincipalSubjects,
      ..._selectedOptionalSubsidiaries,
    };

    // --- Subject Count Validation ---
    final isOLevel =
        _getSubjectsForLevel().firstOrNull?.level == SchoolLevel.oLevel;

    if (isOLevel) {
      final baseClassName = _selectedClass!.split(' ').take(2).join(' ');
      final optionalCount = _selectedPrincipalSubjects.length;

      if (baseClassName == 'Senior 1' || baseClassName == 'Senior 2') {
        // Rule for S1 and S2: 3 to 7 optional subjects
        if (optionalCount < 3 || optionalCount > 7) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Senior 1 & 2 students must select 3 to 7 optional subjects. You have selected $optionalCount.',
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else {
        // Rule for S3 and S4: 1 to 3 optional subjects
        if (optionalCount < 1 || optionalCount > 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Senior 3 & 4 students must select 1 to 3 optional subjects. You have selected $optionalCount.',
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
    } else {
      // A-Level students must take exactly 3 principal subjects.
      if (_selectedPrincipalSubjects.length != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A-Level students must select exactly 3 principal subjects.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    }
    // --- End Validation ---

    try {
      await _enrollmentService.enrollStudent(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        dateOfBirth: _selectedDate!, // Safe now due to the check above
        className: _selectedClass!, // Safe now due to the check above
        parentName: _parentNameController.text.trim(),
        parentNin: _parentNinController.text.trim(),
        sex: _selectedSex!, // Safe now due to the check above
        religion: _selectedReligion,
        address: _addressController.text.trim(),
        phoneNumber: _studentPhoneNumberString,
        parentContact: _parentPhoneNumberString,
        specialNeeds:
            _hasSpecialNeeds ? _specialNeedsController.text.trim() : null,
        // ... pass all other student data
        subjectCodes: allSelectedSubjects.map((s) => s.code).toList(),
      );
      
      // Show login details dialog on successful enrollment
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent accidental dismissal
          builder: (context) => LoginDetailsDialog(
            userName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            email: _emailController.text.trim(),
            password: _passwordController.text, // Use the original password
            role: 'Student',
            onCopyCredentials: () {
              // After copying credentials, close the dialog and return to previous screen
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to admin dashboard
            },
          ),
        );
      }
    } catch (e) {
      // The EnrollmentService should throw specific, user-friendly exceptions.
      // For now, we just show the raw error.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Subject> _getSubjectsForLevel() {
    if (_selectedClass == null) return [];
    // The null check above ensures _selectedClass is not null here.
    // We check against the base class name, without the stream.
    final baseClassName = _selectedClass!.split(' ').take(2).join(' ');
    final isOLevel = [
      'Senior 1',
      'Senior 2',
      'Senior 3',
      'Senior 4',
    ].contains(baseClassName);

    return isOLevel ? OLevelSubjects.all : ALevelSubjects.all;
  }

  /// Automatically selects the appropriate subsidiary subject based on the
  /// three chosen principal subjects.
  void _updateSubsidiarySelection() {
    // This logic only applies to A-Level.
    if (_getSubjectsForLevel().first.level != SchoolLevel.aLevel) return;

    if (_selectedPrincipalSubjects.length == 3) {
      // Define science subject codes for rule application.
      const scienceCodes = {'P510', 'P525', 'P530', 'P425', 'P515'};

      final isScienceCombination = _selectedPrincipalSubjects.every(
        (s) => scienceCodes.contains(s.code),
      );
      final hasPrincipalMath = _selectedPrincipalSubjects.any(
        (s) => s.code == 'P425',
      );

      final allSubjects = _getSubjectsForLevel();
      final subMath = allSubjects.firstWhere((s) => s.code == 'S475');
      final subIct = allSubjects.firstWhere((s) => s.code == 'S850');

      _selectedOptionalSubsidiaries.clear();
      if (isScienceCombination && !hasPrincipalMath) {
        _selectedOptionalSubsidiaries.add(subMath);
      } else {
        _selectedOptionalSubsidiaries.add(subIct);
      }
    } else {
      _selectedOptionalSubsidiaries.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = Provider.of<UserDataProvider>(context, listen: false).userProfile?.schoolId;
    
    // Fetch available classes dynamically
    Future<List<String>> availableClassesFuture;
    if (schoolId != null && schoolId.isNotEmpty) {
      availableClassesFuture = _enrollmentService.getAllAvailableClasses(schoolId);
    } else {
      availableClassesFuture = Future.value([]);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll New Student'),
      ),
      body: FutureBuilder<List<String>>(
        future: availableClassesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading classes: ${snapshot.error}'),
            );
          }
          
          final availableClasses = snapshot.data ?? [];
          
          // Fallback class options if no data available
          final fallbackClasses = [
            'Senior 1',
            'Senior 2', 
            'Senior 3',
            'Senior 4',
            'Senior 1 East',
            'Senior 1 West',
            'Senior 2 East',
            'Senior 2 West',
            'Senior 3 East',
            'Senior 3 West',
            'Senior 4 East',
            'Senior 4 West',
          ];
          
          final finalClasses = availableClasses.isNotEmpty ? availableClasses : fallbackClasses;

          return Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / _getSteps(finalClasses).length,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
              ),
              Expanded(
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_formKeys[_currentStep].currentState!.validate()) {
                      final isLastStep =
                          _currentStep == _getSteps(finalClasses).length - 1;
                      if (isLastStep) {
                        _enrollStudent();
                      } else {
                        setState(() => _currentStep += 1);
                      }
                    }
                  },
                  onStepCancel: _currentStep == 0
                      ? null
                      : () => setState(() => _currentStep -= 1),
                  steps: _getSteps(finalClasses),
              controlsBuilder: (context, details) {
                final isLastStep =
                    _currentStep == _getSteps(availableClasses).length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      if (isLastStep)
                        Expanded(
                          child: LoadingButton(
                            isLoading: _isLoading,
                            onPressed: details.onStepContinue,
                            text: 'Enroll Student',
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text('Next'),
                        ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          )]); // Closing Stepper
        }
      ),
    );
  }

  List<Step> _getSteps(List<String> availableClasses) {
    return [
      Step(
        title: const Text('Student Information'),
        content: Form(
          key: _formKeys[0],
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter a first name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter a last name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: 'Student Email (for login)'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter an email.';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration:
                        const InputDecoration(labelText: 'Initial Password'),
                    obscureText: true,
                    validator: (v) =>
                        (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (v) => v != _passwordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClass,
                    hint: availableClasses.isEmpty ? const Text('No classes available') : const Text('Class'),
                    items: availableClasses.isEmpty 
                        ? [const DropdownMenuItem(value: '', child: Text('No classes available'))]
                        : availableClasses
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                    onChanged: availableClasses.isEmpty ? null : (value) {
                      setState(() {
                        _selectedClass = value;
                        _selectedPrincipalSubjects.clear();
                        _selectedOptionalSubsidiaries.clear();
                      });
                    },
                    validator: (value) =>
                        availableClasses.isEmpty ? 'No classes available' : 
                        (value == null || value.trim().isEmpty) ? 'Please select a class' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) =>
                        value!.isEmpty ? 'Please select a date of birth' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSex,
                          hint: const Text('Sex'),
                          items: ['Male', 'Female']
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSex = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedReligion,
                          hint: const Text('Religion'),
                          items: _religions
                              .map((r) =>
                                  DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedReligion = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Subject Selection'),
        content: Form(
          key: _formKeys[1],
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _selectedClass == null
                  ? const Text('Please select a class in the previous step.')
                  : _buildStudentSubjectSelection(),
            ),
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Parent & Other Details'),
        content: Form(
          key: _formKeys[2],
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parent/Guardian Information',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parentNameController,
                    decoration:
                        const InputDecoration(labelText: 'Parent\'s Full Name'),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter the parent\'s name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parentNinController,
                    decoration: const InputDecoration(
                        labelText: 'Parent\'s NIN (National ID Number)'),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter the parent\'s NIN'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      _parentPhoneNumberString = number.phoneNumber;
                    },
                    onInputValidated: (bool value) {},
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    ),
                    ignoreBlank: true, // Parent phone number is now optional.
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    selectorTextStyle: const TextStyle(color: Colors.black),
                    initialValue: PhoneNumber(isoCode: 'UG'),
                    formatInput: true,
                    keyboardType: TextInputType.phone,
                    inputDecoration: const InputDecoration(
                      labelText: 'Parent\'s Phone Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Additional Student Details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration:
                        const InputDecoration(labelText: 'Home Address'),
                  ),
                  const SizedBox(height: 16),
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      _studentPhoneNumberString = number.phoneNumber;
                    },
                    onInputValidated: (bool value) {},
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    ),
                    ignoreBlank: true, // Student phone number is optional
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    selectorTextStyle: const TextStyle(color: Colors.black),
                    initialValue: PhoneNumber(isoCode: 'UG'),
                    formatInput: true,
                    keyboardType: TextInputType.phone,
                    inputDecoration: const InputDecoration(
                      labelText: 'Student\'s Phone Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Any Special Need or Health Concern?'),
                    value: _hasSpecialNeeds,
                    onChanged: (val) => setState(() => _hasSpecialNeeds = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_hasSpecialNeeds)
                    TextFormField(
                      controller: _specialNeedsController,
                      decoration: const InputDecoration(
                        labelText: 'Please explain',
                      ),
                      maxLines: 3,
                    ),
                ],
              ),
            ),
          ),
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildStudentSubjectSelection() {
    final subjects = _getSubjectsForLevel();
    if (subjects.isEmpty) return const SizedBox.shrink();

    final baseClassName = _selectedClass!.split(' ').take(2).join(' ');
    final isOLevel = [
      'Senior 1',
      'Senior 2',
      'Senior 3',
      'Senior 4',
    ].contains(baseClassName);

    return isOLevel
        ? _buildOLevelSubjectSelection(subjects)
        : _buildALevelSubjectSelection(subjects);
  }

  Widget _buildOLevelSubjectSelection(List<Subject> subjects) {
    final compulsory = subjects.where((s) => s.isCompulsory).toList();
    final optional = subjects.where((s) => !s.isCompulsory).toList();

    final baseClassName = _selectedClass!.split(' ').take(2).join(' ');
    final String optionalSubjectsHint;
    if (baseClassName == 'Senior 1' || baseClassName == 'Senior 2') {
      optionalSubjectsHint = 'Optional Subjects (Select 3 to 7)';
    } else {
      optionalSubjectsHint = 'Optional Subjects (Select 1 to 3)';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compulsory.isNotEmpty) ...[
          const Text(
            'Compulsory Subjects',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...compulsory.map(
            (subject) => CheckboxListTile(
              title: Text(subject.name),
              value: true,
              onChanged: null,
              dense: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (optional.isNotEmpty) ...[
          Text(
            optionalSubjectsHint,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...optional.map(
            (subject) => CheckboxListTile(
              title: Text(subject.name),
              value: _selectedPrincipalSubjects.contains(subject),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedPrincipalSubjects.add(subject);
                  } else {
                    _selectedPrincipalSubjects.remove(subject);
                  }
                });
              },
              dense: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildALevelSubjectSelection(List<Subject> subjects) {
    final compulsory = subjects.where((s) => s.isCompulsory).toList();
    final principals = subjects
        .where((s) => !s.isCompulsory && !s.code.startsWith('S'))
        .toList();

    final bool subsidiaryMathSelected = _selectedOptionalSubsidiaries.any(
      (s) => s.code == 'S475',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compulsory Subjects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...compulsory.map(
          (subject) => CheckboxListTile(
            title: Text(subject.name),
            value: true,
            onChanged: null,
            dense: true,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Principal Subjects (Select exactly 3)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...principals.map(
          (subject) => CheckboxListTile(
            title: Text(subject.name),
            value: _selectedPrincipalSubjects.contains(subject),
            onChanged: (subject.code == 'P425' && subsidiaryMathSelected)
                ? null
                : (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (_selectedPrincipalSubjects.length < 3) {
                          _selectedPrincipalSubjects.add(subject);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You can only select up to 3 principal subjects.',
                              ),
                            ),
                          );
                        }
                      } else {
                        _selectedPrincipalSubjects.remove(subject);
                      }
                      _updateSubsidiarySelection();
                    });
                  },
            dense: true,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Optional Subsidiary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_selectedOptionalSubsidiaries.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.check_box, color: Colors.green),
            title: Text(_selectedOptionalSubsidiaries.first.name),
            dense: true,
          )
        else
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Select 3 principal subjects to assign subsidiary.'),
            dense: true,
          ),
      ],
    );
  }
}

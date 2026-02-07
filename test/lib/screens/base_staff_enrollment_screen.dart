import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/staff_enrollment_service.dart';
import 'package:test/widgets/currency_input_formatter.dart';
import 'package:test/widgets/loading_button.dart';

class BaseStaffEnrollmentScreen extends StatefulWidget {
  final String appBarTitle;
  final List<UserRole> availableRoles;
  final bool isTeacherForm;

  const BaseStaffEnrollmentScreen({
    super.key,
    required this.appBarTitle,
    required this.availableRoles,
    required this.isTeacherForm,
  });

  @override
  State<BaseStaffEnrollmentScreen> createState() =>
      _BaseStaffEnrollmentScreenState();
}

class _BaseStaffEnrollmentScreenState extends State<BaseStaffEnrollmentScreen> {
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(), // Step 1: Account
    GlobalKey<FormState>(), // Step 2: Personal
    GlobalKey<FormState>(), // Step 3: Salary
    GlobalKey<FormState>(), // Step 4: Teaching (optional)
  ];
  final _enrollmentService = StaffEnrollmentService();
  bool _isLoading = false;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _ninController = TextEditingController();
  final _dobController = TextEditingController();
  final _salaryController = TextEditingController();
  final _allowancesController = TextEditingController();

  // State
  UserRole? _selectedRole;
  String? _selectedTitle;
  DateTime? _selectedDate;
  String? _selectedSex;
  String? _selectedQualification;
  String? _selectedMaritalStatus;
  final Set<Subject> _selectedSubjects = {};
  final Set<String> _selectedTeachingDays = {};
  final Set<String> _selectedTeachingClasses = {};
  String? _phoneNumberString;
// Phone number is optional, so default to true.

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void dispose() {
    // Dispose all controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _ninController.dispose();
    _dobController.dispose();
    _salaryController.dispose();
    _allowancesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _enrollStaff() async {
    setState(() => _isLoading = true);

    final schoolId =
        Provider.of<UserDataProvider>(context, listen: false).school!.id;

    // Sanitize currency inputs before parsing
    final salaryString = _salaryController.text.replaceAll(',', '');
    final allowancesString = _allowancesController.text.replaceAll(',', '');

    try {
      await _enrollmentService.enrollStaff(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        schoolId: schoolId.toString(),
        role: _selectedRole!,
        title: _selectedTitle,
        phoneNumber: _phoneNumberString,
        salary: double.tryParse(salaryString),
        allowances: double.tryParse(allowancesString),
        address: _addressController.text.trim(),
        nin: _ninController.text.trim(),
        dateOfBirth: _selectedDate,
        maritalStatus: _selectedMaritalStatus,
        qualification: _selectedQualification,
        sex: _selectedSex,
        subjectCodes: _selectedSubjects.map((s) => s.code).toList(),
        teachingClasses: _selectedTeachingClasses.toList(),
        teachingDays: _selectedTeachingDays.toList(),
      );

      // This code now runs ONLY if the try block completes without any errors.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff enrolled successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred: '
                  '${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Step> _getSteps() {
    final school = Provider.of<UserDataProvider>(context, listen: false).school;
    final allSubjects = {...OLevelSubjects.all, ...ALevelSubjects.all}.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final steps = [
      Step(
        title: const Text('Account Details'),
        content: Form(
          key: _formKeys[0],
          child: _buildSectionCard(
            children: [
              TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email Address (for login)'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _passwordController,
                  decoration:
                      const InputDecoration(labelText: 'Initial Password'),
                  obscureText: true,
                  validator: (v) =>
                      (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
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
              DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  hint: const Text('Role'),
                  items: widget.availableRoles
                      .map((role) => DropdownMenuItem(
                          value: role, child: Text(role.displayName)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (v) => v == null ? 'Required' : null),
            ],
          ),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Personal & Contact'),
        content: Form(
          key: _formKeys[1],
          child: _buildSectionCard(
            children: [
              DropdownButtonFormField<String>(
                  //
                  initialValue: _selectedTitle,
                  hint: const Text('Title'),
                  items: ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof']
                      .map((title) =>
                          DropdownMenuItem(value: title, child: Text(title)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedTitle = value)),
              const SizedBox(height: 24),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  _phoneNumberString = number.phoneNumber;
                },
                onInputValidated: (bool value) {},
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                ),
                ignoreBlank: true,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                selectorTextStyle: const TextStyle(color: Colors.black),
                initialValue: PhoneNumber(isoCode: 'UG'), // Default to Uganda
                formatInput: true,
                keyboardType: TextInputType.phone, //
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _ninController,
                  decoration:
                      const InputDecoration(labelText: 'NIN (National ID)')),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: () => _selectDate(context)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedQualification,
                hint: const Text('Highest Qualification'),
                items: [
                  'Certificate',
                  'Diploma',
                  'Bachelors Degree',
                  'Masters Degree',
                  'Doctorate (PhD)'
                ]
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedQualification = v),
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
                          onChanged: (v) => setState(() => _selectedSex = v))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                          initialValue: _selectedMaritalStatus,
                          hint: const Text('Marital Status'),
                          items: ['Single', 'Married', 'Divorced', 'Widowed']
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedMaritalStatus = v))),
                ],
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Salary Details'),
        content: Form(
          key: _formKeys[2],
          child: _buildSectionCard(
            children: [
              TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(
                      labelText: 'Monthly Salary (Optional)',
                      prefixText: 'UGX '),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()]),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _allowancesController,
                  decoration: const InputDecoration(
                      labelText: 'Monthly Allowances (Optional)',
                      prefixText: 'UGX '),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()]),
            ],
          ),
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];

    if (widget.isTeacherForm) {
      steps.add(
        Step(
          title: const Text('Teaching Details'),
          content: Form(
            key: _formKeys[3],
            child: _buildSectionCard(
              children: [
                Text('Teaching Days',
                    style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                    spacing: 8.0,
                    children: _weekDays
                        .map((day) => FilterChip(
                            label: Text(day),
                            selected: _selectedTeachingDays.contains(day),
                            onSelected: (selected) => setState(() => selected
                                ? _selectedTeachingDays.add(day)
                                : _selectedTeachingDays.remove(day))))
                        .toList()),
                const SizedBox(height: 24),
                Text('Teaching Classes',
                    style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                    spacing: 8.0,
                    children: (school?.allClassNamesWithStreams ?? [])
                        .map((className) => FilterChip(
                            label: Text(className),
                            selected:
                                _selectedTeachingClasses.contains(className),
                            onSelected: (selected) => setState(() => selected
                                ? _selectedTeachingClasses.add(className)
                                : _selectedTeachingClasses.remove(className))))
                        .toList()),
                if (school?.allClassNamesWithStreams.isEmpty ?? true) ...[
                  const SizedBox(height: 8),
                  const Text('No classes available. Manage class streams in '
                      'school settings.'),
                ],
                const SizedBox(height: 24),
                Text('Subjects Taught',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4)),
                  child: ListView(
                    children: allSubjects
                        .map((subject) => CheckboxListTile(
                            title: Text(subject.name),
                            value: _selectedSubjects.contains(subject),
                            onChanged: (selected) => setState(() =>
                                selected == true
                                    ? _selectedSubjects.add(subject)
                                    : _selectedSubjects.remove(subject)),
                            dense: true))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          isActive: _currentStep >= 3,
          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        ),
      );
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / steps.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
          ),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_formKeys[_currentStep].currentState!.validate()) {
                  final isLastStep = _currentStep == steps.length - 1;
                  if (isLastStep) {
                    _enrollStaff();
                  } else {
                    setState(() => _currentStep += 1);
                  }
                }
              },
              onStepCancel: _currentStep == 0
                  ? null
                  : () => setState(() => _currentStep -= 1),
              steps: steps,
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == steps.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      if (isLastStep)
                        Expanded(
                          child: LoadingButton(
                            isLoading: _isLoading,
                            onPressed: details.onStepContinue,
                            text: 'Enroll Staff',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withAlpha(128),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

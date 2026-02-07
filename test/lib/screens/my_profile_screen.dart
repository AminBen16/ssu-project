import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:test/models/subjects.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/enrollment_service.dart';
import 'package:test/services/user_profile_service.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/screens/audio_chat_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userProfileService = UserProfileService();
  final _enrollmentService = EnrollmentService();
  bool _isLoading = false;
  bool _isEditMode = false;

  // Form field controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _ninController;
  late TextEditingController _dobController;

  // State for dropdowns and multi-select chips
  DateTime? _selectedDate;
  String? _selectedTitle;
  String? _selectedSex;
  String? _selectedMaritalStatus;
  late Set<Subject> _selectedSubjects;
  String? _selectedQualification;
  late Set<String> _selectedTeachingClasses;
  late Set<String> _selectedTeachingDays;
  String? _phoneNumberString;
  List<String> _availableClasses = [];
  bool _isFetchingClasses = false;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _fetchAvailableClasses();
  }

  void _loadProfileData() {
    // (Re)Initialize controllers with the current user's data from the provider
    final profile =
        Provider.of<UserDataProvider>(context, listen: false).userProfile!;
    _firstNameController = TextEditingController(text: profile.firstName ?? '');
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _selectedTitle = profile.title;
    _phoneNumberString = profile.phoneNumber;
    _addressController = TextEditingController(text: profile.address);
    _ninController = TextEditingController(text: profile.nin);

    const qualificationOptions = [
      'Certificate',
      'Diploma',
      'Bachelors Degree',
      'Masters Degree',
      'Doctorate (PhD)'
    ];
    // Defensive check: Ensure the stored value is one of the valid options.
    // If not, default to null to prevent a crash.
    if (profile.qualification != null &&
        qualificationOptions.contains(profile.qualification)) {
      _selectedQualification = profile.qualification;
    } else {
      _selectedQualification = null;
    }

    _selectedDate = profile.dateOfBirth;
    _dobController = TextEditingController(
      text: _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : '',
    );

    _selectedSex = profile.sex;
    _selectedMaritalStatus = profile.maritalStatus;

    // Initialize teacher-specific fields
    _selectedSubjects = (profile.subjectCodes ?? [])
        .map((code) => findSubjectByCode(code))
        .whereType<Subject>()
        .toSet();
    _selectedTeachingClasses = (profile.teachingClasses ?? []).toSet();
    _selectedTeachingDays = (profile.teachingDays ?? []).toSet();
  }

  Future<void> _fetchAvailableClasses() async {
    setState(() => _isFetchingClasses = true);
    try {
      final schoolId =
          Provider.of<UserDataProvider>(context, listen: false).userProfile?.schoolId;
      if (schoolId != null) {
        final classes = await _enrollmentService.getAllAvailableClasses(schoolId);
        if (mounted) {
          setState(() {
            _availableClasses = classes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingClasses = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _ninController.dispose();
    _dobController.dispose();
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

  void _showChangePasswordDialog() {
    final passwordFormKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: passwordFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Current Password'),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (v) =>
                    (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
                validator: (v) => v != newPasswordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordFormKey.currentState!.validate()) {
                // Capture context-dependent variables before the async gap.
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                try {
                  await _userProfileService.changeUserPassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  navigator.pop(); // Close the dialog on success.
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('An error occurred: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // Also close the dialog on error.
                  navigator.pop();
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final user =
        Provider.of<UserDataProvider>(context, listen: false).userProfile!;

    final dataToUpdate = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'title': _selectedTitle,
      'phoneNumber': _phoneNumberString,
      'address': _addressController.text.trim(),
      'nin': _ninController.text.trim(),
      'dateOfBirth': _selectedDate,
      'sex': _selectedSex,
      'maritalStatus': _selectedMaritalStatus,
      'qualification': _selectedQualification,
      if (user.role.isTeacher) ...{
        'subjectCodes': _selectedSubjects.map((s) => s.code).toList(),
        'teachingClasses': _selectedTeachingClasses.toList(),
        'teachingDays': _selectedTeachingDays.toList(),
      }
    };

    try {
      await _userProfileService.updateUserProfile(user.uid, dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Pop the screen to return to the previous view, which will have the updated data.
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString()}')),
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
        title: Text(_isEditMode ? 'Edit Profile' : 'My Profile'),
        actions: _isEditMode
            ? [
                TextButton(
                  onPressed: () {
                    _loadProfileData(); // Reset changes
                    setState(() => _isEditMode = false);
                  },
                  child: const Text('Cancel'),
                )
              ]
            : [],
      ),
      body: _isEditMode ? _buildEditView() : _buildDisplayView(),
    );
  }

  /// Builds the read-only display view of the user's profile.
  Widget _buildDisplayView() {
    final user = Provider.of<UserDataProvider>(context).userProfile!;

    ImageProvider? backgroundImage;
    if (user.profilePictureUrl != null) {
      backgroundImage = CachedNetworkImageProvider(user.profilePictureUrl!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: backgroundImage,
                    child: backgroundImage == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(user.role.displayName,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDisplaySectionCard(
            title: 'Personal & Contact Details',
            children: [
              _buildDisplayTile(Icons.badge_outlined, 'User ID',
                  user.userRegId ?? 'Not Assigned'),
              _buildDisplayTile(Icons.email_outlined, 'Email', user.email),
              _buildDisplayTile(Icons.phone_outlined, 'Phone',
                  user.phoneNumber ?? 'Not provided'),
              _buildDisplayTile(Icons.home_outlined, 'Address',
                  user.address ?? 'Not provided'),
              _buildDisplayTile(
                  Icons.fingerprint, 'NIN', user.nin ?? 'Not provided'),
              _buildDisplayTile(
                  Icons.cake_outlined,
                  'Date of Birth',
                  user.dateOfBirth != null
                      ? DateFormat.yMMMd().format(user.dateOfBirth!)
                      : 'Not provided'),
              _buildDisplayTile(
                  Icons.workspace_premium_outlined,
                  'Highest Qualification',
                  user.qualification ?? 'Not provided'),
              _buildDisplayTile(Icons.people_outline, 'Marital Status',
                  user.maritalStatus ?? 'Not provided'),
              _buildDisplayTile(
                  Icons.person_outline, 'Sex', user.sex ?? 'Not provided'),
            ],
          ),
          const SizedBox(height: 24),
          if (user.role.isTeacher) ...[
            _buildDisplaySectionCard(
              title: 'Teaching Details',
              children: [
                _buildChipListTile('Teaching Days', user.teachingDays),
                _buildChipListTile('Teaching Classes', user.teachingClasses),
                _buildChipListTile(
                    'Subjects Taught',
                    user.subjectCodes
                        ?.map((code) => findSubjectByCode(code)?.name)
                        .whereType<String>()
                        .toList()),
              ],
            ),
            const SizedBox(height: 24),
          ],
          ElevatedButton.icon(
            onPressed: () => setState(() => _isEditMode = true),
            icon: const Icon(Icons.edit),
            label: const Text('Update My Profile'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          if (user.role.name != 'parent')
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AudioChatScreen(),
                ),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Bot'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
        ],
      ),
    );
  }

  /// Builds the form view for editing the user's profile.
  Widget _buildEditView() {
    final user =
        Provider.of<UserDataProvider>(context, listen: false).userProfile!;
    final isTeacher = user.role.isTeacher;
    final allSubjects = {...OLevelSubjects.all, ...ALevelSubjects.all}.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Personal & Contact Details',
              children: [
                const SizedBox(height: 16),
                _buildTextField(_firstNameController, 'First Name',
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                _buildTextField(_lastNameController, 'Last Name',
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                _buildTextField(_emailController, 'Email Address (Login)',
                    enabled: false),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedTitle,
                    items: ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof']
                        .map((title) => DropdownMenuItem(
                              value: title,
                              child: Text(title),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedTitle = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      _phoneNumberString = number.phoneNumber;
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    ),
                    ignoreBlank: true,
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    initialValue: PhoneNumber(isoCode: 'UG'),
                    formatInput: true,
                  ),
                ),
                _buildTextField(_addressController, 'Address'),
                _buildTextField(_ninController, 'NIN (National ID Number)'),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Highest Qualification',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedQualification,
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
                        decoration: const InputDecoration(
                            labelText: 'Sex', border: OutlineInputBorder()),
                        initialValue: _selectedSex,
                        items: ['Male', 'Female']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSex = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Marital Status',
                            border: OutlineInputBorder()),
                        initialValue: _selectedMaritalStatus,
                        items: ['Single', 'Married', 'Divorced', 'Widowed']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedMaritalStatus = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Change Password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isTeacher) ...[
              _buildSectionCard(
                title: 'Teaching Details',
                children: [
                  const SizedBox(height: 16),
                  Text('Teaching Days',
                      style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8.0,
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
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Teaching Classes',
                      style: Theme.of(context).textTheme.titleMedium),
                  _isFetchingClasses
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Wrap(
                          spacing: 8.0,
                          children: _availableClasses.map((className) {
                      final isSelected =
                          _selectedTeachingClasses.contains(className);
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
                      );
                    }).toList(),
                        ),
                  const SizedBox(height: 24),
                  Text('Subjects Taught',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView(
                      children: allSubjects.map((subject) {
                        return CheckboxListTile(
                          title: Text(subject.name),
                          value: _selectedSubjects.contains(subject),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedSubjects.add(subject);
                              } else {
                                _selectedSubjects.remove(subject);
                              }
                            });
                          },
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 32),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _updateProfile,
              text: 'Save Changes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDisplayTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(value),
      subtitle: Text(label),
      dense: true,
    );
  }

  Widget _buildChipListTile(String title, List<String>? items) {
    if (items == null || items.isEmpty) {
      return _buildDisplayTile(Icons.block, title, 'Not specified');
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: items.map((item) => Chip(label: Text(item))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: !enabled ? Colors.grey.shade200 : null,
        ),
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
      ),
    );
  }
}

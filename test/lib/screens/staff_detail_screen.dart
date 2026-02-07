import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/services/user_profile_service.dart';

class StaffDetailScreen extends StatefulWidget {
  final UserProfile? staffProfile;

  const StaffDetailScreen({super.key, this.staffProfile});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userProfileService = UserProfileService();
  bool _isLoading = false;
  bool _isEditMode = false;

  // Form field controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _salaryController;
  late TextEditingController _allowancesController; //
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
  late Set<String> _selectedTeachingDays;
  late Set<String> _selectedTeachingClasses;
  String? _phoneNumberString;

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
  }

  /// (Re)Initializes controllers with the current staff's data.
  /// This is also used to discard changes when cancelling edit mode.
  void _loadProfileData() {
    final profile = widget.staffProfile;
    if (profile == null) {
      // Initialize with empty values for adding new staff
      _firstNameController = TextEditingController();
      _lastNameController = TextEditingController();
      _emailController = TextEditingController();
      _selectedTitle = null;
      _phoneNumberString = null;
      _addressController = TextEditingController();
      _ninController = TextEditingController();
      _selectedQualification = null;
      _salaryController = TextEditingController();
      _allowancesController = TextEditingController();
      _selectedDate = null;
      _dobController = TextEditingController();
      _selectedSex = null;
      _selectedMaritalStatus = null;
      _selectedSubjects = <Subject>{};
      _selectedTeachingDays = <String>{};
      _selectedTeachingClasses = <String>{};
      return;
    }
    
    _firstNameController = TextEditingController(text: profile.firstName ?? '');
    _lastNameController = TextEditingController(text: profile.lastName ?? '');
    _emailController = TextEditingController(text: profile.email);
    _selectedTitle = profile.title;
    _phoneNumberString = profile.phoneNumber;
    _addressController = TextEditingController(text: profile.address ?? '');
    _ninController = TextEditingController(text: profile.nin ?? '');

    const qualificationOptions = [
      'Certificate',
      'Diploma',
      'Bachelors Degree',
      'Masters Degree',
      'Doctorate (PhD)'
    ];
    _selectedQualification =
        qualificationOptions.contains(profile.qualification)
            ? profile.qualification
            : null;
    _salaryController =
        TextEditingController(text: profile.salary?.toString() ?? '');
    _allowancesController =
        TextEditingController(text: profile.allowances?.toString() ?? '');

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
    _selectedTeachingDays = (profile.teachingDays ?? []).toSet();
    _selectedTeachingClasses = (profile.teachingClasses ?? []).toSet();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _allowancesController.dispose();
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

  Future<void> _deleteStaff() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member?'),
        content: Text(
          'Are you sure you want to permanently delete ${widget.staffProfile?.firstName ?? ''} ${widget.staffProfile?.lastName ?? ''}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _userProfileService.deleteUser(widget.staffProfile!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member deleted successfully.')),
        );
        // Pop with a 'true' result to signal that the list should be refreshed.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deletion failed: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStaffProfile() async {
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
      'salary': double.tryParse(_salaryController.text),
      'allowances': double.tryParse(_allowancesController.text),
      if (widget.staffProfile?.role.isTeacher == true) ...{
        'subjectCodes': _selectedSubjects.map((s) => s.code).toList(),
        'teachingDays': _selectedTeachingDays.toList(),
        'teachingClasses': _selectedTeachingClasses.toList(),
      }
    };

    try {
      await _userProfileService.updateUserProfile(
        widget.staffProfile!.uid,
        dataToUpdate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Pop with a 'true' result to signal that the list should be refreshed.
        Navigator.of(context).pop(true);
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
        title: Text(_isEditMode ? 'Edit Staff Details' : 'Staff Details'),
        actions: _isEditMode
            ? [
                TextButton(
                  onPressed: () {
                    _loadProfileData(); // Reset changes
                    setState(() => _isEditMode = false);
                  },
                  child: const Text('Cancel'),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _isLoading ? null : _updateStaffProfile,
                  tooltip: 'Save Changes',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditMode = true),
                  tooltip: 'Edit Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: _isLoading ? null : _deleteStaff,
                  tooltip: 'Delete Staff Member',
                ),
              ],
      ),
      body: _isEditMode ? _buildEditView() : _buildDisplayView(),
    );
  }

  /// Builds the read-only display view of the staff's profile.
  Widget _buildDisplayView() {
    final user = widget.staffProfile;
    if (user == null) {
      return const Center(
        child: Text('No staff data available'),
      );
    }

    ImageProvider? backgroundImage;
    if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
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
              _buildDisplayTile(
                  Icons.badge_outlined, 'Staff ID', user.userRegId ?? 'N/A'),
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
        ],
      ),
    );
  }

  /// Builds the form view for editing the staff's profile.
  Widget _buildEditView() {
    final profile = widget.staffProfile;
    if (profile == null) {
      return const Center(
        child: Text('No staff data available for editing'),
      );
    }
    
    final isTeacher = profile.role.isTeacher;
    final allSubjects = {...OLevelSubjects.all, ...ALevelSubjects.all}.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final school = Provider.of<UserDataProvider>(context, listen: false).school;

    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editing Profile for ${profile.role.displayName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                  TextEditingController(
                      text: profile.userRegId ?? 'N/A'),
                  'Staff ID',
                  enabled: false),
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
                  onChanged: (value) => setState(() => _selectedTitle = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0), //
                child: InternationalPhoneNumberInput(
                  //
                  onInputChanged: (PhoneNumber number) {
                    //
                    _phoneNumberString = number.phoneNumber; //
                  }, //
                  selectorConfig: const SelectorConfig(
                    //
                    selectorType: PhoneInputSelectorType.BOTTOM_SHEET, //
                  ),
                  ignoreBlank: true,
                  initialValue: PhoneNumber(isoCode: 'UG'), //
                  formatInput: true, //
                  inputDecoration: const InputDecoration(
                      labelText: 'Phone Number', border: OutlineInputBorder()),
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
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSex = v),
                      validator: (v) => v == null ? 'Required' : null,
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
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedMaritalStatus = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_salaryController, 'Monthly Salary',
                  keyboardType: TextInputType.number),
              _buildTextField(_allowancesController, 'Monthly Allowances',
                  keyboardType: TextInputType.number),
              if (isTeacher) ...[
                const SizedBox(height: 24),
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
                Wrap(
                  spacing: 8.0,
                  children:
                      (school?.allClassNamesWithStreams ?? []).map((className) {
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
                if (school?.allClassNamesWithStreams.isEmpty ?? true)
                  const Text(
                      'No classes available. Manage class streams in school settings.'),
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
              const SizedBox(height: 32),
            ],
          ),
        ));
  }

  // --- Helper widgets for Display View ---

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

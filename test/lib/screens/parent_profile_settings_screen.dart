import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../services/user_profile_service.dart';
import '../widgets/loading_button.dart';

class ParentProfileSettingsScreen extends StatefulWidget {
  const ParentProfileSettingsScreen({super.key});

  @override
  State<ParentProfileSettingsScreen> createState() =>
      _ParentProfileSettingsScreenState();
}

class _ParentProfileSettingsScreenState
    extends State<ParentProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userProfileService = UserProfileService();
  bool _isLoading = false;

  // Form field controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _addressController;

  // State for dropdowns
  String? _selectedLanguage;

  // A map of language codes to their display names
  final Map<String, String> _supportedLanguages = {
    'en': 'English',
    'lg': 'Luganda',
    'sw': 'Swahili',
  };

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profile =
        Provider.of<UserDataProvider>(context, listen: false).userProfile;
    if (profile == null) return;

    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _addressController = TextEditingController(text: profile.address);
    _selectedLanguage = profile.preferredLanguage;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userProfile =
        Provider.of<UserDataProvider>(context, listen: false).userProfile;
    if (userProfile == null) return;

    try {
      final updatedProfile = userProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        address: _addressController.text.trim(),
        preferredLanguage: _selectedLanguage,
      );

      await _userProfileService.updateUserProfile(
          userProfile.uid, updatedProfile.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
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
        title: const Text('Profile Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'First name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Last name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Preferred Bot Language',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a language'),
                items: _supportedLanguages.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _saveProfile,
                text: 'Save Changes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

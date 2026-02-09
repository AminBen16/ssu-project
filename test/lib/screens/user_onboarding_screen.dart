// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test/widgets/auth_wrapper.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/user_profile_service.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  Color selectedColor = Colors.deepPurple;
  ThemeMode themeMode = ThemeMode.light;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  final _userProfileService = UserProfileService();

  final List<Color> _colorOptions = [
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.brown,
    Colors.blueGrey,
  ];

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('From Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Picture'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _profileImageBytes = bytes);
    }
  }

  Future<void> _finishSetup() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      final userProfile = userData.userProfile;
      if (userProfile == null) throw Exception('No authenticated user found.');

      // Use the UserProfileService to update settings via your backend.
      await _userProfileService.updateUserSettings(
        userId: userProfile.uid,
        themeColor: selectedColor,
        themeMode: themeMode,
        profileImageBytes: _profileImageBytes,
        isFirstTimeSetupComplete: true, // Mark setup as complete
      );

      // PATCH: Wait for profile refresh to complete before navigation
      await userData.refreshUserProfile();
      
      // CRITICAL: Verify profile was successfully refreshed
      if (userData.userProfile == null) {
        throw Exception('Profile refresh failed - cannot proceed to dashboard');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setup complete! Welcome.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error finishing user setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile =
        Provider.of<UserDataProvider>(context, listen: false).userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome!')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${userProfile?.firstName ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Let\'s personalize your account to get you started.'),
              const SizedBox(height: 32),
              Text(
                'Profile Picture',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                          : null,
                      child: _profileImageBytes == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Picture'),
                      onPressed: _pickImage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Theme Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: _colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
              ...[
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode'),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) setState(() => themeMode = value);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode'),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) setState(() => themeMode = value);
                  },
                ),
              ],
              const SizedBox(height: 40),
              LoadingButton(
                isLoading: _isSaving,
                onPressed: _finishSetup,
                text: 'Finish Setup & Go to Dashboard',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

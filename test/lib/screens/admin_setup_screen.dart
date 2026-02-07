// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test/widgets/auth_wrapper.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/api_client.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  Color selectedColor = Colors.deepPurple;
  ThemeMode themeMode = ThemeMode.light;
  bool selfRegistrationEnabled = false;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final ApiClient _apiClient = ApiClient();

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

    // Compress the image to a reasonable size for faster uploads.
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 50, // 50% quality
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _profileImageBytes = bytes);
    }
  }

  Future<void> _completeSetup(UserDataProvider userDataProvider) async {
    // Capture the context before the async gap.
    // ignore: use_build_context_synchronously
    final navigator = Navigator.of(context);
    // ignore: use_build_context_synchronously
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Setup complete! Welcome.')),
      );
      // Re-initialize to fetch the latest user profile and navigate
      await userDataProvider.initialize();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  Future<void> _finishSetup() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
    });

    try {
      final userDataProvider = Provider.of<UserDataProvider>(
        context,
        listen: false,
      );
      final userId = userDataProvider.userProfile?.uid;
      final schoolId = userDataProvider.userProfile?.schoolId;

      if (userId == null) {
        throw Exception('User ID not found. Please log in again.');
      }

      // --- Send settings as JSON ---
      final settingsData = {
        'themeColor': selectedColor.value.toString(),
        'themeMode': themeMode.name,
        'isFirstTimeSetupComplete': true,
      };

      // Send settings as JSON
      await _apiClient.post('/users/$userId/profile-picture', body: settingsData);
      
      // Update school-specific settings if applicable
      if (schoolId != null) {
        await _apiClient.put('/schools/$schoolId',
            body: {'selfRegistrationEnabled': selfRegistrationEnabled});
      }

      // Navigate to the dashboard
      await _completeSetup(userDataProvider);
    } catch (e) {
      debugPrint('Error finishing setup: $e');
      if (mounted) {
        String errorMessage = 'Failed to save settings: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole =
        Provider.of<UserDataProvider>(context, listen: false).userProfile?.role;
    final isChiefAdmin = userRole == UserRole.chiefAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Environment Setup')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Your Experience',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Set up your preferred look and feel for the system.'),
              const SizedBox(height: 32),

              // Profile Picture Upload
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

              // Color Scheme Selection
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

              // Dark/Light Mode
              Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
              Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Mode'),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (v) => setState(() => themeMode = v!),
                  ),
                  RadioListTile<ThemeMode>(
                      title: const Text('Dark Mode'),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (v) => setState(() => themeMode = v!)),
                ],
              ),
              const SizedBox(height: 32),

              // Self-registration setting is only for school admins, not the Chief Admin.
              if (!isChiefAdmin) ...[
                Text(
                  'Student Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SwitchListTile(
                  title: const Text('Enable Self-Registration'),
                  subtitle: const Text(
                    'Allow students to create their own accounts.',
                  ),
                  value: selfRegistrationEnabled,
                  onChanged: (bool value) =>
                      setState(() => selfRegistrationEnabled = value),
                ),
                const SizedBox(height: 40),
              ],

              // Finish Button
              LoadingButton(
                isLoading: _isUploading,
                onPressed: _finishSetup,
                text: 'Finish Setup',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

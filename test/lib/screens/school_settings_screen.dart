import 'dart:developer' as developer;

import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test/services/api_client.dart';
import 'package:test/screens/admin_setup_screen.dart';
import 'package:provider/provider.dart';
import 'package:test/screens/class_stream_management_screen.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/providers/user_data_provider.dart';

class SchoolSettingsScreen extends StatefulWidget {
  const SchoolSettingsScreen({super.key});

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  Uint8List? _logoBytes;
  final _apiClient = ApiClient();
  String? _initialLogoUrl;

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController(); //
  final _mottoController = TextEditingController();
  final _countryController = TextEditingController();
  final _missionController = TextEditingController();
  final _visionController = TextEditingController();
  final _anthemController = TextEditingController();
  final _uniformController = TextEditingController();

  String? _phoneNumberString;
  PhoneNumber? _initialPhoneNumber;
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final school = Provider.of<UserDataProvider>(context, listen: false).school;
    if (school != null) {
      _nameController.text = school.name;
      _addressController.text = school.address ?? '';
      _phoneNumberString = school.contact;
      if (_phoneNumberString != null && _phoneNumberString!.isNotEmpty) {
        // Asynchronously parse the initial number to set the country flag etc.
        PhoneNumber.getRegionInfoFromPhoneNumber(_phoneNumberString!)
            .then((info) {
          if (mounted) setState(() => _initialPhoneNumber = info);
        });
      }
      _mottoController.text = school.motto ?? '';
      _countryController.text = school.country ?? 'Uganda'; // Default to Uganda
      _initialLogoUrl = school.logoUrl;
      _missionController.text = school.mission ?? '';
      _visionController.text = school.vision ?? '';
      _anthemController.text = school.anthem ?? '';
      _uniformController.text = school.uniformDetails ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mottoController.dispose();
    _countryController.dispose();
    _missionController.dispose();
    _visionController.dispose();
    _anthemController.dispose();
    _uniformController.dispose();
    super.dispose();
  }

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

  Future<void> _pickLogo() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;
    final XFile? pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _logoBytes = bytes;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userData = Provider.of<UserDataProvider>(
        context,
        listen: false,
      );
      final schoolId = userData.userProfile?.schoolId;
      if (schoolId == null) throw Exception('School ID not found');

      String? logoUrl;
      if (_logoBytes != null) {
        // This assumes your backend has an endpoint for school logo uploads
        final response = await _apiClient.sendMultipartRequest(
          '/api/schools/$schoolId/logo',
          files: [
            http.MultipartFile.fromBytes(
              'logo', // field name expected by the server
              _logoBytes!,
              filename: 'logo.jpg',
            ),
          ],
        );

        if (response != null) {
          logoUrl = response['url'];
        }
      }

      final schoolData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': _phoneNumberString,
        'motto': _mottoController.text.trim(),
        'country': _countryController.text.trim(),
        'mission': _missionController.text.trim(),
        'vision': _visionController.text.trim(),
        'anthem': _anthemController.text.trim(),
        'uniformDetails': _uniformController.text.trim(),
        if (logoUrl != null) 'logoUrl': logoUrl,
      };

      await _apiClient.put('/api/schools/$schoolId/settings', body: schoolData);

      if (mounted) {
        // Capture the context before the async gap.
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        await userData.refreshUserProfile();
        scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('School details updated successfully!')));
        if (userData.userProfile?.isFirstTimeSetupComplete != true) {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminSetupScreen()),
          );
        }
      }
    } catch (e) {
      developer.log('Error saving school settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save details: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? logoImage;
    if (_logoBytes != null) {
      logoImage = MemoryImage(_logoBytes!);
    } else if (_initialLogoUrl != null) {
      logoImage = CachedNetworkImageProvider(_initialLogoUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('School Customization')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: logoImage,
                      child: logoImage == null
                          ? const Icon(Icons.school, size: 50)
                          : null,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload School Logo'),
                      onPressed: _pickLogo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'School name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
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
              ),
              const SizedBox(height: 16),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  _phoneNumberString = number.phoneNumber;
                },
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                ),
                ignoreBlank: true,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                selectorTextStyle: const TextStyle(color: Colors.black),
                initialValue: _initialPhoneNumber ?? PhoneNumber(isoCode: 'UG'),
                formatInput: true,
                keyboardType: TextInputType.phone,
                inputDecoration: const InputDecoration(
                    labelText: 'Contact Information',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mottoController,
                decoration: const InputDecoration(
                  labelText: 'School Motto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _missionController,
                decoration: const InputDecoration(
                  labelText: 'Mission',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _visionController,
                decoration: const InputDecoration(
                  labelText: 'Vision',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _anthemController,
                decoration: const InputDecoration(
                  labelText: 'School Anthem',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uniformController,
                decoration: const InputDecoration(
                  labelText: 'Uniform Details (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ListTile(
                title: const Text('Manage Class Streams'),
                subtitle:
                    const Text('Divide classes like S1 into S1A, S1B, etc.'),
                leading: const Icon(Icons.view_stream_outlined),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context)
                      .push<bool>(MaterialPageRoute(
                    builder: (_) => const ClassStreamManagementScreen(),
                  ))
                      .then((result) {
                    if (result == true) {
                      // The streams were updated. Manually trigger a refresh of the
                      // UserDataProvider to get the latest school data without
                      // resetting the navigation stack. This keeps the user on this screen.
                      // ignore: use_build_context_synchronously
                      Provider.of<UserDataProvider>(context, listen: false)
                          .refreshUserProfile();
                    }
                  });
                },
              ),
              const Divider(),
              const SizedBox(height: 16),
              LoadingButton(
                isLoading: _isSaving,
                onPressed: _saveSettings,
                text: 'Save Details',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


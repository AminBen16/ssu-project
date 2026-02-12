import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/school_service.dart';
import 'package:test/screens/school_settings_screen.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/widgets/radio_group.dart';

/// Enum representing the different classifications for a school.
enum SchoolClassification {
  governmentAided('Government Aided (USE)'),
  government('Government Schools'),
  privatePartnered('Private Partnered'),
  solePrivate('Sole Private');

  /// The user-facing display name for the classification.
  final String displayName;
  const SchoolClassification(this.displayName);
}

class SchoolClassificationScreen extends StatefulWidget {
  const SchoolClassificationScreen({super.key});

  @override
  State<SchoolClassificationScreen> createState() =>
      _SchoolClassificationScreenState();
}

class _SchoolClassificationScreenState
    extends State<SchoolClassificationScreen> {
  SchoolClassification? _selectedClassification;
  bool _isSaving = false;
  final SchoolService _schoolService = SchoolService();

  void _saveAndContinue() async {
    if (_selectedClassification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a classification.')),
      );
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Call the new service method that hits our backend endpoint.
      await _schoolService.createSchool(
        name: _selectedClassification!.displayName,
        classification: _selectedClassification!.name,
      );

      if (mounted) {
        final userDataProvider =
            Provider.of<UserDataProvider>(context, listen: false);
        final navigator = Navigator.of(context);

        // Re-initialize the user data to fetch the updated profile with the new schoolId.
        await userDataProvider.initialize();

        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const SchoolSettingsScreen()),
        );
      }
    } catch (e) {
      developer.log('Error saving school classification: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initial Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CLASSIFICATION OF SCHOOL',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Please choose one option for your school.'),
            const SizedBox(height: 24),
            AppRadioGroup<SchoolClassification>(
              groupValue: _selectedClassification,
              onChanged: (value) {
                setState(() {
                  _selectedClassification = value;
                });
              },
              children: [
                RadioListTile<SchoolClassification>(
                  title: Text(SchoolClassification.governmentAided.displayName),
                  value: SchoolClassification.governmentAided,
                  // ignore: deprecated_member_use
                  groupValue: _selectedClassification,
                  // ignore: deprecated_member_use
                  onChanged: (value) =>
                      setState(() => _selectedClassification = value),
                ),
                RadioListTile<SchoolClassification>(
                  title: Text(SchoolClassification.government.displayName),
                  value: SchoolClassification.government,
                  // ignore: deprecated_member_use
                  groupValue: _selectedClassification,
                  // ignore: deprecated_member_use
                  onChanged: (value) =>
                      setState(() => _selectedClassification = value),
                ),
                RadioListTile<SchoolClassification>(
                  title:
                      Text(SchoolClassification.privatePartnered.displayName),
                  value: SchoolClassification.privatePartnered,
                  // ignore: deprecated_member_use
                  groupValue: _selectedClassification,
                  // ignore: deprecated_member_use
                  onChanged: (value) =>
                      setState(() => _selectedClassification = value),
                ),
                RadioListTile<SchoolClassification>(
                  title: Text(SchoolClassification.solePrivate.displayName),
                  value: SchoolClassification.solePrivate,
                  // ignore: deprecated_member_use
                  groupValue: _selectedClassification,
                  // ignore: deprecated_member_use
                  onChanged: (value) =>
                      setState(() => _selectedClassification = value),
                ),
              ],
            ),
            const Spacer(),
            LoadingButton(
              isLoading: _isSaving,
              onPressed: _saveAndContinue,
              text: 'Save and Continue',
            ),
          ],
        ),
      ),
    );
  }
}


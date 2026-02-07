import 'package:flutter/material.dart';
import 'package:test/ai_scheme_generator_service.dart';
import 'package:test/screens/edit_scheme_of_work_screen.dart';
import 'package:test/constants.dart';
import 'package:provider/provider.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/models/subjects.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/scheme_of_work_model.dart';

class SchemeOfWorkGeneratorScreen extends StatefulWidget {
  const SchemeOfWorkGeneratorScreen({super.key});

  @override
  State<SchemeOfWorkGeneratorScreen> createState() =>
      _SchemeOfWorkGeneratorScreenState();
}

class _SchemeOfWorkGeneratorScreenState
    extends State<SchemeOfWorkGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AISchemeGeneratorService();
  bool _isLoading = false;

  // Form state
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedTerm;
  int? _selectedYear;

  Future<void> _generateScheme() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final schoolCountry = Provider.of<UserDataProvider>(
            context,
            listen: false,
          ).school?.country ??
          'Uganda'; // Default fallback

      final entries = await _aiService.generateScheme(
        subject: _selectedSubject!,
        className: _selectedClass!,
        term: _selectedTerm!,
        year: _selectedYear!,
        country: schoolCountry,
      );

      if (mounted) {
        // Create a temporary SchemeOfWork object to pass to the editor.
        // The editor will handle filling in the teacherId and saving.
        final generatedScheme = SchemeOfWork(
          teacherId: '', // This will be set by the editor on save.
          subject: _selectedSubject!,
          className: _selectedClass!,
          term: _selectedTerm!,
          year: _selectedYear!,
          weeklyEntries: entries,
          updatedAt: DateTime.now(),
        );

        // Navigate to the editor screen, pre-filled with the generated data.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EditSchemeOfWorkScreen(scheme: generatedScheme),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate scheme: $e')),
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
    final school = Provider.of<UserDataProvider>(context).school;
    final classNames = school?.allClassNamesWithStreams ?? [];

    // Combine and get unique subject names from the central source.
    final allSubjectNames = {
      ...OLevelSubjects.all,
      ...ALevelSubjects.all,
    }.map((s) => s.name).toSet().toList();
    allSubjectNames.sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Scheme of Work')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Generate with AI',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide the details below and let AI create a draft scheme of work for the term.',
            ),
            const SizedBox(height: 24),
            _buildHeaderForm(classNames, allSubjectNames),
            const SizedBox(height: 32),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _generateScheme,
              icon: Icons.auto_awesome,
              text: 'Generate Scheme',
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI is generating your scheme...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderForm(
      List<String> classNames, List<String> allSubjectNames) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedClass,
                onChanged: (v) => setState(() => _selectedClass = v),
                items: classNames
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                initialValue: _selectedSubject,
                onChanged: (v) => setState(() => _selectedSubject = v),
                items: allSubjectNames
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Term',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedTerm,
                onChanged: (v) => setState(() => _selectedTerm = v),
                items: AppConstants.terms
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedYear,
                onChanged: (v) => setState(() => _selectedYear = v),
                items: List.generate(3, (i) => DateTime.now().year + i)
                    .map(
                      (y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())),
                    )
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

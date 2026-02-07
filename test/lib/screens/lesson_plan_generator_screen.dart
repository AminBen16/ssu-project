import 'package:flutter/material.dart';
import 'package:test/models/subjects.dart';
import 'package:test/services/ai_lesson_plan_service.dart';
import 'package:provider/provider.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/providers/user_data_provider.dart';

class LessonPlanGeneratorScreen extends StatefulWidget {
  const LessonPlanGeneratorScreen({super.key});

  @override
  State<LessonPlanGeneratorScreen> createState() =>
      _LessonPlanGeneratorScreenState();
}

class _LessonPlanGeneratorScreenState extends State<LessonPlanGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _durationController = TextEditingController(text: '40 minutes');
  final _lessonPlanService = AILessonPlanService();

  String? _selectedSubject;
  String? _selectedClass;
  bool _isLoading = false;
  String? _generatedPlan;

  @override
  void dispose() {
    _topicController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _generatedPlan = null;
    });

    try {
      final schoolCountry = Provider.of<UserDataProvider>(
            context,
            listen: false,
          ).school?.country ??
          'Uganda'; // Default fallback

      final plan = await _lessonPlanService.generateLessonPlan(
        subject: _selectedSubject!,
        topic: _topicController.text,
        classLevel: _selectedClass!,
        duration: _durationController.text,
        country: schoolCountry,
      );
      setState(() => _generatedPlan = plan);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate plan: $e')));
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

    // Combine and get unique subject names
    final allSubjectNames = {
      ...OLevelSubjects.all,
      ...ALevelSubjects.all,
    }.map((s) => s.name).toSet().toList();
    allSubjectNames.sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Plan Generator')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Generate a New Lesson Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Subject',
              ),
              initialValue: _selectedSubject,
              items: allSubjectNames
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubject = v),
              validator: (v) => v == null ? 'Please select a subject' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Please enter a topic' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Class',
                    ),
                    initialValue: _selectedClass,
                    items: classNames
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedClass = v),
                    validator: (v) =>
                        v == null ? 'Please select a class' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _generatePlan,
              icon: Icons.auto_awesome,
              text: 'Generate Plan',
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI is generating your plan...'),
                    ],
                  ),
                ),
              ),
            if (_generatedPlan != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(_generatedPlan!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

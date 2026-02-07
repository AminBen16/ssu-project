import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/lesson_plan_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/subjects.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/services/lesson_plan_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EditLessonPlanScreen extends StatefulWidget {
  final LessonPlan? lessonPlan;

  const EditLessonPlanScreen({super.key, this.lessonPlan});

  @override
  State<EditLessonPlanScreen> createState() => _EditLessonPlanScreenState();
}

class _EditLessonPlanScreenState extends State<EditLessonPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lessonPlanService = LessonPlanService();
  bool _isLoading = false;
  bool _isOnline = true;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  // Form field controllers
  late TextEditingController _topicController;
  late TextEditingController _objectivesController;
  late TextEditingController _materialsController;
  late TextEditingController _activitiesController;
  late TextEditingController _evaluationController;
  String? _selectedClass;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.lessonPlan?.topic);
    _objectivesController = TextEditingController(
      text: widget.lessonPlan?.objectives,
    );
    _materialsController = TextEditingController(
      text: widget.lessonPlan?.materialsText,
    );
    _activitiesController = TextEditingController(
      text: widget.lessonPlan?.activitiesText,
    );
    _evaluationController = TextEditingController(
      text: widget.lessonPlan?.evaluation,
    );
    _selectedClass = widget.lessonPlan?.className;
    _selectedSubject = widget.lessonPlan?.subject;

    // Initialize connectivity monitoring
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((List<ConnectivityResult> results) {
      setState(() {
        _isOnline = results.any((result) => result != ConnectivityResult.none);
      });
    });

    // Check initial connectivity
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = results.any((result) => result != ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    _objectivesController.dispose();
    _materialsController.dispose();
    _activitiesController.dispose();
    _evaluationController.dispose();
    super.dispose();
  }

  Future<void> _saveLessonPlan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );
    final userProfile = user.userProfile!;

    final lessonPlan = LessonPlan.fromForm(
      id: widget.lessonPlan?.id,
      teacherId: userProfile.uid,
      schoolId: user.school!.id.toString(),
      subject: _selectedSubject,
      topic: _topicController.text,
      className: _selectedClass,
      objectives: _objectivesController.text,
      materials: _materialsController.text,
      activitiesText: _activitiesController.text,
      evaluation: _evaluationController.text,
      startDate: widget.lessonPlan?.startDate ?? DateTime.now(),
      endDate: widget.lessonPlan?.endDate ?? DateTime.now(),
      createdAt: widget.lessonPlan?.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      final schoolId = Provider.of<UserDataProvider>(context, listen: false)
          .userProfile
          ?.schoolId;

      if (schoolId != null) {
        await _lessonPlanService.saveLessonPlan(lessonPlan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lesson plan saved successfully!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save lesson plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = Provider.of<UserDataProvider>(context).school;
    final classNames = school?.allClassNamesWithStreams ?? [];

    // Combine and get unique subject names from the central source.
    final allSubjectNames = AllSubjects.list.map((s) => s.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lessonPlan == null ? 'New Lesson Plan' : 'Edit Lesson Plan',
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      hint: const Text('Class'),
                      onChanged: (value) =>
                          setState(() => _selectedClass = value),
                      items: classNames
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      hint: const Text('Subject'),
                      onChanged: (value) =>
                          setState(() => _selectedSubject = value),
                      items: allSubjectNames
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _objectivesController,
                decoration: const InputDecoration(
                  labelText: 'Learning Objectives',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materialsController,
                decoration: const InputDecoration(
                  labelText: 'Materials / Resources',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _activitiesController,
                decoration: const InputDecoration(
                  labelText: 'Teaching & Learning Activities',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _evaluationController,
                decoration: const InputDecoration(
                  labelText: 'Assessment / Evaluation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _saveLessonPlan,
                text: 'Save Lesson Plan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

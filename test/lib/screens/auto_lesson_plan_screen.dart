import 'package:flutter/material.dart';
import 'package:test/models/lesson_plan_model.dart';
import 'package:test/services/lesson_plan_service.dart';
import 'package:test/services/curriculum_service.dart';

class AutoLessonPlanScreen extends StatefulWidget {
  final String teacherId;
  final String schoolId;

  const AutoLessonPlanScreen({
    Key? key,
    required this.teacherId,
    required this.schoolId,
  }) : super(key: key);

  @override
  _AutoLessonPlanScreenState createState() => _AutoLessonPlanScreenState();
}

class _AutoLessonPlanScreenState extends State<AutoLessonPlanScreen> {
  final LessonPlanService _lessonPlanService = LessonPlanService();
  final CurriculumService _curriculumService = CurriculumService();
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _classNameController = TextEditingController();
  final _studentCountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedSubject;
  String? _selectedTopic;
  String? _selectedDuration;
  String? _selectedTeachingStyle;
  List<String> _selectedLearningObjectives = [];
  List<String> _availableResources = [];
  final _resourceController = TextEditingController();
  
  bool _isGenerating = false;
  LessonPlan? _generatedLessonPlan;

  // Sample data - would come from curriculum service
  final List<Map<String, String>> _subjects = [
    {'id': '1', 'name': 'Chemistry'},
    {'id': '2', 'name': 'Biology'},
    {'id': '3', 'name': 'Physics'},
    {'id': '4', 'name': 'Mathematics'},
    {'id': '5', 'name': 'English'},
  ];

  final List<Map<String, String>> _topics = [
    {'id': '1', 'name': 'Chemical Reactions'},
    {'id': '2', 'name': 'Atomic Structure'},
    {'id': '3', 'name': 'Periodic Table'},
    {'id': '4', 'name': 'Organic Chemistry'},
  ];

  final List<String> _durations = [
    '40 minutes',
    '60 minutes',
    '80 minutes',
    '120 minutes',
  ];

  final List<String> _teachingStyles = [
    'Interactive',
    'Collaborative',
    'Direct Instruction',
    'Mixed Methods',
    'Hands-on Learning',
  ];

  final List<String> _commonLearningObjectives = [
    'Understand key concepts and terminology',
    'Apply knowledge to solve problems',
    'Analyze and interpret data',
    'Evaluate different approaches',
    'Create original solutions',
    'Communicate ideas effectively',
  ];

  final List<String> _commonResources = [
    'Whiteboard/Smartboard',
    'Presentation slides',
    'Textbook',
    'Worksheet',
    'Laboratory equipment',
    'Computer/Internet access',
    'Video clips',
    'Manipulatives',
    'Chart paper',
    'Markers',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _classNameController.dispose();
    _studentCountController.dispose();
    _notesController.dispose();
    _resourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Generate Lesson Plan'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_generatedLessonPlan != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveLessonPlan,
              tooltip: 'Save Lesson Plan',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Information'),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Curriculum Details'),
              _buildCurriculumSection(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Learning Objectives'),
              _buildLearningObjectivesSection(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Teaching Preferences'),
              _buildTeachingPreferencesSection(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Available Resources'),
              _buildResourcesSection(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Additional Notes'),
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              _buildActionButtons(),
              if (_generatedLessonPlan != null) ...[
                const SizedBox(height: 24),
                _buildGeneratedLessonPlan(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Lesson Title',
                hintText: 'Enter a descriptive title for your lesson',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a lesson title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                hintText: 'e.g., Senior 5A, Form 3B',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the class name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _studentCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Students',
                hintText: 'Enter the number of students',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the number of students';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: _subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject['id'],
                  child: Text(subject['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                  _selectedTopic = null; // Reset topic when subject changes
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedTopic,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
              ),
              items: _topics.map((topic) {
                return DropdownMenuItem(
                  value: topic['id'],
                  child: Text(topic['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopic = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a topic';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedDuration,
              decoration: const InputDecoration(
                labelText: 'Lesson Duration',
                border: OutlineInputBorder(),
              ),
              items: _durations.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a duration';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningObjectivesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Learning Objectives:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _commonLearningObjectives.map((objective) {
                final isSelected = _selectedLearningObjectives.contains(objective);
                return FilterChip(
                  label: Text(objective),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLearningObjectives.add(objective);
                      } else {
                        _selectedLearningObjectives.remove(objective);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Selected: ${_selectedLearningObjectives.length} objectives',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTeachingStyle,
              decoration: const InputDecoration(
                labelText: 'Preferred Teaching Style',
                border: OutlineInputBorder(),
              ),
              items: _teachingStyles.map((style) {
                return DropdownMenuItem(
                  value: style,
                  child: Text(style),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTeachingStyle = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Resources:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _commonResources.map((resource) {
                final isSelected = _availableResources.contains(resource);
                return FilterChip(
                  label: Text(resource),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _availableResources.add(resource);
                      } else {
                        _availableResources.remove(resource);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.green[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _resourceController,
                    decoration: const InputDecoration(
                      labelText: 'Add Custom Resource',
                      hintText: 'Enter a custom resource',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCustomResource,
                  tooltip: 'Add Resource',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes',
            hintText: 'Any additional notes or considerations for this lesson',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _generateLessonPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isGenerating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Generating...'),
                    ],
                  )
                : const Text('Generate Lesson Plan'),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _resetForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildGeneratedLessonPlan() {
    if (_generatedLessonPlan == null) return const SizedBox.shrink();

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Lesson Plan Generated Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Title: ${_generatedLessonPlan!.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Duration: ${_generatedLessonPlan!.duration}'),
            Text('Class: ${_generatedLessonPlan!.className}'),
            Text('Learning Objectives: ${_generatedLessonPlan!.learningObjectives.length}'),
            Text('Activities: ${_generatedLessonPlan!.activities.length}'),
            Text('Materials: ${_generatedLessonPlan!.materials.length}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _viewLessonPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Full Lesson Plan'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _regenerateLessonPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Regenerate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomResource() {
    final resource = _resourceController.text.trim();
    if (resource.isNotEmpty && !_availableResources.contains(resource)) {
      setState(() {
        _availableResources.add(resource);
        _resourceController.clear();
      });
    }
  }

  Future<void> _generateLessonPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLearningObjectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one learning objective'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final lessonPlan = await _lessonPlanService.generateAutoLessonPlan(
        teacherId: widget.teacherId,
        subjectId: _selectedSubject!,
        topicId: _selectedTopic!,
        className: _classNameController.text,
        duration: _selectedDuration!,
        learningObjectives: _selectedLearningObjectives,
        preferredTeachingStyle: _selectedTeachingStyle,
        availableResources: _availableResources,
        studentCount: int.tryParse(_studentCountController.text),
      );

      setState(() {
        _generatedLessonPlan = lessonPlan;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson plan generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate lesson plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _titleController.clear();
      _classNameController.clear();
      _studentCountController.clear();
      _notesController.clear();
      _resourceController.clear();
      _selectedSubject = null;
      _selectedTopic = null;
      _selectedDuration = null;
      _selectedTeachingStyle = null;
      _selectedLearningObjectives.clear();
      _availableResources.clear();
      _generatedLessonPlan = null;
    });
  }

  Future<void> _saveLessonPlan() async {
    if (_generatedLessonPlan == null) return;

    try {
      // Add any additional notes to the lesson plan
      if (_notesController.text.isNotEmpty) {
        final updatedPlan = LessonPlan(
          id: _generatedLessonPlan!.id,
          teacherId: _generatedLessonPlan!.teacherId,
          schoolId: _generatedLessonPlan!.schoolId,
          subjectId: _generatedLessonPlan!.subjectId,
          topicId: _generatedLessonPlan!.topicId,
          className: _generatedLessonPlan!.className,
          title: _generatedLessonPlan!.title,
          date: _generatedLessonPlan!.date,
          startTime: _generatedLessonPlan!.startTime,
          endTime: _generatedLessonPlan!.endTime,
          duration: _generatedLessonPlan!.duration,
          learningObjectives: _generatedLessonPlan!.learningObjectives,
          teachingMethods: _generatedLessonPlan!.teachingMethods,
          activities: _generatedLessonPlan!.activities,
          assessments: _generatedLessonPlan!.assessments,
          materials: _generatedLessonPlan!.materials,
          homework: _generatedLessonPlan!.homework,
          notes: '${_generatedLessonPlan!.notes}\n\nAdditional Notes:\n${_notesController.text}',
          status: 'published',
          createdAt: _generatedLessonPlan!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _lessonPlanService.saveLessonPlan(updatedPlan);
      } else {
        await _lessonPlanService.saveLessonPlan(_generatedLessonPlan!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson plan saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save lesson plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewLessonPlan() {
    if (_generatedLessonPlan == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonPlanDetailView(lessonPlan: _generatedLessonPlan!),
      ),
    );
  }

  void _regenerateLessonPlan() {
    _generateLessonPlan();
  }
}

class LessonPlanDetailView extends StatelessWidget {
  final LessonPlan lessonPlan;

  const LessonPlanDetailView({Key? key, required this.lessonPlan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lessonPlan.title),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard('Basic Information', [
              'Class: ${lessonPlan.className}',
              'Date: ${lessonPlan.date.toString().split(' ')[0]}',
              'Duration: ${lessonPlan.duration}',
              'Status: ${lessonPlan.status}',
            ]),
            const SizedBox(height: 16),
            
            _buildInfoCard('Learning Objectives', lessonPlan.learningObjectives),
            const SizedBox(height: 16),
            
            _buildInfoCard('Teaching Methods', lessonPlan.teachingMethods),
            const SizedBox(height: 16),
            
            _buildInfoCard('Materials', lessonPlan.materials),
            const SizedBox(height: 16),
            
            _buildInfoCard('Activities', lessonPlan.activities.map((a) => '${a['name']} - ${a['description']}').toList()),
            const SizedBox(height: 16),
            
            _buildInfoCard('Notes', [lessonPlan.notes]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...content.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

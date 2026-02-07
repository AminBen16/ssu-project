import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/ai_assistant_intent.dart';
import 'package:test/models/subjects.dart';
import 'package:test/constants.dart';
import 'package:test/models/grading_models.dart';
import 'package:test/models/student_model.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/marks_service.dart';
import 'package:test/services/student_service.dart';
import 'package:test/widgets/voice_assistant_panel.dart';

class DetailedMarksEntryScreen extends StatefulWidget {
  final String? initialClassName;
  final String? initialSubjectName;
  final String? initialTerm;
  final int? initialYear;
  const DetailedMarksEntryScreen(
      {super.key,
      this.initialClassName,
      this.initialSubjectName,
      this.initialTerm,
      this.initialYear});

  @override
  State<DetailedMarksEntryScreen> createState() =>
      _DetailedMarksEntryScreenState();
}

class _DetailedMarksEntryScreenState extends State<DetailedMarksEntryScreen> {
  // State variables
  String? _selectedClass;
  Subject? _selectedSubject;
  String? _selectedTerm;
  int? _selectedYear;
  List<Student> _students = [];
  Map<String, Map<String, PaperScores>> _existingMarks = {};
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Services
  final _studentService = StudentService();
  final _marksService = MarksService();

  // A map to hold the text controllers for each student and each paper's scores
  final Map<String, Map<String, Map<String, TextEditingController>>>
      _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill dropdowns if initial values are provided (e.g., from voice assistant)
    if (widget.initialClassName != null) {
      _selectedClass = widget.initialClassName;
    }
    if (widget.initialSubjectName != null) {
      final allSubjects = [...OLevelSubjects.all, ...ALevelSubjects.all];
      try {
        _selectedSubject = allSubjects.firstWhere((s) =>
            s.name.toLowerCase() == widget.initialSubjectName!.toLowerCase());
      } catch (e) {
        // Subject not found, do nothing
      }
    }
    if (widget.initialTerm != null) {
      _selectedTerm = widget.initialTerm;
    }
    if (widget.initialYear != null) {
      _selectedYear = widget.initialYear;
    }
    // If all values are present, automatically load students.
    if (_selectedClass != null &&
        _selectedSubject != null &&
        _selectedTerm != null &&
        _selectedYear != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
    }
  }

  @override
  void dispose() {
    // Clean up all the text controllers
    _scoreControllers.forEach((_, paperMap) {
      paperMap.forEach((_, scoreMap) {
        scoreMap.forEach((_, controller) {
          controller.dispose();
        });
      });
    });
    super.dispose();
  }

  Future<void> _loadStudents() async {
    if (_selectedClass == null ||
        _selectedSubject == null ||
        _selectedTerm == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select class, subject, term, and year.')),
      );
      return;
    }

    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).userProfile?.schoolId;
    if (schoolId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    final students = await _studentService.getStudentsByClass(
      schoolId: schoolId,
      className: _selectedClass!,
    );

    // Fetch existing marks for these students
    final studentIds = students.map((s) => s.id).toList();
    final existingMarks = await _marksService.getMarksForClass(
      schoolId: schoolId,
      subjectCode: _selectedSubject!.code,
      term: _selectedTerm!,
      year: _selectedYear!,
      studentIds: studentIds,
    );

    // Initialize controllers and pre-fill with existing marks
    _initializeControllers(students, _selectedSubject!, existingMarks);

    setState(() {
      _students = students;
      _existingMarks = existingMarks;
      _isLoading = false;
    });
  }

  void _initializeControllers(
    List<Student> students,
    Subject subject,
    Map<String, Map<String, PaperScores>> existingMarks,
  ) {
    // Clear old controllers
    _scoreControllers.clear();
    for (var student in students) {
      _scoreControllers[student.id] = {};
      final studentMarks = existingMarks[student.id];
      for (var paper in subject.papers) {
        final paperScores = studentMarks?[paper.code];
        _scoreControllers[student.id]![paper.code] = {
          'bot':
              TextEditingController(text: paperScores?.bot?.toString() ?? ''),
          'mot':
              TextEditingController(text: paperScores?.mot?.toString() ?? ''),
          'eot':
              TextEditingController(text: paperScores?.eot?.toString() ?? ''),
        };
      }
    }
  }

  Future<void> _saveAllMarks() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the invalid scores before saving.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).userProfile?.schoolId;
    if (schoolId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: School ID not found.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final List<Map<String, dynamic>> allMarksData = [];

      for (var student in _students) {
        final paperScores = <String, PaperScores>{};
        for (var paper in _selectedSubject!.papers) {
          final botText =
              _scoreControllers[student.id]![paper.code]!['bot']!.text;
          final motText =
              _scoreControllers[student.id]![paper.code]!['mot']!.text;
          final eotText =
              _scoreControllers[student.id]![paper.code]!['eot']!.text;

          paperScores[paper.code] = PaperScores.fromStrings(
            botText,
            motText,
            eotText,
          );
        }

        // Prepare the data for this student and add it to our batch list.
        allMarksData.add({
          'studentId': student.id,
          'subjectCode': _selectedSubject!.code,
          'term': _selectedTerm!,
          'year': _selectedYear!,
          'paperScores':
              paperScores.map((key, value) => MapEntry(key, value.toJson())),
        });
      }
      // Call the new batch save method once with all the data.
      await _marksService.saveAllMarksForClass(allMarksData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All marks saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving marks: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showVoiceAssistant() async {
    final result = await showModalBottomSheet<AssistantIntent>(
      context: context,
      builder: (_) => const VoiceAssistantPanel(contextHint: 'marks_entry'),
    );

    if (result is RecordMarksIntent) {
      // Find the student in the list
      final student = _students.firstWhere(
        (s) => s.fullName.toLowerCase() == result.studentName.toLowerCase(),
        orElse: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Student "${result.studentName}" not found in this class.')),
          );
          // Return a dummy student to avoid null checks, though no action will be taken.
          return Student(
              id: '', firstName: '', lastName: '', className: '', schoolId: '');
        },
      );

      if (student.id.isEmpty) return; // Student not found

      // Find the paper in the selected subject
      final paper = _selectedSubject?.papers.firstWhere(
        (p) => p.name.toLowerCase() == result.paperName.toLowerCase(),
        orElse: () {
          // Handle case where paper name is not found
          return const SubjectPaper(code: '', name: '');
        },
      );

      if (paper == null || paper.code.isEmpty) return;

      // Update the controllers with the dictated scores
      setState(() {
        _scoreControllers[student.id]?[paper.code]?['bot']?.text =
            result.scores['bot'] ?? '';
        _scoreControllers[student.id]?[paper.code]?['mot']?.text =
            result.scores['mot'] ?? '';
        _scoreControllers[student.id]?[paper.code]?['eot']?.text =
            result.scores['eot'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolDetails = Provider.of<UserDataProvider>(context).school;
    final classNames = schoolDetails?.allClassNamesWithStreams ?? [];

    final allSubjects = [...OLevelSubjects.all, ...ALevelSubjects.all];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Student Marks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _students.isEmpty ? null : _showVoiceAssistant,
            tooltip: 'Dictate Marks',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedClass,
                          hint: const Text('Select Class'),
                          onChanged: (value) =>
                              setState(() => _selectedClass = value),
                          items: classNames
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<Subject>(
                          isExpanded: true,
                          initialValue: _selectedSubject,
                          hint: const Text('Select Subject'),
                          onChanged: (value) =>
                              setState(() => _selectedSubject = value),
                          items: allSubjects
                              .map<DropdownMenuItem<Subject>>(
                                (Subject s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTerm,
                          hint: const Text('Select Term'),
                          onChanged: (value) =>
                              setState(() => _selectedTerm = value),
                          items: AppConstants.terms
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedYear,
                          hint: const Text('Select Year'),
                          onChanged: (value) =>
                              setState(() => _selectedYear = value),
                          items: List.generate(
                                  5, (index) => DateTime.now().year - index)
                              .map((y) => DropdownMenuItem(
                                  value: y, child: Text(y.toString())))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadStudents,
              icon: const Icon(Icons.people),
              label: const Text('Load Students'),
            ),
            const Divider(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_students.isEmpty)
              const Expanded(child: Center(child: Text('No students loaded.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    bool hasMissingScores = false;
                    // Check if any score is missing for the selected subject
                    for (final paper in _selectedSubject!.papers) {
                      final scores = _existingMarks[student.id]?[paper.code];
                      if (scores?.bot == null ||
                          scores?.mot == null ||
                          scores?.eot == null) {
                        hasMissingScores = true;
                        break;
                      }
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ExpansionTile(
                        leading: hasMissingScores
                            ? const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange)
                            : const Icon(Icons.check_circle_outline,
                                color: Colors.green),
                        title: Text(student.fullName),
                        children: _selectedSubject!.papers.map((paper) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paper.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Row(
                                  children: [
                                    _buildScoreField(
                                      student.id,
                                      paper.code,
                                      'bot',
                                      'BOT',
                                    ),
                                    _buildScoreField(
                                      student.id,
                                      paper.code,
                                      'mot',
                                      'MOT',
                                    ),
                                    _buildScoreField(
                                      student.id,
                                      paper.code,
                                      'eot',
                                      'EOT',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            if (_students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LoadingButton(
                  isLoading: _isLoading,
                  onPressed: _saveAllMarks,
                  text: 'Save All Marks',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreField(
    String studentId,
    String paperCode,
    String scoreType,
    String label,
  ) {
    final double maxScore = scoreType == 'eot' ? 100.0 : 3.0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: TextFormField(
          controller: _scoreControllers[studentId]![paperCode]![scoreType],
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null; // Allow empty (null) scores
            }
            final score = double.tryParse(value);
            if (score == null) {
              return 'Invalid';
            }
            if (score < 0 || score > maxScore) {
              return '0-${maxScore.toInt()}';
            }
            return null;
          },
        ),
      ),
    );
  }
}

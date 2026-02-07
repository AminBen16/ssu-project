import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:test/models/exam_model.dart';
import 'package:test/models/subjects.dart';
import 'package:test/services/api_client.dart';
import 'package:test/models/question_model.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/exam_service.dart';

class EditExamScreen extends StatefulWidget {
  final Exam? exam;
  const EditExamScreen({super.key, this.exam});

  @override
  State<EditExamScreen> createState() => _EditExamScreenState();
}

class _EditExamScreenState extends State<EditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examService = ExamService();
  bool _isLoading = false;

  // Form state
  late TextEditingController _titleController;
  late TextEditingController _instructionsController;
  String? _selectedClass;
  String? _selectedSubject;
  List<dynamic> _questions = [];
  final _picker = ImagePicker();
  // Map to hold temporary image data before upload
  final Map<int, Uint8List> _questionImageBytes = {};
  // State for tracking upload progress
  double? _uploadProgress;
  int? _uploadingQuestionIndex;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.exam?.title);
    _instructionsController =
        TextEditingController(text: widget.exam?.instructions);
    _selectedClass = widget.exam?.className;
    _selectedSubject = widget.exam?.subject;
    if (widget.exam != null) {
      _questions = List<dynamic>.from(
          widget.exam!.questions.map((q) => q.toMap()).toList());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({'text': '', 'type': 'shortAnswer', 'options': []});
    });
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

  Future<void> _pickImageForQuestion(int index) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _questionImageBytes[index] = bytes;
        // Also clear any existing imageUrl if a new image is picked
        _questions[index]['imageUrl'] = null;
      });
    }
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final user = Provider.of<UserDataProvider>(
        context,
        listen: false,
      );
      final userProfile = user.userProfile;
      final schoolId = userProfile?.schoolId; // Assuming school is loaded
      final apiClient = ApiClient();

      // Handle image uploads before saving the exam data
      for (int i = 0; i < _questions.length; i++) {
        if (_questionImageBytes.containsKey(i) && userProfile != null) {
          final bytes = _questionImageBytes[i]!;
          setState(() {
            _uploadingQuestionIndex = i;
            _uploadProgress = 0.0;
          });
          final response = await apiClient.sendMultipart(
            'api/exams/images/upload',
            files: [
              http.MultipartFile.fromBytes('image', bytes,
                  filename: 'question_$i.jpg')
            ],
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final responseData = await response.stream.bytesToString();
            final downloadUrl = jsonDecode(responseData)['url'] as String?;
            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              _questions[i]['imageUrl'] = downloadUrl;
            } else {
              throw Exception(
                  'Image upload for question ${i + 1} did not return a valid URL.');
            }
          } else {
            // Stop execution if an image upload fails.
            final errorBody = await response.stream.bytesToString();
            throw Exception(
                'Failed to upload image for question ${i + 1}. Server response: $errorBody');
          }
        }
      }

      // Clear progress after all uploads are done
      if (mounted) {
        setState(() => _uploadProgress = null);
      }

      final exam = Exam(
        id: widget.exam?.id,
        title: _titleController.text, // Assuming a default or to be added field
        description: '',
        instructions: _instructionsController.text,
        className: _selectedClass!,
        subject: _selectedSubject!,
        questions: _questions.map((q) => Question.fromMap(q)).toList(),
        teacherId: userProfile!.uid,
        schoolId: schoolId!,
        date: widget.exam?.date ?? DateTime.now(), // Added required parameter
        createdAt: widget.exam?.createdAt ??
            DateTime.now(), // Added required parameter
      );

      await _examService.saveExam(exam);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exam Saved!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving exam: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content:
                Text('Failed to save exam. Please try again.\nError: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = Provider.of<UserDataProvider>(context).school;
    final classNames = school?.allClassNamesWithStreams ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam == null ? 'New Exam' : 'Edit Exam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addQuestion,
            tooltip: 'Add Question',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeaderForm(classNames),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionEditor(index);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LoadingButton(
          isLoading: _isLoading,
          onPressed: _saveExam,
          text: 'Save Exam',
        ),
      ),
    );
  }

  Widget _buildHeaderForm(List<String> classNames) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Exam Title'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instructionsController,
            decoration: const InputDecoration(
              labelText: 'Exam Instructions',
              hintText: 'e.g., Answer all questions.',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  hint: const Text('Class'),
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
                  isExpanded: true,
                  initialValue: _selectedSubject,
                  hint: const Text('Subject'),
                  onChanged: (v) => setState(() => _selectedSubject = v),
                  items: [...OLevelSubjects.all, ...ALevelSubjects.all]
                      .map((s) => s.name)
                      .toSet() // Remove duplicates
                      .toList()
                      .map((subjectName) => DropdownMenuItem(
                            value: subjectName,
                            child: Text(subjectName),
                          ))
                      .toList(),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatQuestionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.essay:
        return 'Essay';
      }
  }

  Widget _buildQuestionEditor(int index) {
    final question = _questions[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Question ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                DropdownButton<QuestionType>(
                  value: QuestionType.values.firstWhere(
                      (e) => e.name == question['type'],
                      orElse: () => QuestionType.shortAnswer),
                  items: QuestionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_formatQuestionTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (newType) {
                    setState(() {
                      question['type'] = newType!.name;
                      if (newType != QuestionType.multipleChoice) {
                        question['options'] = [];
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() {
                    _questions.removeAt(index);
                    _questionImageBytes.remove(index);
                  }),
                ),
              ],
            ),
            TextFormField(
              initialValue: question['text'],
              decoration: const InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (v) => question['text'] = v,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Question text is required'
                  : null,
            ),
            if (_uploadingQuestionIndex == index &&
                _uploadProgress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Text(
                  'Uploading image... ${(_uploadProgress! * 100).toStringAsFixed(0)}%'),
            ],
            const SizedBox(height: 12),
            _buildImagePreview(index),
            TextButton.icon(
              onPressed: () => _pickImageForQuestion(index),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add/Change Image'),
            ),
            if (question['type'] == 'multipleChoice')
              _buildMultipleChoiceEditor(question),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceEditor(dynamic question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Multiple Choice Options',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...List.generate(question.options.length, (optionIndex) {
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: question.options[optionIndex],
                  decoration:
                      InputDecoration(labelText: 'Option ${optionIndex + 1}'),
                  onChanged: (value) {
                    question.options[optionIndex] = value;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() => question.options.removeAt(optionIndex));
                },
              ),
            ],
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
          onPressed: () {
            setState(() => (question['options'] as List).add(''));
          },
        ),
      ],
    );
  }

  Widget _buildImagePreview(int index) {
    // Check for newly picked image bytes first
    if (_questionImageBytes.containsKey(index)) {
      return Image.memory(_questionImageBytes[index]!, height: 100);
    }
    // Then check for an existing image URL from the server
    final imageUrl = _questions[index]['imageUrl'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 100,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      );
    }
    // No image
    return const SizedBox.shrink();
  }
}

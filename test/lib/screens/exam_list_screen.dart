import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/models/exam_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/edit_exam_screen.dart';
import 'package:test/screens/typeset_exam_preview_screen.dart';
import 'package:test/services/exam_service.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  late Future<List<Exam>> _examsFuture;
  final _examService = ExamService();

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  void _loadExams() {
    final user =
        Provider.of<UserDataProvider>(context, listen: false).userProfile!;
    final schoolId = user.schoolId;

    if (schoolId == null) {
      // If the user has no schoolId, we can't fetch exams.
      // We'll set the future to an error state to display a message.
      setState(() {
        _examsFuture = Future.error('User is not associated with a school.');
      });
    } else {
      setState(() {
        _examsFuture =
            _examService.getExams(schoolId: schoolId, teacherId: user.uid);
      });
    }
  }

  Future<void> _refreshExams() async {
    _loadExams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Exams / Question Banks')),
      body: RefreshIndicator(
        onRefresh: _refreshExams,
        child: FutureBuilder<List<Exam>>(
          future: _examsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text('No exams found. Tap + to create one.'));
            }

            final exams = snapshot.data!;
            return ListView.builder(
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(exam.title),
                    subtitle: Text(
                      '${exam.className} - ${exam.subject}\n${exam.questions.length} questions | Updated: ${DateFormat.yMMMd().format(exam.updatedAt ?? exam.createdAt)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditExamScreen(exam: exam),
                            ),
                          );
                          if (result == true) {
                            _loadExams();
                          }
                        } else if (value == 'typeset') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  TypesetExamPreviewScreen(exam: exam),
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Exam?'),
                              content: const Text(
                                  'Are you sure you want to delete this exam?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _examService.deleteExam(
                                  schoolId: exam.schoolId, examId: exam.id!);
                              _loadExams();
                            } catch (e) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Failed to delete exam: $e')));
                            }
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'typeset',
                          child: ListTile(
                            leading: Icon(Icons.print_outlined),
                            title: Text('Typeset & Print'),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading:
                                Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const EditExamScreen()),
          );
          if (result == true) {
            _loadExams();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

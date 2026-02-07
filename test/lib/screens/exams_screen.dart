import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/exam_service.dart';
import 'package:test/widgets/future_handler.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final examService = ExamService();

    if (userData.userProfile?.schoolId == null) {
      return const Scaffold(
        body: Center(child: Text('School information not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: FutureHandler<List<dynamic>>(
        future: examService.getStudentExams(
          schoolId: userData.userProfile!.schoolId!,
          studentId: userData.userProfile!.uid,
        ),
        loadingWidget: const Center(child: CircularProgressIndicator()),
        emptyMessage: 'No exams found.',
        builder: (context, exams) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index] as Map<String, dynamic>;
              final examDate = DateTime.tryParse(exam['examDate'] ?? '');
              final daysUntil = examDate != null
                  ? examDate.difference(DateTime.now()).inDays
                  : null;
              final isUrgent = daysUntil != null && daysUntil <= 1;

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isUrgent ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(
                      Icons.quiz,
                      color: isUrgent
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                  title: Text(
                    exam['name'] ?? 'Exam',
                    style: TextStyle(
                      color: isUrgent ? Colors.red.shade700 : null,
                    ),
                  ),
                  subtitle: Text(
                    '${exam['subject'] ?? 'Subject'} • ${exam['className'] ?? 'Class'} • ${_formatExamDate(examDate)}',
                    style: TextStyle(
                      color:
                          isUrgent ? Colors.red.shade600 : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatExamDate(DateTime? date) {
    if (date == null) return 'Date TBA';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference > 1 && difference <= 7) return 'In $difference days';
    if (difference > 7) return '${date.day}/${date.month}/${date.year}';
    return '${difference.abs()} days ago';
  }
}

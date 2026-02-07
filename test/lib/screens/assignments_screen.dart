import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/assignment_service.dart';
import 'package:test/widgets/future_handler.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final assignmentService = AssignmentService();

    if (userData.userProfile?.schoolId == null) {
      return const Scaffold(
        body: Center(child: Text('School information not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: FutureHandler<List<Map<String, dynamic>>>(
        future: assignmentService.getStudentAssignments(
          schoolId: userData.userProfile!.schoolId!,
          studentId: userData.userProfile!.uid,
        ),
        loadingWidget: const Center(child: CircularProgressIndicator()),
        emptyMessage: 'No assignments found.',
        builder: (context, assignments) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              final dueDate = DateTime.tryParse(assignment['dueDate'] ?? '');
              final isOverdue =
                  dueDate != null && dueDate.isBefore(DateTime.now());
              final isCompleted = assignment['isCompleted'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOverdue && !isCompleted
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.assignment,
                      color: isOverdue && !isCompleted
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                  title: Text(
                    assignment['title'] ?? 'Assignment',
                    style: TextStyle(
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isOverdue && !isCompleted
                          ? Colors.red.shade700
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    '${assignment['subject'] ?? 'Subject'} • Due: ${dueDate != null ? _formatDate(dueDate) : 'No due date'}',
                    style: TextStyle(
                      color: isOverdue && !isCompleted
                          ? Colors.red.shade600
                          : Colors.grey.shade600,
                    ),
                  ),
                  trailing: isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 0) return 'In $difference days';
    return '${difference.abs()} days ago';
  }
}

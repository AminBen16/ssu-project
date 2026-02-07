import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/marks_service.dart';
import 'package:test/widgets/future_handler.dart';

class FullGradesScreen extends StatefulWidget {
  const FullGradesScreen({super.key});

  @override
  State<FullGradesScreen> createState() => _FullGradesScreenState();
}

class _FullGradesScreenState extends State<FullGradesScreen> {
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final marksService = MarksService();

    if (userData.userProfile?.schoolId == null) {
      return const Scaffold(
        body: Center(child: Text('School information not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Grades'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: FutureHandler<Map<String, dynamic>>(
        future: MarksService.getStudentGrades(
          int.parse(userData.userProfile!.schoolId!),
          userData.userProfile!.uid,
        ),
        loadingWidget: const Center(child: CircularProgressIndicator()),
        emptyMessage: 'No grades available.',
        builder: (context, gradesData) {
          final overallGrade = gradesData['overallGrade'] as String? ?? 'N/A';
          final gpa = gradesData['gpa'] as double? ?? 0.0;
          final recentSubjects =
              gradesData['recentSubjects'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Grade Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Overall Performance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Grade',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(overallGrade)
                                        .withAlpha((255 * 0.1).round()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    overallGrade,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: _getGradeColor(overallGrade),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'GPA',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  gpa.toStringAsFixed(2),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Subject Grades
                Text(
                  'Subject Grades',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                if (recentSubjects.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No subject grades available'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentSubjects.length,
                    itemBuilder: (context, index) {
                      final subject =
                          recentSubjects[index] as Map<String, dynamic>;
                      final subjectName =
                          subject['subject'] as String? ?? 'Unknown';
                      final grade = subject['grade'] as String? ?? 'N/A';
                      final score = subject['score'] as double? ?? 0.0;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getGradeColor(grade)
                                .withAlpha((255 * 0.1).round()),
                            child: Text(
                              grade.isNotEmpty ? grade[0] : 'A',
                              style: TextStyle(
                                color: _getGradeColor(grade),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(subjectName),
                          subtitle: Text(
                              'Grade: $grade • Score: ${score.toStringAsFixed(1)}%'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getGradeColor(grade)
                                  .withAlpha((255 * 0.1).round()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              grade,
                              style: TextStyle(
                                color: _getGradeColor(grade),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                  ),

                const SizedBox(height: 24),

                // Grade Scale Reference
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grade Scale Reference',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildGradeScaleItem('A', '90-100%', Colors.green),
                        _buildGradeScaleItem('B+', '80-89%', Colors.lightGreen),
                        _buildGradeScaleItem(
                            'B', '70-79%', Colors.yellow.shade700),
                        _buildGradeScaleItem('C+', '60-69%', Colors.orange),
                        _buildGradeScaleItem('C', '50-59%', Colors.deepOrange),
                        _buildGradeScaleItem(
                            'D', '40-49%', Colors.red.shade700),
                        _buildGradeScaleItem('F', 'Below 40%', Colors.red),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B+':
        return Colors.lightGreen;
      case 'B':
        return Colors.yellow.shade700;
      case 'C+':
        return Colors.orange;
      case 'C':
        return Colors.deepOrange;
      case 'D':
        return Colors.red.shade700;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGradeScaleItem(String grade, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$grade: $range',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

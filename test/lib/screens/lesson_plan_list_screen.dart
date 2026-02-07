import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/models/lesson_plan_model.dart';
import 'package:test/services/lesson_plan_service.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/edit_lesson_plan_screen.dart';
import 'package:test/screens/lesson_plan_generator_screen.dart';
import 'package:test/widgets/stream_handler.dart';

class LessonPlanListScreen extends StatelessWidget {
  const LessonPlanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).userProfile;
    final schoolId =
        Provider.of<UserDataProvider>(context, listen: false).school?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My Lesson Plans')),
      body: StreamHandler<List<LessonPlan>>(
        stream: (userProfile != null && schoolId != null)
            ? LessonPlanService().getLessonPlansStream(
                teacherId: userProfile.uid,
                queryParams: {'school_id': schoolId.toString()},
              )
            : Stream.value([]),
        emptyMessage: 'No lesson plans found. Tap the + button to create one.',
        builder: (context, snapshot) {
          final plans = snapshot; // The data from the stream

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(plan.title),
                  subtitle: Text(
                    '${plan.className} - ${plan.subjectId}\nUpdated: ${DateFormat.yMMMd().format(plan.updatedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => EditLessonPlanScreen(lessonPlan: plan)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LessonPlanGeneratorScreen(),
            ),
          );
        },
        tooltip: 'Create Lesson Plan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

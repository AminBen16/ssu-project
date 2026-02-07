import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/timetable_constants.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/timetable_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/timetable_service.dart';

enum TimetableMode { classView, teacherView }

class ViewTimetableScreen extends StatefulWidget {
  final TimetableMode mode;
  final String? className; // Required for classView and student's view
  final List<String>?
  studentSubjectCodes; // Optional, for student's personalized view

  const ViewTimetableScreen({
    super.key,
    required this.mode,
    this.className,
    this.studentSubjectCodes,
  }) : assert(mode == TimetableMode.classView ? className != null : true);

  @override
  State<ViewTimetableScreen> createState() => _ViewTimetableScreenState();
}

class _ViewTimetableScreenState extends State<ViewTimetableScreen> {
  Future<Map<String, Map<String, ScheduledLesson>>>? _timetableFuture;
  final _timetableService = TimetableService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timetableFuture == null) {
      _loadTimetable();
    }
  }

  void _loadTimetable() {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final user = userData.userProfile;
    final school = userData.school;

    if (user == null || school == null) return;

    if (widget.mode == TimetableMode.classView) {
      setState(() {
        _timetableFuture = _timetableService.getClassTimetable(
          schoolId: school.id.toString(),
          className: widget.className!,
        );
      });
    } else {
      // Teacher Mode
      setState(() {
        _timetableFuture = _timetableService.getTeacherTimetable(
          schoolId: school.id.toString(),
          teacherId: user.uid,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: FutureBuilder<Map<String, Map<String, ScheduledLesson>>>(
        future: _timetableFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Timetable not available.'));
          }

          final timetableData = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  const DataColumn(label: Text('Time')),
                  ...TimetableConstants.daysOfWeek.map(
                    (day) => DataColumn(label: Text(day)),
                  ),
                ],
                rows: TimetableConstants.timeSlots.map((slot) {
                  return DataRow(
                    cells: [
                      DataCell(Text(slot.displayTime)),
                      ...TimetableConstants.daysOfWeek.map((day) {
                        final lesson = timetableData[day]?[slot.id];
                        final isBreak =
                            slot.id.contains('BREAK') ||
                            slot.id.contains('LUNCH');

                        // For students, check if the lesson's subject is one they take.
                        bool isStudentLesson = true;
                        if (widget.mode == TimetableMode.classView &&
                            widget.studentSubjectCodes != null &&
                            lesson != null) {
                          final allSubjects = [
                            ...OLevelSubjects.all,
                            ...ALevelSubjects.all,
                          ];
                          final subject = allSubjects.firstWhere(
                            (s) => s.name == lesson.subjectName,
                            orElse: () => const Subject(
                              name: '',
                              code: 'NOT_FOUND',
                              level: SchoolLevel.oLevel,
                              papers: [],
                            ),
                          );
                          if (subject.code != 'NOT_FOUND' &&
                              !widget.studentSubjectCodes!.contains(
                                subject.code,
                              )) {
                            isStudentLesson = false;
                          }
                        }

                        return DataCell(
                          Container(
                            width: 120,
                            color: isBreak ? Colors.grey.shade200 : null,
                            child: isBreak
                                ? Center(
                                    child: Text(
                                      slot.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : !isStudentLesson
                                ? Center(
                                    child: Text(
                                      'Free Period',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : lesson == null
                                ? const Center(child: Text('-'))
                                : Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          lesson.subjectName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          // For teachers, show class name. For students, show teacher name.
                                          widget.mode ==
                                                  TimetableMode.teacherView
                                              ? lesson.room ?? ''
                                              : lesson.teacherName,
                                          style: const TextStyle(fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/timetable_constants.dart';
import 'package:test/models/timetable_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/staff_service.dart';
import 'package:test/services/timetable_service.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/screens/timetable_constraints_screen.dart';
import 'package:test/screens/timetable_generator_screen.dart';

class TimetableManagementScreen extends StatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  State<TimetableManagementScreen> createState() =>
      _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends State<TimetableManagementScreen> {
  String? _selectedClass;
  Map<String, Map<String, ScheduledLesson>> _timetableData = {};
  List<UserProfile> _teachers = [];
  bool _isLoading = false;

  final _timetableService = TimetableService();
  final _staffService = StaffService();

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();
    final teachers = await _staffService.getTeachingStaff(schoolId);
    setState(() => _teachers = teachers);
  }

  Future<void> _fetchTimetable(String className) async {
    setState(() => _isLoading = true);
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();
    final data = await _timetableService.getClassTimetable(
      schoolId: schoolId,
      className: className,
    );
    setState(() {
      _timetableData = data;
      _isLoading = false;
    });
  }

  Future<void> _showEditLessonDialog(String day, TimeSlot timeSlot) async {
    if (_selectedClass == null) return;

    // Get the schoolId from the provider BEFORE the async gap (showDialog).
    // This avoids the 'use_build_context_synchronously' warning.
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();

    ScheduledLesson? existingLesson = _timetableData[day]?[timeSlot.id];
    final subjects = [...OLevelSubjects.all, ...ALevelSubjects.all];

    final result = await showDialog<ScheduledLesson?>(
      context: context,
      builder: (context) {
        String? selectedSubject = existingLesson?.subjectName;
        UserProfile? selectedTeacher;
        if (existingLesson?.teacherId != null) {
          for (final teacher in _teachers) {
            if (teacher.uid == existingLesson!.teacherId) {
              selectedTeacher = teacher;
              break;
            }
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Lesson for ${timeSlot.displayTime}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubject,
                    hint: const Text('Select Subject'),
                    onChanged: (value) =>
                        setDialogState(() => selectedSubject = value),
                    items: subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.name,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserProfile>(
                    initialValue: selectedTeacher,
                    hint: const Text('Select Teacher'),
                    onChanged: (value) =>
                        setDialogState(() => selectedTeacher = value),
                    items: _teachers
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              '${t.firstName ?? ''} ${t.lastName ?? ''}'.trim(),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              actions: [
                if (existingLesson != null)
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(null), // Special value to indicate deletion
                    child: const Text(
                      'DELETE',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSubject != null && selectedTeacher != null) {
                      Navigator.of(context).pop(
                        ScheduledLesson(
                          subjectName: selectedSubject!,
                          teacherId: selectedTeacher!.uid,
                          teacherName:
                              '${selectedTeacher!.firstName ?? ''} ${selectedTeacher!.lastName ?? ''}'
                                  .trim(),
                          room: _selectedClass,
                        ),
                      );
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );

    // After the dialog closes, check if the widget is still in the tree.
    if (!mounted) return;

    // Handle the result from the dialog
    if (result != null) {
      // Save the new lesson
      await _timetableService.setLesson(
        schoolId: schoolId,
        className: _selectedClass!,
        day: day,
        timeSlotId: timeSlot.id,
        lesson: result,
      );
    } else if (result == null && existingLesson != null) {
      // A null result from the dialog after it was opened for an existing lesson means delete
      await _timetableService.removeLesson(
        schoolId: schoolId,
        className: _selectedClass!,
        day: day,
        timeSlotId: timeSlot.id,
      );
    }
    // Refresh the timetable data
    if (_selectedClass != null) _fetchTimetable(_selectedClass!);
  }

  @override
  Widget build(BuildContext context) {
    final school = Provider.of<UserDataProvider>(context).school;
    final classNames = school?.allClassNamesWithStreams ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rule),
            tooltip: 'Manage Constraints',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TimetableConstraintsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedClass,
                    hint: const Text('Select a Class'),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedClass = value);
                        _fetchTimetable(value);
                      }
                    },
                    items: classNames
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Generate with AI',
                  onPressed: _selectedClass == null
                      ? null
                      : () {
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (_) => TimetableGeneratorScreen(
                                className: _selectedClass!,
                              ),
                            ),
                          )
                              .then((_) {
                            if (_selectedClass != null) {
                              _fetchTimetable(_selectedClass!);
                            }
                          });
                        },
                ),
              ],
            ),
          ),
          const Divider(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_selectedClass == null)
            const Expanded(
              child: Center(child: Text('Please select a class to begin.')),
            )
          else
            Expanded(
              child: SingleChildScrollView(
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
                            final lesson = _timetableData[day]?[slot.id];
                            final isBreak = slot.id.contains('BREAK') ||
                                slot.id.contains('LUNCH');
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
                                    : InkWell(
                                        onTap: () =>
                                            _showEditLessonDialog(day, slot),
                                        child: lesson == null
                                            ? const Center(
                                                child: Icon(
                                                  Icons.add,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      lesson.subjectName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    Text(
                                                      lesson.teacherName,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
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
              ),
            ),
        ],
      ),
    );
  }
}

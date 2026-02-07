import 'dart:math';
import 'package:test/services/staff_service.dart';
import 'package:test/services/student_service.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/timetable_constants.dart';
import 'package:test/models/timetable_model.dart';
import 'package:test/models/timetable_constraints_service.dart';

class TimetableGeneratorService {
  final _staffService = StaffService();
  final _studentService = StudentService();
  final _constraintsService = TimetableConstraintsService();
  final _random = Random();

  Future<Map<String, Map<String, ScheduledLesson>>> generateClassTimetable({
    required String schoolId,
    required String className,
  }) async {
    // 1. Fetch constraints, teachers, and subjects for the class
    final constraints = await _constraintsService.getConstraints(schoolId);
    final teachers = await _staffService.getTeachingStaff(schoolId);
    if (teachers.isEmpty) {
      throw Exception('No teachers available to generate timetable.');
    }

    // Fetch subjects based on what students in the class are actually enrolled in,
    // rather than using all possible subjects for the level. This makes the
    // timetable specific and relevant to the class.
    final studentsInClass = await _studentService.getStudentsByClass(
        schoolId: schoolId, className: className);

    if (studentsInClass.isEmpty) {
      throw Exception(
          'No students found in class $className to determine subjects.');
    }

    // Get all unique subject codes for the class from all students
    // Use `?? []` to prevent exceptions if a student has a null subjectCodes list.
    final classSubjectCodes =
        studentsInClass.expand((student) => student.subjectCodes).toSet();

    if (classSubjectCodes.isEmpty) {
      throw Exception(
          'No subjects are registered for students in class $className.');
    }

    // Map codes back to Subject objects. This list includes all subjects (compulsory and optional) for the class.
    final allSubjectsList = [...OLevelSubjects.all, ...ALevelSubjects.all];
    final assignableSubjects = allSubjectsList
        .where((s) => classSubjectCodes.contains(s.code))
        .toList();

    if (assignableSubjects.isEmpty) {
      throw Exception('No subjects available for this class level.');
    }

    // 2. Simulate a delay for the "AI" process
    await Future.delayed(const Duration(seconds: 5));

    // 3. Generate the timetable. This mock generator has limitations:
    // - It does not check for teacher clashes across different classes simultaneously.
    // - It does not guarantee minimum periods are met, only maximums.
    // A real implementation would need a more advanced constraint satisfaction algorithm.
    final Map<String, Map<String, ScheduledLesson>> timetable = {};
    final Map<String, int> teacherDailyWorkload =
        {}; // {teacherId_day: lessonCount}
    final Map<String, int> subjectWeeklyCount = {}; // {subjectCode: count}
    const maxLessonsPerDay = 5;

    for (final day in TimetableConstants.daysOfWeek) {
      timetable[day] = {};
      for (final slot in TimetableConstants.timeSlots) {
        if (slot.id.contains('BREAK') || slot.id.contains('LUNCH')) continue;

        // Filter subjects that haven't reached their max weekly periods
        final availableSubjects = assignableSubjects.where((s) {
          final maxPeriods = constraints[s.code]?.$2;
          final currentCount = subjectWeeklyCount[s.code] ?? 0;
          // If maxPeriods is null, there's no limit.
          return maxPeriods == null || currentCount < maxPeriods;
        }).toList();

        if (availableSubjects.isEmpty) continue;

        // Pick a random subject from the available list
        final assignedSubject =
            availableSubjects[_random.nextInt(availableSubjects.length)];

        // Find teachers for the selected subject who are available and have capacity
        final availableTeachersForSubject = teachers.where((teacher) {
          final isQualified =
              teacher.subjectCodes?.contains(assignedSubject.code) ?? false;
          final isAvailableOnDay = teacher.teachingDays?.contains(day) ?? true;
          final workloadKey = '${teacher.uid}_$day';
          final currentWorkload = teacherDailyWorkload[workloadKey] ?? 0;
          return isQualified &&
              isAvailableOnDay &&
              currentWorkload < maxLessonsPerDay;
        }).toList();

        if (availableTeachersForSubject.isEmpty) continue;

        final assignedTeacher = availableTeachersForSubject[_random.nextInt(
          availableTeachersForSubject.length,
        )];

        timetable[day]![slot.id] = ScheduledLesson(
          subjectName: assignedSubject.name,
          teacherId: assignedTeacher.uid,
          teacherName:
              '${assignedTeacher.firstName} ${assignedTeacher.lastName}'.trim(),
          room: className,
        );

        // Update the teacher's workload for the day
        final workloadKey = '${assignedTeacher.uid}_$day';
        teacherDailyWorkload[workloadKey] =
            (teacherDailyWorkload[workloadKey] ?? 0) + 1;

        // Update the subject's weekly count
        subjectWeeklyCount[assignedSubject.code] =
            (subjectWeeklyCount[assignedSubject.code] ?? 0) + 1;
      }
    }
    return timetable;
  }
}

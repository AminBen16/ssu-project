import 'package:test/models/user_profile.dart';
import 'package:test/models/student.dart';
import 'package:test/models/assignment.dart';
import 'package:test/models/exam.dart';
import 'package:test/models/fee_payment.dart';
import 'package:test/models/lesson_plan.dart';
import 'package:test/models/scheme_of_work.dart';
import 'package:test/models/timetable_entry.dart';

/// Comprehensive data validation service for SSU system
/// Validates all data before API calls and database operations
class DataValidationService {
  /// Validates user profile data before saving
  static Map<String, String> validateUserProfile(UserProfile profile) {
    final errors = <String, String>{};

    // Validate basic fields
    if (profile.firstName?.trim().isEmpty ?? true) {
      errors['firstName'] = 'First name is required';
    }
    if (profile.lastName?.trim().isEmpty ?? true) {
      errors['lastName'] = 'Last name is required';
    }
    if (profile.email?.trim().isEmpty ?? true) {
      errors['email'] = 'Email is required';
    }
    if (profile.email != null &&
        !RegExp(r'^[\w-\.]+@[\w\.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(profile.email!)) {
      errors['email'] = 'Invalid email format';
    }
    if (profile.phoneNumber?.trim().isEmpty ?? true) {
      errors['phoneNumber'] = 'Phone number is required';
    }
    if (profile.phoneNumber != null &&
        !RegExp(r'^\+256\d{7,15}$').hasMatch(profile.phoneNumber!)) {
      errors['phoneNumber'] = 'Invalid phone number format (Uganda format)';
    }

    // Validate role
    if (profile.role == null) {
      errors['role'] = 'User role is required';
    }

    // Validate school and school ID
    if (profile.schoolId == null || profile.schoolId!.trim().isEmpty) {
      errors['schoolId'] = 'School ID is required';
    }

    return errors;
  }

  /// Validates student data before saving
  static Map<String, String> validateStudent(Student student) {
    final errors = <String, String>{};

    if (student.firstName.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
    }
    if (student.lastName.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
    }
    if (student.email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@[\w\.-]+\.[a-zA-Z]{2,}$').hasMatch(student.email)) {
      errors['email'] = 'Invalid email format';
    }
    if (student.phoneNumber.trim().isEmpty) {
      errors['phoneNumber'] = 'Phone number is required';
    }
    if (!RegExp(r'^\+256\d{7,15}$').hasMatch(student.phoneNumber)) {
      errors['phoneNumber'] = 'Invalid phone number format (Uganda format)';
    }

    // Validate student ID and school
    if (student.studentId.trim().isEmpty) {
      errors['studentId'] = 'Student ID is required';
    }
    if (student.schoolId?.trim().isEmpty ?? true) {
      errors['schoolId'] = 'School ID is required';
    }

    // Validate class/grade
    if (student.grade.trim().isEmpty) {
      errors['grade'] = 'Grade is required';
    }

    // Validate date of birth
    if (student.dateOfBirth == null) {
      errors['dateOfBirth'] = 'Date of birth is required';
    } else {
      final now = DateTime.now();
      final age = now.difference(student.dateOfBirth!).inDays / 365;
      if (age < 6 || age > 18) {
        errors['dateOfBirth'] = 'Student age must be between 6 and 18 years';
      }
    }

    return errors;
  }

  /// Validates assignment data
  static Map<String, String> validateAssignment(Assignment assignment) {
    final errors = <String, String>{};

    if (assignment.title.trim().isEmpty) {
      errors['title'] = 'Assignment title is required';
    }
    if (assignment.description.trim().isEmpty) {
      errors['description'] = 'Assignment description is required';
    }
    if (assignment.dueDate == null) {
      errors['dueDate'] = 'Due date is required';
    } else {
      if (assignment.dueDate!.isBefore(DateTime.now())) {
        errors['dueDate'] = 'Due date cannot be in the past';
      }
    }

    return errors;
  }

  /// Validates exam data
  static Map<String, String> validateExam(Exam exam) {
    final errors = <String, String>{};

    if (exam.title.trim().isEmpty) {
      errors['title'] = 'Exam title is required';
    }
    if (exam.examDate == null) {
      errors['examDate'] = 'Exam date is required';
    }
    if (exam.examDate!.isBefore(DateTime.now())) {
      errors['examDate'] = 'Exam date cannot be in the past';
    }

    return errors;
  }

  /// Validates fee payment data
  static Map<String, String> validateFeePayment(FeePayment payment) {
    final errors = <String, String>{};

    if (payment.amount <= 0) {
      errors['amount'] = 'Payment amount must be positive';
    }
    if (payment.paymentDate == null) {
      errors['paymentDate'] = 'Payment date is required';
    }
    if (payment.paymentMethod.trim().isEmpty) {
      errors['paymentMethod'] = 'Payment method is required';
    }

    return errors;
  }

  /// Validates timetable data
  static Map<String, String> validateTimetableEntry(TimetableEntry entry) {
    final errors = <String, String>{};

    if (entry.subject.trim().isEmpty) {
      errors['subject'] = 'Subject is required';
    }
    if (entry.startTime == null || entry.endTime == null) {
      errors['time'] = 'Start and end times are required';
    } else {
      if (entry.endTime!.isBefore(entry.startTime!)) {
        errors['time'] = 'End time must be after start time';
      }
    }

    return errors;
  }

  /// Validates scheme of work data
  static Map<String, String> validateSchemeOfWork(SchemeOfWork scheme) {
    final errors = <String, String>{};

    if (scheme.title.trim().isEmpty) {
      errors['title'] = 'Scheme title is required';
    }
    if (scheme.subject.trim().isEmpty) {
      errors['subject'] = 'Subject is required';
    }
    if (scheme.grade.trim().isEmpty) {
      errors['grade'] = 'Grade is required';
    }

    return errors;
  }

  /// Validates lesson plan data
  static Map<String, String> validateLessonPlan(LessonPlan plan) {
    final errors = <String, String>{};

    if (plan.title.trim().isEmpty) {
      errors['title'] = 'Lesson plan title is required';
    }
    if (plan.subject.trim().isEmpty) {
      errors['subject'] = 'Subject is required';
    }
    if (plan.grade.trim().isEmpty) {
      errors['grade'] = 'Grade is required';
    }

    return errors;
  }
}

import 'package:flutter/material.dart';
import 'package:test/screens/base_staff_enrollment_screen.dart';
import 'package:test/models/user_roles.dart';

class TeacherEnrollmentScreen extends StatelessWidget {
  const TeacherEnrollmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseStaffEnrollmentScreen(
      appBarTitle: 'Enroll New Teacher',
      availableRoles: UserRole.allTeachingRoles,
      isTeacherForm: true,
    );
  }
}

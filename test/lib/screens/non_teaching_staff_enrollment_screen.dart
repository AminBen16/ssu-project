import 'package:flutter/material.dart';
import 'package:test/screens/base_staff_enrollment_screen.dart';
import 'package:test/models/user_roles.dart';

class NonTeachingStaffEnrollmentScreen extends StatelessWidget {
  const NonTeachingStaffEnrollmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseStaffEnrollmentScreen(
      appBarTitle: 'Enroll Non-Teaching Staff',
      availableRoles: UserRole.allNonTeachingRoles,
      isTeacherForm: false,
    );
  }
}

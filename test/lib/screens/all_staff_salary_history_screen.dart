import 'package:flutter/material.dart';
import 'package:test/screens/salary_history_screen.dart';
import 'package:test/widgets/staff_selection_list.dart';

class AllStaffSalaryHistoryScreen extends StatelessWidget {
  const AllStaffSalaryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffSelectionList(
      appBarTitle: 'Staff Salary History',
      onStaffSelected: (staff) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SalaryHistoryScreen(
              staffId: staff.uid,
              staffName: staff.fullName,
            ),
          ),
        );
            },
    );
  }
}

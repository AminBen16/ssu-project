import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/student_enrollment_screen.dart';
import 'package:test/widgets/app_drawer.dart';
import 'package:test/widgets/dashboards/dashboards.dart';
import 'package:test/screens/system_admin_dashboard_screen.dart';

import 'package:test/widgets/voice_assistant_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to get the user's role and rebuild the UI accordingly.
    return Consumer<UserDataProvider>(
      builder: (context, userData, child) {
        // Guard: Check if the secondary services are ready.
        // While this is false, the background initialization is still running.
        if (userData.userProfile == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
            ),
            drawer:
                const AppDrawer(), // Keep drawer to prevent UI shift on load
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finalizing setup...'),
                ],
              ),
            ),
          );
        }
        final userRole = userData.userProfile?.role;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              // Voice Assistant Button
              IconButton(
                icon: const Icon(Icons.mic),
                tooltip: 'Voice Assistant',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const VoiceAssistantPanel(
                      contextHint: 'dashboard',
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Log Out',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirm Log Out'),
                        content:
                            const Text('Are you sure you want to log out?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          TextButton(
                            child: const Text('Log Out'),
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              // Use the provider to handle logout for consistent state management.
                              await Provider.of<UserDataProvider>(context,
                                      listen: false)
                                  .logout();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: _buildDashboardBody(context, userRole),
          drawer: const AppDrawer(),
          // Only show the FAB to users who can enroll students.
          floatingActionButton: _buildFloatingActionButton(context, userRole),
        );
      },
    );
  }

  // Helper method to build the body based on the user's role.
  Widget _buildDashboardBody(BuildContext context, UserRole? role) {
    if (role == null) {
      // Show a generic view or loading state if role is not yet available.
      return const Center(child: Text('Welcome!'));
    }

    // Build the UI based on the user's role.
    switch (role) {
      case UserRole.headTeacher:
      case UserRole.director:
      case UserRole.deputyHeadTeacher:
      case UserRole.systemAdmin:
      case UserRole.schoolAdmin:
        return const AdminDashboard();
      case UserRole.chiefAdmin:
        return const SystemAdminDashboardScreen();
      case UserRole.teacher:
      case UserRole.classTeacher:
      case UserRole.headOfDepartment:
      case UserRole.directorOfStudies:
        return const TeacherDashboard();
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.parent:
        return const ParentDashboard();
      // Ugandan School Non-Teaching Staff Roles
      case UserRole.nonTeachingStaff:
      case UserRole.bursar:
      case UserRole.schoolSecretary:
      case UserRole.librarian:
      case UserRole.labTechnician:
      case UserRole.computerLabAttendant:
      case UserRole.schoolNurse:
      case UserRole.counselor:
      case UserRole.securityGuard:
      case UserRole.caretaker:
      case UserRole.cook:
      case UserRole.driver:
      case UserRole.storeKeeper:
      case UserRole.boardingMaster:
        return const StaffDashboard();
      default:
        return Center(
          child: Text('Welcome! Your role is: ${role.displayName}'),
        );
    }
  }

  Widget? _buildFloatingActionButton(BuildContext context, UserRole? role) {
    if (role != null && UserRole.enrollmentRoles.contains(role)) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StudentEnrollmentScreen(),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Enroll Student'),
      );
    }
    return null; // Return null to hide the FAB for other roles.
  }
}

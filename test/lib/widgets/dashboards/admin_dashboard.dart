import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/screens/fee_management_screen.dart';
import 'package:test/screens/student_enrollment_screen.dart';
import 'package:test/screens/view_staff_screen.dart';
import 'package:test/screens/staff_enrollment_screen.dart';
import 'package:test/screens/salary_management_screen.dart';
import 'package:test/screens/student_list_screen.dart';
import 'package:test/screens/report_card_screen.dart';
import 'package:test/screens/class_stream_management_screen.dart';
import 'package:test/screens/manage_books_screen.dart';
import 'package:test/screens/scheme_of_work_list_screen.dart';
import 'package:test/screens/lesson_plan_list_screen.dart';
import 'package:test/screens/exam_list_screen.dart';
import 'package:test/screens/school_settings_screen.dart';
import 'package:test/screens/salary_history_screen.dart';
import 'package:test/screens/performance_analyzer_screen.dart';
import 'package:test/widgets/fee_summary_card.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/user_profile_service.dart';
import 'package:test/services/student_service.dart';
import 'package:test/models/user_roles.dart';

/// A dashboard widget for school administrators.
///
/// Provides an overview of school metrics and quick access to management functions.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userData, child) {
        final school = userData.school;
        final userRole = userData.userProfile?.role;
        final canEnrollUsers =
            userRole != null && UserRole.enrollmentRoles.contains(userRole);

        return FutureBuilder<Map<String, int>>(
          future: _getRealTimeStats(context),
          builder: (context, snapshot) {
            final realTimeStats = snapshot.data ?? {'staff': 0, 'students': 0};

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Overview
                    _buildQuickStats(context, school, realTimeStats),
                    const SizedBox(height: 16),

                    // Overview Section
                    const FeeSummaryCard(),
                    const SizedBox(height: 16),

                    // Staff Management Section
                    _buildSection(
                      context,
                      title: 'Staff Management',
                      actions: [
                        _ActionCard(
                          title: 'View Staff',
                          icon: Icons.people,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ViewStaffScreen(),
                            ));
                          },
                        ),
                        if (canEnrollUsers)
                          _ActionCard(
                            title: 'Add Staff',
                            icon: Icons.person_add,
                            onTap: () async {
                              final result =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const StaffEnrollmentScreen(),
                                ),
                              );
                              // Refresh data if staff was successfully enrolled
                              if (result == true && context.mounted) {
                                // Trigger a refresh of user data
                                Provider.of<UserDataProvider>(context,
                                        listen: false)
                                    .refreshUserProfile();
                              }
                            },
                          ),
                        _ActionCard(
                          title: 'Salary Management',
                          icon: Icons.attach_money,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SalaryManagementScreen(),
                            ));
                          },
                        ),
                      ],
                    ),

                    // Student Management Section
                    _buildSection(
                      context,
                      title: 'Student Management',
                      actions: [
                        _ActionCard(
                          title: 'View Students',
                          icon: Icons.school,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const StudentListScreen(),
                            ));
                          },
                        ),
                        if (canEnrollUsers)
                          _ActionCard(
                            title: 'Enroll New Student',
                            icon: Icons.person_add,
                            onTap: () async {
                              final result =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentEnrollmentScreen(),
                                ),
                              );
                              // Refresh data if student was successfully enrolled
                              if (result == true && context.mounted) {
                                // Trigger a refresh of user data
                                Provider.of<UserDataProvider>(context,
                                        listen: false)
                                    .refreshUserProfile();
                              }
                            },
                          ),
                        _ActionCard(
                          title: 'Student Reports',
                          icon: Icons.assessment,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ReportCardScreen(
                                  studentId: '', term: '', year: '0'),
                            ));
                          },
                        ),
                      ],
                    ),

                    // Academic Management Section
                    _buildSection(
                      context,
                      title: 'Academic Management',
                      actions: [
                        _ActionCard(
                          title: 'Class/Stream Management',
                          icon: Icons.class_,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  const ClassStreamManagementScreen(),
                            ));
                          },
                        ),
                        _ActionCard(
                          title: 'Subject Management',
                          icon: Icons.menu_book,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ManageBooksScreen(),
                            ));
                          },
                        ),
                        _ActionCard(
                          title: 'Scheme of Work',
                          icon: Icons.description,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SchemeOfWorkListScreen(),
                            ));
                          },
                        ),
                        _ActionCard(
                          title: 'Lesson Plans',
                          icon: Icons.book,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const LessonPlanListScreen(),
                            ));
                          },
                        ),
                        _ActionCard(
                          title: 'Exams',
                          icon: Icons.quiz,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ExamListScreen(),
                            ));
                          },
                        ),
                      ],
                    ),

                    // Financial Management Section
                    _buildSection(
                      context,
                      title: 'Financial Management',
                      actions: [
                        _ActionCard(
                          title: 'Fee Management',
                          icon: Icons.receipt_long,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const FeeManagementScreen(),
                            ));
                          },
                        ),
                        _ActionCard(
                          title: 'Salary Reports',
                          icon: Icons.history,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SalaryHistoryScreen(),
                            ));
                          },
                        ),
                      ],
                    ),

                    // Settings Section
                    _buildSection(
                      context,
                      title: 'Settings',
                      actions: [
                        _ActionCard(
                          title: 'School Settings',
                          icon: Icons.settings,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SchoolSettingsScreen(),
                            ));
                          },
                        ),
                        _ActionCard(
                          title: 'Performance Analysis',
                          icon: Icons.analytics,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const PerformanceAnalyzerScreen(),
                            ));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build quick stats overview
  Widget _buildQuickStats(
      BuildContext context, school, Map<String, int> realTimeStats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (school != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context: context,
                      title: 'School Name',
                      value: school!.name,
                      icon: Icons.school,
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _statCard(
                      context: context,
                      title: 'Total Students',
                      value:
                          '${realTimeStats['students'] ?? school!.totalStudents ?? 0}',
                      icon: Icons.people,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context: context,
                      title: 'Total Staff',
                      value:
                          '${realTimeStats['staff'] ?? school!.totalStaff ?? 0}',
                      icon: Icons.groups,
                      color: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _statCard(
                      context: context,
                      title: 'Total Classes',
                      value: '${school!.totalClasses ?? 0}',
                      icon: Icons.class_,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Center(
                child: Text(
                  'Loading school data...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> actions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          children: actions,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Helper widget for stat cards
  Widget _statCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch real-time stats to match View Staff screen
  Future<Map<String, int>> _getRealTimeStats(BuildContext context) async {
    try {
      final userProfileService = UserProfileService();
      final studentService = StudentService();

      // Get current user's school ID
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      final schoolId = userData.userProfile?.schoolId;

      if (schoolId == null) {
        debugPrint('School ID not found, returning zero counts');
        return {'staff': 0, 'students': 0};
      }

      // Fetch all users and count staff
      final (users, totalCount) = await userProfileService.getAllUsers(
        page: 1,
        limit: 1000, // Get more users to get accurate counts
      );

      int staffCount = 0;

      // Safely count staff roles
      for (final user in users) {
        try {
          if (UserRole.allStaffRoles.contains(user.role)) {
            staffCount++;
          }
        } catch (e) {
          debugPrint('Error processing user role for ${user.email}: $e');
          // Continue counting other users
        }
      }

      // Fetch students from students table
      int studentCount = 0;
      try {
        final students = await studentService.getStudentsBySchool(schoolId);
        studentCount = students.length;
      } catch (e) {
        debugPrint('Error fetching students: $e');
        // studentCount remains 0
      }

      debugPrint('Real-time stats: Staff=$staffCount, Students=$studentCount');

      return {
        'staff': staffCount,
        'students': studentCount,
      };
    } catch (e, stackTrace) {
      debugPrint('Error fetching real-time stats: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'staff': 0,
        'students': 0,
      };
    }
  }
}

/// A reusable card for dashboard actions.
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

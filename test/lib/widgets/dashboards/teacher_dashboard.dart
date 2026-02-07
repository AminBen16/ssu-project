import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/ai_content_studio_screen.dart';
import '../../models/dashboard_item_model.dart';
import '../../screens/lesson_plan_list_screen.dart';
import '../../screens/marks_entry_screen.dart';
import '../../screens/salary_history_screen.dart';
import '../../screens/scheme_of_work_list_screen.dart';
import '../../providers/user_data_provider.dart';
import '../../screens/report_viewer_screen.dart';
import '../../screens/view_timetable_screen.dart';

/// A modular widget for the Teacher dashboard.
class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  List<DashboardItem> _getAcademicItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.edit_note,
        label: 'Enter Class Marks',
        color: Colors.transparent, // Color is not used in this layout
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MarksEntryScreen()),
        ),
      ),
      DashboardItem(
        icon: Icons.receipt_long,
        label: 'View Class Reports',
        color: Colors.transparent,
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportViewerScreen())),
      ),
    ];
  }

  List<DashboardItem> _getPlanningItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.calendar_view_week,
        label: 'View My Timetable',
        color: Colors.transparent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ViewTimetableScreen(
              mode: TimetableMode.teacherView,
            ),
          ),
        ),
      ),
      DashboardItem(
        icon: Icons.description_outlined,
        label: 'Lesson Plans',
        color: Colors.transparent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LessonPlanListScreen()), //
        ),
      ),
      DashboardItem(
        icon: Icons.view_list_outlined,
        label: 'Schemes of Work',
        color: Colors.transparent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SchemeOfWorkListScreen()),
        ), //
      ),
      DashboardItem(
        icon: Icons.auto_awesome_motion,
        label: 'AI Content Studio',
        color: Colors.transparent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiContentStudioScreen()),
        ),
      ),
    ];
  }

  List<DashboardItem> _getFinancialItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'My Salary History',
        color: Colors.transparent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SalaryHistoryScreen()), //
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final userProfile = userData.userProfile;

    ImageProvider? backgroundImage;
    if (userProfile?.profilePictureUrl != null && userProfile!.profilePictureUrl!.isNotEmpty) {
      backgroundImage =
          CachedNetworkImageProvider(userProfile.profilePictureUrl!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2, //
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: backgroundImage,
                    child: backgroundImage == null
                        ? Text(
                            //
                            userProfile?.firstName?.isNotEmpty == true
                                ? userProfile!.firstName![0]
                                : 'T',
                            style: const TextStyle(fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userProfile?.firstName ?? ''} ${userProfile?.lastName ?? ''}'
                              .trim(),
                          style: Theme.of(context).textTheme.headlineSmall, //
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile?.role.displayName ?? 'Teacher',
                          style: Theme.of(context).textTheme.titleMedium, //
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            context,
            title: 'Academics',
            items: _getAcademicItems(context),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            context,
            title: 'Planning & Resources',
            items: _getPlanningItems(context),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            context,
            title: 'Financials',
            items: _getFinancialItems(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<DashboardItem> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) {
            return ListTile(
              leading:
                  Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              title: Text(item.label),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: item.onTap,
            );
          }),
        ],
      ),
    );
  }
}

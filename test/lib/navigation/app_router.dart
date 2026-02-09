import 'package:flutter/material.dart';
import 'package:test/screens/assignments_screen.dart';
import 'package:test/screens/exams_screen.dart';
import 'package:test/screens/fee_management_screen.dart';
import 'package:test/screens/full_notifications_screen.dart';
import 'package:test/screens/report_card_screen.dart';
import 'package:test/screens/salary_management_screen.dart';
import 'package:test/screens/settings_screen.dart';
import 'package:test/screens/student_list_screen.dart';
import 'package:test/screens/timetable_management_screen.dart';
import 'package:test/screens/user_profile_screen.dart';
import 'package:test/screens/view_timetable_screen.dart';
import 'package:test/screens/help_support_screen.dart';
import 'package:test/screens/privacy_settings_screen.dart';
import 'package:test/screens/appearance_settings_screen.dart';
import 'package:test/screens/curriculum_integrity_audit_screen.dart';
import 'package:test/screens/performance_analyzer_screen.dart';
import 'package:test/screens/scheme_of_work_generator_screen.dart';
import 'package:test/screens/scheme_of_work_list_screen.dart';
import 'package:test/screens/lesson_plan_generator_screen.dart';
import 'package:test/screens/ai_content_studio_screen.dart';
import 'package:test/screens/communication_screen.dart';
import 'package:test/screens/emergency_contacts_screen.dart';
import 'package:test/screens/offline_queue_screen.dart';
import 'package:test/screens/system_admin_dashboard_screen.dart';
import 'package:test/screens/system_admin_login_screen.dart';
import 'package:test/screens/parent_profile_settings_screen.dart';
import 'package:test/screens/subscription_management_screen.dart';

/// Enhanced app router with navigation guards and role-based routing
class AppRouter {
  static const String assignments = '/assignments';
  static const String exams = '/exams';
  static const String feeManagement = '/fee_management';
  static const String notifications = '/notifications';
  static const String reportCard = '/report_card';
  static const String salaryManagement = '/salary_management';
  static const String settings = '/settings';
  static const String studentList = '/student_list';
  static const String timetableManagement = '/timetable_management';
  static const String userProfile = '/user_profile';
  static const String viewTimetable = '/view_timetable';
  static const String helpSupport = '/help_support';
  static const String privacySettings = '/privacy_settings';
  static const String appearanceSettings = '/appearance_settings';
  static const String curriculumAudit = '/curriculum_integrity_audit';
  static const String performanceAnalyzer = '/performance_analyzer';
  static const String schemeOfWorkGenerator = '/scheme_of_work_generator';
  static const String schemeOfWorkList = '/scheme_of_work_list';
  static const String lessonPlanGenerator = '/lesson_plan_generator';
  static const String aiContentStudio = '/ai_content_studio';
  static const String communication = '/communication';
  static const String emergencyContacts = '/emergency_contacts';
  static const String offlineQueue = '/offline_queue';
  static const String systemAdminDashboard = '/system_admin_dashboard';
  static const String systemAdminLogin = '/system_admin_login';
  static const String parentProfileSettings = '/parent_profile_settings';
  static const String subscriptionManagement = '/subscription_management';



  /// Check if user has required role for route
  static bool _hasRequiredRole(String route, List<String> requiredRoles) {
    // This would be called from UserDataProvider in a real implementation
    // For now, return true as placeholder
    return true;
  }

  /// Generate route with navigation guard
  static Route<dynamic> generateRoute(
    RouteSettings settings, {
    String? requiredRole,
    required Widget Function(BuildContext, dynamic) fallbackBuilder,
  }) {
    return MaterialPageRoute(
      builder: (context) {
        // Check role-based access
        if (requiredRole != null &&
            settings.name != null &&
            !_hasRequiredRole(settings.name!, [requiredRole])) {
          return fallbackBuilder(context, settings);
        }

        // Route is accessible, proceed with actual screen
        final routeName = settings.name;
        if (routeName == assignments) {
          return const AssignmentsScreen();
        } else if (routeName == exams) {
          return const ExamsScreen();
        } else if (routeName == feeManagement) {
          return const FeeManagementScreen();
        } else if (routeName == notifications) {
          return const FullNotificationsScreen();
        } else if (routeName == reportCard) {
          return const ReportCardScreen(
            studentId: 'placeholder',
            term: 'placeholder',
            year: '2024',
          );
        } else if (routeName == salaryManagement) {
          return const SalaryManagementScreen();
        } else if (routeName == settings) {
          return const SettingsScreen();
        } else if (routeName == studentList) {
          return const StudentListScreen();
        } else if (routeName == timetableManagement) {
          return const TimetableManagementScreen();
        } else if (routeName == userProfile) {
          return const UserProfileScreen();
        } else if (routeName == viewTimetable) {
          return ViewTimetableScreen(mode: TimetableMode.classView);
        } else if (routeName == helpSupport) {
          return const HelpSupportScreen();
        } else if (routeName == privacySettings) {
          return const PrivacySettingsScreen();
        } else if (routeName == appearanceSettings) {
          return const AppearanceSettingsScreen();
        } else if (routeName == curriculumAudit) {
          return const CurriculumIntegrityAuditScreen();
        } else if (routeName == performanceAnalyzer) {
          return const PerformanceAnalyzerScreen();
        } else if (routeName == schemeOfWorkGenerator) {
          return const SchemeOfWorkGeneratorScreen();
        } else if (routeName == schemeOfWorkList) {
          return const SchemeOfWorkListScreen();
        } else if (routeName == lessonPlanGenerator) {
          return const LessonPlanGeneratorScreen();
        } else if (routeName == aiContentStudio) {
          return const AiContentStudioScreen();
        } else if (routeName == communication) {
          return const CommunicationScreen();
        } else if (routeName == emergencyContacts) {
          return const EmergencyContactsScreen();
        } else if (routeName == offlineQueue) {
          return const OfflineQueueScreen();
        } else if (routeName == systemAdminDashboard) {
          return const SystemAdminDashboardScreen();
        } else if (routeName == systemAdminLogin) {
          return const SystemAdminLoginScreen();
        } else if (routeName == parentProfileSettings) {
          return const ParentProfileSettingsScreen();
        } else if (routeName == subscriptionManagement) {
          return const SubscriptionManagementScreen();
        } else {
          return fallbackBuilder(context, settings);
        }
      },
    );
  }
}

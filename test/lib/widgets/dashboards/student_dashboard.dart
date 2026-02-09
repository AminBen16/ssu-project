import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/models/fee_balance_model.dart';
import 'package:test/services/fee_service.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/student_service.dart';
import 'package:test/services/notification_service.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/student_report_list_screen.dart';
import 'package:test/screens/view_timetable_screen.dart';
import 'package:test/screens/assignments_screen.dart';
import 'package:test/screens/exams_screen.dart';
import 'package:test/screens/manage_books_screen.dart';
import 'package:test/screens/full_grades_screen.dart';
import 'package:test/screens/full_notifications_screen.dart';
import 'package:test/widgets/future_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test/services/assignment_service.dart';
import 'package:test/services/exam_service.dart';
import 'package:test/services/library_service.dart';
import 'package:test/services/marks_service.dart';

/// A modular widget for the Student dashboard.
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late bool _isOnline;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _isOnline = true; // Default to online
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((List<ConnectivityResult> results) {
      setState(() {
        _isOnline = results.any((result) => result != ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final studentService = StudentService();
    final feeService = FeeService();
    final notificationService = NotificationService();
    final assignmentService = AssignmentService();
    final examService = ExamService();
    final libraryService = LibraryService();
    final offlineService = OfflineService();

    ImageProvider? backgroundImage;
    if (userData.userProfile?.profilePictureUrl != null &&
        userData.userProfile!.profilePictureUrl!.isNotEmpty) {
      backgroundImage =
          CachedNetworkImageProvider(userData.userProfile!.profilePictureUrl!);
    }

    if (userData.userProfile == null ||
        userData.userProfile?.schoolId == null) {
      return const Center(child: Text('User or school data not available.'));
    }

    return FutureHandler<Student?>(
      future: studentService.getStudent(
        userData.userProfile!.uid,
      ),
      emptyMessage: 'Could not load student details.',
      builder: (context, student) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Offline Status Header
              _buildOfflineStatusHeader(),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: backgroundImage,
                            child: backgroundImage == null
                                ? Text(
                                    student!.firstName.isNotEmpty
                                        ? student.firstName[0]
                                        : '?',
                                    style: const TextStyle(fontSize: 28),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student!.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                    ),
                                    if (!_isOnline)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Offline',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student.className,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      FutureHandler<FeeBalance>(
                        future: feeService.getStudentFeeBalance(
                          student.id,
                        ),
                        loadingWidget: const Center(
                          child: CircularProgressIndicator(),
                        ),
                        builder: (context, feeBalance) {
                          final balance = feeBalance.balance;
                          final balanceText = NumberFormat.currency(
                            symbol: 'UGX ',
                          ).format(balance);
                          final color = balance > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Current Balance',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (!_isOnline)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Cached',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                balanceText,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStudentAction(
                            context,
                            icon: Icons.receipt_long,
                            label: 'Reports',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StudentReportListScreen(),
                              ),
                            ),
                            isOnline: _isOnline,
                          ),
                          _buildStudentAction(
                            context,
                            icon: Icons.calendar_view_week,
                            label: 'Timetable',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ViewTimetableScreen(
                                  mode: TimetableMode.classView,
                                  className: student.className,
                                  studentSubjectCodes: student.subjectCodes,
                                ),
                              ),
                            ),
                            isOnline: _isOnline,
                          ),
                          _buildStudentAction(
                            context,
                            icon: Icons.assignment,
                            label: 'Assignments',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AssignmentsScreen(),
                              ),
                            ),
                            isOnline: _isOnline,
                          ),
                          _buildStudentAction(
                            context,
                            icon: Icons.quiz,
                            label: 'Exams',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ExamsScreen(),
                              ),
                            ),
                            isOnline: _isOnline,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildAssignmentsSection(context, userData, student,
                          assignmentService, offlineService),
                      const Divider(height: 16),
                      _buildExamsSection(context, userData, student,
                          examService, offlineService),
                      const Divider(height: 16),
                      _buildLibrarySection(context, userData, student,
                          libraryService, offlineService),
                      const Divider(height: 16),
                      _buildGradesSection(context, userData, student, offlineService),
                      const Divider(height: 32),
                      _buildRealNotificationsSection(context, student,
                          notificationService, offlineService),
                      const Divider(height: 16),
                      _buildSyncStatusSection(offlineService),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isOnline = true,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            IconButton.filled(
              onPressed: onTap,
              icon: Icon(icon),
              iconSize: 28,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (!isOnline)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    Icons.offline_bolt,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildRealNotificationsSection(BuildContext context, Student student,
      NotificationService notificationService, OfflineService offlineService) {
    return FutureBuilder<bool>(
      future: offlineService.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? true;

        return FutureHandler<List<Map<String, dynamic>>>(
          future: offlineService.callWithOfflineFallbackAndSync(
            onlineCall: () =>
                notificationService.getStudentNotifications(student.id),
            offlineFallback: () async {
              // Try to get cached notifications
              final cached = await offlineService
                  .getCachedData('student_notifications_${student.id}');
              if (cached != null) {
                return List<Map<String, dynamic>>.from(cached);
              }
              return null;
            },
            cacheKey: 'student_notifications_${student.id}',
            tableName: 'notifications',
            recordId: student.id,
          ),
          loadingWidget: const Center(child: CircularProgressIndicator()),
          emptyMessage: 'No new notifications.',
          builder: (context, notifications) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!isOnline)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (notifications.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FullNotificationsScreen(),
                          ),
                        ),
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (notifications.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No new notifications.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        notifications.length > 3 ? 3 : notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isRead = notification['isRead'] as bool? ?? false;
                      final icon = _getNotificationIcon(
                          notification['icon'] as String? ?? 'notifications');
                      final color = _getNotificationColor(
                          notification['color'] as String? ?? 'grey');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha((255 * 0.1).round()),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(
                          notification['title'] as String? ?? 'Notification',
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          notification['message'] as String? ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: !isRead
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        dense: true,
                        onTap: () async {
                          // Mark as read when tapped
                          if (!isRead) {
                            try {
                              await notificationService.markNotificationAsRead(
                                  notification['id'] as String);
                              // Queue for sync if offline
                              await offlineService.queueForSync('update', {
                                'table': 'notifications',
                                'id': notification['id'],
                                'isRead': true,
                              });
                            } catch (e) {
                              // Handle error silently or show a snackbar
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Notification marked as read offline')),
                                );
                              }
                            }
                          }

                          // Handle notification action if available
                          final actionUrl =
                              notification['actionUrl'] as String?;
                          if (actionUrl != null) {
                            // Handle action URL (to be implemented based on URL structure)
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Action: $actionUrl')),
                              );
                            }
                          }
                        },
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ),
                if (notifications.length > 3)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FullNotificationsScreen(),
                          ),
                        ),
                        child: Text(
                            '+${notifications.length - 3} more notifications'),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getNotificationIcon(String iconName) {
    switch (iconName) {
      case 'calendar_today':
        return Icons.calendar_today;
      case 'receipt':
        return Icons.receipt;
      case 'campaign':
        return Icons.campaign;
      case 'assessment':
        return Icons.assessment;
      case 'schedule':
        return Icons.schedule;
      case 'book':
        return Icons.book;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'teal':
        return Colors.teal;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOfflineStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isOnline ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green.shade700 : Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isOnline
                  ? 'Online - All features available'
                  : 'Offline - Using cached data',
              style: TextStyle(
                color:
                    _isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusSection(OfflineService offlineService) {
    return FutureBuilder<Map<String, dynamic>>(
      future: offlineService.getOfflineDataStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        final pendingSync = status['pendingSyncCount'] as int? ?? 0;

        if (pendingSync == 0 && _isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sync,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sync Status',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (pendingSync > 0)
                Text(
                  '$pendingSync pending operations to sync',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              if (!_isOnline)
                Text(
                  'Will sync when online',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              if (pendingSync > 0 && _isOnline)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await offlineService.processSyncQueue();
                        setState(() {}); // Refresh the UI
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Sync completed successfully')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sync failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsSection(
      BuildContext context,
      UserDataProvider userData,
      Student student,
      AssignmentService assignmentService,
      OfflineService offlineService) {
    return FutureBuilder<bool>(
      future: offlineService.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? true;

        return FutureHandler<List<Map<String, dynamic>>>(
          future: offlineService.callWithOfflineFallbackAndSync(
            onlineCall: () => assignmentService.getStudentAssignments(
              schoolId: userData.userProfile!.schoolId!,
              studentId: student.id,
            ),
            offlineFallback: () async {
              final cached = await offlineService.getCachedData(
                  'assignments_student_${userData.userProfile!.schoolId}_${student.id}');
              if (cached != null) {
                return List<Map<String, dynamic>>.from(cached);
              }
              return [];
            },
            cacheKey:
                'assignments_student_${userData.userProfile!.schoolId}_${student.id}',
            tableName: 'assignments',
            recordId: student.id,
          ),
          loadingWidget: const Center(child: CircularProgressIndicator()),
          emptyMessage: 'No assignments.',
          builder: (context, assignments) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Assignments',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!isOnline)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (assignments.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AssignmentsScreen(),
                          ),
                        ),
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (assignments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No assignments due.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assignments.length > 2 ? 2 : assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = assignments[index];
                      final dueDate =
                          DateTime.tryParse(assignment['dueDate'] ?? '');
                      final isOverdue =
                          dueDate != null && dueDate.isBefore(DateTime.now());
                      final isCompleted = assignment['isCompleted'] ?? false;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOverdue && !isCompleted
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          child: Icon(
                            isCompleted ? Icons.check : Icons.assignment,
                            color: isOverdue && !isCompleted
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                        title: Text(
                          assignment['title'] ?? 'Assignment',
                          style: TextStyle(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isOverdue && !isCompleted
                                ? Colors.red.shade700
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${assignment['subject'] ?? 'Subject'} • Due: ${dueDate != null ? _formatDate(dueDate) : 'No due date'}',
                          style: TextStyle(
                            color: isOverdue && !isCompleted
                                ? Colors.red.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                        dense: true,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                  ),
                if (assignments.length > 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AssignmentsScreen(),
                          ),
                        ),
                        child:
                            Text('+${assignments.length - 2} more assignments'),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExamsSection(BuildContext context, UserDataProvider userData,
      Student student, ExamService examService, OfflineService offlineService) {
    return FutureBuilder<bool>(
      future: offlineService.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? true;

        return FutureHandler<List<dynamic>>(
          future: offlineService.callWithOfflineFallbackAndSync(
            onlineCall: () => examService.getStudentExams(
              schoolId: userData.userProfile!.schoolId!,
              studentId: student.id,
            ),
            offlineFallback: () async {
              final cached = await offlineService.getCachedData(
                  'exams_student_${userData.userProfile!.schoolId}_${student.id}');
              if (cached != null) {
                return List<dynamic>.from(cached);
              }
              return [];
            },
            cacheKey:
                'exams_student_${userData.userProfile!.schoolId}_${student.id}',
            tableName: 'exams',
            recordId: student.id,
          ),
          loadingWidget: const Center(child: CircularProgressIndicator()),
          emptyMessage: 'No upcoming exams.',
          builder: (context, exams) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Upcoming Exams',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!isOnline)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (exams.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ExamsScreen(),
                          ),
                        ),
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (exams.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No upcoming exams.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exams.length > 2 ? 2 : exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index] as Map<String, dynamic>;
                      final examDate =
                          DateTime.tryParse(exam['examDate'] ?? '');
                      final daysUntil =
                          examDate?.difference(DateTime.now()).inDays;
                      final isUrgent = daysUntil != null && daysUntil <= 1;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUrgent
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          child: Icon(
                            Icons.quiz,
                            color: isUrgent
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                        title: Text(
                          exam['name'] ?? 'Exam',
                          style: TextStyle(
                            color: isUrgent ? Colors.red.shade700 : null,
                          ),
                        ),
                        subtitle: Text(
                          '${exam['subject'] ?? 'Subject'} • ${exam['className'] ?? student.className} • ${_formatExamDate(examDate)}',
                          style: TextStyle(
                            color: isUrgent
                                ? Colors.red.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                        dense: true,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                  ),
                if (exams.length > 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ExamsScreen(),
                          ),
                        ),
                        child: Text('+${exams.length - 2} more exams'),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLibrarySection(
      BuildContext context,
      UserDataProvider userData,
      Student student,
      LibraryService libraryService,
      OfflineService offlineService) {
    return FutureBuilder<bool>(
      future: offlineService.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? true;

        return FutureHandler<List<dynamic>>(
          future: offlineService.callWithOfflineFallbackAndSync(
            onlineCall: () => libraryService.getBorrowedBooks(
              student.schoolId,
              student.id,
            ),
            offlineFallback: () async {
              final cached = await offlineService
                  .getCachedData('borrowed_books_${student.id}');
              if (cached != null) {
                return List<dynamic>.from(cached);
              }
              return [];
            },
            cacheKey: 'borrowed_books_${student.id}',
            tableName: 'books',
            recordId: student.id,
          ),
          loadingWidget: const Center(child: CircularProgressIndicator()),
          emptyMessage: 'No borrowed books.',
          builder: (context, books) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Library Books',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!isOnline)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (books.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManageBooksScreen(),
                          ),
                        ),
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (books.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No books currently borrowed.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: books.length > 2 ? 2 : books.length,
                    itemBuilder: (context, index) {
                      final book = books[index] as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            Icons.book,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: Text(book['title'] ?? 'Book Title'),
                        subtitle: Text(
                          'Author: ${book['author'] ?? 'Unknown'} • Due: ${book['dueDate'] ?? 'No due date'}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        dense: true,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                  ),
                if (books.length > 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManageBooksScreen(),
                          ),
                        ),
                        child: Text('+${books.length - 2} more books'),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 0) return 'In $difference days';
    return '${difference.abs()} days ago';
  }

  String _formatExamDate(DateTime? date) {
    if (date == null) return 'Date TBA';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference > 1 && difference <= 7) return 'In $difference days';
    if (difference > 7) return '${date.day}/${date.month}/${date.year}';
    return '${difference.abs()} days ago';
  }

  Widget _buildGradesSection(
      BuildContext context,
      UserDataProvider userData,
      Student student,
      OfflineService offlineService) {
    return FutureBuilder<bool>(
      future: offlineService.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? true;

        return FutureHandler<Map<String, dynamic>>(
          future: MarksService.getStudentGrades(
            int.tryParse(userData.userProfile!.schoolId!) ?? 0,
            int.tryParse(student.id) ?? 0,
          ),
          loadingWidget: const Center(child: CircularProgressIndicator()),
          emptyMessage: 'No grades available.',
          builder: (context, grades) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Grades Overview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!isOnline)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (grades['recentSubjects']?.isNotEmpty ?? false)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FullGradesScreen(),
                          ),
                        ),
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Overall grade card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Grade',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              grades['overallGrade'] ?? 'N/A',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'GPA',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${grades['gpa'] ?? 0.0}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Recent subjects
                if (grades['recentSubjects']?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Subjects',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (grades['recentSubjects'] as List).length > 3
                            ? 3
                            : (grades['recentSubjects'] as List).length,
                        itemBuilder: (context, index) {
                          final subject = (grades['recentSubjects']
                              as List)[index] as Map<String, dynamic>;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                (subject['grade'] as String?)
                                        ?.substring(0, 1) ??
                                    'A',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(subject['subject'] ?? 'Subject'),
                            subtitle: Text(
                                'Grade: ${subject['grade'] ?? 'N/A'} • Score: ${subject['score'] ?? 0}%'),
                            dense: true,
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                      ),
                    ],
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No recent grades available.'),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

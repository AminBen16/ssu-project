import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/notification_service.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/widgets/future_handler.dart';

class FullNotificationsScreen extends StatefulWidget {
  const FullNotificationsScreen({super.key});

  @override
  State<FullNotificationsScreen> createState() => _FullNotificationsScreenState();
}

class _FullNotificationsScreenState extends State<FullNotificationsScreen> {
  late NotificationService _notificationService;
  late OfflineService _offlineService;
  late UserDataProvider _userData;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _offlineService = offlineService;
    _userData = Provider.of<UserDataProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _offlineService.isOnline,
        builder: (context, onlineSnapshot) {
          final isOnline = onlineSnapshot.data ?? true;

          return FutureHandler<List<Map<String, dynamic>>>(
            future: _offlineService.callWithOfflineFallbackAndSync(
              onlineCall: () => _notificationService.getStudentNotifications(
                _userData.userProfile!.uid,
              ),
              offlineFallback: () async {
                final cached = await _offlineService.getCachedData(
                  'student_notifications_${_userData.userProfile!.uid}',
                );
                if (cached != null) {
                  return List<Map<String, dynamic>>.from(cached);
                }
                return [];
              },
              cacheKey: 'student_notifications_${_userData.userProfile!.uid}',
              tableName: 'notifications',
              recordId: _userData.userProfile!.uid,
            ),
            loadingWidget: const Center(child: CircularProgressIndicator()),
            emptyMessage: 'No notifications found.',
            builder: (context, notifications) {
              return Column(
                children: [
                  // Offline indicator
                  if (!isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.orange.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Offline - Showing cached notifications',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),

                  // Mark all as read button
                  if (notifications.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _markAllAsRead(notifications),
                        icon: const Icon(Icons.done_all),
                        label: const Text('Mark All as Read'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ),

                  // Notifications list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isRead = notification['isRead'] as bool? ?? false;
                        final icon = _getNotificationIcon(notification['icon'] as String? ?? 'notifications');
                        final color = _getNotificationColor(notification['color'] as String? ?? 'grey');
                        final timestamp = DateTime.tryParse(notification['createdAt'] ?? '');

                        return Dismissible(
                          key: Key(notification['id'] ?? index.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red.shade100,
                            child: Icon(Icons.delete, color: Colors.red.shade700),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(notification),
                          onDismissed: (direction) => _deleteNotification(notification),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withAlpha((255 * 0.1).round()),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Text(
                                notification['title'] as String? ?? 'Notification',
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['message'] as String? ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timestamp != null ? _formatTimestamp(timestamp) : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
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
                              onTap: () => _handleNotificationTap(notification),
                              isThreeLine: true,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> notifications) async {
    try {
      final unreadNotifications = notifications.where((n) => !(n['isRead'] as bool? ?? false)).toList();

      for (final notification in unreadNotifications) {
        await _notificationService.markNotificationAsRead(notification['id'] as String);
        await _offlineService.queueForSync('update', {
          'table': 'notifications',
          'id': notification['id'],
          'isRead': true,
        });
      }

      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark notifications as read: $e')),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(Map<String, dynamic> notification) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    try {
      // In a real implementation, you'd call an API to delete the notification
      // For now, we'll just remove it from local cache
      await _offlineService.queueForSync('delete', {
        'table': 'notifications',
        'id': notification['id'],
      });

      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e')),
        );
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    final isRead = notification['isRead'] as bool? ?? false;

    // Mark as read if not already read
    if (!isRead) {
      try {
        await _notificationService.markNotificationAsRead(notification['id'] as String);
        await _offlineService.queueForSync('update', {
          'table': 'notifications',
          'id': notification['id'],
          'isRead': true,
        });
        setState(() {});
      } catch (e) {
        // Handle error silently
      }
    }

    // Handle action URL if present
    final actionUrl = notification['actionUrl'] as String?;
    if (actionUrl != null) {
      // Navigate based on action URL (could be deep linking)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: $actionUrl')),
        );
      }
    }

    // Show notification details in a dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification['title'] as String? ?? 'Notification'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(notification['message'] as String? ?? ''),
                const SizedBox(height: 16),
                if (notification['details'] != null)
                  Text(
                    'Details: ${notification['details']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

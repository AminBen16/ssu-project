import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/fee_service.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/student_service.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/widgets/future_handler.dart';
import 'package:test/screens/child_info_card.dart';
import 'package:test/widgets/profile_header_card.dart';
import 'package:test/screens/parent_profile_settings_screen.dart';
import 'package:test/screens/ai_content_studio_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/services/notification_service.dart';
import 'package:test/services/parent_offline_sync_service.dart';

/// A modular widget for the Parent dashboard.
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  static const String _viewModeKey = 'parent_dashboard_view_mode';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.list;
  final ParentOfflineSyncService _syncService = ParentOfflineSyncService();
  final NotificationService _notificationService = NotificationService();
  bool _isSyncing = false;
  Map<String, dynamic> _syncStatus = {};
  List<Map<String, dynamic>> _recentAnnouncements = [];
  bool _isLoadingAnnouncements = false;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadSyncStatus();
    _loadAnnouncements();
    _searchController.addListener(() {
      String searchText = _searchController.text;
      final sanitizedInput = _sanitizeSearchInput(searchText);

      if (sanitizedInput != _searchController.text) {
        // Update the text field with the sanitized input
        _searchController.value = TextEditingValue(
          text: sanitizedInput,
          selection: TextSelection.collapsed(offset: sanitizedInput.length),
        );
      }

      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // Robust sanitization for search input using whitelist approach
  String _sanitizeSearchInput(String input) {
    // Allow only alphanumeric characters and spaces
    final allowedChars = RegExp(r'[a-zA-Z0-9\s]');
    // Filter out any characters that are not in the allowedChars regex
    return input.split('').where((char) => allowedChars.hasMatch(char)).join();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final viewModeString = prefs.getString(_viewModeKey);
    if (viewModeString != null) {
      setState(() {
        _viewMode = ViewMode.values.firstWhere(
          (e) => e.name == viewModeString,
          orElse: () => ViewMode.list, // Default if saved value is invalid
        );
      });
    }
  }

  Future<void> _loadSyncStatus() async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    if (userData.userProfile?.schoolId != null &&
        userData.userProfile?.uid != null) {
      final status = await _syncService.getParentSyncStatus(
        schoolId: userData.userProfile!.schoolId!,
        parentId: userData.userProfile!.uid,
      );
      setState(() {
        _syncStatus = status;
      });
    }
  }

  Future<void> _loadAnnouncements() async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    if (userData.userProfile?.schoolId == null ||
        userData.userProfile?.uid == null) {
      return;
    }

    setState(() {
      _isLoadingAnnouncements = true;
    });

    try {
      // Get children IDs for the parent
      final children = await StudentService().getStudentsByParentId(
        schoolId: userData.userProfile!.schoolId!,
        parentId: userData.userProfile!.uid,
      );
      final childrenIds = children.map((child) => child.id).toList();

      // Load announcements
      final announcements =
          await _notificationService.getNotificationsForParent(
        schoolId: userData.userProfile!.schoolId!,
        parentId: userData.userProfile!.uid,
        childrenIds: childrenIds,
      );

      // Sort by timestamp and take recent ones
      announcements.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      setState(() {
        _recentAnnouncements = announcements.take(5).toList();
      });
    } catch (e) {
      developer.log('Error loading announcements: $e');
      // Keep empty list on error
    } finally {
      setState(() {
        _isLoadingAnnouncements = false;
      });
    }
  }

  Future<void> _performSync() async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    if (userData.userProfile?.schoolId == null ||
        userData.userProfile?.uid == null) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await _syncService.syncParentData(
        schoolId: userData.userProfile!.schoolId!,
        parentId: userData.userProfile!.uid,
      );
      await _loadSyncStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _saveViewMode(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode.name);
  }

  @override
  Widget build(BuildContext context) {
    //Access user data through provider

    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final feeService = FeeService();
    final studentService = StudentService();

    if (userData.userProfile == null ||
        userData.userProfile?.schoolId == null) {
      return const Center(child: Text('User or school data not available.'));
    }

    return Scaffold(
      body: FutureHandler<List<Student>>(
        future: studentService.getStudentsByParentId(
          schoolId: userData.userProfile!.schoolId!,
          parentId: userData.userProfile!.uid,
        ),
        emptyMessage: 'No children linked to this account.',
        builder: (context, children) {
          final filteredChildren = children.where((child) {
            return child.fullName.toLowerCase().contains(_searchQuery);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeaderCard(
                onEdit: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ParentProfileSettingsScreen(),
                  ));
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comprehensive offline status indicator
                    InkWell(
                      onTap: _isSyncing ? null : _performSync,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getSyncStatusColor(),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _getSyncStatusBorderColor()),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSyncStatusIcon(),
                                  size: 16,
                                  color: _getSyncStatusColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getSyncStatusText(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getSyncStatusColor(),
                                  ),
                                ),
                                if (_isSyncing) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _getSyncStatusColor()),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_syncStatus['lastSyncTime'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Last sync: ${_getTimeAgo(DateTime.parse(_syncStatus['lastSyncTime']))}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (_syncStatus['pendingOperations'] != null &&
                                _syncStatus['pendingOperations'] > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: Colors.orange.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_syncStatus['pendingOperations']} pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Announcements Section
                    if (_recentAnnouncements.isNotEmpty ||
                        _isLoadingAnnouncements)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.announcement,
                                    color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Recent Announcements',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.cloud_done,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingAnnouncements)
                              const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else if (_recentAnnouncements.isNotEmpty)
                              Column(
                                children:
                                    _recentAnnouncements.map((announcement) {
                                  final timestamp = DateTime.parse(
                                      announcement['timestamp'] as String);
                                  final timeAgo = _getTimeAgo(timestamp);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.notifications,
                                          size: 16,
                                          color: Colors.blue.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                announcement['title']
                                                        as String? ??
                                                    'Announcement',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (announcement['message'] !=
                                                  null)
                                                Text(
                                                  announcement['message']
                                                      as String,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              Text(
                                                timeAgo,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Text(
                                'No recent announcements',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_recentAnnouncements.isNotEmpty ||
                        _isLoadingAnnouncements)
                      const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for a child...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ToggleButtons(
                          isSelected: [
                            _viewMode == ViewMode.list,
                            _viewMode == ViewMode.grid
                          ],
                          onPressed: (index) {
                            final newMode =
                                index == 0 ? ViewMode.list : ViewMode.grid;
                            if (_viewMode != newMode) {
                              setState(() {
                                _viewMode = newMode;
                              });
                              _saveViewMode(newMode);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          children: const [
                            Icon(Icons.view_list),
                            Icon(Icons.grid_view)
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredChildren.isEmpty && children.isNotEmpty
                    ? Center(
                        child: Text('No results found for "$_searchQuery"'),
                      )
                    : _buildChildrenView(filteredChildren,
                        userData.userProfile!.schoolId!, feeService),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiContentStudioScreen()));
        },
        icon: const Icon(Icons.support_agent),
        label: const Text('Fee Assistant'),
      ),
    );
  }

  Widget _buildChildrenView(
      List<Student> children, String schoolId, FeeService feeService) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren.map((child) => FadeTransition(
                  opacity: child.key == (currentChild?.key)
                      ? const AlwaysStoppedAnimation(0) // Should not happen
                      : (child as dynamic)
                          .animation, // The animation is on the child
                  child: child,
                )),
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final curvedAnimation =
            CurvedAnimation(parent: animation, curve: Curves.easeOut);

        return FadeTransition(
          opacity: curvedAnimation,
          child: SizeTransition(
            sizeFactor: curvedAnimation,
            axis: Axis.vertical,
            child: child,
          ),
        );
      },
      child: _viewMode == ViewMode.grid
          ? GridView.builder(
              key: const ValueKey('grid'), // Unique key for AnimatedSwitcher
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65, // Adjust this ratio to fit your card
              ),
              itemCount: children.length,
              itemBuilder: (context, index) => ChildInfoCard(
                  child: children[index],
                  schoolId: schoolId,
                  feeService: feeService,
                  viewMode: _viewMode),
            )
          : ListView.builder(
              key: const ValueKey('list'), // Unique key for AnimatedSwitcher
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: children.length,
              itemBuilder: (context, index) => ChildInfoCard(
                  child: children[index],
                  schoolId: schoolId,
                  feeService: feeService,
                  viewMode: _viewMode),
            ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getSyncStatusColor() {
    if (_syncStatus['error'] != null) {
      return Colors.red.shade100;
    }
    if (_isSyncing) {
      return Colors.blue.shade100;
    }
    if (_syncStatus['overallSyncStatus'] == 'fully_synced') {
      return Colors.green.shade100;
    }
    if (_syncStatus['overallSyncStatus'] == 'mostly_synced') {
      return Colors.lightGreen.shade100;
    }
    if (_syncStatus['overallSyncStatus'] == 'partially_synced') {
      return Colors.orange.shade100;
    }
    return Colors.grey.shade100;
  }

  IconData _getSyncStatusIcon() {
    if (_syncStatus['error'] != null) {
      return Icons.error;
    }
    if (_isSyncing) {
      return Icons.sync;
    }
    if (_syncStatus['overallSyncStatus'] == 'fully_synced') {
      return Icons.cloud_done;
    }
    if (_syncStatus['overallSyncStatus'] == 'mostly_synced') {
      return Icons.cloud_done;
    }
    if (_syncStatus['overallSyncStatus'] == 'partially_synced') {
      return Icons.cloud_queue;
    }
    return Icons.cloud_off;
  }

  String _getSyncStatusText() {
    if (_syncStatus['error'] != null) {
      return 'Sync Error';
    }
    if (_isSyncing) {
      return 'Syncing...';
    }
    if (_syncStatus['overallSyncStatus'] == 'fully_synced') {
      return 'Fully Synced';
    }
    if (_syncStatus['overallSyncStatus'] == 'mostly_synced') {
      return 'Mostly Synced';
    }
    if (_syncStatus['overallSyncStatus'] == 'partially_synced') {
      return 'Partially Synced';
    }
    return 'Needs Sync';
  }

  Color _getSyncStatusBorderColor() {
    if (_syncStatus['error'] != null) {
      return Colors.red.shade300;
    }
    if (_isSyncing) {
      return Colors.blue.shade300;
    }
    if (_syncStatus['overallSyncStatus'] == 'fully_synced') {
      return Colors.green.shade300;
    }
    if (_syncStatus['overallSyncStatus'] == 'mostly_synced') {
      return Colors.lightGreen.shade300;
    }
    if (_syncStatus['overallSyncStatus'] == 'partially_synced') {
      return Colors.orange.shade300;
    }
    return Colors.grey.shade300;
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test/screens/create_school_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/user_profile_service.dart';
import 'package:test/services/school_service.dart';
import 'package:test/models/school.dart';
import 'package:test/screens/staff_detail_screen.dart';

class SystemAdminDashboardScreen extends StatefulWidget {
  const SystemAdminDashboardScreen({super.key});

  @override
  State<SystemAdminDashboardScreen> createState() =>
      _SystemAdminDashboardScreenState();
}

class _SystemAdminDashboardScreenState
    extends State<SystemAdminDashboardScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  final SchoolService _schoolService = SchoolService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  // State for pagination
  final List<UserProfile> _users = [];
  List<School> _schools = [];
  int _currentPage = 1;
  int _totalUsers = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _showUsers = true; // Toggle between users and schools view

  @override
  void initState() {
    super.initState();
    _fetchUsers(isRefresh: true);
    _fetchSchools();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500),
          () => _fetchUsers(isRefresh: true));
    });

    // Add a listener to the scroll controller to detect when the user
    // reaches the end of the list.
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        if (_showUsers) {
          _fetchUsers();
        } else {
          _fetchSchools();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchSchools() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _error = null;

    try {
      final schools = await _schoolService.getAllSchools();
      setState(() {
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load schools: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUsers({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() => _isLoading = true);

    if (isRefresh) {
      _currentPage = 1;
      _users.clear();
      _hasMore = true;
    }

    try {
      final (newUsers, totalCount) =
          await _userProfileService.getAllUsers(page: _currentPage);
      if (mounted) {
        setState(() {
          _users.addAll(newUsers);
          _totalUsers = totalCount;
          _currentPage++;
          _hasMore = _users.length < _totalUsers;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showUsers ? 'System Admin Dashboard' : 'Schools Dashboard'),
        actions: [
          // Toggle between users and schools
          IconButton(
            icon: Icon(_showUsers ? Icons.business : Icons.people),
            tooltip: _showUsers ? 'View Schools' : 'View Users',
            onPressed: () {
              setState(() {
                _showUsers = !_showUsers;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_showUsers) {
                _searchController.clear();
                _fetchUsers(isRefresh: true);
              } else {
                _fetchSchools();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirm Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      TextButton(
                        child: const Text('Sign Out'),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
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
      body: _buildBody(),
      floatingActionButton: _showUsers ? FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to the screen to create a new school.
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const CreateSchoolScreen(),
            ),
          );
          // If the creation screen returns true, it indicates success,
          // so we refresh the user list to show the new admin.
          if (result == true) {
            _fetchUsers(isRefresh: true);
            _fetchSchools();
          }
        },
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Create School'),
      ) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading && (_showUsers ? _users.isEmpty : _schools.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && (_showUsers ? _users.isEmpty : _schools.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_showUsers) {
                  _fetchUsers(isRefresh: true);
                } else {
                  _fetchSchools();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_showUsers ? _users.isEmpty : _schools.isEmpty) {
      return Center(
        child: Text(_showUsers ? 'No users found.' : 'No schools found.'),
      );
    }

    if (_showUsers) {
      return _buildUsersView();
    } else {
      return _buildSchoolsView();
    }
  }

  Widget _buildUsersView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _users.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _users.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final user = _users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.profilePictureUrl!)
                      : null,
                  child: user.profilePictureUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user.fullName),
                subtitle:
                    Text('${user.email} - Role: ${user.role.displayName}'),
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) =>
                          StaffDetailScreen(staffProfile: user),
                    ),
                  );
                  if (result == true) {
                    _fetchUsers(isRefresh: true);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolsView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _schools.length,
      itemBuilder: (context, index) {
        final school = _schools[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.business, color: Colors.blue.shade800),
            ),
            title: Text(school.name),
            subtitle: Text('ID: ${school.id}'),
            trailing: Text(
              'Staff: ${school.staff?.length ?? 0}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              // Navigate to school details
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('School: ${school.name}')),
              );
            },
          ),
        );
      },
    );
  }
}

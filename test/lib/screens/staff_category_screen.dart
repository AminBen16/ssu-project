import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/staff_service.dart';
import 'package:test/models/user_roles.dart';

import 'package:test/models/staff.dart';
import 'package:test/screens/staff_detail_screen.dart';

class StaffCategoryScreen extends StatefulWidget {
  final String title;
  final Set<UserRole> roles;
  final IconData icon;
  final Color color;

  const StaffCategoryScreen({
    super.key,
    required this.title,
    required this.roles,
    required this.icon,
    required this.color,
  });

  @override
  State<StaffCategoryScreen> createState() => _StaffCategoryScreenState();
}

class _StaffCategoryScreenState extends State<StaffCategoryScreen> {
  late Future<List<Staff>> _staffFuture;
  final _staffService = StaffService();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  void _loadStaff() {
    final schoolId =
        Provider.of<UserDataProvider>(context, listen: false).school?.id;
    if (schoolId != null) {
      _staffFuture = _staffService.getAllStaff(schoolId.toString());
    }
  }

  List<Staff> _filterStaffByCategory(List<Staff> allStaff) {
    return allStaff
        .where(
            (staff) => staff.role != null && widget.roles.contains(staff.role!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.icon, color: widget.color),
            const SizedBox(width: 12),
            Text(widget.title),
          ],
        ),
        backgroundColor: widget.color.withAlpha(26),
      ),
      body: FutureBuilder<List<Staff>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading staff data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStaff,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 64,
                    color: widget.color.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.title.toLowerCase()} found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Staff in this category will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final allStaff = snapshot.data!;
          final categoryStaff = _filterStaffByCategory(allStaff);

          if (categoryStaff.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 64,
                    color: widget.color.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.title.toLowerCase()} found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are no staff members in this category yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(26),
                  border: Border(
                    bottom: BorderSide(color: widget.color.withAlpha(77)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: widget.color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.color,
                                ),
                          ),
                          Text(
                            '${categoryStaff.length} member${categoryStaff.length != 1 ? 's' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: widget.color.withAlpha(204),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${categoryStaff.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Staff list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: categoryStaff.length,
                  itemBuilder: (context, index) {
                    final staff = categoryStaff[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.color.withAlpha(51),
                          child: Icon(
                            Icons.person,
                            color: widget.color,
                          ),
                        ),
                        title: Text(
                          '${staff.firstName} ${staff.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff.role?.displayName ?? 'Unknown Role'),
                            if (staff.email.isNotEmpty)
                              Text(
                                staff.email,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.blue[600],
                                    ),
                              ),
                            if (staff.phoneNumber.isNotEmpty)
                              Text(staff.phoneNumber),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StaffDetailScreen(
                                  staffProfile: staff.toUserProfile()),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

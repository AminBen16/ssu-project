import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/staff_service.dart';

/// A reusable screen widget that displays a searchable list of staff members.
class StaffSelectionList extends StatefulWidget {
  /// The title to display in the AppBar.
  final String appBarTitle;

  /// The callback function that is triggered when a staff member is tapped.
  final void Function(UserProfile staff) onStaffSelected;

  /// The hint text for the search input field.
  final String searchLabel;

  const StaffSelectionList({
    super.key,
    required this.appBarTitle,
    required this.onStaffSelected,
    this.searchLabel = 'Search by name or role',
  });

  @override
  State<StaffSelectionList> createState() => _StaffSelectionListState();
}

class _StaffSelectionListState extends State<StaffSelectionList> {
  late Future<List<UserProfile>> _staffFuture;
  final _staffService = StaffService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  void _loadStaff() {
    final schoolId = Provider.of<UserDataProvider>(context, listen: false)
        .school!
        .id
        .toString();
    _staffFuture = _staffService.getAllStaff(schoolId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                labelText: widget.searchLabel,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserProfile>>(
              future: _staffFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No staff members found.'));
                }

                final staffList = snapshot.data!;
                final filteredStaff = staffList.where((staff) {
                  final query = _searchQuery.toLowerCase();
                  final fullName = staff.fullName.toLowerCase();
                  final role = staff.role.displayName.toLowerCase();
                  return fullName.contains(query) || role.contains(query);
                }).toList();

                return ListView.builder(
                  itemCount: filteredStaff.length,
                  itemBuilder: (context, index) {
                    final staff = filteredStaff[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: staff.profilePictureUrl != null
                              ? CachedNetworkImageProvider(
                                  staff.profilePictureUrl!)
                              : null,
                          child: staff.profilePictureUrl == null
                              ? Text(staff.firstName?.substring(0, 1) ?? '?')
                              : null,
                        ),
                        title: Text(
                            '${staff.title ?? ''} ${staff.firstName ?? ''} ${staff.lastName ?? ''}'
                                .trim()),
                        subtitle: Text(staff.role.displayName),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => widget.onStaffSelected(staff),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

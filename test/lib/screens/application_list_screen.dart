import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/screens/application_detail_screen.dart';
import 'package:test/models/student_application_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/student_application_service.dart';

class ApplicationListScreen extends StatefulWidget {
  const ApplicationListScreen({super.key});

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  late Future<List<StudentApplication>> _applicationsFuture;
  final _applicationService = StudentApplicationService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ApplicationStatus? _selectedStatus = ApplicationStatus.pending; // Default

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _loadApplications() {
    final schoolId =
        Provider.of<UserDataProvider>(context, listen: false).school!.id.toString();
    _applicationsFuture = _applicationService.getApplications(schoolId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Applications')),
      body: Column(
        children: [
          _buildFilterControls(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<StudentApplication>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No new applications found.'));
                }

                final applications = snapshot.data!;

                final filteredApplications = applications.where((app) {
                  final statusMatches =
                      _selectedStatus == null || app.status == _selectedStatus!;
                  final searchMatches = _searchQuery.isEmpty ||
                      '${app.firstName} ${app.lastName}'
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      app.className.toLowerCase().contains(_searchQuery);
                  return statusMatches && searchMatches;
                }).toList();

                if (filteredApplications.isEmpty && applications.isNotEmpty) {
                  return const Center(
                      child: Text('No applications match your filter.'));
                }

                return ListView.builder(
                  itemCount: filteredApplications.length,
                  itemBuilder: (context, index) {
                    final app = filteredApplications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: _buildStatusIcon(app.status),
                        title: Text('${app.firstName} ${app.lastName}'),
                        subtitle: Text(
                            'Applied for ${app.className} on ${DateFormat.yMMMd().format(app.applicationDate)}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ApplicationDetailScreen(application: app),
                            ),
                          );
                        },
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

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or class...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, 'All'), // null represents 'All'
                _buildFilterChip(ApplicationStatus.pending, 'Pending'),
                _buildFilterChip(ApplicationStatus.approved, 'Approved'),
                _buildFilterChip(ApplicationStatus.rejected, 'Rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ApplicationStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = status;
          });
        },
      ),
    );
  }

  Widget _buildStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      case ApplicationStatus.approved:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ApplicationStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }
}

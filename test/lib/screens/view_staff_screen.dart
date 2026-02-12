import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/services/user_profile_service.dart';
import 'package:test/services/export_service.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/screens/staff_detail_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class ViewStaffScreen extends StatefulWidget {
  const ViewStaffScreen({super.key});

  @override
  State<ViewStaffScreen> createState() => _ViewStaffScreenState();
}

class _ViewStaffScreenState extends State<ViewStaffScreen> {
  final _userProfileService = UserProfileService();
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _allStaff = [];
  List<UserProfile> _filteredStaff = [];
  bool _isLoading = false;
  String? _selectedSubject;
  String? _selectedStatus;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _searchController.addListener(_filterStaff);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStaff() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty && _selectedSubject == null && _selectedStatus == null && _selectedRole == null) {
        _filteredStaff = List.from(_allStaff);
      } else {
        _filteredStaff = _allStaff.where((staff) {
          final name = '${staff.firstName} ${staff.lastName}'.toLowerCase();
          final email = staff.email.toLowerCase();
          final role = staff.role.displayName.toLowerCase();
          final matchesSearch = query.isEmpty || 
                 name.contains(query) || 
                 email.contains(query) || 
                 role.contains(query);
          
          final matchesSubject = _selectedSubject == null ||
              (staff.subjectCodes?.contains(_selectedSubject) ?? false);

          final matchesStatus = _selectedStatus == null ||
              staff.employmentStatus == _selectedStatus;
          
          final matchesRole = _selectedRole == null || 
              staff.role.name.toLowerCase() == _selectedRole!.toLowerCase();
          
          return matchesSearch && matchesSubject && matchesStatus && matchesRole;
        }).toList();
      }
    });
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    
    try {
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      final schoolId = userData.school?.id;
      
      if (schoolId == null) {
        throw Exception('School ID not available');
      }

      developer.log('Loading staff for school ID: $schoolId');
      
      // Use UserProfileService.getAllUsers which works with the real endpoint
      final (staff, totalCount) = await _userProfileService.getAllUsers(
        page: 1,
        limit: 100, // Get more staff at once
      );
      
      developer.log('Loaded ${staff.length} staff members');
      
      // Filter only staff roles (exclude students, parents, etc.)
      final staffOnly = staff.where((user) => 
        UserRole.allStaffRoles.contains(user.role)
      ).toList();
      
      setState(() {
        _allStaff = staffOnly;
        _filteredStaff = List.from(staffOnly);
        _isLoading = false;
      });
      
    } catch (e) {
      developer.log('Error loading staff: $e');
      setState(() {
        _allStaff = [];
        _filteredStaff = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Staff'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportStaff,
            tooltip: 'Export Staff',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printStaff,
            tooltip: 'Print List',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search staff by name, email, or role...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Advanced filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String>(
                    hint: const Text('Subject'),
                    value: _selectedSubject,
                    items: ['Mathematics', 'English', 'Science', 'Biology', 'Chemistry', 'Physics', 'History', 'Geography']
                        .map((subject) => DropdownMenuItem(value: subject, child: Text(subject)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                        _filterStaff();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    hint: const Text('Status'),
                    value: _selectedStatus,
                    items: ['Active', 'On Leave', 'Contract', 'Permanent']
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _filterStaff();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    hint: const Text('Role'),
                    value: _selectedRole,
                    items: ['Teacher', 'Head Teacher', 'Deputy Head', 'Administrator', 'Accountant', 'Librarian']
                        .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                        _filterStaff();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedSubject = null;
                        _selectedStatus = null;
                        _selectedRole = null;
                        _searchController.clear();
                        _filterStaff();
                      });
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),
          ),
          
          // Staff count and filters
          if (!_isLoading && _allStaff.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Showing ${_filteredStaff.length} of ${_allStaff.length} staff members',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  _buildRoleFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('Admin', UserRole.adminRoles),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('Teaching', UserRole.allTeachingRoles.toSet()),
                  const SizedBox(width: 8),
                  _buildRoleFilterChip('Non-Teaching', UserRole.allNonTeachingRoles.toSet()),
                ],
              ),
            ),
          
          // Staff list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStaff.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _filteredStaff.length,
                        itemBuilder: (context, index) {
                          final staff = _filteredStaff[index];
                          return _buildStaffCard(staff);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, Set<UserRole>? roles) {
    final isSelected = roles == null 
        ? _filteredStaff.length == _allStaff.length
        : _filteredStaff.every((staff) => roles.contains(staff.role));
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filteredStaff = roles == null 
                ? List.from(_allStaff)
                : _allStaff.where((staff) => roles.contains(staff.role)).toList();
          });
        } else {
          setState(() {
            _filteredStaff = List.from(_allStaff);
          });
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withAlpha(51),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _allStaff.isEmpty ? 'No staff members found' : 'No staff match your search',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _allStaff.isEmpty 
                ? 'Try enrolling staff members first'
                : 'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          if (_allStaff.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.person_add),
              label: const Text('Enroll Staff'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffCard(UserProfile staff) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          backgroundImage: staff.profilePictureUrl?.isNotEmpty == true
              ? CachedNetworkImageProvider(staff.profilePictureUrl ?? '')
              : null,
          child: staff.profilePictureUrl?.isEmpty != false
              ? Text(
                  staff.firstName?.isNotEmpty == true ? staff.firstName![0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          '${staff.firstName} ${staff.lastName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              staff.role.displayName,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (staff.email.isNotEmpty)
              Text(
                staff.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[600],
                ),
              ),
            if (staff.phoneNumber?.isNotEmpty == true)
              Text(staff.phoneNumber ?? ''),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StaffDetailScreen(staffProfile: staff),
            ),
          );
        },
      ),
    );
  }

  void _exportStaff() async {
    try {
      final csvData = await ExportService.exportStaffToExcel(_filteredStaff);
      
      // Save file
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Staff CSV',
        fileName: 'staff_${DateTime.now().millisecondsSinceEpoch}.csv',
        bytes: Uint8List.fromList(csvData.codeUnits),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _printStaff() async {
    try {
      final pdfData = await ExportService.exportStaffToPDF(_filteredStaff);
      
      // Save PDF
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Staff PDF',
        fileName: 'staff_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfData,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print-ready file generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print generation failed: $e')),
        );
      }
    }
  }
}


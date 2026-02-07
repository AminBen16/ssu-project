import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/salary_service.dart';
import 'package:test/widgets/future_handler.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/screens/salary_history_screen.dart';

/// A helper class to hold the combined data of staff and their payment status.
class _StaffPaymentData {
  final List<UserProfile> staffList;
  final Set<String> paidStaffIds;

  _StaffPaymentData({required this.staffList, required this.paidStaffIds});
}

class SalaryManagementScreen extends StatefulWidget {
  const SalaryManagementScreen({super.key});

  @override
  State<SalaryManagementScreen> createState() => _SalaryManagementScreenState();
}

class _SalaryManagementScreenState extends State<SalaryManagementScreen> {
  Future<_StaffPaymentData>? _dataFuture;
  final _salaryService = SalaryService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isBulkMode = false;
  final Set<String> _selectedStaffIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String staffId) {
    setState(() {
      if (_selectedStaffIds.contains(staffId)) {
        _selectedStaffIds.remove(staffId);
      } else {
        _selectedStaffIds.add(staffId);
      }
    });
  }

  void _loadData() {
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM').format(now);
    final currentYear = now.year.toString();

    // Use Future.wait to fetch both staff and their payment status concurrently.
    final combinedFuture = Future.wait([
      _salaryService.getSalariedStaff(schoolId),
      _salaryService.getPaidStaffIdsForMonth(
        schoolId: schoolId,
        month: currentMonth,
        year: int.parse(currentYear),
      ),
    ]).then((results) {
      final staffList = results[0] as List<UserProfile>;
      final paidStaffIds = results[1] as Set<String>;
      return _StaffPaymentData(
          staffList: staffList, paidStaffIds: paidStaffIds);
    });

    setState(() {
      _dataFuture = combinedFuture;
    });
  }

  void _showProcessPaymentDialog(UserProfile staff) {
    final now = DateTime.now();
    String selectedMonth = DateFormat('MMMM').format(now);
    String selectedYear = now.year.toString();
    final totalPay = (staff.salary ?? 0) + (staff.allowances ?? 0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Process Payment for ${staff.firstName}'),
          content: Text(
            'You are about to process a payment of ${NumberFormat.currency(symbol: 'UGX ').format(totalPay)} for $selectedMonth $selectedYear.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userData = Provider.of<UserDataProvider>(
                  context,
                  listen: false,
                );
                await _salaryService.recordSalaryPayment(
                  schoolId: userData.school!.id.toString(),
                  staffId: staff.uid,
                  amount: totalPay,
                  month: selectedMonth,
                  year: int.parse(selectedYear),
                  recordedById: userData.userProfile!.uid,
                  recordedByName:
                      '${userData.userProfile!.firstName} ${userData.userProfile!.lastName}'
                          .trim(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment processed successfully!'),
                    ),
                  );
                  // Refresh the data to show the new payment status
                  _loadData();
                }
              },
              child: const Text('Confirm & Process'),
            ),
          ],
        );
      },
    );
  }

  void _showBulkPaymentDialog(List<UserProfile> allStaff) {
    final now = DateTime.now();
    String selectedMonth = DateFormat('MMMM').format(now);
    int selectedYear = now.year;

    final paymentsToProcess = <Map<String, dynamic>>[];
    double totalAmount = 0.0;

    for (final staff in allStaff) {
      if (_selectedStaffIds.contains(staff.uid)) {
        final totalPay = (staff.salary ?? 0) + (staff.allowances ?? 0);
        if (totalPay > 0) {
          paymentsToProcess.add({'staffId': staff.uid, 'amount': totalPay});
          totalAmount += totalPay;
        }
      }
    }

    if (paymentsToProcess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff with a salary selected.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Bulk Payment'),
          content: Text(
            'You are about to pay ${paymentsToProcess.length} staff members a total of ${NumberFormat.currency(symbol: 'UGX ').format(totalAmount)} for $selectedMonth ${selectedYear.toString()}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userData =
                    Provider.of<UserDataProvider>(context, listen: false);
                await _salaryService.recordBulkSalaryPayments(
                  schoolId: userData.school!.id.toString(),
                  payments: paymentsToProcess,
                  month: selectedMonth,
                  year: selectedYear,
                  recordedById: userData.userProfile!.uid,
                  recordedByName:
                      '${userData.userProfile!.firstName} ${userData.userProfile!.lastName}'
                          .trim(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Bulk payment processed successfully!')),
                  );
                  // Exit bulk mode and refresh
                  setState(() {
                    _isBulkMode = false;
                    _selectedStaffIds.clear();
                  });
                  _loadData();
                }
              },
              child: const Text('Confirm & Process'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureHandler<_StaffPaymentData>(
      future: _dataFuture,
      loadingWidget: Scaffold(
        appBar: AppBar(title: const Text('Salary Management')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      errorBuilder: (context, error) => Scaffold(
        appBar: AppBar(title: const Text('Salary Management')),
        body: Center(child: Text('Error loading staff: $error')),
      ),
      emptyWidget: Scaffold(
        appBar: AppBar(title: const Text('Salary Management')),
        body: const Center(child: Text('No salaried staff found.')),
      ),
      builder: (context, data) {
        final staffList = data.staffList;
        final paidStaffIds = data.paidStaffIds;

        final filteredStaff = staffList.where((staff) {
          final query = _searchQuery.toLowerCase();
          return staff.fullName.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          appBar: _isBulkMode
              ? _buildBulkAppBar(staffList, paidStaffIds)
              : _buildNormalAppBar(),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: filteredStaff.isEmpty && staffList.isNotEmpty
                    ? Center(
                        child: Text('No staff found for "$_searchQuery"'),
                      )
                    : ListView.builder(
                        itemCount: filteredStaff.length,
                        itemBuilder: (context, index) {
                          final staff = filteredStaff[index];
                          final isPaid = paidStaffIds.contains(staff.uid);
                          final totalPay =
                              (staff.salary ?? 0) + (staff.allowances ?? 0);
                          final isSelected =
                              _selectedStaffIds.contains(staff.uid);

                          return Card(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: _isBulkMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: isPaid
                                          ? null
                                          : (value) =>
                                              _toggleSelection(staff.uid),
                                    )
                                  : CircleAvatar(
                                      backgroundImage:
                                          staff.profilePictureUrl != null
                                              ? CachedNetworkImageProvider(
                                                  staff.profilePictureUrl!)
                                              : null,
                                      child: staff.profilePictureUrl == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                              title: Text(staff.fullName),
                              subtitle: Text(staff.role.displayName),
                              trailing: _isBulkMode
                                  ? (isPaid
                                      ? _buildPaidChip()
                                      : Text(
                                          NumberFormat.currency(symbol: 'UGX ')
                                              .format(totalPay)))
                                  : (isPaid
                                      ? _buildPaidChip()
                                      : _buildActionsMenu(
                                          context, staff, totalPay)),
                              onTap: _isBulkMode
                                  ? (isPaid
                                      ? null
                                      : () => _toggleSelection(staff.uid))
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton:
              _isBulkMode ? _buildBulkPayFab(staffList) : null,
        );
      },
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('Salary Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.playlist_add_check),
          onPressed: () => setState(() => _isBulkMode = true),
          tooltip: 'Bulk Pay',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  AppBar _buildBulkAppBar(
      List<UserProfile> allStaff, Set<String> paidStaffIds) {
    final selectedCount = _selectedStaffIds.length;
    final selectableStaff = allStaff
        .where((s) =>
            !paidStaffIds.contains(s.uid) &&
            ((s.salary ?? 0) + (s.allowances ?? 0) > 0))
        .toList();
    final allSelected = selectableStaff.isNotEmpty &&
        _selectedStaffIds.length == selectableStaff.length;

    return AppBar(
      title: Text('$selectedCount Selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isBulkMode = false;
            _selectedStaffIds.clear();
          });
        },
      ),
      actions: [
        if (selectableStaff.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(() {
                if (allSelected) {
                  _selectedStaffIds.clear();
                } else {
                  _selectedStaffIds.addAll(selectableStaff.map((s) => s.uid));
                }
              });
            },
            child: Text(allSelected ? 'DESELECT ALL' : 'SELECT ALL'),
          )
      ],
    );
  }

  Widget _buildBulkPayFab(List<UserProfile> allStaff) {
    if (_selectedStaffIds.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => _showBulkPaymentDialog(allStaff),
      icon: const Icon(Icons.payments),
      label: const Text('Pay Selected'),
    );
  }

  Widget _buildPaidChip() {
    return const Chip(
      avatar: Icon(Icons.check, color: Colors.white),
      label: Text('Paid'),
      backgroundColor: Colors.green,
      labelStyle: TextStyle(color: Colors.white),
    );
  }

  Widget _buildActionsMenu(
      BuildContext context, UserProfile staff, double totalPay) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(symbol: 'UGX ').format(totalPay),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Total Pay', style: TextStyle(fontSize: 10)),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'pay') {
              _showProcessPaymentDialog(staff);
            } else if (value == 'history') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SalaryHistoryScreen(
                  staffId: staff.uid,
                  staffName: staff.fullName,
                ),
              ));
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (totalPay > 0)
              const PopupMenuItem<String>(
                value: 'pay',
                child: Text('Process Payment'),
              ),
            const PopupMenuItem<String>(
              value: 'history',
              child: Text('View History'),
            ),
          ],
        ),
      ],
    );
  }
}

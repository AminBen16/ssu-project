import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/services/parent_fee_service.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/widgets/future_handler.dart';

class FeeCollectionScreen extends StatefulWidget {
  const FeeCollectionScreen({super.key});

  @override
  State<FeeCollectionScreen> createState() => _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends State<FeeCollectionScreen> {
  Future<List<FeePaymentData>>? _feePaymentsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadFeePayments();
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

  void _loadFeePayments() {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final schoolId = userData.school?.id.toString();

    if (schoolId != null) {
      // For admin/bursar view, we need to get all payments across all parents
      // This is a simplified version - in reality, we'd need an admin endpoint
      setState(() {
        _feePaymentsFuture = Future.value([]); // Placeholder
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeePayments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by student name',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Filter: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        items: ['All', 'Completed', 'Pending', 'Failed']
                            .map((filter) => DropdownMenuItem(
                                  value: filter,
                                  child: Text(filter),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureHandler<List<FeePaymentData>>(
              future: _feePaymentsFuture,
              loadingWidget: const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading fee payments: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFeePayments,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              emptyWidget: const Center(
                child: Text('No fee payments found'),
              ),
              builder: (context, payments) {
                final filteredPayments = _filterPayments(payments);

                if (filteredPayments.isEmpty) {
                  return Center(
                    child: Text(
                        'No payments match the current filter: $_selectedFilter'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredPayments.length,
                  itemBuilder: (context, index) {
                    final payment = filteredPayments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(payment.status),
                          child: Icon(
                            _getStatusIcon(payment.status),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                            '${payment.studentName} - ${NumberFormat.currency(symbol: 'UGX ').format(payment.amount)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Method: ${payment.paymentMethod}'),
                            Text(
                              'Date: ${DateFormat.yMMMd().format(payment.paymentDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (payment.transactionId != null)
                              Text(
                                'Transaction: ${payment.transactionId}',
                                style: const TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                        trailing: payment.status == 'pending' ||
                                payment.status == 'processing'
                            ? const Chip(
                                label: Text('Processing'),
                                backgroundColor: Colors.orange,
                              )
                            : Chip(
                                label: Text(payment.status.toUpperCase()),
                                backgroundColor:
                                    _getStatusColor(payment.status),
                              ),
                        onTap: () => _showPaymentDetails(payment),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
    );
  }

  List<FeePaymentData> _filterPayments(List<FeePaymentData> payments) {
    return payments.where((payment) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          payment.studentName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Status filter
      final matchesFilter = _selectedFilter == 'All' ||
          payment.status.toLowerCase() == _selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  void _showPaymentDetails(FeePaymentData payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${payment.studentName} - Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Amount: ${NumberFormat.currency(symbol: 'UGX ').format(payment.amount)}'),
            Text('Payment Method: ${payment.paymentMethod}'),
            Text('Status: ${payment.status.toUpperCase()}'),
            Text('Date: ${DateFormat.yMMMd().format(payment.paymentDate)}'),
            if (payment.transactionId != null)
              Text('Transaction ID: ${payment.transactionId}'),
            if (payment.failureReason != null)
              Text('Failure Reason: ${payment.failureReason}',
                  style: const TextStyle(color: Colors.red)),
            Text('Created: ${DateFormat.yMMMd().format(payment.createdAt)}'),
            if (payment.isOfflinePayment)
              const Text('Offline Payment (Queued for sync)',
                  style: TextStyle(color: Colors.orange, fontSize: 12)),
          ],
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

  void _showAddPaymentDialog() {
    // Implementation for adding new fee payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add payment feature coming soon')),
    );
  }
}

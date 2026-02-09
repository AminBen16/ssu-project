import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/services/parent_fee_service.dart';
import 'package:test/services/salary_service.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/widgets/future_handler.dart';
import 'package:test/models/salary_model.dart';

/// Model for budget category
class BudgetCategory {
  final String name;
  final double allocatedAmount;
  final double spentAmount;
  final String description;

  BudgetCategory({
    required this.name,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.description,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get utilizationPercentage =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;
}

/// Screen for managing school budget.
/// Implements budget tracking and allocation using existing fees and staff_payments tables.
/// Uses offline-first architecture with local SQLite database.
class SchoolBudgetScreen extends StatefulWidget {
  const SchoolBudgetScreen({super.key});

  @override
  State<SchoolBudgetScreen> createState() => _SchoolBudgetScreenState();
}

class _SchoolBudgetScreenState extends State<SchoolBudgetScreen> {
  Future<Map<String, dynamic>>? _budgetDataFuture;
  String _selectedPeriod = 'This Year';

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  void _loadBudgetData() {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final schoolId = userData.school?.id.toString();
    final userId = userData.userProfile?.id.toString();

    if (schoolId != null && userId != null) {
      setState(() {
        _budgetDataFuture = _generateBudgetData(schoolId, userId);
      });
    }
  }

  Future<Map<String, dynamic>> _generateBudgetData(
      String schoolId, String userId) async {
    try {
      // Get projected income from fees table
      final feeSummary = await parentFeeService.getFeeSummary(
        userId,
        schoolId: schoolId,
      );

      // Get salary expenditures from staff_payments table
      final salaryPayments = await _getSalaryPaymentsForPeriod(schoolId);

      // Calculate total projected income (outstanding fees)
      final projectedIncome = feeSummary['totalOutstanding'] as double? ?? 0.0;

      // Calculate total expenditures (paid salaries)
      final totalExpenditures = salaryPayments.fold<double>(
          0.0, (sum, payment) => sum + payment.amountPaid);

      // Create budget categories based on existing data
      final budgetCategories =
          _createBudgetCategories(salaryPayments, projectedIncome);

      // Calculate totals
      final totalAllocated = budgetCategories.fold<double>(
          0.0, (sum, cat) => sum + cat.allocatedAmount);
      final totalSpent = budgetCategories.fold<double>(
          0.0, (sum, cat) => sum + cat.spentAmount);

      return {
        'projectedIncome': projectedIncome,
        'totalExpenditures': totalExpenditures,
        'budgetCategories': budgetCategories,
        'totalAllocated': totalAllocated,
        'totalSpent': totalSpent,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      // Fallback with basic structure
      return {
        'projectedIncome': 0.0,
        'totalExpenditures': 0.0,
        'budgetCategories': <BudgetCategory>[],
        'totalAllocated': 0.0,
        'totalSpent': 0.0,
        'error': e.toString(),
      };
    }
  }

  Future<List<SalaryPayment>> _getSalaryPaymentsForPeriod(
      String schoolId) async {
    try {
      final salariedStaff = await SalaryService().getSalariedStaff(schoolId);

      List<SalaryPayment> allPayments = [];
      for (final staff in salariedStaff) {
        try {
          final payments = await SalaryService().getStaffPaymentHistory(
            schoolId: schoolId,
            staffId: staff.id,
          );
          allPayments.addAll(payments);
        } catch (e) {
          continue;
        }
      }

      // Filter by selected period
      final now = DateTime.now();
      DateTime startDate;
      switch (_selectedPeriod) {
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'This Quarter':
          final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
          startDate = DateTime(now.year, quarterStart, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, 1, 1);
      }

      return allPayments
          .where((payment) =>
              payment.paymentDate.isAfter(startDate) &&
              payment.paymentDate.isBefore(now))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<BudgetCategory> _createBudgetCategories(
      List<SalaryPayment> salaryPayments, double projectedIncome) {
    // Calculate actual salary expenditures
    final salarySpent = salaryPayments.fold<double>(
        0.0, (sum, payment) => sum + payment.amountPaid);

    // Estimate allocations based on projected income
    // Salaries: 60% of projected income
    // Utilities: 10%
    // Supplies: 15%
    // Maintenance: 10%
    // Miscellaneous: 5%

    final salaryAllocation = projectedIncome * 0.6;
    final utilitiesAllocation = projectedIncome * 0.1;
    final suppliesAllocation = projectedIncome * 0.15;
    final maintenanceAllocation = projectedIncome * 0.1;
    final miscellaneousAllocation = projectedIncome * 0.05;

    return [
      BudgetCategory(
        name: 'Salaries',
        allocatedAmount: salaryAllocation,
        spentAmount: salarySpent,
        description: 'Staff salaries and wages',
      ),
      BudgetCategory(
        name: 'Utilities',
        allocatedAmount: utilitiesAllocation,
        spentAmount: 0.0, // No data available, assume 0
        description: 'Electricity, water, internet',
      ),
      BudgetCategory(
        name: 'Supplies',
        allocatedAmount: suppliesAllocation,
        spentAmount: 0.0, // No data available, assume 0
        description: 'Teaching materials, stationery',
      ),
      BudgetCategory(
        name: 'Maintenance',
        allocatedAmount: maintenanceAllocation,
        spentAmount: 0.0, // No data available, assume 0
        description: 'Building and equipment maintenance',
      ),
      BudgetCategory(
        name: 'Miscellaneous',
        allocatedAmount: miscellaneousAllocation,
        spentAmount: 0.0, // No data available, assume 0
        description: 'Other operational expenses',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Budget'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _loadBudgetData();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(
                  value: 'This Quarter', child: Text('This Quarter')),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudgetData,
            tooltip: 'Refresh Budget Data',
          ),
        ],
      ),
      body: FutureHandler<Map<String, dynamic>>(
        future: _budgetDataFuture,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading budget data: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBudgetData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        builder: (context, data) => _buildBudgetOverview(data),
      ),
    );
  }

  Widget _buildBudgetOverview(Map<String, dynamic> data) {
    final projectedIncome = data['projectedIncome'] as double? ?? 0.0;
    final totalExpenditures = data['totalExpenditures'] as double? ?? 0.0;
    final budgetCategories =
        data['budgetCategories'] as List<BudgetCategory>? ?? [];
    final totalAllocated = data['totalAllocated'] as double? ?? 0.0;
    final totalSpent = data['totalSpent'] as double? ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Projected Income',
                  NumberFormat.currency(symbol: 'UGX ').format(projectedIncome),
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Spent',
                  NumberFormat.currency(symbol: 'UGX ').format(totalSpent),
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Budget Utilization',
            '${totalAllocated > 0 ? (totalSpent / totalAllocated * 100).toStringAsFixed(1) : '0.0'}%',
            totalAllocated > 0 && totalSpent <= totalAllocated
                ? Colors.blue
                : Colors.orange,
            totalAllocated > 0 && totalSpent <= totalAllocated
                ? Icons.check_circle
                : Icons.warning,
            fullWidth: true,
          ),

          const SizedBox(height: 24),
          const Text(
            'Budget Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...budgetCategories
              .map((category) => _buildBudgetCategoryCard(category)),

          const SizedBox(height: 24),
          const Text(
            'Budget Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                      'Total Allocated',
                      NumberFormat.currency(symbol: 'UGX ')
                          .format(totalAllocated)),
                  _buildDetailRow('Total Spent',
                      NumberFormat.currency(symbol: 'UGX ').format(totalSpent)),
                  _buildDetailRow(
                      'Remaining Budget',
                      NumberFormat.currency(symbol: 'UGX ')
                          .format(totalAllocated - totalSpent)),
                  _buildDetailRow(
                      'Projected vs Allocated',
                      NumberFormat.currency(symbol: 'UGX ')
                          .format(projectedIncome - totalAllocated)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Last updated: ${DateFormat.yMMMd().add_jm().format(data['lastUpdated'] as DateTime? ?? DateTime.now())}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCategoryCard(BudgetCategory category) {
    final utilizationColor = category.utilizationPercentage > 90
        ? Colors.red
        : category.utilizationPercentage > 75
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${category.utilizationPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: utilizationColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              category.description,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: category.allocatedAmount > 0
                  ? category.spentAmount / category.allocatedAmount
                  : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(utilizationColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allocated: ${NumberFormat.currency(symbol: 'UGX ').format(category.allocatedAmount)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Spent: ${NumberFormat.currency(symbol: 'UGX ').format(category.spentAmount)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Remaining: ${NumberFormat.currency(symbol: 'UGX ').format(category.remainingAmount)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon,
      {bool fullWidth = false}) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

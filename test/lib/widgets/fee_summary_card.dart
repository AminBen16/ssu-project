import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_data_provider.dart';
import '../services/fee_service.dart';

class FeeSummaryCard extends StatefulWidget {
  const FeeSummaryCard({super.key});

  @override
  State<FeeSummaryCard> createState() => _FeeSummaryCardState();
}

class _FeeSummaryCardState extends State<FeeSummaryCard> {
  bool _isLoading = true;
  double _totalExpected = 0;
  double _totalCollected = 0;
  double _outstanding = 0;

  @override
  void initState() {
    super.initState();
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    if (!mounted) return;

    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final school = userData.school;

    if (school == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Ensure ID is a string to avoid argument_type_not_assignable errors
      final schoolId = school.id.toString();
      final feeService = FeeService();

      // Simulate data loading or call service if available
      // In a real implementation:
      final summary = await feeService.getSchoolFeeSummary(schoolId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _totalExpected = summary['totalExpected'] ?? 0.0;
          _totalCollected = summary['totalCollected'] ?? 0.0;
          _outstanding = (_totalExpected - _totalCollected).abs();
        });
      }
    } catch (e) {
      debugPrint('Error loading fee data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  _buildSummaryRow(
                      'Expected Collection', _totalExpected, Colors.blue),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      'Actual Collection', _totalCollected, Colors.green),
                  const Divider(height: 24),
                  _buildSummaryRow('Outstanding', _outstanding, Colors.red,
                      isBold: true),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color,
      {bool isBold = false}) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

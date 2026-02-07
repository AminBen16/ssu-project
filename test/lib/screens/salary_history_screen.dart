import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/models/salary_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/salary_service.dart';
import 'package:test/screens/salary_pdf_preview_screen.dart';

class SalaryHistoryScreen extends StatefulWidget {
  final String? staffId;
  final String? staffName;

  const SalaryHistoryScreen({super.key, this.staffId, this.staffName});

  @override
  State<SalaryHistoryScreen> createState() => _SalaryHistoryScreenState();
}

class _SalaryHistoryScreenState extends State<SalaryHistoryScreen> {
  String? _selectedYear;
  final _salaryService = SalaryService();

  @override
  void initState() {
    super.initState();
    // Default to the current year when the screen loads.
    _selectedYear = DateTime.now().year.toString();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile =
        Provider.of<UserDataProvider>(context, listen: false).userProfile;
    final schoolId =
        Provider.of<UserDataProvider>(context, listen: false).school?.id.toString();

    // Guard clause: If we don't have the necessary data, don't try to build the screen.
    if (userProfile == null || schoolId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Salary History')),
        body: const Center(child: Text('User or school data not available.')),
      );
    }

    // Generate a list of the last 5 years for the dropdown.
    final List<String> years =
        List.generate(5, (index) => (DateTime.now().year - index).toString());

    final targetStaffId = widget.staffId ?? userProfile.uid;
    final targetStaffName = widget.staffName ??
        '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();

    // Use a FutureBuilder to have access to the data for the export button.
    return FutureBuilder<List<SalaryPayment>>(
      future: _salaryService.getStaffPaymentHistory(
        schoolId: schoolId,
        staffId: targetStaffId,
        year: _selectedYear,
      ),
      builder: (context, snapshot) {
        final payments = snapshot.hasData
            // The future now directly returns a list of SalaryPayment objects.
            // The service handles the JSON parsing.
            ? snapshot.data!
            : <SalaryPayment>[];

        final bool hasPayments = payments.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Salary History'),
            actions: [
              if (hasPayments)
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export as PDF',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SalaryPdfPreviewScreen(
                          payments: payments,
                          staffName: targetStaffName,
                          year: _selectedYear!,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedYear,
                  hint: const Text('Filter by Year'),
                  onChanged: (year) => setState(() => _selectedYear = year),
                  items: years
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: _buildBody(context, snapshot),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper to build the body content based on the stream's state.
  Widget _buildBody(
      BuildContext context, AsyncSnapshot<List<SalaryPayment>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Text('No salary payments recorded for $_selectedYear.'),
      );
    }

    final payments = snapshot.data!;

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.teal),
            title: Text(
              NumberFormat.currency(
                symbol: 'UGX ',
              ).format(payment.amountPaid),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                Text('Paid for ${payment.month}, ${payment.year.toString()}'),
            trailing: Text(
              DateFormat.yMMMd().format(payment.paymentDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}

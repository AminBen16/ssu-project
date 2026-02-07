import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test/models/fee_payment_model.dart';
import 'package:test/services/fee_service.dart';
import 'package:test/widgets/future_handler.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const PaymentHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final feeService = FeeService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History for $studentName'),
      ),
      body: FutureHandler<List<FeePayment>>(
        future: feeService.getStudentFeeHistory(studentId),
        emptyMessage: 'No payment history found for this student.',
        builder: (context, payments) {
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Icon(
                      Icons.check,
                      color: Colors.green.shade800,
                    ),
                  ),
                  title: Text(
                    NumberFormat.currency(symbol: 'UGX ').format(
                      payment.amountPaid,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(payment.description),
                  trailing: Text(
                    DateFormat.yMMMd().format(payment.paymentDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

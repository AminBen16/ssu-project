import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/payment_gateway_service.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:url_launcher/url_launcher.dart';

class MakePaymentScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final double balance;

  const MakePaymentScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.balance,
  });

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentGatewayService = PaymentGatewayService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the amount with the outstanding balance if it's positive
    if (widget.balance > 0) {
      _amountController.text = widget.balance.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Get context-dependent data BEFORE the async gap.
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Call your backend to get a payment link from the gateway.
      final paymentLink = await _paymentGatewayService.initializeTransaction(
        amount: amount,
        email: userData.userProfile!.email,
        studentId: widget.studentId,
        studentName: widget.studentName,
        schoolId: userData.school!.id.toString(),
      );

      // 2. Launch the payment gateway's URL for the user to complete payment.
      final uri = Uri.parse(paymentLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        messenger.showSnackBar(
          const SnackBar(
              content: Text(
                  'Redirecting to payment provider. Your balance will update upon confirmation.')),
        );
        if (mounted) Navigator.of(context).pop();
      } else {
        throw Exception('Could not launch payment URL.');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not initiate payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay Fees for ${widget.studentName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outstanding Balance: ${NumberFormat.currency(symbol: 'UGX ').format(widget.balance)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: widget.balance > 0 ? Colors.red : Colors.green,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount to Pay',
                  border: OutlineInputBorder(),
                  prefixText: 'UGX ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter an amount.';
                  }
                  if (double.tryParse(v) == null) {
                    return 'Please enter a valid number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _processPayment,
                text: 'Pay Now',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

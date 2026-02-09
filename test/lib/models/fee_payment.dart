class FeePayment {
  final double amount;
  final DateTime? paymentDate;
  final String paymentMethod;

  FeePayment({
    required this.amount,
    this.paymentDate,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
  }
}

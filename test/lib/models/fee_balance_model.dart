class FeeBalance {
  final double totalFeesDue;
  final double totalAmountPaid;
  final double balance;
  final DateTime? lastPaymentDate;

  FeeBalance({
    required this.totalFeesDue,
    required this.totalAmountPaid,
    required this.balance,
    this.lastPaymentDate,
  });

  /// Creates a FeeBalance instance from a map (typically from JSON).
  factory FeeBalance.fromMap(Map<String, dynamic> map) {
    return FeeBalance(
      totalFeesDue: (map['totalFeesDue'] as num?)?.toDouble() ?? 0.0,
      totalAmountPaid: (map['totalAmountPaid'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.parse(map['lastPaymentDate'] as String)
          : null,
    );
  }
}

/// Represents a single salary payment made to a staff member.
class SalaryPayment {
  final String id;
  final double amountPaid;
  final DateTime paymentDate;
  final String month;
  final int year;
  final String recordedById;
  final String recordedByName;

  SalaryPayment({
    required this.id,
    required this.amountPaid,
    required this.paymentDate,
    required this.month,
    required this.year,
    required this.recordedById,
    required this.recordedByName,
  });

  factory SalaryPayment.fromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: map['id'].toString(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      month: map['month'] as String,
      year: map['year'] as int,
      recordedById: map['recorded_by_id'] as String,
      recordedByName: map['recorded_by_name'] as String,
    );
  }
}

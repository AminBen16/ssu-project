class FeePayment {
  final String id;
  final String? studentId; // Added studentId for filtering
  final double amountPaid;
  final DateTime paymentDate;
  final String status;
  final String description;

  FeePayment({
    required this.id,
    this.studentId, // Made studentId optional for now
    required this.amountPaid,
    required this.paymentDate,
    required this.status,
    required this.description,
  });

  factory FeePayment.fromMap(Map<String, dynamic> map) {
    return FeePayment(
      id: map['id'].toString(),
      studentId: map['student_id']?.toString(), // Parse student_id
      amountPaid: (map['amount_paid'] as num? ?? 0.0).toDouble(),
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'])
          : DateTime.now(),
      status: map['status'] as String? ?? 'Unknown',
      description: map['description'] as String? ?? 'N/A',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId, // Include student_id
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'status': status,
      'description': description,
    };
  }
}

/// Represents a single fee structure item in the school's financial setup.
class FeeStructure {
  final String id;
  final String name;
  final double amount;
  final String description;
  final List<String>? applicableClasses;
  final DateTime createdAt;

  FeeStructure({
    required this.id,
    required this.name,
    required this.amount,
    required this.description,
    this.applicableClasses,
    required this.createdAt,
  });

  /// Creates a [FeeStructure] instance from a map (typically from an API response).
  factory FeeStructure.fromMap(Map<String, dynamic> json) {
    return FeeStructure(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      applicableClasses:
          (json['applicable_classes'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts a [FeeStructure] instance to a JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'description': description,
      // Use snake_case to match backend expectations
      'applicable_classes': applicableClasses,
      // Convert DateTime to ISO 8601 string format for JSON serialization
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Subscription {
  final String plan;
  final String status;
  final DateTime? trialEnds;

  Subscription({
    required this.plan,
    required this.status,
    this.trialEnds,
  });

  /// Creates a Subscription object from a map (typically from API response).
  /// Provides default values to prevent null errors.
  factory Subscription.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      // Return a default 'trial' subscription if none exists.
      return Subscription(plan: 'trial', status: 'active');
    }
    return Subscription(
      plan: data['plan'] ?? 'trial',
      status: data['status'] ?? 'active',
      trialEnds: data['trialEnds'] != null ? DateTime.parse(data['trialEnds'] as String) : null,
    );
  }
}

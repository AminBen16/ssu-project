/// Represents the nested subscription data within a School document.
class Subscription {
  final String plan;
  final String? status;
  final DateTime? trialEnds;

  Subscription({
    required this.plan,
    this.status,
    this.trialEnds,
  });

  /// Creates a Subscription object from a map (typically from API response).
  /// Provides default values to prevent null errors.
  factory Subscription.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      // Return a default 'trial' subscription if none exists.
      return Subscription(plan: 'trial');
    }
    return Subscription(
      plan: data['plan'] ?? 'trial',
      status: data['status'],
      trialEnds: data['trialEnds'] != null ? DateTime.parse(data['trialEnds'] as String) : null,
    );
  }
}

/// Represents a school's data model, mirroring the structure in API response.
class School {
  final String id;
  final String? name;
  final String? address;
  final String? contact;
  final String? logoUrl;
  final String? motto;
  final String? country;
  final String? mission;
  final String? vision;
  final String? anthem;
  final String? uniformDetails;
  final String? website;
  final DateTime? nextTermBeginsOn;
  final int? paidStampColor;
  final Subscription subscription;

  School({
    required this.id,
    this.name,
    this.address,
    this.contact,
    this.logoUrl,
    this.motto,
    this.country,
    this.mission,
    this.vision,
    this.anthem,
    this.uniformDetails,
    this.website,
    this.nextTermBeginsOn,
    this.paidStampColor,
    required this.subscription,
  });

  /// Creates a School object from an API response map.
  factory School.fromMap(Map<String, dynamic> data) {
    return School(
      id: data['id'] as String,
      name: data['name'],
      address: data['address'],
      contact: data['contact'],
      logoUrl: data['logoUrl'],
      motto: data['motto'],
      country: data['country'],
      mission: data['mission'],
      vision: data['vision'],
      anthem: data['anthem'],
      uniformDetails: data['uniformDetails'],
      website: data['website'],
      nextTermBeginsOn: data['nextTermBeginsOn'] != null ? DateTime.parse(data['nextTermBeginsOn'] as String) : null,
      paidStampColor: data['paidStampColor'],
      subscription: Subscription.fromMap(data['subscription']),
    );
  }
}

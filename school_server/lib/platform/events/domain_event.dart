/// Immutable fact that something meaningful happened in the school domain.
///
/// Domain events are the foundation of SSU's AI-native architecture. Business
/// services publish events after successful state changes; downstream handlers
/// can then react without coupling the producer to every consumer.
class DomainEvent {
  DomainEvent({
    required this.id,
    required this.type,
    required this.aggregateId,
    required this.occurredAt,
    required this.payload,
    this.tenantId,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String type;
  final String aggregateId;
  final DateTime occurredAt;
  final String? tenantId;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'aggregateId': aggregateId,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (tenantId != null) 'tenantId': tenantId,
        'payload': Map<String, dynamic>.unmodifiable(payload),
        'metadata': Map<String, dynamic>.unmodifiable(metadata),
      };

  @override
  String toString() => 'DomainEvent(type: $type, id: $id, aggregateId: $aggregateId)';
}

import 'domain_event.dart';

/// Handles one or more domain events.
abstract interface class EventHandler {
  /// Event types this handler is interested in.
  Set<String> get eventTypes;

  /// Process an event.
  Future<void> handle(DomainEvent event);
}

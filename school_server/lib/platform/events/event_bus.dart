import 'dart:async';

import 'domain_event.dart';
import 'event_handler.dart';

/// Lightweight in-process event bus for the first AI-native foundation.
///
/// The bus deliberately has no knowledge of school domains. Domain services
/// publish facts; handlers subscribe to facts. This keeps future agents,
/// workflows, notifications, and analytics decoupled from the originating
/// service.
class EventBus {
  final Map<String, List<EventHandler>> _handlers =
      <String, List<EventHandler>>{};
  final StreamController<DomainEvent> _events =
      StreamController<DomainEvent>.broadcast();

  Stream<DomainEvent> get events => _events.stream;

  void register(EventHandler handler) {
    for (final eventType in handler.eventTypes) {
      final handlers = _handlers.putIfAbsent(eventType, () => <EventHandler>[]);
      if (!handlers.contains(handler)) {
        handlers.add(handler);
      }
    }
  }

  void unregister(EventHandler handler) {
    for (final eventType in handler.eventTypes) {
      final handlers = _handlers[eventType];
      handlers?.remove(handler);
      if (handlers != null && handlers.isEmpty) {
        _handlers.remove(eventType);
      }
    }
  }

  /// Publishes an event after the producer has successfully committed its
  /// state change.
  ///
  /// Each registered handler is isolated: one handler failing does not stop
  /// other handlers from receiving the same event. Errors are returned so the
  /// caller can later connect retry/dead-letter infrastructure without
  /// changing the event contract.
  Future<List<Object>> publish(DomainEvent event) async {
    _events.add(event);
    final handlers = List<EventHandler>.unmodifiable(
      _handlers[event.type] ?? const <EventHandler>[],
    );

    final errors = <Object>[];
    for (final handler in handlers) {
      try {
        await handler.handle(event);
      } catch (error) {
        errors.add(error);
      }
    }
    return errors;
  }

  Future<void> dispose() async {
    await _events.close();
    _handlers.clear();
  }
}

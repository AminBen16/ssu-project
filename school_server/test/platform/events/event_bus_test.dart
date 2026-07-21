import 'package:test/test.dart';

import '../../../lib/platform/events/events.dart';

class _RecordingHandler implements EventHandler {
  _RecordingHandler(this.type);

  final String type;
  final List<DomainEvent> received = <DomainEvent>[];

  @override
  Set<String> get eventTypes => <String>{type};

  @override
  Future<void> handle(DomainEvent event) async {
    received.add(event);
  }
}

void main() {
  group('EventBus', () {
    test('routes an event only to handlers registered for its type', () async {
      final bus = EventBus();
      final attendance = _RecordingHandler('attendance.recorded');
      final fees = _RecordingHandler('fee.payment.received');
      bus.register(attendance);
      bus.register(fees);

      final event = DomainEvent(
        id: 'evt-1',
        type: 'attendance.recorded',
        aggregateId: 'student-1',
        occurredAt: DateTime.utc(2026, 7, 21),
        payload: <String, dynamic>{'present': false},
      );

      final errors = await bus.publish(event);

      expect(errors, isEmpty);
      expect(attendance.received, hasLength(1));
      expect(attendance.received.single.id, 'evt-1');
      expect(fees.received, isEmpty);
      await bus.dispose();
    });

    test('isolates handler failures from other handlers', () async {
      final bus = EventBus();
      final successful = _RecordingHandler('student.enrolled');
      final failing = _FailingHandler('student.enrolled');
      bus.register(failing);
      bus.register(successful);

      final errors = await bus.publish(
        DomainEvent(
          id: 'evt-2',
          type: 'student.enrolled',
          aggregateId: 'student-2',
          occurredAt: DateTime.utc(2026, 7, 21),
          payload: const <String, dynamic>{},
        ),
      );

      expect(errors, hasLength(1));
      expect(successful.received, hasLength(1));
      await bus.dispose();
    });
  });
}

class _FailingHandler implements EventHandler {
  _FailingHandler(this.type);

  final String type;

  @override
  Set<String> get eventTypes => <String>{type};

  @override
  Future<void> handle(DomainEvent event) async {
    throw StateError('handler failure');
  }
}

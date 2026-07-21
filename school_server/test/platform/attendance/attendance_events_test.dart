import 'package:test/test.dart';

import '../../../lib/platform/attendance/attendance_events.dart';
import '../../../lib/platform/events/events.dart';
import '../../../lib/platform/runtime/runtime.dart';

void main() {
  test('platform runtime owns the event bus and attendance publishes a domain event', () async {
    final runtime = PlatformRuntime.instance;
    await runtime.initialize();

    final received = <DomainEvent>[];
    final subscription = runtime.eventBus.events.listen(received.add);
    final publisher = AttendanceEventPublisher(runtime.eventBus);

    final errors = await publisher.publishRecorded(
      attendanceId: 'att-1',
      studentId: 'student-1',
      schoolId: 'school-1',
      date: DateTime.utc(2026, 7, 21),
      present: false,
      recordedBy: 'teacher-1',
      reason: 'Absent',
    );

    expect(errors, isEmpty);
    expect(received, hasLength(1));
    expect(received.single.type, attendanceRecordedEventType);
    expect(received.single.aggregateId, 'student-1');
    expect(received.single.tenantId, 'school-1');
    expect(received.single.payload['present'], isFalse);

    await subscription.cancel();
    await runtime.dispose();
  });
}

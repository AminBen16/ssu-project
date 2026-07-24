import '../events/events.dart';

/// Canonical event type emitted after an attendance record has been
/// successfully persisted by the attendance domain.
const attendanceRecordedEventType = 'attendance.recorded';

/// Publishes attendance facts into the AI-native event fabric.
///
/// The attendance persistence operation remains owned by the attendance
/// domain. This publisher is deliberately small so it can be called immediately
/// after a successful commit without coupling attendance to future agents.
class AttendanceEventPublisher {
  AttendanceEventPublisher(this.eventBus);

  final EventBus eventBus;

  Future<List<Object>> publishRecorded({
    required String attendanceId,
    required String studentId,
    required String schoolId,
    required DateTime date,
    required bool present,
    String? recordedBy,
    String? reason,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return eventBus.publish(
      DomainEvent(
        id: 'attendance-recorded-$attendanceId',
        type: attendanceRecordedEventType,
        aggregateId: studentId,
        tenantId: schoolId,
        occurredAt: DateTime.now().toUtc(),
        payload: <String, dynamic>{
          'attendanceId': attendanceId,
          'studentId': studentId,
          'schoolId': schoolId,
          'date': date.toUtc().toIso8601String(),
          'present': present,
          if (recordedBy != null) 'recordedBy': recordedBy,
          if (reason != null) 'reason': reason,
        },
        metadata: metadata,
      ),
    );
  }
}

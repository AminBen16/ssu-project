/// Constants for timetable generation
class TimetableConstants {
  /// Days of the week for scheduling
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  /// Time slot definitions
  static const List<TimeSlot> timeSlots = [
    TimeSlot(id: 'P1', name: 'Period 1', startTime: '08:00', endTime: '09:00'),
    TimeSlot(id: 'P2', name: 'Period 2', startTime: '09:00', endTime: '10:00'),
    TimeSlot(id: 'P3', name: 'Period 3', startTime: '10:00', endTime: '11:00'),
    TimeSlot(id: 'BREAK1', name: 'Break', startTime: '11:00', endTime: '11:30'),
    TimeSlot(id: 'P4', name: 'Period 4', startTime: '11:30', endTime: '12:30'),
    TimeSlot(id: 'P5', name: 'Period 5', startTime: '12:30', endTime: '13:30'),
    TimeSlot(id: 'LUNCH', name: 'Lunch', startTime: '13:30', endTime: '14:00'),
    TimeSlot(id: 'P6', name: 'Period 6', startTime: '14:00', endTime: '15:00'),
    TimeSlot(id: 'P7', name: 'Period 7', startTime: '15:00', endTime: '16:00'),
    TimeSlot(id: 'P8', name: 'Period 8', startTime: '16:00', endTime: '17:00'),
  ];

  /// Maximum periods per day
  static const int maxPeriodsPerDay = 8;

  /// Maximum consecutive periods allowed
  static const int maxConsecutivePeriods = 3;
}

/// Represents a time slot in the timetable
class TimeSlot {
  final String id;
  final String name;
  final String startTime;
  final String endTime;

  const TimeSlot({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'] as String,
      name: map['name'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
    );
  }
}

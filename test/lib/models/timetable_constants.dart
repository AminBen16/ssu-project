import 'package:test/models/timetable_model.dart';

class TimetableConstants {
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static final List<TimeSlot> timeSlots = [
    TimeSlot(id: 'P1', displayTime: '08:00 - 08:40'),
    TimeSlot(id: 'P2', displayTime: '08:40 - 09:20'),
    TimeSlot(id: 'P3', displayTime: '09:20 - 10:00'),
    TimeSlot(id: 'BREAK1', displayTime: '10:00 - 10:20'),
    TimeSlot(id: 'P4', displayTime: '10:20 - 11:00'),
    TimeSlot(id: 'P5', displayTime: '11:00 - 11:40'),
    TimeSlot(id: 'P6', displayTime: '11:40 - 12:20'),
    TimeSlot(id: 'LUNCH', displayTime: '12:20 - 13:20'),
    TimeSlot(id: 'P7', displayTime: '13:20 - 14:00'),
    TimeSlot(id: 'P8', displayTime: '14:00 - 14:40'),
  ];
}

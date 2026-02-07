import 'package:test/models/timetable_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class TimetableService {
  final ApiClient _apiClient;
  final OfflineService _offlineService;
  final LocalDatabaseService _localDb;

  TimetableService({
    ApiClient? apiClient,
    OfflineService? offlineService,
    LocalDatabaseService? localDb,
  })  : _apiClient = apiClient ?? ApiClient(),
        _offlineService = offlineService ?? OfflineService(),
        _localDb = localDb ?? localDatabaseService;

  /// Saves or updates a specific lesson in the timetable.
  Future<void> setLesson({
    required String schoolId,
    required String className,
    required String day,
    required String timeSlotId,
    required ScheduledLesson lesson,
  }) async {
    final lessonData = lesson.toMap();
    lessonData['schoolId'] = schoolId;
    lessonData['className'] = className;
    lessonData['day'] = day;
    lessonData['slotId'] = timeSlotId;

    await _apiClient.post('/timetable/lesson', body: lessonData);
  }

  /// Saves a full timetable for a class, overwriting any existing data for that class.
  Future<void> saveFullTimetable({
    required String schoolId,
    required String className,
    required Map<String, Map<String, ScheduledLesson>> timetable,
  }) async {
    final lessons = <Map<String, dynamic>>[];

    timetable.forEach((day, dayLessons) {
      dayLessons.forEach((slotId, lesson) {
        final lessonData = lesson.toMap();
        lessonData['day'] = day;
        lessonData['slotId'] = slotId;
        lessons.add(lessonData);
      });
    });

    await _apiClient.post('/timetable/class/$schoolId/$className',
        body: {'lessons': lessons});
  }

  /// Fetches the entire timetable for a given class with offline support.
  Future<Map<String, Map<String, ScheduledLesson>>> getClassTimetable({
    required String schoolId,
    required String className,
  }) async {
    final cacheKey = 'timetable_class_${schoolId}_$className';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/timetable/class/$schoolId/$className');
        final lessons = response as List<dynamic>;

        final Map<String, Map<String, ScheduledLesson>> timetable = {};

        for (final lessonData in lessons) {
          final data = lessonData as Map<String, dynamic>;
          final day = data['day'] as String;
          final slotId = data['slotId'] as String;
          final lesson = ScheduledLesson.fromMap(data);

          timetable.putIfAbsent(day, () => {});
          timetable[day]![slotId] = lesson;
        }

        return timetable;
      },
      offlineFallback: () async {
        // Try to get cached timetable
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final Map<String, dynamic> data = cached as Map<String, dynamic>;
          final Map<String, Map<String, ScheduledLesson>> timetable = {};

          data.forEach((day, dayLessons) {
            if (dayLessons is Map) {
              timetable[day] = {};
              dayLessons.forEach((slotId, lessonData) {
                if (lessonData is Map<String, dynamic>) {
                  timetable[day]![slotId] = ScheduledLesson.fromMap(lessonData);
                }
              });
            }
          });

          return timetable;
        }
        return {};
      },
      cacheKey: cacheKey,
    );
  }

  /// Removes a lesson from the timetable.
  Future<void> removeLesson({
    required String schoolId,
    required String className,
    required String day,
    required String timeSlotId,
  }) async {
    await _apiClient
        .delete('/timetable/lesson/$schoolId/$className/$day/$timeSlotId');
  }

  /// Fetches all lessons assigned to a specific teacher across all classes.
  Future<Map<String, Map<String, ScheduledLesson>>> getTeacherTimetable({
    required String schoolId,
    required String teacherId,
  }) async {
    final response =
        await _apiClient.get('/timetable/teacher/$schoolId/$teacherId');
    final lessons = response as List<dynamic>;

    final teacherTimetable = <String, Map<String, ScheduledLesson>>{};

    for (final lessonData in lessons) {
      final data = lessonData as Map<String, dynamic>;
      final day = data['day'] as String;
      final slotId = data['slotId'] as String;
      final lesson = ScheduledLesson.fromMap(data);

      teacherTimetable.putIfAbsent(day, () => {});
      teacherTimetable[day]![slotId] = lesson;
    }

    return teacherTimetable;
  }
}

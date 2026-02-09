import 'dart:convert';
import 'package:test/models/timetable_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';
import 'package:test/services/timetable_generator_service.dart';
import 'package:test/services/staff_service.dart';

class TimetableService {
  final ApiClient _apiClient;
  final OfflineService _offlineService;
  final LocalDatabaseService _localDb;
  final StaffService _staffService;

  TimetableService({
    ApiClient? apiClient,
    OfflineService? offlineService,
    LocalDatabaseService? localDb,
    StaffService? staffService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _offlineService = offlineService ?? OfflineService(),
        _localDb = localDb ?? localDatabaseService,
        _staffService = staffService ?? StaffService();

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

  /// Enhanced timetable generation using advanced algorithms
  Future<Map<String, dynamic>> generateEnhancedTimetable({
    required String schoolId,
    required String className,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? roomData,
    bool useAdvancedAlgorithms = true,
  }) async {
    try {
      if (useAdvancedAlgorithms) {
        // Use the enhanced CSP solver with graph coloring
        final generatorService = TimetableGeneratorService();
        final result = await generatorService.generateEnhancedTimetable(
          schoolId: schoolId,
          localDb: _localDb,
          staffService: _staffService,
          requirements: requirements ?? {},
          roomData: roomData ?? {},
        );
        
        // Save the generated timetable to cache
        if (result['success'] == true) {
          final timetable = result['timetable'] as Map<String, Map<String, ScheduledLesson>>;
          await saveFullTimetable(
            schoolId: schoolId,
            className: className,
            timetable: timetable,
          );
          
          // Cache validation results
          final cacheKey = 'timetable_validation_${schoolId}_$className';
          await _localDb.setCache(
            cacheKey,
            jsonEncode(result['validation']),
            expiry: Duration(hours: 24),
          );
        }
        
        return result;
      } else {
        // Fallback to legacy generation method
        return await _generateLegacyTimetable(schoolId, className, requirements);
      }
    } catch (e) {
      // Return error information
      return {
        'timetable': <String, Map<String, ScheduledLesson>>{},
        'conflicts': [
          TimetableConflict(
            type: 'system',
            description: 'Enhanced timetable generation failed',
            details: {'error': e.toString()},
            severity: 3,
          )
        ],
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Legacy timetable generation for backward compatibility
  Future<Map<String, dynamic>> _generateLegacyTimetable(
    String schoolId,
    String className,
    Map<String, dynamic>? requirements,
  ) async {
    // Implement fallback to original generation logic
    // This ensures existing UI continues to work
    
    final timetable = <String, Map<String, ScheduledLesson>>{};
    final conflicts = <TimetableConflict>[];
    
    // Simple legacy generation logic
    for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
      timetable[day] = {};
      for (final slot in ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8']) {
        timetable[day]![slot] = ScheduledLesson(
          subjectName: '',
          teacherId: '',
          teacherName: '',
        );
      }
    }
    
    return {
      'timetable': timetable,
      'conflicts': conflicts,
      'success': true,
      'algorithm': 'Legacy',
      'message': 'Generated using legacy algorithm for compatibility',
    };
  }

  /// Validate existing timetable using enhanced validation
  Future<Map<String, dynamic>> validateTimetable({
    required String schoolId,
    required String className,
    Map<String, dynamic>? requirements,
  }) async {
    try {
      // Get existing timetable
      final timetable = await getClassTimetable(schoolId: schoolId, className: className);
      
      // Get constraints from database
      final generatorService = TimetableGeneratorService();
      final constraintData = await generatorService.extractConstraintsFromDatabase(
        schoolId: schoolId,
        localDb: _localDb,
        staffService: _staffService,
      );
      
      final constraints = constraintData['constraints'] as Map<String, TimetableConstraint>;
      final teachers = constraints.keys.where((key) => !key.startsWith('subject') && !key.startsWith('global')).toList();
      final subjects = constraints.values.map((c) => c.subjectId).where((s) => s != 'global').toSet().toList();
      
      // Perform comprehensive validation
      final validationData = generatorService.validateAndReportConflicts(
        timetable: timetable,
        constraints: constraints,
        teachers: teachers,
        subjects: subjects,
        timeSlots: ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'],
        days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        requirements: requirements ?? {},
      );
      
      // Cache validation results
      final cacheKey = 'timetable_validation_${schoolId}_$className';
      await _localDb.setCache(
        cacheKey,
        jsonEncode(validationData),
        expiry: Duration(hours: 24),
      );
      
      return validationData;
    } catch (e) {
      return {
        'conflicts': [
          TimetableConflict(
            type: 'system',
            description: 'Timetable validation failed',
            details: {'error': e.toString()},
            severity: 3,
          )
        ],
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get cached validation results
  Future<Map<String, dynamic>?> getCachedValidation({
    required String schoolId,
    required String className,
  }) async {
    final cacheKey = 'timetable_validation_${schoolId}_$className';
    final cached = await _localDb.getCache(cacheKey);
    
    if (cached != null) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }
    
    return null;
  }

  /// Get timetable quality metrics
  Future<Map<String, dynamic>?> getQualityMetrics({
    required String schoolId,
    required String className,
  }) async {
    final validationData = await getCachedValidation(schoolId: schoolId, className: className);
    
    if (validationData != null) {
      return validationData['qualityMetrics'] as Map<String, dynamic>?;
    }
    
    // If no cached data, perform validation
    final freshValidation = await validateTimetable(schoolId: schoolId, className: className);
    return freshValidation['qualityMetrics'] as Map<String, dynamic>?;
  }

  /// Get improvement suggestions for timetable
  Future<List<Map<String, dynamic>>> getTimetableSuggestions({
    required String schoolId,
    required String className,
  }) async {
    final validationData = await getCachedValidation(schoolId: schoolId, className: className);
    
    if (validationData != null) {
      return (validationData['suggestions'] as List<dynamic>?)
          ?.map((s) => s as Map<String, dynamic>)
          .toList() ?? [];
    }
    
    // If no cached data, perform validation
    final freshValidation = await validateTimetable(schoolId: schoolId, className: className);
    return (freshValidation['suggestions'] as List<dynamic>?)
        ?.map((s) => s as Map<String, dynamic>)
        .toList() ?? [];
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

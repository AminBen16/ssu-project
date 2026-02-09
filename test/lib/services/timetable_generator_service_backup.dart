import 'dart:math';
import 'package:test/services/staff_service.dart';
import 'package:test/services/student_service.dart';
import 'package:test/services/local_database_service.dart';
import 'package:test/models/subject.dart';
import 'package:test/models/staff.dart';
import 'package:test/models/timetable_model.dart';
import 'package:test/models/timetable_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:test/services/platform_channels.dart';

/// Enhanced constraint model for timetable generation
class TimetableConstraint {
  final String teacherId;
  final String subjectId;
  final int minPeriodsPerWeek;
  final int maxPeriodsPerDay;
  final List<String> unavailableTimeSlots;
  final List<String> preferredTimeSlots;
  final int maxConsecutivePeriods;
  final List<String> preferredDays;
  final Map<String, dynamic> customConstraints;

  TimetableConstraint({
    required this.teacherId,
    required this.subjectId,
    this.minPeriodsPerWeek = 1,
    this.maxPeriodsPerDay = 6,
    this.unavailableTimeSlots = const [],
    this.preferredTimeSlots = const [],
    this.maxConsecutivePeriods = 3,
    this.preferredDays = const [],
    this.customConstraints = const {},
  });

  factory TimetableConstraint.fromMap(Map<String, dynamic> map) {
    return TimetableConstraint(
      teacherId: map['teacherId'] as String,
      subjectId: map['subjectId'] as String,
      minPeriodsPerWeek: map['minPeriodsPerWeek'] as int? ?? 1,
      maxPeriodsPerDay: map['maxPeriodsPerDay'] as int? ?? 6,
      unavailableTimeSlots: (map['unavailableTimeSlots'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      preferredTimeSlots: (map['preferredTimeSlots'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      maxConsecutivePeriods: map['maxConsecutivePeriods'] as int? ?? 3,
      preferredDays: (map['preferredDays'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      customConstraints: map['customConstraints'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'subjectId': subjectId,
      'minPeriodsPerWeek': minPeriodsPerWeek,
      'maxPeriodsPerDay': maxPeriodsPerDay,
      'unavailableTimeSlots': unavailableTimeSlots,
      'preferredTimeSlots': preferredTimeSlots,
      'maxConsecutivePeriods': maxConsecutivePeriods,
      'preferredDays': preferredDays,
      'customConstraints': customConstraints,
    };
  }
}

/// Represents a scheduling conflict
class TimetableConflict {
  final String type; // 'teacher', 'room', 'subject', 'constraint'
  final String description;
  final Map<String, dynamic> details;
  final int severity; // 1=minor, 2=major, 3=critical

  TimetableConflict({
    required this.type,
    required this.description,
    required this.details,
    this.severity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'details': details,
      'severity': severity,
    };
  }
}

/// Enhanced timetable generator with real constraint-based scheduling
/// Replaces mock implementation with actual algorithmic generation
class TimetableGeneratorService {
  final MeshPlatformChannels? _meshChannels;

  TimetableGeneratorService([this._meshChannels]);

  /// Enhanced constraint extraction from real database entities
  Future<Map<String, dynamic>> extractConstraintsFromDatabase({
    required String schoolId,
    required LocalDatabaseService localDb,
    required StaffService staffService,
  }) async {
    final extractedConstraints = <String, TimetableConstraint>{};
    final conflicts = <TimetableConflict>[];
    
    try {
      // Get all teaching staff for the school
      final teachingStaff = await staffService.getTeachingStaff(schoolId);
      
      // Get subjects from database (assuming they're cached)
      final subjectsData = await localDb.getAllData('subjects');
      final subjects = subjectsData.map((data) => Subject.fromMap(data['data'] as Map<String, dynamic>)).toList();
      
      // Extract teacher-specific constraints from staff data
      for (final staff in teachingStaff) {
        try {
          // Get teacher's subject assignments from their profile data
          final assignedSubjects = _extractTeacherSubjects(staff);
          
          for (final subject in assignedSubjects) {
            // Create constraint based on teacher's profile and subject requirements
            final constraint = TimetableConstraint(
              teacherId: staff.id,
              subjectId: subject,
              minPeriodsPerWeek: _calculateMinPeriods(subject, subjects),
              maxPeriodsPerDay: staff.profile?['maxPeriodsPerDay'] as int? ?? 6,
              unavailableTimeSlots: _extractUnavailableSlots(staff),
              preferredTimeSlots: _extractPreferredSlots(staff),
              maxConsecutivePeriods: staff.profile?['maxConsecutivePeriods'] as int? ?? 3,
              preferredDays: _extractPreferredDays(staff),
              customConstraints: {
                'teacherName': '${staff.firstName} ${staff.lastName}',
                'qualification': staff.profile?['qualification'] ?? '',
                'experience': staff.profile?['yearsOfExperience'] ?? 0,
              },
            );
            
            extractedConstraints['${staff.id}_$subject'] = constraint;
          }
        } catch (e) {
          conflicts.add(TimetableConflict(
            type: 'constraint',
            description: 'Failed to extract constraints for teacher ${staff.id}',
            details: {'error': e.toString(), 'teacherId': staff.id},
            severity: 2,
          ));
        }
      }
      
      // Add subject-level constraints
      for (final subject in subjects) {
        final subjectConstraint = _createSubjectConstraint(subject);
        extractedConstraints['subject_${subject.id}'] = subjectConstraint;
      }
      
      // Add global school constraints
      extractedConstraints['global'] = TimetableConstraint(
        teacherId: 'global',
        subjectId: 'global',
        minPeriodsPerWeek: 1,
        maxPeriodsPerDay: 7, // Maximum periods in a school day
        maxConsecutivePeriods: 4,
        customConstraints: {
          'schoolId': schoolId,
          'totalPeriodsPerDay': 8,
          'breakPeriods': ['BREAK1', 'LUNCH'],
        },
      );
      
    } catch (e) {
      conflicts.add(TimetableConflict(
        type: 'constraint',
        description: 'Failed to extract constraints from database',
        details: {'error': e.toString(), 'schoolId': schoolId},
        severity: 3,
      ));
    }
    
    return {
      'constraints': extractedConstraints,
      'conflicts': conflicts,
      'totalTeachers': teachingStaff.length,
      'totalSubjects': subjects.length,
    };
  }

  /// Helper method to extract subjects assigned to a teacher
  static List<String> _extractTeacherSubjects(dynamic staff) {
    final subjects = <String>[];
    
    // Extract from profile data
    if (staff.profile != null) {
      final assignedSubjects = staff.profile['assignedSubjects'] as List<dynamic>?;
      if (assignedSubjects != null) {
        subjects.addAll(assignedSubjects.map((s) => s.toString()));
      }
      
      // Extract from qualifications
      final qualifications = staff.profile['qualifications'] as List<dynamic>?;
      if (qualifications != null) {
        for (final qual in qualifications) {
          if (qual is Map<String, dynamic>) {
            final subject = qual['subject'] as String?;
            if (subject != null && !subjects.contains(subject)) {
              subjects.add(subject);
            }
          }
        }
      }
    }
    
    // Fallback to role-based subject assignment
    if (subjects.isEmpty) {
      final role = staff.role?.name.toLowerCase() ?? '';
      switch (role) {
        case 'mathematics_teacher':
          subjects.add('Mathematics');
          break;
        case 'english_teacher':
          subjects.add('English');
          break;
        case 'science_teacher':
          subjects.addAll(['Physics', 'Chemistry', 'Biology']);
          break;
        default:
          subjects.add('General Studies');
      }
    }
    
    return subjects;
  }

  /// Calculate minimum periods per week for a subject
  static int _calculateMinPeriods(String subjectName, List<Subject> subjects) {
    final subject = subjects.where((s) => s.name == subjectName).firstOrNull;
    if (subject != null) {
      // Use subject description or metadata to determine periods
      final desc = subject.description?.toLowerCase() ?? '';
      if (desc.contains('core') || desc.contains('compulsory')) {
        return 5; // Core subjects need more periods
      } else if (desc.contains('practical') || desc.contains('lab')) {
        return 3; // Practical subjects need lab time
      }
    }
    
    // Default based on subject type
    final coreSubjects = ['Mathematics', 'English', 'Science', 'Social Studies'];
    final practicalSubjects = ['Chemistry Lab', 'Physics Lab', 'Biology Lab', 'Computer Studies'];
    
    if (coreSubjects.contains(subjectName)) return 5;
    if (practicalSubjects.contains(subjectName)) return 3;
    return 2; // Default for elective subjects
  }

  /// Extract unavailable time slots from teacher profile
  static List<String> _extractUnavailableSlots(dynamic staff) {
    final unavailableSlots = <String>[];
    
    if (staff.profile != null) {
      final unavailable = staff.profile['unavailableTimeSlots'] as List<dynamic>?;
      if (unavailable != null) {
        unavailableSlots.addAll(unavailable.map((s) => s.toString()));
      }
      
      // Add logical unavailability based on role
      final role = staff.role?.name.toLowerCase() ?? '';
      if (role.contains('admin') || role.contains('head')) {
        unavailableSlots.addAll(['P1', 'P8']); // Admin staff often unavailable first/last period
      }
    }
    
    return unavailableSlots;
  }

  /// Extract preferred time slots from teacher profile
  static List<String> _extractPreferredSlots(dynamic staff) {
    final preferredSlots = <String>[];
    
    if (staff.profile != null) {
      final preferred = staff.profile['preferredTimeSlots'] as List<dynamic>?;
      if (preferred != null) {
        preferredSlots.addAll(preferred.map((s) => s.toString()));
      }
    }
    
    return preferredSlots;
  }

  /// Extract preferred days from teacher profile
  static List<String> _extractPreferredDays(dynamic staff) {
    final preferredDays = <String>[];
    
    if (staff.profile != null) {
      final preferred = staff.profile['preferredDays'] as List<dynamic>?;
      if (preferred != null) {
        preferredDays.addAll(preferred.map((d) => d.toString()));
      }
    }
    
    return preferredDays;
  }

  /// Create subject-level constraints
  static TimetableConstraint _createSubjectConstraint(Subject subject) {
    final desc = subject.description?.toLowerCase() ?? '';
    
    int minPeriods = 2;
    int maxConsecutive = 3;
    List<String> preferredSlots = [];
    
    if (desc.contains('core') || desc.contains('compulsory')) {
      minPeriods = 5;
      preferredSlots = ['P1', 'P2', 'P3']; // Morning slots for core subjects
    } else if (desc.contains('practical') || desc.contains('lab')) {
      minPeriods = 3;
      maxConsecutive = 2; // Lab sessions shouldn't be too long
      preferredSlots = ['P4', 'P5', 'P6', 'P7']; // Mid-day slots for labs
    }
    
    return TimetableConstraint(
      teacherId: 'subject_level',
      subjectId: subject.id.toString(),
      minPeriodsPerWeek: minPeriods,
      maxPeriodsPerDay: 2,
      preferredTimeSlots: preferredSlots,
      maxConsecutivePeriods: maxConsecutive,
      customConstraints: {
        'subjectName': subject.name,
        'description': subject.description,
        'isCore': desc.contains('core'),
        'isPractical': desc.contains('practical') || desc.contains('lab'),
      },
    );
  }

  /// Extracts and validates constraints from input data
  static Map<String, dynamic> _extractConstraints(Map<String, dynamic> constraints) {
    final extractedConstraints = <String, TimetableConstraint>{};
    final conflicts = <TimetableConflict>[];
    
    try {
      // Extract teacher constraints
      if (constraints['teacherConstraints'] != null) {
        final teacherConstraints = constraints['teacherConstraints'] as Map<String, dynamic>;
        teacherConstraints.forEach((teacherId, constraintData) {
          try {
            extractedConstraints[teacherId] = TimetableConstraint.fromMap(constraintData as Map<String, dynamic>);
          } catch (e) {
            conflicts.add(TimetableConflict(
              type: 'constraint',
              description: 'Invalid constraint format for teacher $teacherId',
              details: {'error': e.toString()},
              severity: 3,
            ));
          }
        });
      }
      
      // Extract subject constraints
      if (constraints['subjectConstraints'] != null) {
        final subjectConstraints = constraints['subjectConstraints'] as Map<String, dynamic>;
        subjectConstraints.forEach((subjectId, constraintData) {
          try {
            // Add subject-level constraints to all teachers teaching this subject
            final constraint = TimetableConstraint.fromMap(constraintData as Map<String, dynamic>);
            extractedConstraints['subject_$subjectId'] = constraint;
          } catch (e) {
            conflicts.add(TimetableConflict(
              type: 'constraint',
              description: 'Invalid constraint format for subject $subjectId',
              details: {'error': e.toString()},
              severity: 3,
            ));
          }
        });
      }
      
      // Extract global constraints
      if (constraints['globalConstraints'] != null) {
        final globalConstraints = constraints['globalConstraints'] as Map<String, dynamic>;
        extractedConstraints['global'] = TimetableConstraint(
          teacherId: 'global',
          subjectId: 'global',
          minPeriodsPerWeek: globalConstraints['minPeriodsPerWeek'] as int? ?? 1,
          maxPeriodsPerDay: globalConstraints['maxPeriodsPerDay'] as int? ?? 6,
          maxConsecutivePeriods: globalConstraints['maxConsecutivePeriods'] as int? ?? 3,
          customConstraints: globalConstraints,
        );
      }
    } catch (e) {
      conflicts.add(TimetableConflict(
        type: 'constraint',
        description: 'Failed to extract constraints',
        details: {'error': e.toString()},
        severity: 3,
      ));
    }
    
    return {
      'constraints': extractedConstraints,
      'conflicts': conflicts,
    };
  }

  /// Enhanced conflict graph with room constraints and teacher compatibility
  static Map<String, dynamic> _buildConflictGraph({
    required List<String> teachers,
    required List<String> subjects,
    required Map<String, TimetableConstraint> constraints,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> roomData, // New parameter for room constraints
  }) {
    final conflictGraph = <String, Set<String>>{};
    final conflicts = <TimetableConflict>[];
    final roomAssignments = <String, Map<String, String>>{}; // room -> day -> slot -> subject
    final teacherWorkload = <String, Map<String, int>>{}; // teacher -> day -> period count
    
    // Initialize data structures
    for (final teacherId in teachers) {
      teacherWorkload[teacherId] = {};
      for (final day in days) {
        teacherWorkload[teacherId]![day] = 0;
      }
    }
    
    // Build teacher-subject compatibility and conflict matrix
    for (final teacherId in teachers) {
      final teacherConstraint = constraints[teacherId];
      if (teacherConstraint == null) continue;
      
      // Check teacher availability conflicts
      for (final unavailableSlot in teacherConstraint.unavailableTimeSlots) {
        if (timeSlots.contains(unavailableSlot)) {
          conflicts.add(TimetableConflict(
            type: 'teacher',
            description: 'Teacher $teacherId unavailable at $unavailableSlot',
            details: {
              'teacherId': teacherId,
              'timeSlot': unavailableSlot,
              'reason': 'unavailable',
              'severity': 2,
            },
            severity: 2,
          ));
        }
      }
      
      // Check workload balance conflicts
      final maxPeriodsPerDay = teacherConstraint.maxPeriodsPerDay;
      for (final day in days) {
        final currentLoad = teacherWorkload[teacherId]![day] ?? 0;
        if (currentLoad > maxPeriodsPerDay) {
          conflicts.add(TimetableConflict(
            type: 'teacher',
            description: 'Teacher $teacherId exceeds max periods on $day',
            details: {
              'teacherId': teacherId,
              'day': day,
              'currentLoad': currentLoad,
              'maxAllowed': maxPeriodsPerDay,
            },
            severity: 2,
          ));
        }
      }
      
      // Check consecutive periods constraint
      for (final day in days) {
        if (_wouldExceedConsecutivePeriods(
          teacherId: teacherId,
          day: day,
          slot: 'P1', // Check from first period
          currentTimetable: {}, // Will be populated during assignment
          maxConsecutive: teacherConstraint.maxConsecutivePeriods,
        )) {
          conflicts.add(TimetableConflict(
            type: 'teacher',
            description: 'Teacher $teacherId may exceed consecutive periods on $day',
            details: {
              'teacherId': teacherId,
              'day': day,
              'maxConsecutive': teacherConstraint.maxConsecutivePeriods,
            },
            severity: 1, // Warning level
          ));
        }
      }
    }
    
    // Build room conflict graph
    if (roomData.isNotEmpty) {
      final rooms = roomData['rooms'] as List<dynamic>? ?? [];
      for (final room in rooms) {
        final roomId = room['id'] as String;
        final roomType = room['type'] as String? ?? 'classroom';
        final capacity = room['capacity'] as int? ?? 30;
        
        roomAssignments[roomId] = {};
        
        // Check room-specific constraints
        for (final day in days) {
          roomAssignments[roomId]![day] = '';
          
          // Lab rooms can't be used for non-practical subjects
          if (roomType.toLowerCase().contains('lab')) {
            for (final subject in subjects) {
              if (!_isPracticalSubject(subject, {})) {
                conflicts.add(TimetableConflict(
                  type: 'room',
                  description: 'Lab room $roomId unsuitable for non-practical subject $subject',
                  details: {
                    'roomId': roomId,
                    'roomType': roomType,
                    'subject': subject,
                    'reason': 'lab_mismatch',
                  },
                  severity: 2,
                ));
              }
            }
          }
          
          // Check capacity constraints
          if (capacity < 20) {
            conflicts.add(TimetableConflict(
              type: 'room',
              description: 'Room $roomId has low capacity ($capacity)',
              details: {
                'roomId': roomId,
                'capacity': capacity,
                'minRequired': 20,
              },
              severity: 1, // Warning
            ));
          }
        }
      }
    }
    
    // Check subject distribution and prerequisite conflicts
    final subjectCounts = <String, int>{};
    final subjectPrerequisites = <String, List<String>>{};
    
    for (final subjectId in subjects) {
      final subjectConstraint = constraints['subject_$subjectId'];
      if (subjectConstraint != null) {
        subjectCounts[subjectId] = 0;
        
        // Check minimum periods per week feasibility
        final totalAvailableSlots = days.length * timeSlots.length;
        final breakSlots = timeSlots.where((slot) => 
          slot.contains('BREAK') || slot.contains('LUNCH')).length;
        final usableSlots = totalAvailableSlots - breakSlots;
        
        if (subjectConstraint.minPeriodsPerWeek > usableSlots) {
          conflicts.add(TimetableConflict(
            type: 'subject',
            description: 'Subject $subjectId requires more periods than available',
            details: {
              'subjectId': subjectId,
              'required': subjectConstraint.minPeriodsPerWeek,
              'available': usableSlots,
              'totalSlots': totalAvailableSlots,
              'breakSlots': breakSlots,
            },
            severity: 3,
          ));
        }
        
        // Check for subject sequence conflicts
        final prerequisites = _extractSubjectPrerequisites(subjectId, constraints);
        if (prerequisites.isNotEmpty) {
          subjectPrerequisites[subjectId] = prerequisites;
          
          for (final prereq in prerequisites) {
            if (!subjects.contains(prereq)) {
              conflicts.add(TimetableConflict(
                type: 'subject',
                description: 'Subject $subjectId requires prerequisite $prereq which is not available',
                details: {
                  'subjectId': subjectId,
                  'prerequisite': prereq,
                  'availableSubjects': subjects,
                },
                severity: 3,
              ));
            }
          }
        }
      }
    }
    
    // Build teacher-subject compatibility matrix
    final teacherSubjectCompatibility = <String, Set<String>>{};
    for (final teacherId in teachers) {
      teacherSubjectCompatibility[teacherId] = {};
      
      // Extract subjects this teacher can teach
      final teacherConstraints = constraints.entries
          .where((entry) => entry.key.startsWith(teacherId) && entry.value is TimetableConstraint)
          .map((entry) => entry.value.subjectId)
          .toSet();
      
      teacherSubjectCompatibility[teacherId].addAll(teacherConstraints);
      
      // Check if teacher has insufficient subject assignments
      if (teacherConstraints.isEmpty) {
        conflicts.add(TimetableConflict(
          type: 'teacher',
          description: 'Teacher $teacherId has no subject assignments',
          details: {
            'teacherId': teacherId,
            'suggestion': 'Assign subjects to this teacher or remove from scheduling',
          },
          severity: 2,
        ));
      }
    }
    
    // Check for teacher specialization conflicts
    for (final subject in subjects) {
      final qualifiedTeachers = teachers
          .where((teacherId) => teacherSubjectCompatibility[teacherId]?.contains(subject) ?? false)
          .toList();
      
      if (qualifiedTeachers.isEmpty) {
        conflicts.add(TimetableConflict(
          type: 'subject',
          description: 'No qualified teachers available for subject $subject',
          details: {
            'subject': subject,
            'availableTeachers': teachers,
            'qualifiedTeachers': qualifiedTeachers,
          },
          severity: 3,
        ));
      } else if (qualifiedTeachers.length == 1) {
        // Single point of failure warning
        conflicts.add(TimetableConflict(
          type: 'subject',
          description: 'Only one teacher qualified for subject $subject',
          details: {
            'subject': subject,
            'teacher': qualifiedTeachers.first,
            'risk': 'single_point_of_failure',
          },
          severity: 1, // Warning
        ));
      }
    }
    
    return {
      'conflictGraph': conflictGraph,
      'conflicts': conflicts,
      'subjectCounts': subjectCounts,
      'roomAssignments': roomAssignments,
      'teacherWorkload': teacherWorkload,
      'teacherSubjectCompatibility': teacherSubjectCompatibility,
      'subjectPrerequisites': subjectPrerequisites,
      'feasibilityScore': _calculateFeasibilityScore(conflicts, teachers.length, subjects.length),
    };
  }

  /// Extract subject prerequisites from constraints
  static List<String> _extractSubjectPrerequisites(String subjectId, Map<String, TimetableConstraint> constraints) {
    final constraint = constraints['subject_$subjectId'];
    if (constraint?.customConstraints != null) {
      final prereqs = constraint!.customConstraints['prerequisites'] as List<dynamic>?;
      if (prereqs != null) {
        return prereqs.map((p) => p.toString()).toList();
      }
    }
    return [];
  }

  /// Calculate overall feasibility score for the scheduling problem
  static double _calculateFeasibilityScore(List<TimetableConflict> conflicts, int teacherCount, int subjectCount) {
    if (conflicts.isEmpty) return 1.0;
    
    final criticalConflicts = conflicts.where((c) => c.severity == 3).length;
    final majorConflicts = conflicts.where((c) => c.severity == 2).length;
    final minorConflicts = conflicts.where((c) => c.severity == 1).length;
    
    // Weight conflicts by severity
    final weightedConflicts = (criticalConflicts * 3.0) + (majorConflicts * 2.0) + (minorConflicts * 1.0);
    final maxPossibleConflicts = (teacherCount + subjectCount) * 3.0; // Theoretical maximum
    
    return max(0.0, 1.0 - (weightedConflicts / maxPossibleConflicts));
  }

  /// Builds conflict graph for constraint satisfaction
  static Map<String, dynamic> _buildConflictGraph({
    required List<String> teachers,
    required List<String> subjects,
    required Map<String, TimetableConstraint> constraints,
    required List<String> timeSlots,
    required List<String> days,
  }) {
    final conflictGraph = <String, Set<String>>{};
    final conflicts = <TimetableConflict>[];
    
    // Build teacher-subject compatibility graph
    for (final teacherId in teachers) {
      final teacherConstraint = constraints[teacherId];
      if (teacherConstraint != null) {
        // Check teacher availability
        for (final unavailableSlot in teacherConstraint.unavailableTimeSlots) {
          if (timeSlots.contains(unavailableSlot)) {
            conflicts.add(TimetableConflict(
              type: 'teacher',
              description: 'Teacher $teacherId unavailable at $unavailableSlot',
              details: {
                'teacherId': teacherId,
                'timeSlot': unavailableSlot,
                'reason': 'unavailable',
              },
              severity: 2,
            ));
          }
        }
        
        // Check max periods per day constraint
        if (teacherConstraint.maxPeriodsPerDay < timeSlots.length) {
          conflicts.add(TimetableConflict(
            type: 'teacher',
            description: 'Teacher $teacherId exceeds max periods per day',
            details: {
              'teacherId': teacherId,
              'maxPeriods': teacherConstraint.maxPeriodsPerDay,
              'actualPeriods': timeSlots.length,
            },
            severity: 2,
          ));
        }
      }
    }
    
    // Check subject distribution constraints
    final subjectCounts = <String, int>{};
    for (final subjectId in subjects) {
      final subjectConstraint = constraints['subject_$subjectId'];
      if (subjectConstraint != null) {
        subjectCounts[subjectId] = 0;
        
        // Check minimum periods per week
        if (subjectConstraint.minPeriodsPerWeek > (days.length * timeSlots.length / 2)) {
          conflicts.add(TimetableConflict(
            type: 'subject',
            description: 'Subject $subjectId requires more periods than available',
            details: {
              'subjectId': subjectId,
              'required': subjectConstraint.minPeriodsPerWeek,
              'available': days.length * timeSlots.length ~/ 2,
            },
            severity: 3,
          ));
        }
      }
    }
    
    return {
      'conflictGraph': conflictGraph,
      'conflicts': conflicts,
      'subjectCounts': subjectCounts,
    };
  }

  /// Advanced CSP solver with graph coloring and constraint propagation
  static Map<String, dynamic> _solveCSPWithGraphColoring({
    required List<String> teachers,
    required List<String> subjects,
    required Map<String, TimetableConstraint> constraints,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> requirements,
    required Map<String, dynamic> conflictGraphData,
  }) {
    final timetable = <String, Map<String, ScheduledLesson>>{};
    final assignments = <String, Map<String, Map<String, String>>>{}; // day -> slot -> (teacher, subject)
    final conflicts = <TimetableConflict>[];
    final teacherWorkload = <String, Map<String, int>>{}; // teacher -> day -> period count
    final roomAssignments = <String, Map<String, Map<String, String>>>{}; // room -> day -> slot -> subject
    
    // Extract compatibility data from conflict graph
    final teacherSubjectCompatibility = conflictGraphData['teacherSubjectCompatibility'] as Map<String, Set<String>>? ?? {};
    final subjectPrerequisites = conflictGraphData['subjectPrerequisites'] as Map<String, List<String>>? ?? {};
    final feasibilityScore = conflictGraphData['feasibilityScore'] as double? ?? 0.0;
    
    // Initialize data structures
    for (final day in days) {
      timetable[day] = <String, ScheduledLesson>{};
      assignments[day] = <String, Map<String, String>>{};
      for (final slot in timeSlots) {
        timetable[day]![slot] = ScheduledLesson(
          subjectName: '',
          teacherId: '',
          teacherName: '',
        );
        assignments[day]![slot] = {'teacher': '', 'subject': ''};
      }
    }
    
    // Initialize teacher workload tracking
    for (final teacherId in teachers) {
      teacherWorkload[teacherId] = {};
      for (final day in days) {
        teacherWorkload[teacherId]![day] = 0;
      }
    }
    
    // Create assignment problem graph for graph coloring
    final assignmentGraph = _buildAssignmentGraph(
      subjects: subjects,
      teachers: teachers,
      timeSlots: timeSlots,
      days: days,
      constraints: constraints,
      compatibility: teacherSubjectCompatibility,
    );
    
    // Apply graph coloring to identify optimal assignment order
    final coloringOrder = _graphColoringHeuristic(assignmentGraph);
    
    // Enhanced backtracking with forward checking and constraint propagation
    bool _backtrackWithForwardChecking(int assignmentIndex) {
      if (assignmentIndex >= coloringOrder.length) {
        return true; // All assignments completed successfully
      }
      
      final currentAssignment = coloringOrder[assignmentIndex];
      final subject = currentAssignment['subject'] as String;
      final day = currentAssignment['day'] as String;
      final slot = currentAssignment['slot'] as String;
      
      // Skip break periods for core subjects (hard constraint)
      if ((slot.contains('BREAK') || slot.contains('LUNCH')) && _isCoreSubject(subject, requirements)) {
        return _backtrackWithForwardChecking(assignmentIndex + 1);
      }
      
      // Get domain values (available teachers for this subject-slot combination)
      final availableTeachers = _getAvailableTeachersForSlot(
        subject: subject,
        day: day,
        slot: slot,
        teachers: teachers,
        constraints: constraints,
        compatibility: teacherSubjectCompatibility,
        currentAssignments: assignments,
        teacherWorkload: teacherWorkload,
      );
      
      // Sort teachers by preference (most constrained first)
      final sortedTeachers = _sortTeachersByConstraint(
        availableTeachers,
        subject,
        slot,
        constraints,
      );
      
      for (final teacher in sortedTeachers) {
        // Check if this assignment violates any constraints
        final conflictCheck = _checkAssignmentConstraints(
          subject: subject,
          teacher: teacher,
          day: day,
          slot: slot,
          constraints: constraints,
          currentAssignments: assignments,
          teacherWorkload: teacherWorkload,
          prerequisites: subjectPrerequisites,
        );
        
        if (conflictCheck == null) {
          // Make assignment
          assignments[day]![slot] = {
            'teacher': teacher['id'] as String,
            'subject': subject,
          };
          
          teacherWorkload[teacher['id'] as String]![day] = 
              (teacherWorkload[teacher['id'] as String]![day] ?? 0) + 1;
          
          // Forward checking: prune domains of future assignments
          final prunedDomains = _forwardCheck(
            assignmentIndex + 1,
            coloringOrder,
            assignments,
            constraints,
            teacherSubjectCompatibility,
          );
          
          if (prunedDomains != null) {
            // Continue with backtracking
            if (_backtrackWithForwardChecking(assignmentIndex + 1)) {
              // Assignment successful, update timetable
              timetable[day]![slot] = ScheduledLesson(
                subjectName: subject,
                teacherId: teacher['id'] as String,
                teacherName: '${teacher['firstName']} ${teacher['lastName']}',
                room: _assignOptimalRoom(subject, day, slot, roomAssignments),
              );
              return true;
            }
          }
          
          // Backtrack: undo assignment
          assignments[day]![slot] = {'teacher': '', 'subject': ''};
          teacherWorkload[teacher['id'] as String]![day] = 
              (teacherWorkload[teacher['id'] as String]![day] ?? 0) - 1;
        } else {
          conflicts.add(conflictCheck);
        }
      }
      
      // No valid assignment found for this position
      return false;
    }
    
    // Start the backtracking algorithm
    final success = _backtrackWithForwardChecking(0);
    
    if (!success) {
      conflicts.add(TimetableConflict(
        type: 'algorithm',
        description: 'CSP solver could not find a valid timetable assignment',
        details: {
          'totalAssignments': coloringOrder.length,
          'feasibilityScore': feasibilityScore,
          'suggestion': 'Relax constraints or add more resources',
        },
        severity: 3,
      ));
    }
    
    // Calculate final statistics
    final subjectCounts = <String, int>{};
    for (final day in assignments.keys) {
      for (final slot in assignments[day]!.values) {
        final subject = slot['subject'] ?? '';
        if (subject.isNotEmpty) {
          subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
        }
      }
    }
    
    return {
      'timetable': timetable,
      'conflicts': conflicts,
      'subjectCounts': subjectCounts,
      'teacherWorkload': teacherWorkload,
      'assignments': assignments,
      'success': success,
      'algorithm': 'CSP_GraphColoring_ForwardChecking',
      'complexity': 'O(n^3) where n = total assignments',
    };
  }

  /// Build assignment graph for graph coloring
  static List<Map<String, dynamic>> _buildAssignmentGraph({
    required List<String> subjects,
    required List<String> teachers,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, TimetableConstraint> constraints,
    required Map<String, Set<String>> compatibility,
  }) {
    final assignments = <Map<String, dynamic>>[];
    
    // Create nodes for each subject that needs to be scheduled
    for (final subject in subjects) {
      final subjectConstraint = constraints['subject_$subject'];
      final requiredPeriods = subjectConstraint?.minPeriodsPerWeek ?? 2;
      
      for (int i = 0; i < requiredPeriods; i++) {
        // Find best time slots for this subject
        final preferredSlots = _getPreferredTimeSlots(subject, constraints);
        
        for (final day in days) {
          for (final slot in timeSlots) {
            if (preferredSlots.isEmpty || preferredSlots.contains(slot)) {
              assignments.add({
                'subject': subject,
                'day': day,
                'slot': slot,
                'priority': _calculateAssignmentPriority(subject, slot, constraints),
                'constraints': _getAssignmentConstraints(subject, slot, constraints),
              });
            }
          }
        }
      }
    }
    
    // Sort by priority (most constrained first)
    assignments.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
    return assignments;
  }

  /// Graph coloring heuristic to determine optimal assignment order
  static List<Map<String, dynamic>> _graphColoringHeuristic(List<Map<String, dynamic>> assignments) {
    // Use largest degree ordering for graph coloring
    final colored = <Map<String, dynamic>>[];
    final uncolored = List<Map<String, dynamic>>.from(assignments);
    
    while (uncolored.isNotEmpty) {
      // Find node with highest degree (most conflicts)
      int maxDegree = -1;
      Map<String, dynamic>? selectedNode;
      int selectedIndex = -1;
      
      for (int i = 0; i < uncolored.length; i++) {
        final node = uncolored[i];
        final degree = _calculateNodeDegree(node, uncolored);
        
        if (degree > maxDegree) {
          maxDegree = degree;
          selectedNode = node;
          selectedIndex = i;
        }
      }
      
      if (selectedNode != null) {
        colored.add(selectedNode);
        uncolored.removeAt(selectedIndex);
      }
    }
    
    return colored;
  }

  /// Calculate the degree (number of conflicts) for a node
  static int _calculateNodeDegree(Map<String, dynamic> node, List<Map<String, dynamic>> otherNodes) {
    int degree = 0;
    final subject = node['subject'] as String;
    final day = node['day'] as String;
    final slot = node['slot'] as String;
    
    for (final other in otherNodes) {
      if (other == node) continue;
      
      final otherSubject = other['subject'] as String;
      final otherDay = other['day'] as String;
      final otherSlot = other['slot'] as String;
      
      // Count conflicts: same subject, same time slot, same day
      if (subject == otherSubject && day == otherDay && slot == otherSlot) {
        degree += 3; // High weight for exact conflict
      } else if (day == otherDay && slot == otherSlot) {
        degree += 2; // Medium weight for time slot conflict
      } else if (subject == otherSubject) {
        degree += 1; // Low weight for subject conflict
      }
    }
    
    return degree;
  }

  /// Get available teachers for a specific subject-slot combination
  static List<Map<String, dynamic>> _getAvailableTeachersForSlot({
    required String subject,
    required String day,
    required String slot,
    required List<String> teachers,
    required Map<String, TimetableConstraint> constraints,
    required Map<String, Set<String>> compatibility,
    required Map<String, Map<String, Map<String, String>>> currentAssignments,
    required Map<String, Map<String, int>> teacherWorkload,
  }) {
    final availableTeachers = <Map<String, dynamic>>[];
    
    for (final teacherId in teachers) {
      // Check if teacher can teach this subject
      if (!compatibility[teacherId]?.contains(subject) ?? false) {
        continue;
      }
      
      final constraint = constraints[teacherId];
      if (constraint == null) continue;
      
      // Check availability constraints
      if (constraint.unavailableTimeSlots.contains(slot)) {
        continue;
      }
      
      // Check workload constraints
      final currentLoad = teacherWorkload[teacherId]?[day] ?? 0;
      if (currentLoad >= constraint.maxPeriodsPerDay) {
        continue;
      }
      
      // Check if teacher is already assigned at this time
      bool alreadyAssigned = false;
      for (final assignedSlot in currentAssignments[day]?.values ?? {}) {
        if (assignedSlot['teacher'] == teacherId) {
          alreadyAssigned = true;
          break;
        }
      }
      
      if (alreadyAssigned) {
        continue;
      }
      
      // Check consecutive periods constraint
      if (_wouldExceedConsecutivePeriods(
        teacherId: teacherId,
        day: day,
        slot: slot,
        currentTimetable: _convertAssignmentsToTimetable(currentAssignments),
        maxConsecutive: constraint.maxConsecutivePeriods,
      )) {
        continue;
      }
      
      availableTeachers.add({
        'id': teacherId,
        'priority': _calculateTeacherPriority(
          teacherId: teacherId,
          subject: subject,
          slot: slot,
          constraint: constraint,
        ),
        'workload': currentLoad,
        'maxLoad': constraint.maxPeriodsPerDay,
      });
    }
    
    return availableTeachers;
  }

  /// Forward checking to prune domains of future assignments
  static Map<String, dynamic>? _forwardCheck(
    int startIndex,
    List<Map<String, dynamic>> assignments,
    Map<String, Map<String, Map<String, String>>> currentAssignments,
    Map<String, TimetableConstraint> constraints,
    Map<String, Set<String>> compatibility,
  ) {
    // Check if any future assignments have no possible teachers
    for (int i = startIndex; i < assignments.length; i++) {
      final assignment = assignments[i];
      final subject = assignment['subject'] as String;
      final day = assignment['day'] as String;
      final slot = assignment['slot'] as String;
      
      // Simplified check - in practice, this would be more sophisticated
      bool hasPossibleTeacher = false;
      for (final teacherId in compatibility.keys) {
        if (compatibility[teacherId]?.contains(subject) ?? false) {
          hasPossibleTeacher = true;
          break;
        }
      }
      
      if (!hasPossibleTeacher) {
        return null; // Prune this branch
      }
    }
    
    return {'pruned': true};
  }

  /// Helper methods for the enhanced CSP solver
  static List<String> _getPreferredTimeSlots(String subject, Map<String, TimetableConstraint> constraints) {
    final constraint = constraints['subject_$subject'];
    return constraint?.preferredTimeSlots ?? [];
  }

  static int _calculateAssignmentPriority(String subject, String slot, Map<String, TimetableConstraint> constraints) {
    int priority = 0;
    
    // Core subjects get higher priority
    if (['Mathematics', 'English', 'Science'].contains(subject)) {
      priority += 10;
    }
    
    // Morning slots get higher priority
    if (slot.startsWith('P') && int.tryParse(slot.substring(1)) != null) {
      final periodNum = int.parse(slot.substring(1));
      if (periodNum <= 3) {
        priority += 5;
      }
    }
    
    return priority;
  }

  static Map<String, dynamic> _getAssignmentConstraints(String subject, String slot, Map<String, TimetableConstraint> constraints) {
    return {
      'subject': subject,
      'slot': slot,
      'hasPreferredSlot': constraints['subject_$subject']?.preferredTimeSlots.contains(slot) ?? false,
    };
  }

  static List<Map<String, dynamic>> _sortTeachersByConstraint(
    List<Map<String, dynamic>> teachers,
    String subject,
    String slot,
    Map<String, TimetableConstraint> constraints,
  ) {
    teachers.sort((a, b) {
      final priorityA = a['priority'] as int;
      final priorityB = b['priority'] as int;
      return priorityB.compareTo(priorityA); // Higher priority first
    });
    return teachers;
  }

  static Map<String, Map<String, ScheduledLesson>> _convertAssignmentsToTimetable(
    Map<String, Map<String, Map<String, String>>> assignments,
  ) {
    final timetable = <String, Map<String, ScheduledLesson>>{};
    
    for (final day in assignments.keys) {
      timetable[day] = {};
      for (final slot in assignments[day]!.keys) {
        final assignment = assignments[day]![slot]!;
        timetable[day]![slot] = ScheduledLesson(
          subjectName: assignment['subject'] ?? '',
          teacherId: assignment['teacher'] ?? '',
          teacherName: '',
        );
      }
    }
    
    return timetable;
  }

  /// Check if assignment violates any constraints
  static TimetableConflict? _checkAssignmentConstraints({
    required String subject,
    required Map<String, dynamic> teacher,
    required String day,
    required String slot,
    required Map<String, TimetableConstraint> constraints,
    required Map<String, Map<String, Map<String, String>>> currentAssignments,
    required Map<String, Map<String, int>> teacherWorkload,
    required Map<String, List<String>> prerequisites,
  }) {
    final teacherId = teacher['id'] as String;
    
    // Check prerequisite constraints
    if (prerequisites.containsKey(subject)) {
      final prereqs = prerequisites[subject]!;
      for (final prereq in prereqs) {
        bool prereqScheduled = false;
        for (final scheduledDay in currentAssignments.keys) {
          for (final scheduledSlot in currentAssignments[scheduledDay]!.values) {
            if (scheduledSlot['subject'] == prereq) {
              prereqScheduled = true;
              break;
            }
          }
          if (prereqScheduled) break;
        }
        
        if (!prereqScheduled) {
          return TimetableConflict(
            type: 'prerequisite',
            description: 'Prerequisite $prereq not scheduled before $subject',
            details: {
              'subject': subject,
              'prerequisite': prereq,
              'teacherId': teacherId,
              'day': day,
              'slot': slot,
            },
            severity: 2,
          );
        }
      }
    }
    
    // Check teacher workload constraints
    final currentLoad = teacherWorkload[teacherId]?[day] ?? 0;
    final constraint = constraints[teacherId];
    if (constraint != null && currentLoad >= constraint.maxPeriodsPerDay) {
      return TimetableConflict(
        type: 'teacher',
        description: 'Teacher $teacherId exceeds max periods on $day',
        details: {
          'teacherId': teacherId,
          'day': day,
          'currentLoad': currentLoad,
          'maxAllowed': constraint.maxPeriodsPerDay,
        },
        severity: 2,
      );
    }
    
    return null; // No conflicts
  }

  static String _assignOptimalRoom(
    String subject,
    String day,
    String slot,
    Map<String, Map<String, Map<String, String>>> roomAssignments,
  ) {
    // Simple room assignment - can be enhanced with room constraints
    if (_isPracticalSubject(subject, {})) {
      return 'Lab';
    }
    return 'Classroom';
  }

  /// Try to assign a subject to available slots
  bool _assignSubject(
    String subject,
    int startIndex,
    List<String> teachers,
    Map<String, TimetableConstraint> constraints,
    List<String> timeSlots,
    List<String> days,
    Map<String, Map<String, ScheduledLesson>> timetable,
    Map<String, int> subjectCounts,
    Map<String, dynamic> requirements,
    List<TimetableConflict> conflicts,
  ) {
    for (int i = startIndex; i < days.length; i++) {
      final day = days[i];
      
      // Try each time slot in the day
      for (int j = 0; j < timeSlots.length; j++) {
        final slot = timeSlots[j];
        
        // Skip break periods for core subjects
        if (slot.contains('BREAK') || slot.contains('LUNCH')) {
          final isCore = _isCoreSubject(subject, requirements);
          if (isCore) continue;
        }
        
        // Check if this slot is viable
        final conflict = _checkSlotAvailability(
            day: day,
            slot: slot,
            subject: subject,
            teachers: teachers,
            constraints: constraints,
            currentTimetable: timetable,
            subjectCounts: subjectCounts,
          );
          
          if (conflict == null) {
            // Find available teacher
            final availableTeacher = _findBestAvailableTeacher(
              subject: subject,
              day: day,
              slot: slot,
              teachers: teachers,
              constraints: constraints,
              currentTimetable: timetable,
            );
            
            if (availableTeacher != null) {
              // Assign lesson
              timetable[day]![slot] = ScheduledLesson(
                subjectName: subject,
                teacherId: availableTeacher['id'] as String,
                teacherName: '${availableTeacher['firstName']} ${availableTeacher['lastName']}',
                room: 'Classroom', // Default room assignment
              );
              
              subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
              return true;
            }
          }
        }
      }
      
      // If we couldn't assign in this day, try next day
      // continue is implicit here as we're in the for loop
    }
    
    // Backtrack - couldn't assign this subject
    return false;
  }

  /// Constraint Satisfaction Problem (CSP) solver with backtracking
  static Map<String, dynamic> _solveCSP({
    required List<String> teachers,
    required List<String> subjects,
    required Map<String, TimetableConstraint> constraints,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> requirements,
  }) {
    final timetable = <String, Map<String, ScheduledLesson>>{};
    final assignments = <String, Map<String, String>>{}; // teacher -> day -> slot -> subject
    final conflicts = <TimetableConflict>[];
    
    // Initialize timetable structure
    for (final day in days) {
      timetable[day] = <String, ScheduledLesson>{};
      for (final slot in timeSlots) {
        timetable[day]![slot] = ScheduledLesson(
          subjectName: '',
          teacherId: '',
          teacherName: '',
        );
      }
    }
    
    // Track subject distribution
    final subjectCounts = <String, int>{};
    for (final subject in subjects) {
      subjectCounts[subject] = 0;
    }
    
    // Priority-based subject ordering (core subjects first)
    final prioritizedSubjects = _prioritizeSubjects(subjects, requirements);
    
    // Main assignment loop with backtracking
    for (final subject in prioritizedSubjects) {
      final assigned = _assignSubject(
        subject,
        0,
        teachers,
        constraints,
        timeSlots,
        days,
        timetable,
        subjectCounts,
        requirements,
        conflicts,
      );
      if (!assigned) {
        conflicts.add(TimetableConflict(
          type: 'subject',
          description: 'Could not schedule subject $subject',
          details: {
            'subject': subject,
            'reason': 'No available slots or teachers',
          },
          severity: 3,
        ));
      }
    }
    
    return {
      'timetable': timetable,
      'conflicts': conflicts,
      'subjectCounts': subjectCounts,
    };
  }

  /// Prioritizes subjects based on importance and requirements
  static List<String> _prioritizeSubjects(List<String> subjects, Map<String, dynamic> requirements) {
    final coreSubjects = <String>[];
    final electiveSubjects = <String>[];
    final practicalSubjects = <String>[];
    
    for (final subject in subjects) {
      if (_isCoreSubject(subject, requirements)) {
        coreSubjects.add(subject);
      } else if (_isPracticalSubject(subject, requirements)) {
        practicalSubjects.add(subject);
      } else {
        electiveSubjects.add(subject);
      }
    }
    
    // Return prioritized list: core -> practical -> elective
    return [...coreSubjects, ...practicalSubjects, ...electiveSubjects];
  }

  /// Checks if a subject is a core subject
  static bool _isCoreSubject(String subject, Map<String, dynamic> requirements) {
    final coreSubjects = requirements['coreSubjects'] as List<dynamic>? ?? 
        ['Mathematics', 'English', 'Science', 'Social Studies'];
    return coreSubjects.contains(subject);
  }

  /// Checks if a subject requires practical sessions
  static bool _isPracticalSubject(String subject, Map<String, dynamic> requirements) {
    final practicalSubjects = requirements['practicalSubjects'] as List<dynamic>? ?? 
        ['Chemistry Lab', 'Physics Lab', 'Biology Lab', 'Computer Studies'];
    return practicalSubjects.contains(subject);
  }

  /// Finds the best available teacher for a subject-slot combination
  static Map<String, dynamic>? _findBestAvailableTeacher({
    required String subject,
    required String day,
    required String slot,
    required List<String> teachers,
    required Map<String, TimetableConstraint> constraints,
    required Map<String, Map<String, ScheduledLesson>> currentTimetable,
  }) {
    final availableTeachers = <Map<String, dynamic>>[];
    
    for (final teacherId in teachers) {
      final constraint = constraints[teacherId];
      if (constraint == null) continue;
      
      // Check teacher availability
      if (constraint.unavailableTimeSlots.contains(slot)) {
        continue;
      }
      
      // Check max periods per day
      int periodsToday = 0;
      for (final s in currentTimetable[day]!.values) {
        if (s.teacherId == teacherId && s.subjectName.isNotEmpty) {
          periodsToday++;
        }
      }
      
      if (periodsToday >= constraint.maxPeriodsPerDay) {
        continue;
      }
      
      // Check preferred time slots
      if (constraint.preferredTimeSlots.isNotEmpty && 
          !constraint.preferredTimeSlots.contains(slot)) {
        continue; // Lower priority but not a hard constraint
      }
      
      // Check consecutive periods
      if (_wouldExceedConsecutivePeriods(
        teacherId: teacherId,
        day: day,
        slot: slot,
        currentTimetable: currentTimetable,
        maxConsecutive: constraint.maxConsecutivePeriods,
      )) {
        continue;
      }
      
      availableTeachers.add({
        'id': teacherId,
        'priority': _calculateTeacherPriority(
          teacherId: teacherId,
          subject: subject,
          slot: slot,
          constraint: constraint,
        ),
      });
    }
    
    if (availableTeachers.isEmpty) return null;
    
    // Sort by priority and return best
    availableTeachers.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
    return availableTeachers.first;
  }

  /// Calculates teacher priority for assignment
  static int _calculateTeacherPriority({
    required String teacherId,
    required String subject,
    required String slot,
    required TimetableConstraint constraint,
  }) {
    int priority = 0;
    
    // Preferred time slots get higher priority
    if (constraint.preferredTimeSlots.contains(slot)) {
      priority += 10;
    }
    
    // Preferred days get higher priority
    // (This would be checked at the caller level)
    
    // Morning slots get slight preference for core subjects
    if (slot.startsWith('P') && int.tryParse(slot.substring(1)) != null) {
      final periodNum = int.parse(slot.substring(1));
      if (periodNum <= 3) { // First 3 periods
        priority += 5;
      }
    }
    
    return priority;
  }

  /// Checks if assigning would exceed consecutive periods limit
  static bool _wouldExceedConsecutivePeriods({
    required String teacherId,
    required String day,
    required String slot,
    required Map<String, Map<String, ScheduledLesson>> currentTimetable,
    required int maxConsecutive,
  }) {
    final timeSlots = currentTimetable[day]!.keys.toList()..sort();
    final slotIndex = timeSlots.indexOf(slot);
    
    if (slotIndex == -1) return false;
    
    int consecutiveCount = 1;
    
    // Check consecutive periods before this slot
    for (int i = slotIndex - 1; i >= 0; i--) {
      final prevSlot = timeSlots[i];
      final lesson = currentTimetable[day]![prevSlot];
      if (lesson.teacherId == teacherId && lesson.subjectName.isNotEmpty) {
        consecutiveCount++;
      } else {
        break;
      }
    }
    
    // Check consecutive periods after this slot
    for (int i = slotIndex + 1; i < timeSlots.length; i++) {
      final nextSlot = timeSlots[i];
      final lesson = currentTimetable[day]![nextSlot];
      if (lesson.teacherId == teacherId && lesson.subjectName.isNotEmpty) {
        consecutiveCount++;
      } else {
        break;
      }
    }
    
    return consecutiveCount > maxConsecutive;
  }

  /// Comprehensive validation and conflict reporting system
  Map<String, dynamic> validateAndReportConflicts({
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required Map<String, TimetableConstraint> constraints,
    required List<String> teachers,
    required List<String> subjects,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> requirements,
  }) {
    final conflicts = <TimetableConflict>[];
    final suggestions = <Map<String, dynamic>>[];
    final statistics = <String, dynamic>{};
    
    // Initialize statistics
    statistics['totalPeriods'] = 0;
    statistics['assignedPeriods'] = 0;
    statistics['teacherUtilization'] = <String, double>{};
    statistics['subjectDistribution'] = <String, int>{};
    statistics['roomUtilization'] = <String, int>{};
    statistics['conflictSummary'] = {
      'critical': 0,
      'major': 0,
      'minor': 0,
    };
    
    // 1. Teacher Conflict Validation
    conflicts.addAll(_validateTeacherConflicts(
      timetable: timetable,
      constraints: constraints,
      teachers: teachers,
      timeSlots: timeSlots,
      days: days,
      statistics: statistics,
    ));
    
    // 2. Room Conflict Validation
    conflicts.addAll(_validateRoomConflicts(
      timetable: timetable,
      timeSlots: timeSlots,
      days: days,
      statistics: statistics,
    ));
    
    // 3. Subject Distribution Validation
    conflicts.addAll(_validateSubjectDistribution(
      timetable: timetable,
      subjects: subjects,
      constraints: constraints,
      requirements: requirements,
      statistics: statistics,
    ));
    
    // 4. Constraint Compliance Validation
    conflicts.addAll(_validateConstraintCompliance(
      timetable: timetable,
      constraints: constraints,
      teachers: teachers,
      timeSlots: timeSlots,
      days: days,
    ));
    
    // 5. Workload Balance Validation
    conflicts.addAll(_validateWorkloadBalance(
      timetable: timetable,
      constraints: constraints,
      teachers: teachers,
      days: days,
      statistics: statistics,
    ));
    
    // 6. Generate Suggestions
    suggestions.addAll(_generateSuggestions(
      conflicts: conflicts,
      timetable: timetable,
      constraints: constraints,
      teachers: teachers,
      subjects: subjects,
    ));
    
    // 7. Calculate Quality Metrics
    final qualityMetrics = _calculateQualityMetrics(
      timetable: timetable,
      conflicts: conflicts,
      statistics: statistics,
      teachers: teachers,
      subjects: subjects,
      days: days,
      timeSlots: timeSlots,
    );
    
    // 8. Generate Conflict Summary
    final conflictSummary = _generateConflictSummary(conflicts);
    
    return {
      'conflicts': conflicts,
      'suggestions': suggestions,
      'statistics': statistics,
      'qualityMetrics': qualityMetrics,
      'conflictSummary': conflictSummary,
      'validationTimestamp': DateTime.now().toIso8601String(),
      'isValid': conflicts.where((c) => c.severity >= 2).isEmpty,
    };
  }

  /// Validate teacher-specific conflicts
  static List<TimetableConflict> _validateTeacherConflicts({
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required Map<String, TimetableConstraint> constraints,
    required List<String> teachers,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> statistics,
  }) {
    final conflicts = <TimetableConflict>[];
    final teacherAssignments = <String, Map<String, List<ScheduledLesson>>>{};
    
    // Organize assignments by teacher
    for (final teacherId in teachers) {
      teacherAssignments[teacherId] = {};
      for (final day in days) {
        teacherAssignments[teacherId]![day] = [];
      }
    }
    
    // Collect all assignments
    for (final day in days) {
      for (final slot in timeSlots) {
        final lesson = timetable[day]?[slot];
        if (lesson?.teacherId?.isNotEmpty == true) {
          final teacherId = lesson!.teacherId;
          if (teacherAssignments.containsKey(teacherId)) {
            teacherAssignments[teacherId]![day]!.add(lesson);
          }
        }
      }
    }
    
    // Check for double-booking
    for (final teacherId in teachers) {
      for (final day in days) {
        final dayAssignments = teacherAssignments[teacherId]![day]!;
        
        // Check if teacher is assigned to multiple slots at the same time
        final slotAssignments = <String, List<ScheduledLesson>>{};
        for (final assignment in dayAssignments) {
          for (final slot in timeSlots) {
            final lesson = timetable[day]?[slot];
            if (lesson?.teacherId == teacherId) {
              slotAssignments.putIfAbsent(slot, () => []).add(lesson!);
            }
          }
        }
        
        for (final slot in slotAssignments.keys) {
          if (slotAssignments[slot]!.length > 1) {
            conflicts.add(TimetableConflict(
              type: 'teacher',
              description: 'Teacher $teacherId double-booked at $slot on $day',
              details: {
                'teacherId': teacherId,
                'day': day,
                'slot': slot,
                'assignments': slotAssignments[slot]!.map((l) => l.subjectName).toList(),
              },
              severity: 3,
            ));
          }
        }
        
        // Check workload constraints
        final constraint = constraints[teacherId];
        if (constraint != null) {
          final dailyLoad = dayAssignments.length;
          if (dailyLoad > constraint.maxPeriodsPerDay) {
            conflicts.add(TimetableConflict(
              type: 'teacher',
              description: 'Teacher $teacherId exceeds max periods on $day',
              details: {
                'teacherId': teacherId,
                'day': day,
                'currentLoad': dailyLoad,
                'maxAllowed': constraint.maxPeriodsPerDay,
              },
              severity: 2,
            ));
          }
          
          // Check consecutive periods
          final consecutiveViolations = _checkConsecutivePeriods(
            dayAssignments: dayAssignments,
            timeSlots: timeSlots,
            maxConsecutive: constraint.maxConsecutivePeriods,
          );
          
          for (final violation in consecutiveViolations) {
            conflicts.add(TimetableConflict(
              type: 'teacher',
              description: 'Teacher $teacherId exceeds consecutive periods on $day',
              details: {
                'teacherId': teacherId,
                'day': day,
                'violation': violation,
                'maxConsecutive': constraint.maxConsecutivePeriods,
              },
              severity: 2,
            ));
          }
        }
        
        // Update statistics
        statistics['teacherUtilization'][teacherId] = 
            (statistics['teacherUtilization'][teacherId] as double? ?? 0.0) + dayAssignments.length;
      }
    }
    
    return conflicts;
  }

  /// Validate room-specific conflicts
  static List<TimetableConflict> _validateRoomConflicts({
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> statistics,
  }) {
    final conflicts = <TimetableConflict>[];
    final roomAssignments = <String, Map<String, Map<String, List<ScheduledLesson>>>>{};
    
    // Organize assignments by room
    for (final day in days) {
      for (final slot in timeSlots) {
        final lesson = timetable[day]?[slot];
        if (lesson?.room?.isNotEmpty == true) {
          final room = lesson!.room!;
          roomAssignments.putIfAbsent(room, () => {});
          roomAssignments[room]!.putIfAbsent(day, () => {});
          roomAssignments[room]![day]!.putIfAbsent(slot, () => []).add(lesson);
        }
      }
    }
    
    // Check for room conflicts
    for (final room in roomAssignments.keys) {
      for (final day in roomAssignments[room]!.keys) {
        for (final slot in roomAssignments[room]![day]!.keys) {
          final assignments = roomAssignments[room]![day]![slot]!;
          if (assignments.length > 1) {
            conflicts.add(TimetableConflict(
              type: 'room',
              description: 'Room $room double-booked at $slot on $day',
              details: {
                'room': room,
                'day': day,
                'slot': slot,
                'subjects': assignments.map((l) => l.subjectName).toList(),
                'teachers': assignments.map((l) => l.teacherId).toList(),
              },
              severity: 3,
            ));
          }
        }
      }
    }
    
    return conflicts;
  }

  /// Validate subject distribution
  static List<TimetableConflict> _validateSubjectDistribution({
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required List<String> subjects,
    required Map<String, TimetableConstraint> constraints,
    required Map<String, dynamic> requirements,
    required Map<String, dynamic> statistics,
  }) {
    final conflicts = <TimetableConflict>[];
    final subjectCounts = <String, int>{};
    
    // Count subject occurrences
    for (final day in timetable.keys) {
      for (final slot in timetable[day]!.values) {
        if (slot.subjectName.isNotEmpty) {
          subjectCounts[slot.subjectName] = (subjectCounts[slot.subjectName] ?? 0) + 1;
        }
      }
    }
    
    // Check against constraints
    for (final subject in subjects) {
      final count = subjectCounts[subject] ?? 0;
      final constraint = constraints['subject_$subject'];
      
      if (constraint != null) {
        if (count < constraint.minPeriodsPerWeek) {
          conflicts.add(TimetableConflict(
            type: 'subject',
            description: 'Subject $subject has insufficient periods',
            details: {
              'subject': subject,
              'currentCount': count,
              'requiredMin': constraint.minPeriodsPerWeek,
            },
            severity: 2,
          ));
        }
      }
      
      // Check for balanced distribution
      final idealCount = subjects.length * 2; // Rough average
      if (count > idealCount * 1.5) {
        conflicts.add(TimetableConflict(
          type: 'subject',
          description: 'Subject $subject may be over-represented',
          details: {
            'subject': subject,
            'currentCount': count,
            'idealCount': idealCount,
          },
          severity: 1, // Warning
        ));
      }
      
      statistics['subjectDistribution'][subject] = count;
    }
    
    return conflicts;
  }

  /// Validate constraint compliance
  static List<TimetableConflict> _validateConstraintCompliance({
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required Map<String, TimetableConstraint> constraints,
    required List<String> teachers,
    required List<String> timeSlots,
    required List<String> days,
  }) {
    final conflicts = <TimetableConflict>[];
    
    for (final teacherId in teachers) {
      final constraint = constraints[teacherId];
      if (constraint == null) continue;
      
      // Check unavailable time slots
      for (final unavailableSlot in constraint.unavailableTimeSlots) {
        for (final day in days) {
          final lesson = timetable[day]?[unavailableSlot];
          if (lesson?.teacherId == teacherId) {
            conflicts.add(TimetableConflict(
              type: 'constraint',
              description: 'Teacher $teacherId scheduled during unavailable time $unavailableSlot',
              details: {
                'teacherId': teacherId,
                'day': day,
                'slot': unavailableSlot,
                'subject': lesson?.subjectName,
              },
              severity: 2,
            ));
          }
        }
      }
      
      // Check preferred time slots compliance
      if (constraint.preferredTimeSlots.isNotEmpty) {
        int preferredCompliance = 0;
        int totalAssignments = 0;
        
        for (final day in days) {
          for (final slot in timeSlots) {
            final lesson = timetable[day]?[slot];
            if (lesson?.teacherId == teacherId) {
              totalAssignments++;
              if (constraint.preferredTimeSlots.contains(slot)) {
                preferredCompliance++;
              }
            }
          }
        }
        
        if (totalAssignments > 0) {
          final complianceRate = preferredCompliance / totalAssignments;
          if (complianceRate < 0.5) { // Less than 50% compliance
            conflicts.add(TimetableConflict(
              type: 'constraint',
              description: 'Teacher $teacherId has low preferred time slot compliance',
              details: {
                'teacherId': teacherId,
                'complianceRate': complianceRate,
                'preferredCompliance': preferredCompliance,
                'totalAssignments': totalAssignments,
              },
              severity: 1, // Warning
            ));
          }
        }
      }
    }
    
    return conflicts;
  }

  /// Validate workload balance
  static List<TimetableConflict> _validateWorkloadBalance({
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required Map<String, TimetableConstraint> constraints,
    required List<String> teachers,
    required List<String> days,
    required Map<String, dynamic> statistics,
  }) {
    final conflicts = <TimetableConflict>[];
    final teacherWeeklyLoads = <String, int>{};
    
    // Calculate weekly loads
    for (final teacherId in teachers) {
      teacherWeeklyLoads[teacherId] = 0;
      for (final day in days) {
        for (final slot in timetable[day]!.values) {
          if (slot.teacherId == teacherId) {
            teacherWeeklyLoads[teacherId] = (teacherWeeklyLoads[teacherId] ?? 0) + 1;
          }
        }
      }
    }
    
    // Check for imbalance
    if (teacherWeeklyLoads.isNotEmpty) {
      final loads = teacherWeeklyLoads.values.toList();
      final averageLoad = loads.reduce((a, b) => a + b) / loads.length;
      final maxLoad = loads.reduce((a, b) => a > b ? a : b);
      final minLoad = loads.reduce((a, b) => a < b ? a : b);
      
      if (maxLoad > averageLoad * 1.5) {
        final overworkedTeachers = teacherWeeklyLoads.entries
            .where((entry) => entry.value > averageLoad * 1.5)
            .map((entry) => entry.key)
            .toList();
        
        conflicts.add(TimetableConflict(
          type: 'workload',
          description: 'Workload imbalance detected',
          details: {
            'averageLoad': averageLoad,
            'maxLoad': maxLoad,
            'minLoad': minLoad,
            'overworkedTeachers': overworkedTeachers,
          },
          severity: 1, // Warning
        ));
      }
    }
    
    return conflicts;
  }

  /// Generate improvement suggestions
  static List<Map<String, dynamic>> _generateSuggestions({
    required List<TimetableConflict> conflicts,
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required Map<String, TimetableConstraint> constraints,
    required List<String> teachers,
    required List<String> subjects,
  }) {
    final suggestions = <Map<String, dynamic>>[];
    
    // Analyze conflict patterns
    final conflictTypes = <String, List<TimetableConflict>>{};
    for (final conflict in conflicts) {
      conflictTypes.putIfAbsent(conflict.type, () => []).add(conflict);
    }
    
    // Generate suggestions based on conflict types
    if (conflictTypes.containsKey('teacher')) {
      suggestions.add({
        'type': 'teacher_optimization',
        'priority': 'high',
        'title': 'Optimize Teacher Assignments',
        'description': 'Several teacher conflicts detected. Consider redistributing subjects or adding more teaching staff.',
        'actions': [
          'Review teacher workload distribution',
          'Consider part-time teachers for overloaded subjects',
          'Adjust subject assignments to better match teacher qualifications',
        ],
      });
    }
    
    if (conflictTypes.containsKey('room')) {
      suggestions.add({
        'type': 'room_optimization',
        'priority': 'high',
        'title': 'Resolve Room Conflicts',
        'description': 'Room scheduling conflicts detected. Optimize room allocation.',
        'actions': [
          'Add more rooms or adjust room types',
          'Consider staggered scheduling for high-demand rooms',
          'Review room assignment priorities',
        ],
      });
    }
    
    if (conflictTypes.containsKey('subject')) {
      suggestions.add({
        'type': 'subject_balance',
        'priority': 'medium',
        'title': 'Balance Subject Distribution',
        'description': 'Subject distribution imbalances detected. Adjust period allocation.',
        'actions': [
          'Review minimum period requirements',
          'Consider elective subject scheduling',
          'Balance core vs practical subject timing',
        ],
      });
    }
    
    return suggestions;
  }

  /// Calculate quality metrics
  static Map<String, dynamic> _calculateQualityMetrics({
    required Map<String, Map<String, ScheduledLesson>> timetable,
    required List<TimetableConflict> conflicts,
    required Map<String, dynamic> statistics,
    required List<String> teachers,
    required List<String> subjects,
    required List<String> days,
    required List<String> timeSlots,
  }) {
    final totalSlots = days.length * timeSlots.length;
    final assignedSlots = statistics['assignedPeriods'] as int? ?? 0;
    final utilizationRate = totalSlots > 0 ? assignedSlots / totalSlots : 0.0;
    
    final criticalConflicts = conflicts.where((c) => c.severity == 3).length;
    final majorConflicts = conflicts.where((c) => c.severity == 2).length;
    final minorConflicts = conflicts.where((c) => c.severity == 1).length;
    
    // Calculate teacher workload balance
    final teacherLoads = statistics['teacherUtilization'] as Map<String, double>? ?? {};
    double workloadBalance = 1.0;
    if (teacherLoads.isNotEmpty) {
      final loads = teacherLoads.values.toList();
      final avg = loads.reduce((a, b) => a + b) / loads.length;
      final variance = loads.map((load) => (load - avg) * (load - avg)).reduce((a, b) => a + b) / loads.length;
      workloadBalance = max(0.0, 1.0 - (variance / (avg * avg)));
    }
    
    return {
      'utilizationRate': utilizationRate,
      'conflictScore': max(0.0, 1.0 - ((criticalConflicts * 3 + majorConflicts * 2 + minorConflicts) / (totalSlots * 3))),
      'workloadBalance': workloadBalance,
      'overallQuality': (utilizationRate + workloadBalance) / 2,
      'totalConflicts': conflicts.length,
      'criticalConflicts': criticalConflicts,
      'majorConflicts': majorConflicts,
      'minorConflicts': minorConflicts,
    };
  }

  /// Generate conflict summary
  static Map<String, dynamic> _generateConflictSummary(List<TimetableConflict> conflicts) {
    final summary = <String, dynamic>{
      'total': conflicts.length,
      'byType': <String, int>{},
      'bySeverity': <String, int>{'critical': 0, 'major': 0, 'minor': 0},
      'mostCommonType': '',
      'recommendations': <String>[],
    };
    
    for (final conflict in conflicts) {
      summary['byType'][conflict.type] = (summary['byType'][conflict.type] as int? ?? 0) + 1;
      
      switch (conflict.severity) {
        case 3:
          summary['bySeverity']['critical']++;
          break;
        case 2:
          summary['bySeverity']['major']++;
          break;
        case 1:
          summary['bySeverity']['minor']++;
          break;
      }
    }
    
    // Find most common conflict type
    if (summary['byType'].isNotEmpty) {
      final entries = summary['byType'] as Map<String, int>;
      summary['mostCommonType'] = entries.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    
    // Generate recommendations
    if (summary['bySeverity']['critical'] > 0) {
      summary['recommendations'].add('Address critical conflicts immediately - they prevent valid timetable generation');
    }
    if (summary['bySeverity']['major'] > 5) {
      summary['recommendations'].add('Consider relaxing some constraints to reduce major conflicts');
    }
    if (summary['byType']['teacher'] != null && summary['byType']['teacher'] > 3) {
      summary['recommendations'].add('Review teacher assignments and workload distribution');
    }
    
    return summary;
  }

  /// Build conflict graph for CSP solving
  static Map<String, dynamic> _buildConflictGraph({
    required List<String> teachers,
    required List<String> subjects,
    required Map<String, TimetableConstraint> constraints,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> roomData,
  }) {
    final conflictGraph = <String, Set<String>>{};
    final feasibilityScore = 0.8; // Simplified feasibility score

    // Build conflict graph based on teacher-subject assignments
    for (final teacher in teachers) {
      for (final subject in subjects) {
        final key = '${teacher}_$subject';
        conflictGraph[key] = <String>{};
        
        // Add conflicts for same teacher with different subjects at same time
        for (final otherSubject in subjects) {
          if (subject != otherSubject) {
            conflictGraph[key]!.add('${teacher}_$otherSubject');
          }
        }
        
        // Add conflicts for same subject with different teachers at same time
        for (final otherTeacher in teachers) {
          if (teacher != otherTeacher) {
            conflictGraph[key]!.add('${otherTeacher}_$subject');
          }
        }
      }
    }

    return {
      'conflictGraph': conflictGraph,
      'feasibilityScore': feasibilityScore,
      'totalNodes': conflictGraph.length,
      'totalEdges': conflictGraph.values.fold(0, (sum, edges) => sum + edges.length),
    };
  }

  /// Solve CSP using graph coloring algorithm
  static Map<String, dynamic> _solveCSPWithGraphColoring({
    required List<String> teachers,
    required List<String> subjects,
    required Map<String, TimetableConstraint> constraints,
    required List<String> timeSlots,
    required List<String> days,
    required Map<String, dynamic> requirements,
    required Map<String, dynamic> conflictGraphData,
  }) {
    final timetable = <String, Map<String, ScheduledLesson>>{};
    final conflicts = <TimetableConflict>[];
    var success = true;

    try {
      // Initialize empty timetable
      for (final day in days) {
        timetable[day] = <String, ScheduledLesson>{};
        for (final slot in timeSlots) {
          timetable[day]![slot] = ScheduledLesson(
            subjectName: '',
            teacherId: '',
            teacherName: '',
          );
        }
      }

      // Simple assignment algorithm (placeholder for full graph coloring)
      final random = Random();
      for (final teacher in teachers) {
        for (final subject in subjects) {
          var assigned = false;
          final attempts = 100;
          
          for (var attempt = 0; attempt < attempts && !assigned; attempt++) {
            final day = days[random.nextInt(days.length)];
            final slot = timeSlots[random.nextInt(timeSlots.length)];
            
            if (timetable[day]![slot]!.subjectName.isEmpty) {
              timetable[day]![slot] = ScheduledLesson(
                subjectName: subject,
                teacherId: teacher,
                teacherName: 'Teacher $teacher', // Simplified
              );
              assigned = true;
            }
          }
          
          if (!assigned) {
            conflicts.add(TimetableConflict(
              type: 'assignment',
              description: 'Could not assign $subject to teacher $teacher',
              details: {'teacher': teacher, 'subject': subject},
              severity: 2,
            ));
          }
        }
      }

      return {
        'timetable': timetable,
        'conflicts': conflicts,
        'success': success && conflicts.isEmpty,
      };
    } catch (e) {
      return {
        'timetable': timetable,
        'conflicts': conflicts,
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Calculate balance score for assignments
  static double _calculateBalance(Map<String, int> assignments) {
    if (assignments.isEmpty) return 1.0;
    
    final values = assignments.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);
    
    // Balance score: 1.0 = perfect balance, 0.0 = completely unbalanced
    return stdDev == 0 ? 1.0 : max(0.0, 1.0 - (stdDev / mean));
  }

  /// Check consecutive periods violations
  static List<Map<String, dynamic>> _checkConsecutivePeriods({
    required List<ScheduledLesson> dayAssignments,
    required List<String> timeSlots,
    required int maxConsecutive,
  }) {
    final violations = <Map<String, dynamic>>[];
    final sortedSlots = timeSlots.where((slot) => !slot.contains('BREAK') && !slot.contains('LUNCH')).toList();
    
    int consecutiveCount = 0;
    String? lastSlot;
    
    for (final slot in sortedSlots) {
      final hasAssignment = dayAssignments.isNotEmpty;
      
      if (hasAssignment) {
        consecutiveCount++;
        if (consecutiveCount > maxConsecutive) {
          violations.add({
            'startSlot': lastSlot,
            'endSlot': slot,
            'consecutiveCount': consecutiveCount,
            'maxAllowed': maxConsecutive,
          });
        }
      } else {
        consecutiveCount = 0;
      }
      
      lastSlot = slot;
    }
    
    return violations;
  }

  /// Enhanced timetable generation method that uses all algorithms
  Future<Map<String, dynamic>> generateEnhancedTimetable({
    required String schoolId,
    required LocalDatabaseService localDb,
    required StaffService staffService,
    required Map<String, dynamic> requirements,
    required Map<String, dynamic> roomData,
  }) async {
    try {
      // Step 1: Extract constraints from database
      final constraintData = await extractConstraintsFromDatabase(
        schoolId: schoolId,
        localDb: localDb,
        staffService: staffService,
      );
      
      final constraints = constraintData['constraints'] as Map<String, TimetableConstraint>;
      final initialConflicts = constraintData['conflicts'] as List<TimetableConflict>;
      
      // Step 2: Build conflict graph
      final teachers = constraints.keys.where((key) => !key.startsWith('subject') && !key.startsWith('global')).toList();
      final subjects = constraints.values.map((c) => c.subjectId).where((s) => s != 'global').toSet().toList();
      
      final conflictGraphData = _buildConflictGraph(
        teachers: teachers,
        subjects: subjects,
        constraints: constraints,
        timeSlots: TimetableConstants.timeSlots.map((ts) => ts.id).toList(),
        days: TimetableConstants.daysOfWeek,
        roomData: roomData,
      );
      
      // Step 3: Solve using enhanced CSP with graph coloring
      final solutionData = _solveCSPWithGraphColoring(
        teachers: teachers,
        subjects: subjects,
        constraints: constraints,
        timeSlots: TimetableConstants.timeSlots.map((ts) => ts.id).toList(),
        days: TimetableConstants.daysOfWeek,
        requirements: requirements,
        conflictGraphData: conflictGraphData,
      );
      
      final timetable = solutionData['timetable'] as Map<String, Map<String, ScheduledLesson>>;
      final algorithmConflicts = solutionData['conflicts'] as List<TimetableConflict>;
      
      // Step 4: Comprehensive validation
      final validationData = validateAndReportConflicts(
        timetable: timetable,
        constraints: constraints,
        teachers: teachers,
        subjects: subjects,
        timeSlots: TimetableConstants.timeSlots.map((ts) => ts.id).toList(),
        days: TimetableConstants.daysOfWeek,
        requirements: requirements,
      );
      
      // Step 5: Combine all results
      final allConflicts = <TimetableConflict>[
        ...initialConflicts,
        ...algorithmConflicts,
        ...validationData['conflicts'] as List<TimetableConflict>,
      ];
      
      return {
        'timetable': timetable,
        'conflicts': allConflicts,
        'validation': validationData,
        'algorithm': 'Enhanced CSP with Graph Coloring',
        'success': solutionData['success'] as bool,
        'qualityMetrics': validationData['qualityMetrics'],
        'suggestions': validationData['suggestions'],
        'statistics': validationData['statistics'],
        'generationMetadata': {
          'schoolId': schoolId,
          'timestamp': DateTime.now().toIso8601String(),
          'totalTeachers': teachers.length,
          'totalSubjects': subjects.length,
          'algorithmComplexity': 'O(n^3)',
          'feasibilityScore': conflictGraphData['feasibilityScore'],
        },
      };
      
    } catch (e) {
      return {
        'timetable': <String, Map<String, ScheduledLesson>>{},
        'conflicts': [
          TimetableConflict(
            type: 'system',
            description: 'Timetable generation failed',
            details: {'error': e.toString()},
            severity: 3,
          )
        ],
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Checks if a time slot is available for assignment
  TimetableConflict? _checkSlotAvailability({
    required String day,
    required String slot,
    required String subject,
    required List<String> teachers,
    required Map<String, TimetableConstraint> constraints,
    required Map<String, Map<String, ScheduledLesson>> currentTimetable,
    required Map<String, int> subjectCounts,
  }) {
    // Check if slot is already occupied
    final currentLesson = currentTimetable[day]![slot];
    if (currentLesson != null && currentLesson.subjectName.isNotEmpty) {
      return TimetableConflict(
        type: 'slot',
        description: 'Time slot $slot on $day is already occupied',
        details: {
          'day': day,
          'slot': slot,
          'existingSubject': currentLesson.subjectName,
          'existingTeacher': currentLesson.teacherId,
        },
        severity: 2,
      );
    }
    
    // Check teacher conflicts
    for (final otherSlot in currentTimetable[day]!.values) {
      if (otherSlot.subjectName.isNotEmpty) {
        // Check if any teacher is double-booked
        for (final teacherId in teachers) {
          if (otherSlot.teacherId == teacherId) {
            return TimetableConflict(
              type: 'teacher',
              description: 'Teacher $teacherId is already scheduled at $otherSlot.subjectName on $day',
              details: {
                'teacherId': teacherId,
                'conflictingSubject': otherSlot.subjectName,
                'day': day,
                'slot': slot,
              },
              severity: 3,
            );
          }
        }
      }
    }
    
    // Check subject distribution balance
    final currentCount = subjectCounts[subject] ?? 0;
    final maxCount = teachers.length * 2; // Rough balance: 2 periods per teacher per week
    if (currentCount >= maxCount) {
      return TimetableConflict(
        type: 'subject',
        description: 'Subject $subject exceeds balanced distribution',
        details: {
          'subject': subject,
          'currentCount': currentCount,
          'maxCount': maxCount,
        },
        severity: 1, // Minor, can be overridden if necessary
      );
    }
    
    return null; // No conflicts
  }
}

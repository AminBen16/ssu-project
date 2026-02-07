/// Represents a single weekly entry within a scheme of work.
class WeeklySchemeEntry {
  int weekNumber;
  final String topic;
  final String objectives;
  final String activities;
  final String references;

  WeeklySchemeEntry({
    required this.weekNumber,
    required this.topic,
    required this.objectives,
    required this.activities,
    required this.references,
  });

  // Convert a WeeklySchemeEntry instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'topic': topic,
      'objectives': objectives,
      'activities': activities,
      'references': references,
    };
  }

  // Create a WeeklySchemeEntry instance from a Map
  factory WeeklySchemeEntry.fromMap(Map<String, dynamic> map) {
    return WeeklySchemeEntry(
      weekNumber: map['weekNumber'] as int? ?? 0,
      topic: map['topic'] as String? ?? '',
      objectives: map['objectives'] as String? ?? '',
      activities: map['activities'] as String? ?? '',
      references: map['references'] as String? ?? '',
    );
  }
}

/// Represents a full scheme of work for a term.
class SchemeOfWork {
  final String? id;
  final String teacherId;
  final String subject;
  final String className;
  final String term;
  final int year;
  final List<WeeklySchemeEntry> weeklyEntries;
  final dynamic updatedAt; // Can be Timestamp or FieldValue

  SchemeOfWork({
    this.id,
    required this.teacherId,
    required this.subject,
    required this.className,
    required this.term,
    required this.year,
    required this.weeklyEntries,
    this.updatedAt,
  });

  // Convert a SchemeOfWork instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'subject': subject,
      'className': className,
      'term': term,
      'year': year,
      'weeklyEntries': weeklyEntries.map((e) => e.toMap()).toList(),
      'updatedAt': updatedAt,
    };
  }

  // Create a SchemeOfWork instance from a Map
  factory SchemeOfWork.fromMap(Map<String, dynamic> map) {
    return SchemeOfWork(
      id: map['id'] as String?,
      teacherId: map['teacherId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      className: map['className'] as String? ?? '',
      term: map['term'] as String? ?? '',
      year: map['year'] as int? ?? DateTime.now().year,
      weeklyEntries: (map['weeklyEntries'] as List<dynamic>?)
              ?.map((e) => WeeklySchemeEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: map['updatedAt'],
    );
  }
}

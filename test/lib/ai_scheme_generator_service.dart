import 'package:flutter/foundation.dart';
import 'package:test/models/scheme_of_work_model.dart';

class AISchemeGeneratorService {
  Future<List<WeeklySchemeEntry>> generateScheme({
    required String subject,
    required String className,
    required String term,
    required int year,
    required String country,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // This is a placeholder. In a real application, you would make an API call
    // to a generative AI service (like Google's Gemini API) here.
    debugPrint(
        'Generating scheme for $subject, $className, $term, $year in $country');

    // Return some dummy data that matches the expected structure.
    return List.generate(12, (index) {
      final week = index + 1;
      return WeeklySchemeEntry(
        weekNumber: week,
        topic: 'Topic for Week $week',
        objectives: 'Students will be able to...',
        activities: '1. Activity A\n2. Activity B',
        references: 'Notes for week $week',
      );
    });
  }
}

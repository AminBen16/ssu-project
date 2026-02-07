import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:test/models/scheme_of_work_model.dart';
import 'package:test/services/gemini_service.dart';

class AISchemeGeneratorService {
  final _geminiService = GeminiService();

  Future<List<WeeklySchemeEntry>> generateScheme({
    required String subject,
    required String className,
    required String term,
    required int year,
    required String country,
  }) async {
    final prompt = """
    Generate a 12-week scheme of work for the subject "$subject" for class "$className" during "$term, $year" based on the $country curriculum.
    The output MUST be a valid JSON array of objects. Each object in the array represents a week and must have the following keys with string values: "topic", "objectives", "activities", "references".

    Example format for a single week object:
    {
      "topic": "Introduction to Algebra",
      "objectives": "Students will be able to define variables and form simple algebraic expressions.",
      "activities": "Teacher explanation, group work on worksheets, Q&A session.",
      "references": "Textbook Chapter 3, Online math resources."
    }

    Provide the full 12-week JSON array. Do not include any text or markdown formatting before or after the JSON array.
    """;

    final response = await _geminiService.generateText(prompt);

    if (response == null || response.isEmpty) {
      throw Exception('AI failed to generate a response.');
    }

    try {
      // Clean the response to ensure it's just the JSON array
      final jsonString = response
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> jsonList = jsonDecode(jsonString);

      return jsonList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        final schemeEntry = WeeklySchemeEntry.fromMap(item);

        schemeEntry.weekNumber = index + 1;
        return schemeEntry;
      }).toList();
    } catch (e) {
      debugPrint('Error parsing AI scheme of work response: $e');
      debugPrint('Raw AI Response:\n$response');
      throw Exception(
          'Failed to parse the generated scheme. The AI returned an invalid format.');
    }
  }
}

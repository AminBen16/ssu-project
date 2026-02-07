import 'package:test/services/gemini_service.dart';

class AILessonPlanService {
  final _geminiService = GeminiService();

  Future<String> generateLessonPlan({
    required String subject,
    required String topic,
    required String classLevel,
    required String duration,
    required String country,
  }) async {
    final prompt = """
    Generate a detailed lesson plan for the subject "$subject" on the topic "$topic".
    The target audience is class "$classLevel" in $country.
    The lesson duration is $duration.
    The lesson plan should be well-structured with clear sections for:
    1. Learning Objectives
    2. Materials and Resources
    3. Lesson Activities (with approximate timings)
    4. Assessment/Evaluation Methods

    Please provide a comprehensive and practical plan.
    """;

    final response = await _geminiService.generateText(prompt);

    if (response == null || response.isEmpty) {
      throw Exception('AI failed to generate a lesson plan.');
    }

    return response;
  }
}

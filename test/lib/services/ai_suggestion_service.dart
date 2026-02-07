import 'package:test/services/gemini_service.dart';

class AISuggestionService {
  final _geminiService = GeminiService();

  Future<String?> getPostSuggestion(String eventType) async {
    final prompt = """
    You are a social media manager for a school.
    Write a short, engaging social media post for the following event type: "$eventType".
    The post should be positive, professional, and suitable for platforms like Facebook or Twitter.
    Keep it under 280 characters. Do not include hashtags.
    """;
    return await _geminiService.generateText(prompt);
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:test/services/gemini_service.dart';
import 'package:test/models/ai_assistant_intent.dart';

/// A service to handle voice command processing and execution.
class AIAssistantService {
  final _geminiService = GeminiService();

  String _getCommandPrompt(String text, String? contextHint) {
    // Base prompt structure for custom rule-based assistant
    String prompt = '''
You are a rule-based AI assistant for a school management app. Your task is to understand user commands and extract information into a structured JSON format.
The user said: "$text"
The app has predefined lists of classes, subjects, and terms. Try to match user's speech to closest item in these lists.
Example Classes: "Senior 1 A", "Senior 2 B", "Senior 4"
Example Subjects: "Mathematics", "English Language", "Physics"
Example Terms: "Term 1", "Term 2", "Term 3".
The current year is ${DateTime.now().year}.

If intent is not clear or does not match a possible intent, return a JSON object with intent "unknown".
Output ONLY JSON object.
''';

    // Add context-specific instructions
    switch (contextHint) {
      case 'marks_entry':
        prompt += '''
The user is on the 'Marks Entry' screen. A primary intent is 'record_marks'.
Entities for 'record_marks' are: 'student_name', 'paper_name', and 'scores' (an object with 'bot', 'mot', 'eot' as string values).
Example: "For John Doe, paper one, BOT is 2, MOT is 3, EOT is 85" -> {"intent": "record_marks", "entities": {"student_name": "John Doe", "paper_name": "Paper 1", "scores": {"bot": "2", "mot": "3", "eot": "85"}}}
''';
        break;
      default: // Dashboard or general context
        prompt += '''
A primary intent is 'navigate'.
Entities for 'navigate' are: 'screen' (e.g., "marks_entry", "lesson_plans") and 'arguments' (an object with initial values like 'class_name', 'subject_name').
Example: "Open marks entry for Senior 1" -> {"intent": "navigate", "entities": {"screen": "marks_entry", "arguments": {"class_name": "Senior 1"}}}
''';
        break;
    }
    return prompt;
  }

  /// Uses Gemini to understand the user's command and returns a structured intent.
  Future<AssistantIntent> parseCommand(String text,
      {String? contextHint}) async {
    final prompt = _getCommandPrompt(text, contextHint);

    try {
      final response = await _geminiService.generateText(prompt);
      if (response == null || response.isEmpty) return UnknownIntent();

      // Clean the response to ensure it's valid JSON
      final jsonString =
          response.replaceAll('```json', '').replaceAll('```', '').trim();
      final intentData = jsonDecode(jsonString) as Map<String, dynamic>;
      final intent = intentData['intent'];
      final entities = intentData['entities'] as Map<String, dynamic>?;

      switch (intent) {
        case 'navigate':
          return NavigateIntent(
            screen: entities?['screen'] as String? ?? '',
            arguments: entities?['arguments'] as Map<String, dynamic>? ?? {},
          );
        case 'record_marks':
          return RecordMarksIntent(
            studentName: entities?['student_name'] as String? ?? '',
            paperName: entities?['paper_name'] as String? ?? '',
            scores: Map<String, String>.from(entities?['scores'] ?? {}),
          );
        default:
          return UnknownIntent();
      }
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      return UnknownIntent(message: 'I had trouble understanding that.');
    }
  }

  /// Uses Gemini to understand a command related to an image.
  Future<AssistantIntent> parseImageCommand(
      {required Uint8List imageBytes, required String command}) async {
    final prompt = '''
You are a helpful AI assistant. The user has provided an image and a voice command.
Analyze the image and respond to the user's command: "$command".
If the image contains a math problem, solve it step-by-step.
If you cannot fulfill the request, explain why.
Provide the answer as plain text.
''';

    try {
      final response = await _geminiService.generateTextFromImageAndPrompt(
          prompt: prompt, imageBytes: imageBytes);
      return SolveImageIntent(
          solutionText: response ?? 'I could not find a solution.');
    } catch (e) {
      debugPrint('Error parsing image command: $e');
      return UnknownIntent(message: 'I had trouble analyzing the image.');
    }
  }
}

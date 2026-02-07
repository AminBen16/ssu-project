import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A service class for local AI model interactions.
///
/// This class provides methods for interacting with local AI models,
/// removing dependencies on external AI services.
class GeminiService {
  /// Generates a text response from a local model endpoint (e.g., Ollama with Gemma).
  Future<String?> generateTextLocal(String prompt, String url) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'gemma', // Or your specific local model name
          'prompt': prompt,
          'stream': false, // Get the full response at once
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['response'] as String?;
      } else {
        debugPrint(
            'Local model request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error calling local model: $e');
      return null;
    }
  }

  /// Generates text response (stub implementation for compatibility).
  Future<String?> generateText(String prompt) async {
    // Since external AI is removed, return a placeholder response
    debugPrint('generateText called with prompt: $prompt');
    return 'This is a placeholder response. AI features have been disabled.';
  }

  /// Generates text from image and prompt (stub implementation for compatibility).
  Future<String?> generateTextFromImageAndPrompt(
      {required String prompt, required Uint8List imageBytes}) async {
    // Since external AI is removed, return a placeholder response
    debugPrint(
        'generateTextFromImageAndPrompt called with prompt: $prompt and image bytes length: ${imageBytes.length}');
    return 'This is a placeholder response for image analysis. AI features have been disabled.';
  }
}

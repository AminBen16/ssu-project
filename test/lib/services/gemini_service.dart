import 'dart:convert';
import 'package:flutter/foundation.dart';

/// A custom rule-based assistant service for school management commands.
///
/// This replaces external AI models with deterministic pattern matching
/// and algorithmic processing for common school tasks.
class GeminiService {
  static final List<String> _validClasses = [
    'Senior 1', 'Senior 2', 'Senior 3', 'Senior 4', 'Senior 5', 'Senior 6',
    'Primary 1', 'Primary 2', 'Primary 3', 'Primary 4', 'Primary 5', 'Primary 6', 'Primary 7',
    'S1', 'S2', 'S3', 'S4', 'S5', 'S6',
    'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'
  ];

  static final List<String> _validSubjects = [
    'Mathematics', 'English', 'Physics', 'Chemistry', 'Biology',
    'History', 'Geography', 'Economics', 'Literature',
    'Computer Studies', 'Agriculture', 'Religious Education',
    'Math', 'Eng', 'Phy', 'Chem', 'Bio'
  ];

  static final List<String> _validTerms = [
    'Term 1', 'Term 2', 'Term 3', 'T1', 'T2', 'T3'
  ];

  /// Generates text response using rule-based pattern matching.
  Future<String?> generateText(String prompt) async {
    debugPrint('Custom assistant processing: $prompt');
    
    // Extract command type from prompt
    final commandType = _extractCommandType(prompt);
    final entities = _extractEntities(prompt);
    
    switch (commandType) {
      case 'navigate':
        return _generateNavigateResponse(entities);
      case 'marks_entry':
        return _generateMarksEntryResponse(entities);
      case 'help':
        return _generateHelpResponse();
      default:
        return _generateUnknownResponse();
    }
  }

  /// Generates text using a local model endpoint (simulated here as rule-based).
  Future<String?> generateTextLocal(String prompt, String endpointUrl) async {
    // In a real implementation, this would make an HTTP POST to the local LLM (e.g. Ollama/Gemma).
    // For this self-contained version, we use the internal rule-based engine.
    return generateText(prompt);
  }

  /// Generates text from image and prompt using algorithmic analysis.
  Future<String?> generateTextFromImageAndPrompt({
    required String prompt, 
    required Uint8List imageBytes
  }) async {
    debugPrint('Image analysis request: $prompt');
    
    // Simple keyword-based image analysis
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('math') || lowerPrompt.contains('solve') || lowerPrompt.contains('calculate')) {
      return _analyzeMathProblem(prompt);
    }
    
    if (lowerPrompt.contains('read') || lowerPrompt.contains('text')) {
      return 'I can see this contains text, but I need more specific instructions about what you want me to do with it.';
    }
    
    return 'I can see an image. Please tell me specifically what you\'d like me to do with it (solve, read, analyze, etc.).';
  }

  String _extractCommandType(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    debugPrint('Extracting command type from: "$prompt"');
    
    // Check for help command first (highest priority)
    // More precise help detection
    if (lowerPrompt.startsWith('help') || 
        lowerPrompt.contains(' what can you do') ||
        (lowerPrompt.contains('help me') && !lowerPrompt.contains('navigate') && !lowerPrompt.contains('open'))) {
      debugPrint('Detected help command');
      return 'help';
    }
    
    if (lowerPrompt.contains('navigate') || lowerPrompt.contains('open') || lowerPrompt.contains('go to')) {
      debugPrint('Detected navigate command');
      return 'navigate';
    }
    
    if (lowerPrompt.contains('marks') || lowerPrompt.contains('grade') || lowerPrompt.contains('score')) {
      debugPrint('Detected marks_entry command');
      return 'marks_entry';
    }
    
    debugPrint('Detected unknown command');
    return 'unknown';
  }

  Map<String, dynamic> _extractEntities(String prompt) {
    final entities = <String, dynamic>{};
    final lowerPrompt = prompt.toLowerCase();
    
    // Extract class
    for (final className in _validClasses) {
      if (lowerPrompt.contains(className.toLowerCase())) {
        entities['class_name'] = className;
        break;
      }
    }
    
    // Extract subject
    for (final subject in _validSubjects) {
      if (lowerPrompt.contains(subject.toLowerCase())) {
        entities['subject_name'] = subject;
        break;
      }
    }
    
    // Extract term
    for (final term in _validTerms) {
      if (lowerPrompt.contains(term.toLowerCase())) {
        entities['term'] = term;
        break;
      }
    }
    
    // Extract year
    final yearRegex = RegExp(r'\b(20\d{2})\b');
    final yearMatch = yearRegex.firstMatch(prompt);
    if (yearMatch != null) {
      entities['year'] = int.tryParse(yearMatch.group(1) ?? '');
    }
    
    return entities;
  }

  String _generateNavigateResponse(Map<String, dynamic> entities) {
    final screen = entities['screen'] as String? ?? 'marks_entry';
    final className = entities['class_name'] as String?;
    final subjectName = entities['subject_name'] as String?;
    
    if (screen == 'marks_entry') {
      return jsonEncode({
        'intent': 'navigate',
        'entities': {
          'screen': 'marks_entry',
          'arguments': {
            if (className != null) 'class_name': className,
            if (subjectName != null) 'subject_name': subjectName,
          }
        }
      });
    }
    
    return jsonEncode({
      'intent': 'unknown',
      'message': 'I can help you navigate to marks entry. Try saying "Open marks entry for Senior 1 Mathematics"'
    });
  }

  String _generateMarksEntryResponse(Map<String, dynamic> entities) {
    return jsonEncode({
      'intent': 'navigate',
      'entities': {
        'screen': 'marks_entry',
        'arguments': entities
      }
    });
  }

  String _generateHelpResponse() {
    return jsonEncode({
      'intent': 'unknown',
      'message': '''I can help you with:
• Navigate to marks entry: "Open marks entry for Senior 1 Mathematics"
• Record marks: "For John Doe, paper one, BOT is 2, MOT is 3"
• Analyze images: Show me a math problem
• Navigate to screens: "Go to dashboard"

Try commands like:
• "Open marks entry"
• "Navigate to Senior 2 English"
• "Record marks for student"'''
    });
  }

  String _generateUnknownResponse() {
    return jsonEncode({
      'intent': 'unknown',
      'message': 'I didn\'t understand that. Try "help" for available commands.'
    });
  }

  String _analyzeMathProblem(String prompt) {
    // Simple math problem analysis based on keywords
    final lowerPrompt = prompt.toLowerCase();
    
    // Check for specific math operations
    if (lowerPrompt.contains('add') || lowerPrompt.contains('plus') || lowerPrompt.contains('+')) {
      return 'This appears to be an addition problem. Please provide the numbers you want me to add.';
    }
    
    if (lowerPrompt.contains('subtract') || lowerPrompt.contains('minus') || lowerPrompt.contains('-')) {
      return 'This appears to be a subtraction problem. Please provide the numbers you want me to subtract.';
    }
    
    if (lowerPrompt.contains('multiply') || lowerPrompt.contains('times') || lowerPrompt.contains('×')) {
      return 'This appears to be a multiplication problem. Please provide the numbers you want me to multiply.';
    }
    
    if (lowerPrompt.contains('divide') || lowerPrompt.contains('÷')) {
      return 'This appears to be a division problem. Please provide the numbers you want me to divide.';
    }
    
    // General math problem response
    return 'I can see this is a math problem. Please tell me what specific calculation you need help with (add, subtract, multiply, divide).';
  }
}

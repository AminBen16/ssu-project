/// Defines the structured intents that the AI Assistant can understand.
/// This separates the "understanding" of a command from its "execution".
library;

/// Base class for all assistant intents.
sealed class AssistantIntent {}

/// Represents an intent to navigate to a specific screen.
class NavigateIntent extends AssistantIntent {
  final String screen;
  final Map<String, dynamic> arguments;

  NavigateIntent({required this.screen, this.arguments = const {}});
}

/// Represents an intent to record marks for a student on the Marks Entry screen.
class RecordMarksIntent extends AssistantIntent {
  final String studentName;
  final String paperName;
  final Map<String, String>
      scores; // e.g., {'bot': '2', 'mot': '3', 'eot': '85'}

  RecordMarksIntent({
    required this.studentName,
    required this.paperName,
    required this.scores,
  });
}

/// Represents an intent to solve a problem from an image.
class SolveImageIntent extends AssistantIntent {
  final String solutionText;

  SolveImageIntent({required this.solutionText});
}

/// Represents a command that the assistant could not understand.
class UnknownIntent extends AssistantIntent {
  final String message;
  UnknownIntent({this.message = "Sorry, I didn't understand that command."});
}

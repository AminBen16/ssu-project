// IMPORTANT: Add this file to your .gitignore to keep your API key secret!

// These keys are now loaded from environment variables.
// Pass them during build:
// flutter run --dart-define=GEMINI_API_KEY=your_key --dart-define=ELEVENLABS_API_KEY=your_key ...

const String geminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

const String elevenLabsApiKey =
    String.fromEnvironment('ELEVENLABS_API_KEY', defaultValue: '');

const String stabilityApiKey =
    String.fromEnvironment('STABILITY_API_KEY', defaultValue: '');

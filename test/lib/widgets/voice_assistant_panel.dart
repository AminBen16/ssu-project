import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test/services/ai_assistant_service.dart';
import 'package:test/models/ai_assistant_intent.dart';
import 'package:test/models/marks_entry_screen.dart';

class VoiceAssistantPanel extends StatefulWidget {
  /// An optional hint about the current screen to give the AI more context.
  final String? contextHint;
  const VoiceAssistantPanel({super.key, this.contextHint});

  @override
  State<VoiceAssistantPanel> createState() => _VoiceAssistantPanelState();
}

class _VoiceAssistantPanelState extends State<VoiceAssistantPanel> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AIAssistantService _assistantService = AIAssistantService();
  final ImagePicker _picker = ImagePicker();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusMessage = 'Press the button and start speaking.';
  String _transcribedText = '';
  Uint8List? _capturedImageBytes;
  String? _aiResponseText;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initializes speech-to-text and text-to-speech services.
  void _initializeServices() async {
    try {
      final hasSpeech = await _speechToText.initialize();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);

      if (mounted) {
        setState(() {
          _isInitialized = hasSpeech;
          if (!hasSpeech) {
            _statusMessage = 'Speech recognition is not available.';
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing voice services: $e');
      if (mounted) {
        setState(() => _statusMessage = 'Error initializing voice services.');
      }
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      try {
        await _flutterTts.speak(text);
        debugPrint('Speaking: $text');
      } catch (e) {
        debugPrint('TTS Error: $e');
        // Fallback: show message visually if TTS fails
        if (mounted) {
          setState(() => _statusMessage = text);
        }
      }
    }
  }

  void _startListening() async {
    if (!_isInitialized || !_speechToText.isAvailable) {
      setState(() => _statusMessage = 'Speech recognition not available.');
      _speak(_statusMessage);
      return;
    }
    setState(() {
      _aiResponseText = null; // Clear previous AI response
      _isListening = true;
      _statusMessage = 'Listening...';
      _transcribedText = '';
    });
    _speak(_statusMessage);
    
    try {
      await _speechToText.listen(
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          onDevice: true,
        ),
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
            debugPrint('Transcribed: ${result.recognizedWords}');
          });
          if (result.finalResult) {
            _stopListeningAndProcess();
          }
        },
        onSoundLevelChange: (level) {
          // Optional: Visual feedback for sound level
          if (mounted && level > 0.5) {
            setState(() {
              // Could add visual indicator here if needed
            });
          }
        },
        // FIXED: Removed onDone parameter - not supported in speech_to_text API
      );
    } catch (e) {
      debugPrint('Speech recognition exception: $e');
      setState(() {
        _isListening = false;
        _statusMessage = 'Speech recognition failed. Please try again.';
      });
      _speak('Speech recognition failed. Please try again.');
    }
  }

  Future<void> _captureImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _capturedImageBytes = bytes;
        _statusMessage = 'Image captured! Now ask a question.';
        _aiResponseText = null;
      });
      _speak(_statusMessage);
    }
  }

  void _stopListeningAndProcess() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _statusMessage = 'Processing command...';
      });
      _speak(_statusMessage);

      if (_transcribedText.isNotEmpty) {
        AssistantIntent intent;
        try {
          // Check if there's an image to process with the command
          if (_capturedImageBytes != null) {
            intent = await _assistantService.parseImageCommand(
              imageBytes: _capturedImageBytes!,
              command: _transcribedText,
            );
          } else {
            // No image, process as a regular voice command
            intent = await _assistantService.parseCommand(
              _transcribedText,
              contextHint: widget.contextHint,
            );
          }
          
          if (mounted) {
            await _handleIntent(intent);
          }
        } catch (e) {
          debugPrint('Intent processing error: $e');
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Error processing command. Please try again.';
          });
          _speak('Error processing command. Please try again.');
        }
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'No speech detected. Try again.';
        });
        _speak(_statusMessage);
      }
    } catch (e) {
      debugPrint('Stop listening error: $e');
      setState(() {
        _isListening = false;
        _isProcessing = false;
        _statusMessage = 'Error stopping listening. Please try again.';
      });
      _speak('Error stopping listening. Please try again.');
    }
  }

  Future<void> _handleIntent(AssistantIntent intent) async {
    // Capture context-dependent objects before an async gap.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!mounted) return;

    switch (intent) {
      case NavigateIntent():
        // For now, we only handle navigation to marks entry. This can be expanded.
        if (intent.screen == 'marks_entry') {
          const message = 'Navigating to marks entry...';
          setState(() => _statusMessage = message);
          await _speak(message);

          if (!mounted) return;
          navigator.pop(); // Close the panel first
          navigator.push(
            MaterialPageRoute(
              builder: (_) => DetailedMarksEntryScreen(
                initialClassName: intent.arguments['class_name'] as String?,
                initialSubjectName: intent.arguments['subject_name'] as String?,
                initialTerm: intent.arguments['term'] as String?,
                initialYear: (intent.arguments['year'] as num?)?.toInt(),
              ),
            ),
          );
        } else if (intent.screen == 'dashboard') {
          const message = 'Navigating to dashboard...';
          setState(() => _statusMessage = message);
          await _speak(message);
          
          if (!mounted) return;
          navigator.pop(); // Close panel
          // Already on dashboard, no navigation needed
        } else if (intent.screen == 'help') {
          const message = 'Here are the commands I can help you with...';
          setState(() => _statusMessage = message);
          await _speak(message);
          
          // Show help dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Voice Assistant Help'),
                content: const Text(
                  'Available commands:\n\n'
                  '• "Open marks entry" - Navigate to marks entry\n'
                  '• "Open marks entry for [class] [subject]" - Navigate with pre-filled data\n'
                  '• "Go to dashboard" - Return to dashboard\n'
                  '• "Help" - Show this help message\n'
                  '• Take a photo and say "Solve this" - Analyze image\n\n'
                  'Examples:\n'
                  '• "Open marks entry for Senior 1 Mathematics"\n'
                  '• "Navigate to Term 2"\n'
                  '• "Record marks for John Doe"',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          }
        } else {
          final message = "Sorry, I can't navigate to '${intent.screen}' yet.";
          setState(() => _statusMessage = message);
          await _speak(message);
        }
        break;
      case RecordMarksIntent():
        // Pop the panel and return the intent data to the calling screen.
        navigator.pop(intent);
        break;
      case SolveImageIntent():
        setState(() {
          _aiResponseText = intent.solutionText;
          _statusMessage = 'Here is the result:';
        });
        await _speak(intent.solutionText); // Speak the solution
        break;
      case UnknownIntent():
        setState(() => _statusMessage = intent.message);
        await _speak(intent.message); // Speak the error message
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(intent.message),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            _statusMessage,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_capturedImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.memory(
                _capturedImageBytes!,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          if (_aiResponseText != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SelectableText(
                _aiResponseText!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          if (_transcribedText.isNotEmpty)
            Text(
              '"$_transcribedText"',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                iconSize: 30,
                tooltip: 'Analyze an image',
                onPressed: _isListening || _isProcessing ? null : _captureImage,
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTapDown: !_isInitialized || _isProcessing
                    ? null
                    : (_) => _startListening(),
                onTapUp: !_isInitialized || _isProcessing
                    ? null
                    : (_) => _stopListeningAndProcess(),
                onTapCancel: !_isInitialized || _isProcessing
                    ? null
                    : () => _stopListeningAndProcess(),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _isListening
                      ? Colors.red.shade700
                      : Theme.of(context).colorScheme.primary,
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _isInitialized ? Icons.mic : Icons.mic_off,
                              color: Colors.white,
                              size: 40,
                            ),
                            // Audio level indicator
                            if (_isListening)
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 20),
              // Button to clear the image, balances the UI.
              _capturedImageBytes != null
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 30,
                      tooltip: 'Remove image',
                      onPressed: () => setState(() {
                        _capturedImageBytes = null;
                        _statusMessage =
                            'Image removed. Press the button and start speaking.';
                      }),
                    )
                  : const SizedBox(width: 48), // Matches IconButton width
            ],
          ),
          const SizedBox(height: 20),
          const Text('Hold to speak, release to process.'),
        ],
      ),
    );
  }
}

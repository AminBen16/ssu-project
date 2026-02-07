import 'package:flutter/material.dart';
import '../models/domain_models.dart';
import '../services/communication_service.dart';

class VoiceNoteRecorder extends StatefulWidget {
  final String receiverId;
  final CommunicationService communicationService;

  const VoiceNoteRecorder({
    super.key,
    required this.receiverId,
    required this.communicationService,
  });

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  bool _isRecording = false;
  DateTime? _startTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopAndSend(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Colors.blue,
          shape: BoxShape.circle,
          boxShadow: _isRecording
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 5,
                  )
                ]
              : null,
        ),
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _startTime = DateTime.now();
    });
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;

    final duration = DateTime.now().difference(_startTime ?? DateTime.now());

    setState(() {
      _isRecording = false;
    });

    if (duration.inMilliseconds < 500) {
      return;
    }

    // Simulation of audio content since audio package is not available in context
    const String audioContent = "AUDIO_DATA_BASE64_PLACEHOLDER";

    try {
      await widget.communicationService.sendMessage(
        receiverId: widget.receiverId,
        content: audioContent,
        type: MessageType.audio,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice note: $e')),
        );
      }
    }
  }
}

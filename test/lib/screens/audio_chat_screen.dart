import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AudioChatScreen extends StatefulWidget {
  final io.Socket? socket;
  const AudioChatScreen({super.key, this.socket});

  @override
  State<AudioChatScreen> createState() => _AudioChatScreenState();
}

class _AudioChatScreenState extends State<AudioChatScreen> {
  final String _sessionId = const Uuid().v4();
  final _audioRecorder = FlutterSoundRecorder();
  final _audioPlayer = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  io.Socket? _socket;
  StreamSubscription? _recorderSubscription;

  @override
  void initState() {
    super.initState();
    _initAudioRecorder();
    _initAudioPlayer();
    _connectSocket();
  }

  Future<void> _initAudioRecorder() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
    await _audioRecorder.openRecorder();
  }

  Future<void> _initAudioPlayer() async {
    await _audioPlayer.openPlayer();
  }

  void _connectSocket() {
    try {
      // Configure socket options for reconnection
      _socket = widget.socket ?? io.io('http://localhost:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnectionAttempts': 5, // example: try to reconnect 5 times
        'reconnectionDelay':
            3000, // example: wait 3 seconds before reconnecting
      });

      _socket!.onConnect((_) {
        debugPrint('Connected to Socket.IO server');
      });

      _socket!.on('audio', (data) {
        debugPrint('Received audio data');
        _playAudio(data);
      });

      _socket!.onDisconnect((_) {
        debugPrint('Disconnected from Socket.IO server');
      });

      _socket!.onError((err) {
        debugPrint('Socket.IO error: $err');
      });

      _socket!.onReconnect((attempt) {
        debugPrint('Reconnected after $attempt attempts');
      });

      _socket!.on('reconnecting', (attempt) {
        debugPrint('Attempting to reconnect... (Attempt: $attempt)');
      });
      _socket!.connect();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _startRecording() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_$_sessionId.aac';

      // Use a stream to send audio data in real-time
      _recorderSubscription = _audioRecorder.onProgress!.listen((recordData) {
        if (recordData.decibels != null) {
          // You can also emit volume levels for visual feedback
          _socket!.emit('audioStream', recordData.decibels);
        }
      }, onError: (e) => debugPrint('recorder stream error: $e'));

      await _audioRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stopRecorder();
    _recorderSubscription?.cancel(); // Cancel the stream

    setState(() {
      _isRecording = false;
    });

    if (_recordingPath != null) {
      await _sendAudio(_recordingPath!);
    }
  }

  Future<void> _sendAudio(String path) async {
    try {
      debugPrint('Sending audio: $path');
      File audioFile = File(path);
      Uint8List audioBytes = await audioFile.readAsBytes();
      debugPrint('Audio byte count: ${audioBytes.length}');
      _socket!.emit('audio', audioBytes);
    } catch (e) {
      debugPrint('Error sending audio: $e');
    }
  }

  Future<void> _playAudio(Uint8List data) async {
    try {
      await _audioPlayer.startPlayer(
        fromDataBuffer: data,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    _socket?.disconnect();
    _recorderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Chat'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            if (_isPlaying) const Text('Playing audio...'),
          ],
        ),
      ),
    );
  }
}

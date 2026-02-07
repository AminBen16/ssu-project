import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:test/screens/audio_chat_screen.dart';

import 'audio_chat_screen_test.mocks.dart';

@GenerateMocks(
    [FlutterSoundRecorder, FlutterSoundPlayer, io.Socket, StreamSubscription])
void main() {
  late MockFlutterSoundRecorder mockAudioRecorder;
  late MockFlutterSoundPlayer mockAudioPlayer;
  late MockSocket mockSocket;

  setUp(() {
    mockAudioRecorder = MockFlutterSoundRecorder();
    mockAudioPlayer = MockFlutterSoundPlayer();
    mockSocket = MockSocket();

    // Mock the onProgress stream
    when(mockAudioRecorder.onProgress)
        .thenAnswer((_) => Stream.fromIterable([]));

    // Stub the socket methods with appropriate return types
    when(mockSocket.on(any, any)).thenAnswer((_) => () {});
    when(mockSocket.connect()).thenReturn(mockSocket as dynamic);
    when(mockSocket.emit(any, any)).thenAnswer((_) {});
    when(mockSocket.disconnect()).thenReturn(mockSocket);
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AudioChatScreen(socket: mockSocket),
      ),
    );
  }

  testWidgets('AudioChatScreen initial UI', (WidgetTester tester) async {
    // Arrange
    when(mockAudioRecorder.openRecorder()).thenAnswer((_) => Future.value());
    when(mockAudioPlayer.openPlayer()).thenAnswer((_) => Future.value());

    // Act
    await pumpWidget(tester);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Audio Chat'), findsOneWidget);
    expect(find.text('Start Recording'), findsOneWidget);
    expect(find.text('Playing audio...'), findsNothing);
  });

  testWidgets('should start and stop recording', (WidgetTester tester) async {
    // Arrange
    when(mockAudioRecorder.openRecorder()).thenAnswer((_) => Future.value());
    when(mockAudioPlayer.openPlayer()).thenAnswer((_) => Future.value());
    when(mockAudioRecorder.startRecorder(
      toFile: anyNamed('toFile'),
      codec: anyNamed('codec'),
    )).thenAnswer((_) => Future.value());
    when(mockAudioRecorder.stopRecorder()).thenAnswer((_) => Future.value());

    await pumpWidget(tester);
    await tester.pumpAndSettle();

    // Act & Assert: Start recording
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    expect(find.text('Stop Recording'), findsOneWidget);
    verify(mockAudioRecorder.startRecorder(
      toFile: anyNamed('toFile'),
      codec: Codec.aacADTS,
    )).called(1);

    // Act & Assert: Stop recording
    await tester.tap(find.text('Stop Recording'));
    await tester.pump();

    expect(find.text('Start Recording'), findsOneWidget);
    verify(mockAudioRecorder.stopRecorder()).called(1);
  });

  testWidgets('should show "Playing audio..." when audio is received',
      (WidgetTester tester) async {
    // Arrange
    when(mockAudioRecorder.openRecorder()).thenAnswer((_) => Future.value());
    when(mockAudioPlayer.openPlayer()).thenAnswer((_) => Future.value());
    when(mockAudioPlayer.startPlayer(
      fromDataBuffer: anyNamed('fromDataBuffer'),
      codec: anyNamed('codec'),
      whenFinished: anyNamed('whenFinished'),
    )).thenAnswer((_) => Future.value());

    await pumpWidget(tester);
    await tester.pumpAndSettle();

    // Simulate receiving audio from the socket
    final audioHandler =
        verify(mockSocket.on('audio', captureAny)).captured.single;
    audioHandler([]); // Pass empty data

    await tester.pump();

    // Assert
    expect(find.text('Playing audio...'), findsOneWidget);
  });
}

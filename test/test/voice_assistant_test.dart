import 'package:flutter_test/flutter_test.dart';
import 'package:test/services/ai_assistant_service.dart';
import 'dart:typed_data';

void main() {
  group('Custom Voice Assistant Tests', () {
    late AIAssistantService assistantService;

    setUp(() {
      assistantService = AIAssistantService();
    });

    test('Should parse navigation to marks entry command', () async {
      final intent = await assistantService.parseCommand('Open marks entry for Senior 1 Mathematics');
      
      expect(intent.runtimeType.toString(), 'NavigateIntent');
      expect((intent as dynamic).screen, 'marks_entry');
      expect((intent as dynamic).arguments['class_name'], 'Senior 1');
      expect((intent as dynamic).arguments['subject_name'], 'Mathematics');
    });

    test('Should parse help command', () async {
      final intent = await assistantService.parseCommand('Help me');
      
      expect(intent.runtimeType.toString(), 'UnknownIntent');
      expect((intent as dynamic).message, contains('I can help you with'));
    });

    test('Should parse simple marks entry command', () async {
      final intent = await assistantService.parseCommand('Open marks entry');
      
      expect(intent.runtimeType.toString(), 'NavigateIntent');
      expect((intent as dynamic).screen, 'marks_entry');
    });

    test('Should handle unknown command gracefully', () async {
      final intent = await assistantService.parseCommand('Do something random');
      
      expect(intent.runtimeType.toString(), 'UnknownIntent');
      expect((intent as dynamic).message, contains('didn\'t understand'));
    });

    test('Should analyze math problem image', () async {
      final intent = await assistantService.parseImageCommand(
        imageBytes: Uint8List.fromList([1, 2, 3]), // dummy bytes
        command: 'Solve this math problem',
      );
      
      expect(intent.runtimeType.toString(), 'SolveImageIntent');
      expect((intent as dynamic).solutionText, contains('math problem'));
    });
  });
}

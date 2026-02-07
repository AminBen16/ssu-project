import 'package:flutter/material.dart';
import 'package:test/widgets/loading_button.dart';

/// A screen that provides an AI-powered chat interface for assistance.
class AiContentStudioScreen extends StatefulWidget {
  const AiContentStudioScreen({super.key});

  @override
  State<AiContentStudioScreen> createState() => _AiContentStudioScreenState();
}

class _AiContentStudioScreenState extends State<AiContentStudioScreen> {
  final _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });
    _textController.clear();

    // Simulate a network call to an AI service
    await Future.delayed(const Duration(seconds: 2));

    // A mock response from the AI
    const aiResponse =
        'Based on the current fee structure, the outstanding balance for the next term is expected to be UGX 550,000. Would you like a detailed breakdown?';

    setState(() {
      _messages.add({'role': 'assistant', 'content': aiResponse});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Fee Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      message['content']!,
                      style: TextStyle(
                        color: isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration:
                        const InputDecoration(hintText: 'Ask about fees...'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                LoadingButton(
                    isLoading: _isLoading,
                    onPressed: _sendMessage,
                    icon: Icons.send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

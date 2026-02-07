import 'dart:async';
import '../models/domain_models.dart';

abstract class MessageStorage {
  Future<void> saveMessage(Message message);
  Future<Message?> getMessage(String id);
  Future<List<Message>> getMessagesForPeer(String peerId);
  Future<List<Message>> getAllMessages();
  Future<void> updateMessageStatus(String id, DeliveryStatus status);
  Future<void> deleteMessage(String id);
  Stream<List<Message>> getMessagesStream(String peerId);
  Future<void> close();
}

class InMemoryMessageStorage implements MessageStorage {
  final Map<String, Message> _messages = {};
  final _controller = StreamController<void>.broadcast();

  @override
  Future<void> saveMessage(Message message) async {
    _messages[message.id] = message;
    _notify();
  }

  @override
  Future<Message?> getMessage(String id) async {
    return _messages[id];
  }

  @override
  Future<List<Message>> getMessagesForPeer(String peerId) async {
    final list = _messages.values
        .where((m) => m.senderId == peerId || m.receiverId == peerId)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<List<Message>> getAllMessages() async {
    return _messages.values.toList();
  }

  @override
  Future<void> updateMessageStatus(String id, DeliveryStatus status) async {
    final message = _messages[id];
    if (message != null) {
      _messages[id] = message.copyWith(status: status);
      _notify();
    }
  }

  @override
  Future<void> deleteMessage(String id) async {
    _messages.remove(id);
    _notify();
  }

  @override
  Stream<List<Message>> getMessagesStream(String peerId) async* {
    yield await getMessagesForPeer(peerId);
    await for (final _ in _controller.stream) {
      yield await getMessagesForPeer(peerId);
    }
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

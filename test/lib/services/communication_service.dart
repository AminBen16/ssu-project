import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../models/domain_models.dart';
import '../models/crypto_utils.dart';
import 'message_storage.dart';
import 'transport_manager.dart';

class CommunicationService {
  final MessageStorage _storage;
  final TransportManager _transport;
  final PeerDiscovery _discovery;
  final String _localDeviceId;
  final String _encryptionKey;

  final StreamController<List<Peer>> _peersController =
      StreamController.broadcast();
  List<Peer> _knownPeers = [];

  StreamSubscription? _transportSub;
  StreamSubscription? _discoverySub;

  CommunicationService({
    required MessageStorage storage,
    required TransportManager transport,
    required PeerDiscovery discovery,
    required String localDeviceId,
    required String encryptionKey,
  })  : _storage = storage,
        _transport = transport,
        _discovery = discovery,
        _localDeviceId = localDeviceId,
        _encryptionKey = encryptionKey;

  Future<void> initialize() async {
    _transportSub = _transport.incomingPayloads.listen(_handleIncomingPayload);
    _discoverySub = _discovery.detectedPeers.listen(_handlePeersDetected);
    await _discovery.startDiscovery();
  }

  Stream<List<Peer>> get peersStream => _peersController.stream;

  List<Peer> get currentPeers => List.unmodifiable(_knownPeers);

  Future<void> sendMessage({
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final msgId = _generateId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Store locally as plaintext for the sender
    final message = Message(
      id: msgId,
      senderId: _localDeviceId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      status: DeliveryStatus.pending,
      type: type,
      isEncrypted: false,
    );

    await _storage.saveMessage(message);

    await _attemptSend(message);
  }

  Future<void> retryMessage(String messageId) async {
    final message = await _storage.getMessage(messageId);
    if (message == null) return;
    if (message.senderId != _localDeviceId) return;

    await _storage.updateMessageStatus(messageId, DeliveryStatus.pending);
    await _attemptSend(message);
  }

  Future<void> _attemptSend(Message message) async {
    try {
      // Encrypt for transmission
      final encryptedContent =
          CryptoUtils().encrypt(message.content, _encryptionKey);

      final transmissionMessage = message.copyWith(
        content: encryptedContent,
        isEncrypted: true,
      );

      final payloadMap = {
        'type': 'MESSAGE',
        'data': transmissionMessage.toMap(),
      };

      final payloadJson = json.encode(payloadMap);

      if (message.receiverId == 'BROADCAST') {
        await _transport.broadcastPayload(payloadJson);
      } else {
        await _transport.sendPayload(message.receiverId, payloadJson);
      }

      await _storage.updateMessageStatus(message.id, DeliveryStatus.sent);
    } catch (e) {
      await _storage.updateMessageStatus(message.id, DeliveryStatus.failed);
    }
  }

  Future<void> _handleIncomingPayload(TransportPayload payload) async {
    try {
      final map = json.decode(payload.content) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'MESSAGE') {
        final data = map['data'] as Map<String, dynamic>;
        var message = Message.fromMap(data);

        // Decrypt if needed
        if (message.isEncrypted) {
          try {
            final decrypted =
                CryptoUtils().decrypt(message.content, _encryptionKey);
            message = message.copyWith(
              content: decrypted,
              isEncrypted: false,
            );
          } catch (e) {
            message = message.copyWith(
              metadata: 'Decryption failed: $e',
            );
          }
        }

        // Filter for me or broadcast
        if (message.receiverId == _localDeviceId ||
            message.receiverId == 'BROADCAST') {
          // Check if we already have it to avoid duplicates (idempotency)
          final existing = await _storage.getMessage(message.id);
          if (existing == null) {
            message = message.copyWith(status: DeliveryStatus.delivered);
            await _storage.saveMessage(message);
          }
        }
      }
    } catch (e) {
      // Ignore malformed
    }
  }

  void _handlePeersDetected(List<Peer> peers) {
    _knownPeers = peers;
    if (!_peersController.isClosed) {
      _peersController.add(_knownPeers);
    }
  }

  String _generateId() {
    return const Uuid().v4();
  }

  Future<void> dispose() async {
    await _transportSub?.cancel();
    await _discoverySub?.cancel();
    await _discovery.stopDiscovery();
    await _peersController.close();
  }
}

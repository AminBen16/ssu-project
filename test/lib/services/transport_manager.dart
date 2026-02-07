import 'dart:async';
import '../models/domain_models.dart';

class TransportPayload {
  final String senderId;
  final String content;

  const TransportPayload({
    required this.senderId,
    required this.content,
  });
}

abstract class TransportManager {
  Stream<TransportPayload> get incomingPayloads;
  Future<void> sendPayload(String targetDeviceId, String payload);
  Future<void> broadcastPayload(String payload);
  Future<void> dispose();
}

abstract class PeerDiscovery {
  Stream<List<Peer>> get detectedPeers;
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> dispose();
}

class LocalTransportManager implements TransportManager {
  final StreamController<TransportPayload> _controller =
      StreamController.broadcast();
  final String localDeviceId;

  LocalTransportManager(this.localDeviceId);

  @override
  Stream<TransportPayload> get incomingPayloads => _controller.stream;

  @override
  Future<void> sendPayload(String targetDeviceId, String payload) async {
    if (targetDeviceId == localDeviceId) {
      _controller.add(TransportPayload(
        senderId: localDeviceId,
        content: payload,
      ));
    }
  }

  @override
  Future<void> broadcastPayload(String payload) async {
    _controller.add(TransportPayload(
      senderId: localDeviceId,
      content: payload,
    ));
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  void simulateIncoming(String senderId, String payload) {
    if (!_controller.isClosed) {
      _controller.add(TransportPayload(
        senderId: senderId,
        content: payload,
      ));
    }
  }
}

class LocalPeerDiscovery implements PeerDiscovery {
  final StreamController<List<Peer>> _controller = StreamController.broadcast();
  Timer? _discoveryTimer;
  final List<Peer> _simulatedPeers = [];

  @override
  Stream<List<Peer>> get detectedPeers => _controller.stream;

  @override
  Future<void> startDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_simulatedPeers.isEmpty) {
        _simulatedPeers.add(Peer(
          id: 'peer-sim-1',
          deviceId: 'device-sim-1',
          name: 'Simulated Neighbor',
          isOnline: true,
          lastSeen: now,
        ));
      } else {
        final p = _simulatedPeers[0];
        _simulatedPeers[0] = p.copyWith(lastSeen: now);
      }
      if (!_controller.isClosed) {
        _controller.add(List.from(_simulatedPeers));
      }
    });
  }

  @override
  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _simulatedPeers.clear();
    if (!_controller.isClosed) {
      _controller.add([]);
    }
  }

  @override
  Future<void> dispose() async {
    _discoveryTimer?.cancel();
    await _controller.close();
  }
}

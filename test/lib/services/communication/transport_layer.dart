import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/services/communication/messaging_interface.dart';

/// Base class for all transport layers
abstract class BaseTransportLayer implements TransportLayer {
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  bool _isActive = false;
  NetworkStatus _status = NetworkStatus.offline;

  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  NetworkStatus get status => _status;

  @override
  Future<void> initialize() async {
    // Common initialization
  }

  @override
  Future<void> start() async {
    _isActive = true;
    _status = NetworkStatus.connecting;
    _updateStatus();
  }

  @override
  Future<void> stop() async {
    _isActive = false;
    _status = NetworkStatus.offline;
    await _dataController.close();
    _updateStatus();
  }

  void emitData(String data) {
    if (_isActive && !_dataController.isClosed) {
      _dataController.add(data);
    }
  }

  void _updateStatus([NetworkStatus? newStatus]) {
    _status = newStatus ??
        (_isActive ? NetworkStatus.connected : NetworkStatus.offline);
  }
}

/// Mesh transport layer using Bluetooth and Wi-Fi Direct
class MeshTransportLayer extends BaseTransportLayer {
  final MeshPlatformChannels _platformChannels;
  final BasePeerDiscovery _peerDiscovery;

  MeshTransportLayer(this._platformChannels, this._peerDiscovery);

  @override
  String get id => 'mesh_transport';
  @override
  TransportType get type => TransportType.mesh;
  @override
  int get priority => 10;

  @override
  Future<void> initialize() async {
    await _platformChannels.initialize();
    _platformChannels.dataReceiveStream.listen(emitData);
    _platformChannels.statusStream.listen((meshStatus) {
      _updateStatus(meshStatus.isConnected
          ? NetworkStatus.connected
          : NetworkStatus.offline);
    });
  }

  @override
  Future<void> start() async {
    await super.start();
    await _platformChannels.startPeerDiscovery();
    await _peerDiscovery.startDiscovery();
    _updateStatus(NetworkStatus.connecting);
  }

  @override
  Future<void> stop() async {
    await _platformChannels.stopPeerDiscovery();
    await _peerDiscovery.stopDiscovery();
    await super.stop();
  }

  @override
  Future<bool> sendData(String data, String targetDeviceId) async {
    return await _platformChannels.sendDataToPeer(targetDeviceId, data);
  }

  @override
  Future<bool> isAvailable() async {
    final meshStatus = await _platformChannels.getMeshStatus();
    return meshStatus?.isEnabled == true && meshStatus!.connectedPeersCount > 0;
  }
}

/// LAN transport layer
class LanTransportLayer extends BaseTransportLayer {
  final LanPeerDiscovery _peerDiscovery;

  LanTransportLayer(this._peerDiscovery);

  @override
  String get id => 'lan_transport';
  @override
  TransportType get type => TransportType.lan;
  @override
  int get priority => 5;

  @override
  Future<void> start() async {
    await super.start();
    await _peerDiscovery.startDiscovery();
    _updateStatus(NetworkStatus.connected);
  }

  @override
  Future<void> stop() async {
    await _peerDiscovery.stopDiscovery();
    await super.stop();
  }

  @override
  Future<bool> sendData(String data, String targetDeviceId) async {
    try {
      // Check if target device is in discovered peers
      final peers = await _peerDiscovery.getDiscoveredPeers();
      final targetPeer = peers.where((peer) => peer.deviceId == targetDeviceId);
      if (targetPeer.isEmpty) {
        return false; // Target device not found
      }

      final targetPeerInfo = targetPeer.first;

      // Establish TCP connection to target device
      final socket = await Socket.connect(
        targetPeerInfo.ipAddress,
        targetPeerInfo.port ?? 8080, // Default port for LAN communication
        timeout: const Duration(seconds: 5),
      );

      try {
        // Send data with length prefix for proper framing
        final dataBytes = utf8.encode(data);
        final lengthBytes = ByteData(4)
          ..setUint32(0, dataBytes.length, Endian.big);
        socket.add(lengthBytes.buffer.asUint8List());
        socket.add(dataBytes);

        // Wait for acknowledgment
        await socket.flush();
        await socket.timeout(const Duration(seconds: 2)).first;

        return true;
      } finally {
        await socket.close();
      }
    } catch (e) {
      // Log error but don't throw - return false to indicate failure
      print('LAN transport send failed: $e');
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if there are any discovered peers
      final peers = await _peerDiscovery.getDiscoveredPeers();
      return peers.isNotEmpty;
    } catch (e) {
      return false; // Return false on error instead of always true
    }
  }
}

/// Internet transport layer using WebSocket
class InternetTransportLayer extends BaseTransportLayer {
  final WebSocketConnection _connection;

  InternetTransportLayer(this._connection);

  @override
  String get id => 'internet_transport';
  @override
  TransportType get type => TransportType.internet;
  @override
  int get priority => 1;

  @override
  Future<void> initialize() async {
    _connection.dataStream.listen(emitData);
  }

  @override
  Future<void> start() async {
    await super.start();
    await _connection.connect();
    _updateStatus(NetworkStatus.connected);
  }

  @override
  Future<void> stop() async {
    await _connection.disconnect();
    await super.stop();
  }

  @override
  Future<bool> sendData(String data, String targetDeviceId) async {
    await _connection.sendData(data);
    return true;
  }

  @override
  Future<bool> isAvailable() async {
    return _connection.isConnected;
  }
}

/// Manager for multiple transport layers
class DefaultTransportManager implements TransportManager {
  final List<TransportLayer> _transports;
  final StreamController<String> _combinedDataController =
      StreamController<String>.broadcast();

  DefaultTransportManager(this._transports);

  @override
  Stream<String> get dataStream => _combinedDataController.stream;

  @override
  Future<void> start() async {
    for (final transport in _transports) {
      await transport.initialize();
      await transport.start();
      transport.dataStream.listen((data) {
        _combinedDataController.add(data);
      });
    }
  }

  @override
  Future<void> stop() async {
    for (final transport in _transports) {
      await transport.stop();
    }
    await _combinedDataController.close();
  }

  @override
  Future<void> sendData(String data) async {
    for (final transport in _transports) {
      if (await transport.isAvailable()) {
        try {
          await transport.sendData(data, '');
          return;
        } catch (e) {
          continue;
        }
      }
    }
    throw Exception('No transport available');
  }

  @override
  Future<NetworkStatus> getNetworkStatus() async {
    for (final transport in _transports) {
      if (await transport.isAvailable()) {
        return transport.status;
      }
    }
    return NetworkStatus.offline;
  }
}

/// WebSocket connection stub
class WebSocketConnection {
  final String url;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  bool _isConnected = false;

  WebSocketConnection(this.url);

  Stream<String> get dataStream => _dataController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    _isConnected = true;
  }

  Future<void> disconnect() async {
    _isConnected = false;
  }

  Future<void> sendData(String data) async {}
}

/// Peer discovery base
abstract class BasePeerDiscovery implements PeerDiscovery {
  final StreamController<List<Peer>> _peerController =
      StreamController<List<Peer>>.broadcast();

  @override
  Stream<List<Peer>> get peerStream =>
      _peerController.stream; // Fixed return type

  @override
  Future<List<Peer>> getDiscoveredPeers() async => [];

  @override
  Future<void> initialize() async {}
}

class MeshPeerDiscovery extends BasePeerDiscovery {
  final MeshPlatformChannels _channels;
  MeshPeerDiscovery(this._channels);
  @override
  Future<void> startDiscovery() async => await _channels.startPeerDiscovery();
  @override
  Future<void> stopDiscovery() async => await _channels.stopPeerDiscovery();
}

class LanPeerDiscovery extends BasePeerDiscovery {
  @override
  Future<void> startDiscovery() async {}
  @override
  Future<void> stopDiscovery() async {}
}

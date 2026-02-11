import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/domain_models.dart';


enum TransportType {
  bluetooth,
  wifiDirect,
}

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

/// Bluetooth LE Transport Manager using flutter_blue_plus
/// Integrates real Bluetooth LE communication for offline messaging
class BluetoothTransportManager implements TransportManager {
  final StreamController<TransportPayload> _controller =
      StreamController.broadcast();
  final String localDeviceId;
  fbp.FlutterBluePlus? _flutterBlue;
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _txCharacteristic;
  fbp.BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  BluetoothTransportManager(this.localDeviceId);

  @override
  Stream<TransportPayload> get incomingPayloads => _controller.stream;

  Future<void> initialize() async {
    try {
      _flutterBlue = fbp.FlutterBluePlus();
      // Request permissions and enable Bluetooth
      await fbp.FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint('Bluetooth initialization failed: $e');
    }
  }

  @override
  Future<void> sendPayload(String targetDeviceId, String payload) async {
    if (_txCharacteristic != null && _connectedDevice != null) {
      try {
        final data = utf8.encode(payload);
        await _txCharacteristic!.write(data);
      } catch (e) {
        debugPrint('Failed to send Bluetooth payload: $e');
      }
    }
  }

  @override
  Future<void> broadcastPayload(String payload) async {
    // Bluetooth LE doesn't support true broadcasting, send to connected device
    await sendPayload('', payload);
  }

  Future<void> startScanning() async {
    if (_flutterBlue == null) return;

    _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (result.device.platformName.isNotEmpty) {
          // Connect to discovered device
          _connectToDevice(result.device);
        }
      }
    });

    await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
  }

  Future<void> _connectToDevice(fbp.BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;

      // Discover services and characteristics
      final services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == '0000180f-0000-1000-8000-00805f9b34fb') {
          // Custom service UUID
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() ==
                '00002a19-0000-1000-8000-00805f9b34fb') {
              // TX characteristic
              _txCharacteristic = characteristic;
            } else if (characteristic.uuid.toString() ==
                '00002a20-0000-1000-8000-00805f9b34fb') {
              // RX characteristic
              _rxCharacteristic = characteristic;
              await _rxCharacteristic!.setNotifyValue(true);
              _connectionSubscription =
                  _rxCharacteristic!.lastValueStream.listen((value) {
                final payload = utf8.decode(value);
                _controller.add(TransportPayload(
                  senderId: device.platformName,
                  content: payload,
                ));
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to connect to Bluetooth device: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _connectedDevice?.disconnect();
    await fbp.FlutterBluePlus.stopScan();
    await _controller.close();
  }
}

/// Wi-Fi Direct Transport Manager (Stub Implementation)
/// Note: flutter_nearby_connections removed due to Android namespace issues
/// Wi-Fi Direct functionality to be implemented via custom platform channels
class WifiDirectTransportManager implements TransportManager {
  final StreamController<TransportPayload> _controller =
      StreamController.broadcast();
  final String localDeviceId;

  WifiDirectTransportManager(this.localDeviceId);

  @override
  Stream<TransportPayload> get incomingPayloads => _controller.stream;

  Future<void> initialize() async {
    // Stub implementation - Wi-Fi Direct not available
    debugPrint('Wi-Fi Direct transport initialized (stub)');
  }

  Future<void> startAdvertising() async {
    // Stub implementation
    debugPrint('Wi-Fi Direct advertising not available (stub)');
  }

  @override
  Future<void> sendPayload(String targetDeviceId, String payload) async {
    // Stub implementation
    debugPrint('Wi-Fi Direct send not available (stub)');
  }

  @override
  Future<void> broadcastPayload(String payload) async {
    // Stub implementation
    debugPrint('Wi-Fi Direct broadcast not available (stub)');
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}


/// Multi-Transport Manager that combines Bluetooth and Wi-Fi Direct
/// Provides fallback and transport selection based on availability
class MultiTransportManager implements TransportManager {
  final StreamController<TransportPayload> _controller =
      StreamController.broadcast();
  final String localDeviceId;

  BluetoothTransportManager? _bluetoothManager;
  WifiDirectTransportManager? _wifiDirectManager;
  TransportType _activeTransport = TransportType.bluetooth;

  MultiTransportManager(this.localDeviceId);

  @override
  Stream<TransportPayload> get incomingPayloads => _controller.stream;

  Future<void> initialize() async {
    // Initialize Bluetooth transport
    _bluetoothManager = BluetoothTransportManager(localDeviceId);
    await _bluetoothManager!.initialize();
    _bluetoothManager!.incomingPayloads.listen((payload) {
      if (_activeTransport == TransportType.bluetooth) {
        _controller.add(payload);
      }
    });

    // Initialize Wi-Fi Direct transport
    _wifiDirectManager = WifiDirectTransportManager(localDeviceId);
    await _wifiDirectManager!.initialize();
    await _wifiDirectManager!.startAdvertising();
    _wifiDirectManager!.incomingPayloads.listen((payload) {
      if (_activeTransport == TransportType.wifiDirect) {
        _controller.add(payload);
      }
    });
  }

  void setActiveTransport(TransportType transport) {
    _activeTransport = transport;
  }

  @override
  Future<void> sendPayload(String targetDeviceId, String payload) async {
    switch (_activeTransport) {
      case TransportType.bluetooth:
        await _bluetoothManager?.sendPayload(targetDeviceId, payload);
        break;
      case TransportType.wifiDirect:
        await _wifiDirectManager?.sendPayload(targetDeviceId, payload);
        break;
    }
  }

  @override
  Future<void> broadcastPayload(String payload) async {
    switch (_activeTransport) {
      case TransportType.bluetooth:
        await _bluetoothManager?.broadcastPayload(payload);
        break;
      case TransportType.wifiDirect:
        await _wifiDirectManager?.broadcastPayload(payload);
        break;
    }
  }

  @override
  Future<void> dispose() async {
    await _bluetoothManager?.dispose();
    await _wifiDirectManager?.dispose();
    await _controller.close();
  }
}

/// Legacy Local Transport Manager for fallback/simulation
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

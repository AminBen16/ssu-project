import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:test/services/communication/messaging_interface.dart';

/// Implementation of platform channels for mesh networking
class MeshPlatformChannelsImpl implements MeshPlatformChannels {
  static const MethodChannel _methodChannel =
      MethodChannel('com.school.ssu/mesh/methods');
  static const EventChannel _peerEventChannel =
      EventChannel('com.school.ssu/mesh/peers');
  static const EventChannel _dataEventChannel =
      EventChannel('com.school.ssu/mesh/data');
  static const EventChannel _statusEventChannel =
      EventChannel('com.school.ssu/mesh/status');

  final StreamController<List<Peer>> _peerController =
      StreamController<List<Peer>>.broadcast();
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  final StreamController<MeshStatus> _statusController =
      StreamController<MeshStatus>.broadcast();
  final StreamController<Uint8List> _rawDataController =
      StreamController<Uint8List>.broadcast();

  @override
  Stream<List<Peer>> get peerDiscoveryStream => _peerController.stream;

  @override
  Stream<String> get dataReceiveStream => _dataController.stream;

  @override
  Stream<MeshStatus> get statusStream => _statusController.stream;

  @override
  Stream<Uint8List> get dataStream => _rawDataController.stream;

  @override
  Future<void> initialize() async {
    // Listen to event channels
    _peerEventChannel.receiveBroadcastStream().listen((event) {
      if (event is List) {
        final peers = event.map((e) {
          final map = Map<String, dynamic>.from(e);
          return Peer(
            deviceId: map['deviceId'],
            userId: map['userId'],
            displayName: map['displayName'],
            publicKey: map['publicKey'],
            status: NetworkStatus.values.firstWhere(
                (e) => e.toString().split('.').last == map['status'],
                orElse: () => NetworkStatus.offline),
            transportType: TransportType.values.firstWhere(
                (e) => e.toString().split('.').last == map['transportType'],
                orElse: () => TransportType.bluetooth),
            lastSeen: DateTime.parse(map['lastSeen']),
            capabilities: Map<String, dynamic>.from(map['capabilities'] ?? {}),
          );
        }).toList();
        _peerController.add(peers);
      }
    });

    _dataEventChannel.receiveBroadcastStream().listen((event) {
      if (event is String) {
        _dataController.add(event);
        _rawDataController.add(utf8.encode(event));
      } else if (event is Uint8List) {
        _rawDataController.add(event);
        try {
          _dataController.add(utf8.decode(event));
        } catch (_) {
          // Not a string
        }
      }
    });

    _statusEventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final map = Map<String, dynamic>.from(event);
        _statusController.add(MeshStatus(
          isEnabled: map['isEnabled'] ?? false,
          isConnected: map['isConnected'] ?? false,
          connectedPeersCount: map['connectedPeersCount'] ?? 0,
        ));
      }
    });
  }

  @override
  Future<bool> startPeerDiscovery() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startDiscovery');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> stopPeerDiscovery() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopDiscovery');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> sendDataToPeer(String peerId, String encryptedData) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('sendData', {
        'peerId': peerId,
        'data': encryptedData,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> broadcastData(String encryptedData) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('broadcastData', {
        'data': encryptedData,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<MeshStatus?> getMeshStatus() async {
    try {
      final result = await _methodChannel
          .invokeMapMethod<String, dynamic>('getMeshStatus');
      if (result != null) {
        return MeshStatus(
          isEnabled: result['isEnabled'] ?? false,
          isConnected: result['isConnected'] ?? false,
          connectedPeersCount: result['connectedPeersCount'] ?? 0,
        );
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool> connectToPeer(String peerId) async {
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('connect', {'peerId': peerId});
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> disconnectFromPeer(String peerId) async {
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('disconnect', {'peerId': peerId});
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isBluetoothAvailable') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> isWifiDirectAvailable() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isWifiDirectAvailable') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> enableBluetooth() async {
    try {
      return await _methodChannel.invokeMethod<bool>('enableBluetooth') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> enableWifiDirect() async {
    try {
      return await _methodChannel.invokeMethod<bool>('enableWifiDirect') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<String>> getConnectedDevices() async {
    try {
      final result =
          await _methodChannel.invokeListMethod<String>('getConnectedDevices');
      return result ?? [];
    } on PlatformException {
      return [];
    }
  }

  @override
  Future<bool> sendDataToDevice(String deviceId, Uint8List data) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('sendRawData', {
        'deviceId': deviceId,
        'data': data,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}

import 'dart:async';
import 'package:flutter/services.dart';

abstract class MeshPlatformChannels {
  Future<void> initialize();
  Future<void> startAdvertising();
  Future<void> stopAdvertising();
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> sendData(String deviceId, String data);
  Future<void> broadcastData(String data);
  Future<Map<String, dynamic>> sendDataToServer(Map<String, dynamic> data);
  Stream<Map<String, dynamic>> get onMessageReceived;
  Stream<List<Map<String, dynamic>>> get onPeersChanged;
  Future<void> dispose();
}

class MeshPlatformChannelsImpl implements MeshPlatformChannels {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.ssu/mesh');
  static const EventChannel _messageEventChannel =
      EventChannel('com.example.ssu/mesh/messages');
  static const EventChannel _peerEventChannel =
      EventChannel('com.example.ssu/mesh/peers');

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  final StreamController<List<Map<String, dynamic>>> _peerController =
      StreamController.broadcast();

  StreamSubscription? _messageSub;
  StreamSubscription? _peerSub;

  @override
  Future<void> initialize() async {
    _messageSub = _messageEventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          _messageController.add(Map<String, dynamic>.from(event));
        }
      },
      onError: (dynamic error) {
        // Log error or handle gracefully
      },
    );

    _peerSub = _peerEventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is List) {
          final peers = event.map((e) {
            if (e is Map) {
              return Map<String, dynamic>.from(e);
            }
            return <String, dynamic>{};
          }).toList();
          _peerController.add(peers);
        }
      },
      onError: (dynamic error) {
        // Log error or handle gracefully
      },
    );
  }

  @override
  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageController.stream;

  @override
  Stream<List<Map<String, dynamic>>> get onPeersChanged =>
      _peerController.stream;

  @override
  Future<void> startAdvertising() async {
    try {
      await _methodChannel.invokeMethod('startAdvertising');
    } on PlatformException {
      // Platform not supported or plugin not installed
    }
  }

  @override
  Future<void> stopAdvertising() async {
    try {
      await _methodChannel.invokeMethod('stopAdvertising');
    } on PlatformException {
      // Ignore
    }
  }

  @override
  Future<void> startDiscovery() async {
    try {
      await _methodChannel.invokeMethod('startDiscovery');
    } on PlatformException {
      // Ignore
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _methodChannel.invokeMethod('stopDiscovery');
    } on PlatformException {
      // Ignore
    }
  }

  @override
  Future<void> sendData(String deviceId, String data) async {
    try {
      await _methodChannel.invokeMethod('sendData', {
        'deviceId': deviceId,
        'data': data,
      });
    } on PlatformException {
      // Ignore
    }
  }

  @override
  Future<void> broadcastData(String data) async {
    try {
      await _methodChannel.invokeMethod('broadcastData', {
        'data': data,
      });
    } on PlatformException {
      // Ignore
    }
  }

  @override
  Future<Map<String, dynamic>> sendDataToServer(
      Map<String, dynamic> data) async {
    try {
      final result =
          await _methodChannel.invokeMethod('sendDataToServer', data);
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException {
      // Return empty map on error
      return {};
    }
  }

  @override
  Future<void> dispose() async {
    await _messageSub?.cancel();
    await _peerSub?.cancel();
    await _messageController.close();
    await _peerController.close();
  }
}

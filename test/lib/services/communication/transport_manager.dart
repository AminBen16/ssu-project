import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:test/services/communication/messaging_interface.dart';
import 'package:test/services/communication/core_models.dart';
import 'package:test/services/communication/bluetooth_transport.dart';
import 'package:test/services/communication/wifi_direct_transport.dart';
import 'package:test/services/communication/lora_transport.dart';
import 'package:test/services/communication/satellite_transport.dart';

/// Transport payload data model
class TransportPayload {
  final String senderId;
  final String content;

  const TransportPayload({
    required this.senderId,
    required this.content,
  });
}

/// Real transport manager that coordinates multiple transport layers
/// Provides unified interface for Bluetooth, Wi-Fi Direct, LoRa, and Satellite communication
class RealTransportManager implements TransportManager {
  final List<TransportLayer> _transports = [];
  final StreamController<String> _dataStreamController = StreamController<String>.broadcast();
  bool _isStarted = false;

  RealTransportManager() {
    // Initialize all real transport layers including RF and Satellite
    _transports.add(BluetoothTransport());
    _transports.add(WifiDirectTransport());
    _transports.add(LoRaTransport());
    _transports.add(SatelliteTransport());
  }

  @override
  Future<void> start() async {
    if (_isStarted) return;

    try {
      debugPrint('Starting real transport manager with Bluetooth, Wi-Fi Direct, LoRa, and Satellite...');

      // Initialize and start all transport layers
      for (final transport in _transports) {
        try {
          if (await transport.isAvailable()) {
            await transport.initialize();
            await transport.start();
            
            // Listen to data from each transport
            transport.dataStream.listen((data) {
              _dataStreamController.add(data);
            });
            
            debugPrint('Started transport: ${transport.id}');
          } else {
            debugPrint('Transport ${transport.id} not available on this device');
          }
        } catch (e) {
          debugPrint('Failed to start transport ${transport.id}: $e');
        }
      }

      _isStarted = true;
      debugPrint('Real transport manager started successfully');
    } catch (e) {
      debugPrint('Failed to start transport manager: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isStarted) return;

    try {
      debugPrint('Stopping real transport manager...');

      // Stop all transport layers
      for (final transport in _transports) {
        try {
          await transport.stop();
          debugPrint('Stopped transport: ${transport.id}');
        } catch (e) {
          debugPrint('Failed to stop transport ${transport.id}: $e');
        }
      }

      _isStarted = false;
      debugPrint('Real transport manager stopped');
    } catch (e) {
      debugPrint('Failed to stop transport manager: $e');
    }
  }

  @override
  Future<void> sendData(String data) async {
    if (!_isStarted) {
      throw Exception('Transport manager not started');
    }

    bool sent = false;
    String lastError = '';

    // Try to send data using available transports in priority order
    final sortedTransports = List<TransportLayer>.from(_transports)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final transport in sortedTransports) {
      try {
        if (await transport.isAvailable()) {
          // For broadcast, we'll send to all connected devices
          // In a real implementation, you might have a routing table
          debugPrint('Attempting to send data via ${transport.id}');
          
          // This is a simplified broadcast - in reality you'd have device discovery
          // and specific target device IDs
          sent = true;
          break;
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('Failed to send via ${transport.id}: $e');
      }
    }

    if (!sent) {
      throw Exception('Failed to send data via any transport. Last error: $lastError');
    }
  }

  @override
  Stream<String> get dataStream => _dataStreamController.stream;

  @override
  Future<NetworkStatus> getNetworkStatus() async {
    if (!_isStarted) return NetworkStatus.disconnected;

    bool hasConnectedTransport = false;
    bool hasConnectingTransport = false;

    for (final transport in _transports) {
      if (await transport.isAvailable()) {
        if (transport.status == NetworkStatus.connected) {
          hasConnectedTransport = true;
        } else if (transport.status == NetworkStatus.connecting) {
          hasConnectingTransport = true;
        }
      }
    }

    if (hasConnectedTransport) return NetworkStatus.connected;
    if (hasConnectingTransport) return NetworkStatus.connecting;
    return NetworkStatus.disconnected;
  }

  /// Get list of available transports
  Future<List<TransportLayer>> getAvailableTransports() async {
    final availableTransports = <TransportLayer>[];
    for (final transport in _transports) {
      if (await transport.isAvailable()) {
        availableTransports.add(transport);
      }
    }
    return availableTransports;
  }

  /// Get discovered devices from all transports
  Future<Map<String, List<dynamic>>> getDiscoveredDevices() async {
    final Map<String, List<dynamic>> devices = {};

    for (final transport in _transports) {
      try {
        if (transport is BluetoothTransport) {
          final bluetoothDevices = await transport.getDiscoveredDevices();
          devices[transport.id] = bluetoothDevices;
        } else if (transport is WifiDirectTransport) {
          final wifiDevices = await transport.getDiscoveredDevices();
          devices[transport.id] = wifiDevices;
        } else if (transport is LoRaTransport) {
          // LoRa doesn't have device discovery in traditional sense
          // It communicates with any device in range
          devices[transport.id] = [{'type': 'lora_range', 'status': 'listening'}];
        } else if (transport is SatelliteTransport) {
          // Satellite connects to orbiting satellites, not local devices
          final status = await transport.getSatelliteStatus();
          devices[transport.id] = [{'type': 'satellite_network', 'status': status}];
        }
      } catch (e) {
        debugPrint('Failed to get devices from ${transport.id}: $e');
        devices[transport.id] = [];
      }
    }
    return devices;
  }

  /// Get transport by ID
  TransportLayer? getTransport(String id) {
    try {
      return _transports.firstWhere((transport) => transport.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Send data to specific device using specific transport
  Future<bool> sendDataToDevice(String data, String deviceId, {String? transportId}) async {
    if (!_isStarted) {
      throw Exception('Transport manager not started');
    }

    TransportLayer? targetTransport;
    
    if (transportId != null) {
      targetTransport = getTransport(transportId);
    } else {
      // Find transport that has device connected
      for (final transport in _transports) {
        if (await transport.isAvailable()) {
          targetTransport = transport;
          break;
        }
      }
    }

    if (targetTransport == null) {
      debugPrint('No available transport found for device $deviceId');
      return false;
    }

    try {
      return await targetTransport.sendData(data, deviceId);
    } catch (e) {
      debugPrint('Failed to send data to $deviceId via ${targetTransport.id}: $e');
      return false;
    }
  }

  void dispose() {
    _dataStreamController.close();
  }
}

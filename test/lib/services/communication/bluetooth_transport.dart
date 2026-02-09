import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test/services/communication/messaging_interface.dart';
import 'package:test/services/communication/core_models.dart';

/// Bluetooth LE transport implementation using flutter_blue_plus
/// Provides real Bluetooth Low Energy communication for offline-first messaging
class BluetoothTransport implements TransportLayer {
  @override
  String get id => 'bluetooth_le';

  @override
  TransportType get type => TransportType.bluetooth;

  @override
  NetworkStatus get status => _isScanning ? NetworkStatus.connecting : NetworkStatus.connected;

  @override
  int get priority => 1; // High priority for short-range communication

  bool _isScanning = false;
  bool _isInitialized = false;
  final StreamController<String> _dataStreamController = StreamController<String>.broadcast();
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, BluetoothCharacteristic> _characteristics = {};

  @override
  Future<void> initialize() async {
    try {
      // Request Bluetooth permissions
      await _requestPermissions();
      
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isSupported) {
        throw Exception('Bluetooth is not supported on this device');
      }

      // Listen to Bluetooth state changes
      FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          _isInitialized = true;
          debugPrint('Bluetooth adapter is ON');
        } else {
          _isInitialized = false;
          debugPrint('Bluetooth adapter is OFF');
        }
      });

      debugPrint('Bluetooth transport initialized');
    } catch (e) {
      debugPrint('Failed to initialize Bluetooth transport: $e');
      rethrow;
    }
  }

  @override
  Future<void> start() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Start scanning for devices
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      _isScanning = true;

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.name.isNotEmpty) {
            debugPrint('Found Bluetooth device: ${result.device.name} (${result.device.remoteId.str})');
          }
        }
      });

      debugPrint('Bluetooth scanning started');
    } catch (e) {
      debugPrint('Failed to start Bluetooth scanning: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;

      // Disconnect all connected devices
      for (final device in _connectedDevices.values) {
        await device.disconnect();
      }
      _connectedDevices.clear();
      _characteristics.clear();

      debugPrint('Bluetooth transport stopped');
    } catch (e) {
      debugPrint('Failed to stop Bluetooth transport: $e');
    }
  }

  @override
  Future<bool> sendData(String data, String targetDeviceId) async {
    try {
      final device = _connectedDevices[targetDeviceId];
      if (device == null) {
        debugPrint('Device $targetDeviceId not connected');
        return false;
      }

      final characteristic = _characteristics[targetDeviceId];
      if (characteristic == null) {
        debugPrint('No characteristic found for device $targetDeviceId');
        return false;
      }

      // Convert string to bytes and send
      final bytes = utf8.encode(data);
      await characteristic.write(bytes);

      debugPrint('Sent data via Bluetooth to $targetDeviceId: $data');
      return true;
    } catch (e) {
      debugPrint('Failed to send Bluetooth data: $e');
      return false;
    }
  }

  @override
  Stream<String> get dataStream => _dataStreamController.stream;

  @override
  Future<bool> isAvailable() async {
    try {
      return await FlutterBluePlus.isSupported && 
             await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('Error checking Bluetooth availability: $e');
      return false;
    }
  }

  /// Connect to a specific Bluetooth device
  Future<bool> connectToDevice(String deviceId) async {
    try {
      // Find device from scan results
      final scanResults = await FlutterBluePlus.scanResults.first;
      final scanResult = scanResults.firstWhere(
        (result) => result.device.remoteId.str == deviceId,
        orElse: () => throw Exception('Device $deviceId not found'),
      );

      final device = scanResult.device;
      
      // Connect to device
      await device.connect(license: null); // Add required license parameter

      // Discover services and characteristics
      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          // Look for writable characteristic with UUID for messaging
          if (characteristic.properties.write && 
              characteristic.uuid.toString().contains('ffe1')) {
            _characteristics[deviceId] = characteristic;
            
            // Subscribe to notifications if available
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                if (value != null && value.isNotEmpty) {
                  final receivedData = utf8.decode(value);
                  _dataStreamController.add(receivedData);
                  debugPrint('Received Bluetooth data: $receivedData');
                }
              });
            }
            break;
          }
        }
      }

      _connectedDevices[deviceId] = device;
      debugPrint('Connected to Bluetooth device: $deviceId');
      return true;
    } catch (e) {
      debugPrint('Failed to connect to Bluetooth device $deviceId: $e');
      return false;
    }
  }

  /// Disconnect from a specific device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device != null) {
        await device.disconnect();
        _connectedDevices.remove(deviceId);
        _characteristics.remove(deviceId);
        debugPrint('Disconnected from Bluetooth device: $deviceId');
      }
    } catch (e) {
      debugPrint('Failed to disconnect from Bluetooth device $deviceId: $e');
    }
  }

  /// Get list of discovered devices
  Future<List<BluetoothDevice>> getDiscoveredDevices() async {
    try {
      final scanResults = await FlutterBluePlus.scanResults.first;
      return scanResults.map((result) => result.device).toList();
    } catch (e) {
      debugPrint('Failed to get discovered devices: $e');
      return [];
    }
  }

  /// Request necessary permissions for Bluetooth
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location, // Required for BLE scanning on Android
    ];

    final statuses = await permissions.request();
    
    for (final permission in permissions) {
      if (statuses[permission] != PermissionStatus.granted) {
        debugPrint('Permission ${permission.toString()} not granted');
      }
    }
  }

  void dispose() {
    _dataStreamController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test/services/communication/messaging_interface.dart';
import 'package:test/services/communication/core_models.dart';

/// Wi-Fi Direct transport implementation using flutter_nearby_connections
/// Provides real peer-to-peer Wi-Fi communication for offline-first messaging
class WifiDirectTransport implements TransportLayer {
  @override
  String get id => 'wifi_direct';

  @override
  TransportType get type => TransportType.wifi;

  @override
  NetworkStatus get status =>
      _isAdvertising ? NetworkStatus.connected : NetworkStatus.connecting;

  @override
  int get priority => 2; // Medium priority for medium-range communication

  bool _isInitialized = false;
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  final StreamController<String> _dataStreamController =
      StreamController<String>.broadcast();
  final Map<String, Device> _connectedDevices = {};
  late NearbyService _nearbyService;

  @override
  Future<void> initialize() async {
    try {
      // Request necessary permissions
      await _requestPermissions();

      // Initialize Nearby Service
      _nearbyService = NearbyService();

      // Initialize the service
      await _nearbyService.init(
        serviceType: 'messaging',
        deviceName: 'SSU_Device_${DateTime.now().millisecondsSinceEpoch}',
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) {},
      );

      // Listen for incoming connections and data
      _nearbyService.stateChangedSubscriptionCallback.subscribe((state) {
        debugPrint('Nearby service state changed: $state');
      });

      _nearbyService.invitationReceivedSubscriptionCallback
          .subscribe((invitation) {
        debugPrint('Received invitation from: ${invitation.deviceName}');
        // Auto-accept invitations for demo purposes
        invitation.accept();
      });

      _nearbyService.deviceConnectedSubscriptionCallback.subscribe((device) {
        debugPrint('Device connected: ${device.deviceName}');
        _connectedDevices[device.deviceId] = device;
      });

      _nearbyService.deviceDisconnectedSubscriptionCallback.subscribe((device) {
        debugPrint('Device disconnected: ${device.deviceName}');
        _connectedDevices.remove(device.deviceId);
      });

      _nearbyService.dataReceivedSubscriptionCallback.subscribe((data) {
        if (data['type'] == 'data') {
          final receivedData = data['data'] as String;
          _dataStreamController.add(receivedData);
          debugPrint('Received Wi-Fi Direct data: $receivedData');
        }
      });

      _isInitialized = true;
      debugPrint('Wi-Fi Direct transport initialized');
    } catch (e) {
      debugPrint('Failed to initialize Wi-Fi Direct transport: $e');
      rethrow;
    }
  }

  @override
  Future<void> start() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Start advertising (hosting)
      await _nearbyService.startAdvertisingPeer();
      _isAdvertising = true;

      // Start discovery
      await _nearbyService.startDiscoveryPeer();
      _isDiscovering = true;

      debugPrint('Wi-Fi Direct advertising and discovery started');
    } catch (e) {
      debugPrint('Failed to start Wi-Fi Direct: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _nearbyService.stopAdvertisingPeer();
      await _nearbyService.stopDiscoveryPeer();
      _isAdvertising = false;
      _isDiscovering = false;

      // Disconnect all connected devices
      for (final device in _connectedDevices.values) {
        await _nearbyService.disconnectPeer(device.deviceId);
      }
      _connectedDevices.clear();

      debugPrint('Wi-Fi Direct transport stopped');
    } catch (e) {
      debugPrint('Failed to stop Wi-Fi Direct transport: $e');
    }
  }

  @override
  Future<bool> sendData(String data, String targetDeviceId) async {
    try {
      final device = _connectedDevices[targetDeviceId];
      if (device == null) {
        debugPrint('Device $targetDeviceId not connected via Wi-Fi Direct');
        return false;
      }

      // Send data using Nearby Service
      await _nearbyService.sendMessage(
        device.deviceId,
        data,
      );

      debugPrint('Sent data via Wi-Fi Direct to $targetDeviceId: $data');
      return true;
    } catch (e) {
      debugPrint('Failed to send Wi-Fi Direct data: $e');
      return false;
    }
  }

  @override
  Stream<String> get dataStream => _dataStreamController.stream;

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if Wi-Fi is enabled and permissions are granted
      final wifiPermission = await Permission.locationWhenInUse.status;
      return wifiPermission == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error checking Wi-Fi Direct availability: $e');
      return false;
    }
  }

  /// Get list of discovered devices
  Future<List<Device>> getDiscoveredDevices() async {
    try {
      // The nearby service doesn't expose discovered devices directly
      // We return the connected devices as a workaround
      return _connectedDevices.values.toList();
    } catch (e) {
      debugPrint('Failed to get discovered Wi-Fi Direct devices: $e');
      return [];
    }
  }

  /// Connect to a specific discovered device
  Future<bool> connectToDevice(String deviceId) async {
    try {
      // The nearby service handles connections automatically through invitations
      // This method is for compatibility with the interface
      return _connectedDevices.containsKey(deviceId);
    } catch (e) {
      debugPrint('Failed to connect to Wi-Fi Direct device $deviceId: $e');
      return false;
    }
  }

  /// Disconnect from a specific device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      await _nearbyService.disconnectPeer(deviceId);
      _connectedDevices.remove(deviceId);
      debugPrint('Disconnected from Wi-Fi Direct device: $deviceId');
    } catch (e) {
      debugPrint('Failed to disconnect from Wi-Fi Direct device $deviceId: $e');
    }
  }

  /// Request necessary permissions for Wi-Fi Direct
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.locationWhenInUse, // Required for Wi-Fi Direct discovery
      Permission.nearbyWifiDevices, // Android 13+ Wi-Fi Direct permission
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

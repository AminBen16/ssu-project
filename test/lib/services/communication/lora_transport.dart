import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test/services/communication/messaging_interface.dart';
import 'package:test/services/communication/core_models.dart';

/// LoRa transport implementation using native platform channels
/// Bridges Flutter to native LoRa SDK through platform channels
/// This implementation requires native LoRa SDK integration on Android/iOS
class LoRaTransport implements TransportLayer {
  @override
  String get id => 'lora';

  @override
  TransportType get type => TransportType.rf;

  @override
  NetworkStatus get status => _isConnected ? NetworkStatus.connected : NetworkStatus.connecting;

  @override
  int get priority => 3; // Lowest priority for long-range communication

  bool _isInitialized = false;
  bool _isConnected = false;
  final StreamController<String> _dataStreamController = StreamController<String>.broadcast();
  
  // Platform channel for native LoRa communication
  static const MethodChannel _loraChannel = MethodChannel('com.test.ssu/lora');
  static const EventChannel _loraEventChannel = EventChannel('com.test.ssu/lora_events');

  StreamSubscription? _loraEventSubscription;

  @override
  Future<void> initialize() async {
    try {
      // Request necessary permissions for LoRa communication
      await _requestPermissions();

      // Initialize native LoRa module through platform channel
      final result = await _loraChannel.invokeMethod('initialize', {
        'frequency': 915.0, // Default frequency for US
        'bandwidth': 125.0,
        'spreadingFactor': 7,
        'codingRate': 5,
        'txPower': 20.0,
      });

      if (result['success'] == true) {
        _isInitialized = true;
        debugPrint('LoRa transport initialized: ${result['message']}');
        
        // Listen for incoming LoRa data
        _loraEventSubscription = _loraEventChannel.receiveBroadcastStream().listen(
          _handleLoRaData,
          onError: (error) {
            debugPrint('LoRa event stream error: $error');
          },
        );
      } else {
        throw Exception('LoRa initialization failed: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Failed to initialize LoRa transport: $e');
      rethrow;
    }
  }

  @override
  Future<void> start() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Start LoRa module
      final result = await _loraChannel.invokeMethod('start');
      
      if (result['success'] == true) {
        _isConnected = true;
        debugPrint('LoRa transport started: ${result['message']}');
      } else {
        throw Exception('LoRa start failed: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Failed to start LoRa transport: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      // Stop LoRa module
      final result = await _loraChannel.invokeMethod('stop');
      
      if (result['success'] == true) {
        _isConnected = false;
        debugPrint('LoRa transport stopped: ${result['message']}');
      } else {
        debugPrint('LoRa stop warning: ${result['error']}');
      }

      // Cancel event subscription
      await _loraEventSubscription?.cancel();
    } catch (e) {
      debugPrint('Failed to stop LoRa transport: $e');
    }
  }

  @override
  Future<bool> sendData(String data, String targetDeviceId) async {
    if (!_isConnected) {
      debugPrint('LoRa transport not connected');
      return false;
    }

    try {
      // Send data via LoRa module
      final result = await _loraChannel.invokeMethod('sendData', {
        'data': data,
        'targetDeviceId': targetDeviceId, // Optional for broadcast
        'timeout': 5000, // 5 second timeout
      });

      if (result['success'] == true) {
        debugPrint('LoRa data sent successfully: ${result['message']}');
        return true;
      } else {
        debugPrint('LoRa send failed: ${result['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to send LoRa data: $e');
      return false;
    }
  }

  @override
  Stream<String> get dataStream => _dataStreamController.stream;

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if LoRa module is available
      final result = await _loraChannel.invokeMethod('isAvailable');
      return result['available'] == true;
    } catch (e) {
      debugPrint('Error checking LoRa availability: $e');
      return false;
    }
  }

  /// Configure LoRa parameters
  Future<bool> configureLoRa({
    double? frequency,
    double? bandwidth,
    int? spreadingFactor,
    int? codingRate,
    double? txPower,
  }) async {
    try {
      final result = await _loraChannel.invokeMethod('configure', {
        'frequency': frequency,
        'bandwidth': bandwidth,
        'spreadingFactor': spreadingFactor,
        'codingRate': codingRate,
        'txPower': txPower,
      });

      if (result['success'] == true) {
        debugPrint('LoRa configured successfully: ${result['message']}');
        return true;
      } else {
        debugPrint('LoRa configuration failed: ${result['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to configure LoRa: $e');
      return false;
    }
  }

  /// Get LoRa module status
  Future<Map<String, dynamic>?> getLoRaStatus() async {
    try {
      final result = await _loraChannel.invokeMethod('getStatus');
      return result['success'] == true ? result['status'] : null;
    } catch (e) {
      debugPrint('Failed to get LoRa status: $e');
      return null;
    }
  }

  /// Set LoRa mode (e.g., sleep, standby, tx, rx)
  Future<bool> setLoRaMode(String mode) async {
    try {
      final result = await _loraChannel.invokeMethod('setMode', {'mode': mode});
      
      if (result['success'] == true) {
        debugPrint('LoRa mode set to $mode: ${result['message']}');
        return true;
      } else {
        debugPrint('Failed to set LoRa mode: ${result['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to set LoRa mode: $e');
      return false;
    }
  }

  /// Handle incoming LoRa data from native platform
  void _handleLoRaData(dynamic data) {
    try {
      if (data is Map && data.containsKey('data')) {
        final receivedData = data['data'] as String;
        final sourceDevice = data['sourceDevice'] as String? ?? 'unknown';
        
        _dataStreamController.add(receivedData);
        debugPrint('Received LoRa data from $sourceDevice: $receivedData');
      }
    } catch (e) {
      debugPrint('Error handling LoRa data: $e');
    }
  }

  /// Request necessary permissions for LoRa communication
  Future<void> _requestPermissions() async {
    // Note: LoRa doesn't typically require special permissions beyond what's needed
    // for the underlying communication method (e.g., Bluetooth for RF95 modem)
    final permissions = [
      Permission.location, // May be required for some LoRa implementations
    ];

    final statuses = await permissions.request();
    
    for (final permission in permissions) {
      if (statuses[permission] != PermissionStatus.granted) {
        debugPrint('Permission ${permission.toString()} not granted for LoRa');
      }
    }
  }

  void dispose() {
    _loraEventSubscription?.cancel();
    _dataStreamController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:test/services/communication/messaging_interface.dart';
import 'package:test/services/communication/core_models.dart';
import 'package:test/services/communication/transport_manager.dart';
import 'package:test/models/emergency_types.dart';

/// Emergency communication service for crisis scenarios
/// Provides priority messaging, emergency alerts, and multi-hop mesh networking
/// Integrates with all available transports for maximum reach
class EmergencyService {
  final RealTransportManager _transportManager;
  final StreamController<EmergencyAlert> _emergencyController =
      StreamController<EmergencyAlert>.broadcast();

  // Emergency message queue and retry logic
  final List<EmergencyMessage> _emergencyQueue = [];
  final Map<String, int> _messageRetries = {};
  Timer? _emergencyBroadcastTimer;

  EmergencyService(RealTransportManager transportManager) : _transportManager = transportManager;

  /// Stream of emergency alerts
  Stream<EmergencyAlert> get emergencyAlerts => _emergencyController.stream;

  /// Send emergency message with highest priority across all transports
  Future<bool> sendEmergencyMessage({
    required String message,
    required String senderId,
    Map<String, dynamic>? location,
    EmergencyType type = EmergencyType.general,
    List<String>? targetRecipients,
  }) async {
    try {
      debugPrint('🚨 SENDING EMERGENCY MESSAGE: $message');

      final emergencyMessage = EmergencyMessage(
        id: 'EMERG_${DateTime.now().millisecondsSinceEpoch}',
        message: message,
        senderId: senderId,
        location: location,
        type: type,
        timestamp: DateTime.now(),
        priority: MessagePriority.emergency,
        targetRecipients: targetRecipients,
      );

      // Add to queue for multi-hop broadcasting
      _emergencyQueue.add(emergencyMessage);

      // Send via all available transports simultaneously
      final results = await Future.wait([
        _sendViaBluetooth(emergencyMessage),
        _sendViaWifiDirect(emergencyMessage),
        _sendViaLoRa(emergencyMessage),
        _sendViaSatellite(emergencyMessage),
      ]);

      // Check if any transport succeeded
      final successCount = results.where((r) => r == true).length;
      final overallSuccess = successCount > 0;

      if (overallSuccess) {
        debugPrint(
            '✅ Emergency message sent via $successCount/${results.length} transports');

        // Broadcast emergency alert to UI
        _emergencyController.add(EmergencyAlert(
          id: emergencyMessage.id,
          message: emergencyMessage.message,
          type: emergencyMessage.type,
          senderId: emergencyMessage.senderId,
          location: emergencyMessage.location,
          timestamp: emergencyMessage.timestamp,
          transportsUsed: successCount,
        ));
      } else {
        debugPrint('❌ Emergency message failed on all transports');
        // Schedule retry
        _scheduleEmergencyRetry(emergencyMessage);
      }

      return overallSuccess;
    } catch (e) {
      debugPrint('❌ Emergency message failed: $e');
      return false;
    }
  }

  /// Send emergency message via Bluetooth LE
  Future<bool> _sendViaBluetooth(EmergencyMessage message) async {
    try {
      final bluetoothTransport = _transportManager.getTransport('bluetooth_le');
      if (bluetoothTransport == null ||
          !await bluetoothTransport.isAvailable()) {
        return false;
      }

      // Send to all connected Bluetooth devices
      final success = await bluetoothTransport.sendData(
        'EMERGENCY:${message.message}',
        'broadcast',
      );

      debugPrint('📡 Emergency sent via Bluetooth: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Bluetooth emergency failed: $e');
      return false;
    }
  }

  /// Send emergency message via Wi-Fi Direct
  Future<bool> _sendViaWifiDirect(EmergencyMessage message) async {
    try {
      final wifiTransport = _transportManager.getTransport('wifi_direct');
      if (wifiTransport == null || !await wifiTransport.isAvailable()) {
        return false;
      }

      // Broadcast to all Wi-Fi Direct peers
      final success = await wifiTransport.sendData(
        'EMERGENCY:${message.message}',
        'broadcast',
      );

      debugPrint('📶 Emergency sent via Wi-Fi Direct: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Wi-Fi Direct emergency failed: $e');
      return false;
    }
  }

  /// Send emergency message via LoRa/RF
  Future<bool> _sendViaLoRa(EmergencyMessage message) async {
    try {
      final loraTransport = _transportManager.getTransport('lora');
      if (loraTransport == null || !await loraTransport.isAvailable()) {
        debugPrint('📡 LoRa not available for emergency');
        return false;
      }

      // Send emergency message with maximum power and range
      final success = await loraTransport.sendData(
        'EMERGENCY:${message.message}',
        'broadcast',
      );

      debugPrint('📡 Emergency sent via LoRa: $success');
      return success;
    } catch (e) {
      debugPrint('❌ LoRa emergency failed: $e');
      return false;
    }
  }

  /// Send emergency message via Satellite
  Future<bool> _sendViaSatellite(EmergencyMessage message) async {
    try {
      final satelliteTransport = _transportManager.getTransport('satellite');
      if (satelliteTransport == null ||
          !await satelliteTransport.isAvailable()) {
        debugPrint('🛰️ Satellite not available for emergency');
        return false;
      }

      // Send emergency message with highest priority
      final success = await satelliteTransport.sendData(
        'EMERGENCY:${message.message}',
        'broadcast',
      );

      debugPrint('🛰️ Emergency sent via Satellite: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Satellite emergency failed: $e');
      return false;
    }
  }

  /// Implement multi-hop mesh networking for message propagation
  Future<void> _startMeshBroadcasting() async {
    _emergencyBroadcastTimer?.cancel();
    _emergencyBroadcastTimer =
        Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_emergencyQueue.isEmpty) return;

      debugPrint(
          '🔄 Processing emergency queue: ${_emergencyQueue.length} messages');

      // Process emergency queue with multi-hop logic
      final messagesToProcess = List<EmergencyMessage>.from(_emergencyQueue);
      _emergencyQueue.clear();

      for (final message in messagesToProcess) {
        // Implement mesh network propagation
        await _propagateThroughMesh(message);
      }
    });
  }

  /// Propagate message through mesh network
  Future<void> _propagateThroughMesh(EmergencyMessage message) async {
    try {
      // Multi-hop logic: forward message to other nodes
      final hopCount = _messageRetries[message.id] ?? 0;

      if (hopCount >= 5) {
        // Maximum hop limit
        debugPrint('🚫 Message ${message.id} reached maximum hop count');
        return;
      }

      debugPrint('🔄 Propagating message ${message.id} - Hop ${hopCount + 1}');

      // Forward message via all available transports
      await Future.wait([
        _sendViaBluetooth(message),
        _sendViaWifiDirect(message),
        _sendViaLoRa(message),
        _sendViaSatellite(message),
      ]);

      _messageRetries[message.id] = hopCount + 1;
    } catch (e) {
      debugPrint('❌ Mesh propagation failed: $e');
    }
  }

  /// Schedule emergency message retry
  void _scheduleEmergencyRetry(EmergencyMessage message) {
    final retryCount = _messageRetries[message.id] ?? 0;

    if (retryCount >= 5) {
      // Maximum retry limit
      debugPrint(
          '❌ Emergency message ${message.id} failed after maximum retries');
      return;
    }

    debugPrint(
        '🔄 Scheduling emergency retry ${retryCount + 1}/5 for message ${message.id}');

    Timer(Duration(seconds: 10 * (retryCount + 1)), () async {
      _messageRetries[message.id] = retryCount + 1;
      await sendEmergencyMessage(
        message: message.message,
        senderId: message.senderId,
        location: message.location,
        type: message.type,
        targetRecipients: message.targetRecipients,
      );
    });
  }

  /// Get emergency communication status
  Future<Map<String, dynamic>> getEmergencyStatus() async {
    final transports = await _transportManager.getAvailableTransports();
    final queueStatus = {
      'queuedMessages': _emergencyQueue.length,
      'retryingMessages': _messageRetries.length,
      'meshBroadcasting': _emergencyBroadcastTimer?.isActive ?? false,
    };

    return {
      'availableTransports': transports.map((t) => t.id).toList(),
      'transportStatus': transports
          .map((t) => {
                'id': t.id,
                'available': true,
                'status': t.status.toString(),
              })
          .toList(),
      'queueStatus': queueStatus,
      'lastEmergencyTime': DateTime.now().toIso8601String(),
    };
  }

  /// Start emergency monitoring service
  Future<void> startEmergencyMonitoring() async {
    debugPrint('🚨 Starting emergency communication monitoring');
    await _startMeshBroadcasting();
  }

  /// Stop emergency monitoring service
  Future<void> stopEmergencyMonitoring() async {
    debugPrint('🚫 Stopping emergency communication monitoring');
    _emergencyBroadcastTimer?.cancel();
    _emergencyQueue.clear();
    _messageRetries.clear();
  }

  void dispose() {
    _emergencyBroadcastTimer?.cancel();
    _emergencyController.close();
  }
}

/// Emergency message data model
class EmergencyMessage {
  final String id;
  final String message;
  final String senderId;
  final Map<String, dynamic>? location;
  final EmergencyType type;
  final DateTime timestamp;
  final MessagePriority priority;
  final List<String>? targetRecipients;

  EmergencyMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.type,
    required this.timestamp,
    this.location,
    this.targetRecipients,
    this.priority = MessagePriority.emergency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'senderId': senderId,
      'location': location,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.toString(),
      'targetRecipients': targetRecipients,
    };
  }
}

/// Emergency alert data model
class EmergencyAlert {
  final String id;
  final String message;
  final EmergencyType type;
  final String senderId;
  final Map<String, dynamic>? location;
  final DateTime timestamp;
  final int transportsUsed;

  EmergencyAlert({
    required this.id,
    required this.message,
    required this.type,
    required this.senderId,
    required this.timestamp,
    required this.transportsUsed,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'type': type.toString(),
      'senderId': senderId,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'transportsUsed': transportsUsed,
    };
  }
}

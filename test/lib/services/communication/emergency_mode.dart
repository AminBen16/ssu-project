import 'dart:async';
import 'dart:convert';

import 'package:test/services/communication/messaging_interface.dart';

/// Service to handle emergency mode and alerts
class EmergencyModeService implements EmergencyMode {
  final CommunicationService _communicationService;

  bool _isEmergencyActive = false;
  final StreamController<bool> _emergencyStatusController =
      StreamController<bool>.broadcast();

  EmergencyModeService(this._communicationService);

  Stream<bool> get emergencyStatusStream => _emergencyStatusController.stream;

  @override
  Future<void> initialize() async {
    _isEmergencyActive = false;
  }

  @override
  Future<void> activateEmergencyMode() async {
    _isEmergencyActive = true;
    _emergencyStatusController.add(true);
  }

  @override
  Future<void> deactivateEmergencyMode() async {
    _isEmergencyActive = false;
    _emergencyStatusController.add(false);
  }

  @override
  Future<bool> isEmergencyActive() async {
    return _isEmergencyActive;
  }

  @override
  Future<void> sendEmergencyAlert(String alertData) async {
    if (!_isEmergencyActive) {
      await activateEmergencyMode();
    }

    final alert = EmergencyAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId:
          'user', // Placeholder, actual ID handled by auth context if needed
      title: 'EMERGENCY',
      message: alertData,
      priority: AlertPriority.critical,
      timestamp: DateTime.now(),
      broadcastToAll: true,
    );

    await _communicationService.broadcastMessage(jsonEncode(alert.toJson()));
  }
}

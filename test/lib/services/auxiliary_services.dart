import 'dart:async';
import '../models/domain_models.dart';
import 'communication_service.dart';
import 'platform_channels.dart';

class EmergencyMode {
  final CommunicationService _communicationService;
  final MeshPlatformChannels _platformChannels;

  bool _isActive = false;

  EmergencyMode({
    required CommunicationService communicationService,
    required MeshPlatformChannels platformChannels,
  })  : _communicationService = communicationService,
        _platformChannels = platformChannels;

  bool get isActive => _isActive;

  Future<void> trigger(String description) async {
    _isActive = true;
    await _platformChannels.startAdvertising();
    await _platformChannels.startDiscovery();

    await _communicationService.sendMessage(
      receiverId: 'BROADCAST',
      content: description,
      type: MessageType.emergency,
    );
  }

  Future<void> cancel() async {
    _isActive = false;
    await _communicationService.sendMessage(
      receiverId: 'BROADCAST',
      content: 'Emergency Cancelled',
      type: MessageType.system,
    );
  }
}

class BatteryOptimizationService {
  final MeshPlatformChannels _channels;

  BatteryOptimizationService(this._channels);

  Future<void> enablePowerSaving() async {
    await _channels.stopDiscovery();
    await _channels.stopAdvertising();
  }

  Future<void> disablePowerSaving() async {
    await _channels.startDiscovery();
    await _channels.startAdvertising();
  }
}

class FailureHandlingService {
  final MeshPlatformChannels _channels;

  FailureHandlingService(this._channels);

  Future<void> reportFailure(String error) async {}

  Future<void> attemptRecovery() async {
    await _channels.initialize();
  }
}

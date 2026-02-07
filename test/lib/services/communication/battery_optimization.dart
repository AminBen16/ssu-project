import 'dart:async';

import 'package:flutter/services.dart';
import 'package:test/services/communication/messaging_interface.dart';

/// Service to handle battery optimization for background mesh networking
class BatteryOptimizationService implements BatteryOptimization {
  static const MethodChannel _channel = MethodChannel('com.school.ssu/battery');

  bool _isOptimized = false;
  final StreamController<bool> _optimizationController =
      StreamController<bool>.broadcast();

  Stream<bool> get optimizationStream => _optimizationController.stream;

  @override
  Future<void> initialize() async {
    // Check initial state
    try {
      final isIgnoring =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      _isOptimized = isIgnoring ?? false;
      _optimizationController.add(_isOptimized);
    } on PlatformException {
      // Platform not supported or error
    }
  }

  @override
  Future<bool> isCharging() async {
    try {
      final status = await _channel.invokeMethod<String>('getBatteryStatus');
      return status == 'charging' || status == 'full';
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<int> getBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      return level ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  @override
  Future<void> optimizeForBattery() async {
    // Reduce mesh activity to save battery
    // This might involve increasing beacon intervals or stopping discovery
    // when not actively used
    _isOptimized = true;
    _optimizationController.add(true);

    // Notify native layer to enter low power mode if available
    try {
      await _channel.invokeMethod('setLowPowerMode', {'enabled': true});
    } on PlatformException {
      // Ignore
    }
  }

  @override
  Future<void> disableOptimization() async {
    // Resume full mesh activity
    _isOptimized = false;
    _optimizationController.add(false);

    try {
      await _channel.invokeMethod('setLowPowerMode', {'enabled': false});
    } on PlatformException {
      // Ignore
    }
  }

  /// Request permission to ignore battery optimizations (Android Doze mode)
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Adjust mesh parameters based on battery level
  Future<void> adjustMeshParameters() async {
    final level = await getBatteryLevel();
    final charging = await isCharging();

    if (charging) {
      await disableOptimization();
    } else if (level < 20) {
      // Critical battery - aggressive optimization
      await optimizeForBattery();
    } else if (level < 50) {
      // Moderate battery - balanced mode
      // Could implement a 'balanced' mode here
    }
  }
}

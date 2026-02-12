import 'dart:async';
import 'platform_channels.dart';

/// Web-compatible implementation of MeshPlatformChannels
/// This provides no-op implementations since platform channels don't work on web
class MeshPlatformChannelsWeb implements MeshPlatformChannels {
  @override
  Future<void> initialize() async {
    // No-op on web
  }

  @override
  Future<void> startAdvertising() async {
    // No-op on web
  }

  @override
  Future<void> stopAdvertising() async {
    // No-op on web
  }

  @override
  Future<void> startDiscovery() async {
    // No-op on web
  }

  @override
  Future<void> stopDiscovery() async {
    // No-op on web
  }

  @override
  Future<void> sendData(String deviceId, String data) async {
    // No-op on web
  }

  @override
  Future<void> broadcastData(String data) async {
    // No-op on web
  }

  @override
  Stream<Map<String, dynamic>> get onMessageReceived => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> get onPeersChanged => const Stream.empty();

  @override
  Future<Map<String, dynamic>> sendDataToServer(Map<String, dynamic> data) async {
    // No-op on web, return empty map
    return {};
  }

  @override
  Future<void> dispose() async {
    // No-op on web
  }
}

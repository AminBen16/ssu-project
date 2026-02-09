import 'dart:typed_data';
import 'package:test/services/communication/core_models.dart';

export 'package:test/services/communication/core_models.dart';

/// Core messaging interfaces for the communication system

/// Transport manager interface
abstract class TransportManager {
  Future<void> start();
  Future<void> stop();
  Future<void> sendData(String data);
  Stream<String> get dataStream;
  Future<NetworkStatus> getNetworkStatus();
}

/// Message encryption interface
abstract class MessageEncryption {
  Future<String> encrypt(String payload, String recipientId);
  Future<String> decrypt(String encryptedPayload);
  Future<KeyPair> generateKeyPair();
  Future<String> getPublicKey(String deviceId);
  Future<String> encryptVoiceNote(Uint8List audioData, String recipientId);
  Future<Uint8List> decryptVoiceNote(String encryptedVoiceData);
}

/// Transport layer interface
abstract class TransportLayer {
  String get id;
  TransportType get type;
  NetworkStatus get status;
  int get priority;

  Future<void> initialize();
  Future<void> start();
  Future<void> stop();
  Future<bool> sendData(String data, String targetDeviceId);
  Stream<String> get dataStream;
  Future<bool> isAvailable();
}

/// Message storage interface
abstract class MessageStorage {
  Future<void> storeMessage(String messageId, Map<String, dynamic> message);
  Future<Map<String, dynamic>?> getMessage(String messageId);
  Future<List<Map<String, dynamic>>> getMessagesForDevice(String deviceId);
  Future<void> deleteMessage(String messageId);
  Future<void> markMessageDelivered(String messageId);
  Future<List<Map<String, dynamic>>> getPendingMessages();
  Future<void> updateMessageStatus(String messageId, DeliveryStatus status);
  Future<void> deleteExpiredMessages();
  Future<List<Map<String, dynamic>>> getAllMessages();
}

/// Peer discovery interface
abstract class PeerDiscovery {
  Future<void> initialize();
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Stream<List<Peer>> get peerStream;
  Future<List<Peer>> getDiscoveredPeers();
}

/// Platform channels interface for native communication
abstract class MeshPlatformChannels {
  Future<void> initialize();
  Future<bool> isBluetoothAvailable();
  Future<bool> isWifiDirectAvailable();
  Future<bool> enableBluetooth();
  Future<bool> enableWifiDirect();
  Future<List<String>> getConnectedDevices();
  Future<bool> sendDataToDevice(String deviceId, Uint8List data);
  Stream<Uint8List> get dataStream;
  Stream<List<Peer>> get peerDiscoveryStream;
  Stream<String> get dataReceiveStream;
  Stream<MeshStatus> get statusStream;
  Future<bool> startPeerDiscovery();
  Future<bool> stopPeerDiscovery();
  Future<bool> sendDataToPeer(String peerId, String encryptedData);
  Future<bool> broadcastData(String encryptedData);
  Future<MeshStatus?> getMeshStatus();
  Future<bool> connectToPeer(String peerId);
  Future<bool> disconnectFromPeer(String peerId);
}

/// Battery optimization interface
abstract class BatteryOptimization {
  Future<void> initialize();
  Future<bool> isCharging();
  Future<int> getBatteryLevel();
  Future<void> optimizeForBattery();
  Future<void> disableOptimization();
}

/// Emergency mode interface
abstract class EmergencyMode {
  Future<void> initialize();
  Future<void> activateEmergencyMode();
  Future<void> deactivateEmergencyMode();
  Future<bool> isEmergencyActive();
  Future<void> sendEmergencyAlert(String alertData);
}

/// Failure handling interface
abstract class FailureHandling {
  Future<void> initialize();
  Future<void> handleConnectionFailure(String deviceId);
  Future<void> handleMessageFailure(String messageId);
  Future<void> retryFailedMessages();
  Future<Map<String, dynamic>> getFailureStats();
}

/// Store and forward logic interface
abstract class StoreAndForward {
  Future<void> initialize();
  Future<void> storeMessageForLater(String message, String targetDeviceId);
  Future<void> processStoredMessages();
  Future<int> getStoredMessageCount();
  Future<void> clearOldMessages(Duration maxAge);
}

/// Communication service main interface
abstract class CommunicationService {
  Future<void> initialize();
  Future<void> sendMessage(String message, String recipientId);
  Future<void> broadcastMessage(String message);
  Stream<String> get messageStream;
  Future<List<Peer>> getConnectedPeers();
  Future<NetworkStatus> getNetworkStatus();
}

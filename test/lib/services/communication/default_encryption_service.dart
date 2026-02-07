import 'dart:typed_data';
import 'messaging_interface.dart';

/// Default encryption service implementation
class EncryptionService implements MessageEncryption {
  @override
  Future<String> encrypt(String payload, String recipientId) async {
    // Stub implementation - return base64 encoded payload
    return payload;
  }

  @override
  Future<String> decrypt(String encryptedPayload) async {
    // Stub implementation - return payload as-is
    return encryptedPayload;
  }

  @override
  Future<KeyPair> generateKeyPair() async {
    // Stub implementation
    return KeyPair(publicKey: 'public_key', privateKey: 'private_key');
  }

  @override
  Future<String> getPublicKey(String deviceId) async {
    // Stub implementation
    return 'public_key_$deviceId';
  }

  @override
  Future<String> encryptVoiceNote(Uint8List audioData, String recipientId) async {
    return String.fromCharCodes(audioData);
  }

  @override
  Future<Uint8List> decryptVoiceNote(String encryptedVoiceData) async {
    return Uint8List.fromList(encryptedVoiceData.codeUnits);
  }
}

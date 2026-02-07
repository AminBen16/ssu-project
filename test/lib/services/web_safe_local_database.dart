import 'package:test/services/communication/messaging_interface.dart';

/// Web-compatible wrapper for LocalDatabaseService that provides no-op implementations
/// for all MessageStorage methods since local file storage is not available on web.
class WebSafeLocalDatabaseService implements MessageStorage {
  @override
  Future<void> storeMessage(
      String messageId, Map<String, dynamic> message) async {
    // No-op on web - messages are not persisted locally
  }

  @override
  Future<Map<String, dynamic>?> getMessage(String messageId) async {
    return null; // No local storage on web
  }

  @override
  Future<List<Map<String, dynamic>>> getMessagesForDevice(
      String deviceId) async {
    return []; // No local storage on web
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    // No-op on web
  }

  @override
  Future<void> markMessageDelivered(String messageId) async {
    // No-op on web
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    return []; // No local storage on web
  }

  @override
  Future<void> updateMessageStatus(
      String messageId, DeliveryStatus status) async {
    // No-op on web
  }

  @override
  Future<void> deleteExpiredMessages() async {
    // No-op on web
  }

  @override
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    return []; // No local storage on web
  }
}

// Web-safe singleton instance
final webSafeLocalDatabaseService = WebSafeLocalDatabaseService();

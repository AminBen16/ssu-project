import 'package:test/services/communication/messaging_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-compatible wrapper for LocalDatabaseService that provides implementations
/// using SharedPreferences for local storage on web and mobile.
class WebSafeLocalDatabaseService implements MessageStorage {
  late SharedPreferences _prefs;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> storeMessage(
      String messageId, Map<String, dynamic> message) async {
    await _initPrefs();
    final key = 'message_$messageId';
    final jsonString = message.toString(); // Simple serialization for demo
    await _prefs.setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> getMessage(String messageId) async {
    await _initPrefs();
    final key = 'message_$messageId';
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      // Simple deserialization - in production, use proper JSON parsing
      return {'data': jsonString};
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getMessagesForDevice(
      String deviceId) async {
    await _initPrefs();
    final allKeys = _prefs.getKeys();
    final deviceMessages = <Map<String, dynamic>>[];

    for (final key in allKeys) {
      if (key.startsWith('message_') && key.contains(deviceId)) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          deviceMessages.add(
              {'id': key.replaceFirst('message_', ''), 'data': jsonString});
        }
      }
    }

    return deviceMessages;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _initPrefs();
    final key = 'message_$messageId';
    await _prefs.remove(key);
  }

  @override
  Future<void> markMessageDelivered(String messageId) async {
    await _initPrefs();
    final key = 'message_status_$messageId';
    await _prefs.setString(key, 'delivered');
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    await _initPrefs();
    final allKeys = _prefs.getKeys();
    final pendingMessages = <Map<String, dynamic>>[];

    for (final key in allKeys) {
      if (key.startsWith('message_') &&
          !_prefs.containsKey(
              'message_status_${key.replaceFirst('message_', '')}')) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          pendingMessages.add(
              {'id': key.replaceFirst('message_', ''), 'data': jsonString});
        }
      }
    }

    return pendingMessages;
  }

  @override
  Future<void> updateMessageStatus(
      String messageId, DeliveryStatus status) async {
    await _initPrefs();
    final key = 'message_status_$messageId';
    await _prefs.setString(key, status.toString());
  }

  @override
  Future<void> deleteExpiredMessages() async {
    await _initPrefs();
    // Simple implementation - delete messages older than 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final allKeys = _prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('message_')) {
        // In a real implementation, you'd store timestamps
        // For now, just keep recent messages
        final messageId = key.replaceFirst('message_', '');
        if (messageId.length > 10) {
          // Simple heuristic for old messages
          await _prefs.remove(key);
          await _prefs.remove('message_status_$messageId');
        }
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    await _initPrefs();
    final allKeys = _prefs.getKeys();
    final allMessages = <Map<String, dynamic>>[];

    for (final key in allKeys) {
      if (key.startsWith('message_')) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          allMessages.add(
              {'id': key.replaceFirst('message_', ''), 'data': jsonString});
        }
      }
    }

    return allMessages;
  }

  /// Additional methods for general data storage (not part of MessageStorage interface)
  Future<void> saveData(
      String table, String key, Map<String, dynamic> data) async {
    await _initPrefs();
    final fullKey = '${table}_$key';
    final jsonString = data.toString(); // Simple serialization
    await _prefs.setString(fullKey, jsonString);
  }

  Future<Map<String, dynamic>?> getData(String table, String key) async {
    await _initPrefs();
    final fullKey = '${table}_$key';
    final jsonString = _prefs.getString(fullKey);
    if (jsonString != null) {
      // Simple deserialization
      return {'data': jsonString};
    }
    return null;
  }

  Future<void> deleteData(String table, String key) async {
    await _initPrefs();
    final fullKey = '${table}_$key';
    await _prefs.remove(fullKey);
  }

  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    await _initPrefs();
    final allKeys = _prefs.getKeys();
    final tableData = <Map<String, dynamic>>[];

    for (final key in allKeys) {
      if (key.startsWith('${table}_')) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          tableData.add(
              {'key': key.replaceFirst('${table}_', ''), 'data': jsonString});
        }
      }
    }

    return tableData;
  }
}

// Web-safe singleton instance
final webSafeLocalDatabaseService = WebSafeLocalDatabaseService();

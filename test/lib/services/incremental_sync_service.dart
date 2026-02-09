import 'package:flutter/foundation.dart';
import 'package:test/services/platform_channels.dart';

/// Incremental synchronization service for efficient data sync
/// Reduces bandwidth usage and improves offline performance
class IncrementalSyncService {
  final MeshPlatformChannels _meshChannels;

  IncrementalSyncService(this._meshChannels);

  /// Syncs only changed data to minimize bandwidth
  static Future<Map<String, dynamic>> syncIncremental({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required String entityType,
    DateTime? lastSyncTime,
  }) async {
    debugPrint('Starting incremental sync for $entityType');
    
    final changes = <String, dynamic>{};
    final timestamp = DateTime.now().toIso8601String();
    
    // Compare local and server data to find changes
    for (final key in localData.keys) {
      if (!serverData.containsKey(key)) {
        // New local data, send to server
        changes[key] = {
          'action': 'create',
          'data': localData[key],
          'timestamp': timestamp,
        };
      } else {
        final localValue = localData[key];
        final serverValue = serverData[key];
        
        if (localValue.toString() != serverValue.toString()) {
          // Data changed, send update
          changes[key] = {
            'action': 'update',
            'old_value': localValue,
            'new_value': serverValue,
            'timestamp': timestamp,
          };
        }
      }
    }
    
    // Check for server-side changes not present locally
    for (final key in serverData.keys) {
      if (!localData.containsKey(key)) {
        changes[key] = {
          'action': 'delete',
          'data': serverData[key],
          'timestamp': timestamp,
        };
      }
    }
    
    if (changes.isEmpty) {
      debugPrint('No changes to sync');
      return {
        'action': 'no_changes',
        'timestamp': timestamp,
        'changes': [],
      };
    }
    
    // Send changes to server for processing
    try {
      final response = await _meshChannels.sendDataToServer({
        'entityType': entityType,
        'changes': changes,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      });
      
      debugPrint('Incremental sync completed: ${changes.length} changes');
      return {
        'action': 'completed',
        'timestamp': timestamp,
        'changes': changes,
        'server_response': response,
      };
    } catch (e) {
      debugPrint('Incremental sync failed: $e');
      return {
        'action': 'error',
        'timestamp': timestamp,
        'error': e.toString(),
        'changes': changes,
      };
    }
  }

  /// Gets sync status for monitoring
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await _meshChannels.getSyncStatus();
      return response;
    } catch (e) {
      debugPrint('Failed to get sync status: $e');
      return {
        'action': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'local_database_service.dart';
import 'api_client.dart';

/// Conflict resolution strategies
const String conflictStrategyServerWins = 'server_wins';
const String conflictStrategyClientWins = 'client_wins';
const String conflictStrategyManual = 'manual';

/// Offline-first service wrapper that provides caching and sync functionality.
/// Wraps API calls with local storage fallbacks and background synchronization.
class OfflineService {
  final ApiClient _apiClient;
  final LocalDatabaseService _localDb;
  final Connectivity _connectivity;
  final Logger _logger = Logger();

  OfflineService({
    ApiClient? apiClient,
    LocalDatabaseService? localDb,
    Connectivity? connectivity,
  })  : _apiClient = apiClient ?? ApiClient(),
        _localDb = localDb ?? localDatabaseService,
        _connectivity = connectivity ?? Connectivity();

  /// Check if device is online
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Generic offline-first API call wrapper
  Future<T> callWithOfflineFallback<T>({
    required Future<T> Function() onlineCall,
    required Future<T?> Function() offlineFallback,
    required String cacheKey,
    Duration cacheDuration = const Duration(hours: 24),
  }) async {
    final online = await isOnline;

    if (online) {
      try {
        final result = await onlineCall();
        // Cache successful online results
        await _cacheResult(cacheKey, result);
        return result;
      } catch (e) {
        // Online call failed, try offline fallback
        final cached = await offlineFallback();
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    } else {
      // Offline mode - use cached data
      final cached = await offlineFallback();
      if (cached != null) {
        return cached;
      }
      throw Exception('No internet connection and no cached data available');
    }
  }

  /// Cache result with timestamp
  Future<void> _cacheResult(String key, dynamic data) async {
    final cacheData = {
      'key': key,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _localDb.setMetadata('cache_$key', jsonEncode(cacheData));
  }

  /// Queue operation for later sync
  Future<void> queueForSync(String operation, Map<String, dynamic> data) async {
    await _localDb.addToSyncQueue(data['table'] ?? 'unknown', operation, data);
  }

  /// Process sync queue when online
  Future<void> processSyncQueue() async {
    final online = await isOnline;
    if (!online) return;

    final pendingOperations = await _localDb.getPendingSyncOperations();

    for (final operation in pendingOperations) {
      try {
        // Process each operation based on type
        await _processSyncOperation(operation);
        await _localDb.removeFromSyncQueue(operation['id']);
      } catch (e) {
        // Increment retry count
        final retryCount = (operation['retryCount'] ?? 0) + 1;
        if (retryCount < 3) {
          // Max 3 retries
          await _localDb.updateSyncRetryCount(
              int.parse(operation['id'].toString()), retryCount, e.toString());
        } else {
          // Remove failed operations after max retries
          await _localDb
              .removeFromSyncQueue(int.parse(operation['id'].toString()));
        }
      }
    }
  }

  /// Process individual sync operation
  Future<void> _processSyncOperation(Map<String, dynamic> operation) async {
    final tableName = operation['tableName'];
    final operationType = operation['operation'];
    final data = jsonDecode(operation['data']) as Map<String, dynamic>;

    // Check for custom endpoint in data
    String endpoint = '/$tableName';
    if (data.containsKey('__endpoint')) {
      endpoint = data['__endpoint'];
      data.remove('__endpoint');
    }

    switch (operationType) {
      case 'insert':
        await _apiClient.post(endpoint, body: data);
        break;
      case 'update':
        await _apiClient.put('$endpoint/${data['id']}', body: data);
        break;
      case 'delete':
        await _apiClient.delete('$endpoint/${data['id']}');
        break;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _localDb.clearCache();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final dbSize = await _localDb.getDatabaseSize();
    final pendingSync = await _localDb.getPendingSyncOperations();

    return {
      'databaseSize': dbSize,
      'pendingSyncOperations': pendingSync.length,
      'cacheEnabled': true,
    };
  }

  /// Enhanced offline-first API call with conflict resolution
  Future<T> callWithOfflineFallbackAndSync<T>({
    required Future<T> Function() onlineCall,
    required Future<T?> Function() offlineFallback,
    required String cacheKey,
    required String tableName,
    required String recordId,
    Duration cacheDuration = const Duration(hours: 24),
    String conflictStrategy = conflictStrategyServerWins,
  }) async {
    final online = await isOnline;

    if (online) {
      try {
        final result = await onlineCall();
        // Cache successful online results
        await _cacheResult(cacheKey, result);
        // Also save to local database for offline access
        if (result is Map<String, dynamic>) {
          await _localDb.saveData(tableName, recordId, result);
        }
        return result;
      } catch (e) {
        // Online call failed, try offline fallback
        final cached = await offlineFallback();
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    } else {
      // Offline mode - use cached data
      final cached = await offlineFallback();
      if (cached != null) {
        return cached;
      }
      throw Exception('No internet connection and no cached data available');
    }
  }

  /// Sync data between local and server with conflict resolution
  Future<void> syncDataWithConflictResolution({
    required String tableName,
    required String recordId,
    required Future<Map<String, dynamic>?> Function() fetchServerData,
    required Future<Map<String, dynamic>?> Function() getLocalData,
    required Future<void> Function(Map<String, dynamic>) updateServerData,
    required Future<void> Function(Map<String, dynamic>) updateLocalData,
    String conflictStrategy = conflictStrategyServerWins,
  }) async {
    final online = await isOnline;
    if (!online) return;

    try {
      final serverData = await fetchServerData();
      final localData = await getLocalData();

      if (serverData == null && localData == null) return;

      if (serverData == null && localData != null) {
        // Local data exists but server doesn't - upload local data
        await updateServerData(localData);
        return;
      }

      if (serverData != null && localData == null) {
        // Server data exists but local doesn't - download server data
        await updateLocalData(serverData);
        return;
      }

      // Both exist - check for conflicts
      if (serverData != null && localData != null) {
        final conflict = await _detectConflict(serverData, localData);
        if (conflict) {
          await _resolveConflict(
            serverData: serverData,
            localData: localData,
            tableName: tableName,
            recordId: recordId,
            updateServerData: updateServerData,
            updateLocalData: updateLocalData,
            strategy: conflictStrategy,
          );
        }
      }
    } catch (e) {
      // Log error but don't throw - sync failures shouldn't break the app
      _logger.e('Sync error for $tableName:$recordId: $e');
    }
  }

  /// Detect if there's a conflict between server and local data
  Future<bool> _detectConflict(
      Map<String, dynamic> serverData, Map<String, dynamic> localData) async {
    // Simple conflict detection based on last modified timestamp
    final serverModified =
        serverData['updatedAt'] ?? serverData['lastModified'];
    final localModified = localData['updatedAt'] ?? localData['lastModified'];

    if (serverModified == null || localModified == null) {
      // If no timestamps, compare data content
      return !_areDataEqual(serverData, localData);
    }

    final serverTime = DateTime.tryParse(serverModified.toString());
    final localTime = DateTime.tryParse(localModified.toString());

    if (serverTime == null || localTime == null) {
      return !_areDataEqual(serverData, localData);
    }

    // Conflict if both were modified after the other was last synced
    return serverTime.isAfter(localTime) &&
        localTime.isAfter(serverTime.subtract(const Duration(seconds: 1)));
  }

  /// Check if two data objects are equal (ignoring timestamps)
  bool _areDataEqual(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    final copy1 = Map<String, dynamic>.from(data1);
    final copy2 = Map<String, dynamic>.from(data2);

    // Remove timestamp fields for comparison
    copy1.remove('updatedAt');
    copy1.remove('lastModified');
    copy1.remove('createdAt');
    copy2.remove('updatedAt');
    copy2.remove('lastModified');
    copy2.remove('createdAt');

    return jsonEncode(copy1) == jsonEncode(copy2);
  }

  /// Resolve conflicts based on strategy
  Future<void> _resolveConflict({
    required Map<String, dynamic> serverData,
    required Map<String, dynamic> localData,
    required String tableName,
    required String recordId,
    required Future<void> Function(Map<String, dynamic>) updateServerData,
    required Future<void> Function(Map<String, dynamic>) updateLocalData,
    required String strategy,
  }) async {
    switch (strategy) {
      case conflictStrategyServerWins:
        await updateLocalData(serverData);
        break;
      case conflictStrategyClientWins:
        await updateServerData(localData);
        break;
      case conflictStrategyManual:
        // For manual resolution, keep both and mark for user review
        await _queueConflictForManualResolution(
            tableName, recordId, serverData, localData);
        break;
      default:
        // Default to server wins
        await updateLocalData(serverData);
    }
  }

  /// Queue conflict for manual resolution
  Future<void> _queueConflictForManualResolution(
    String tableName,
    String recordId,
    Map<String, dynamic> serverData,
    Map<String, dynamic> localData,
  ) async {
    final conflictData = {
      'tableName': tableName,
      'recordId': recordId,
      'serverData': serverData,
      'localData': localData,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _localDb.setMetadata(
        'conflict_${tableName}_$recordId', jsonEncode(conflictData));
  }

  /// Get pending conflicts for manual resolution
  Future<List<Map<String, dynamic>>> getPendingConflicts() async {
    final conflicts = <Map<String, dynamic>>[];

    // Get all metadata keys that start with 'conflict_'
    // Since we don't have a direct way to list all metadata keys,
    // we'll check for common conflict patterns
    final tables = [
      'notifications',
      'students',
      'staff',
      'exams',
      'assignments',
      'fees',
      'books'
    ];

    for (final table in tables) {
      try {
        final conflictKey = 'conflict_${table}_';
        // This is a simplified approach - in a real implementation,
        // you'd need to scan all metadata or maintain a conflict index
        final conflictJson = await _localDb.getMetadata(conflictKey);
        if (conflictJson != null) {
          final conflict = jsonDecode(conflictJson) as Map<String, dynamic>;
          conflicts.add(conflict);
        }
      } catch (e) {
        // Continue checking other tables
        continue;
      }
    }

    return conflicts;
  }

  /// Resolve manual conflict
  Future<void> resolveManualConflict(
    String tableName,
    String recordId,
    Map<String, dynamic> resolvedData,
    bool updateServer,
  ) async {
    if (updateServer) {
      // Update server with resolved data
      // This would need to be implemented based on the specific API
    } else {
      // Update local data
      await _localDb.saveData(tableName, recordId, resolvedData);
    }

    // Remove conflict record
    await _localDb.setMetadata('conflict_${tableName}_$recordId', '');
  }

  /// Bulk sync all data for a user
  Future<void> performBulkSync({
    required String userId,
    required String schoolId,
    required Map<String, Future<void> Function()> syncOperations,
  }) async {
    final online = await isOnline;
    if (!online) return;

    for (final entry in syncOperations.entries) {
      try {
        await entry.value();
      } catch (e) {
        _logger.e('Bulk sync failed for ${entry.key}: $e');
        // Continue with other sync operations
      }
    }
  }

  /// Get offline data status
  Future<Map<String, dynamic>> getOfflineDataStatus() async {
    final dbStats = await _localDb.getDatabaseSize();
    final pendingSync = await _localDb.getPendingSyncOperations();
    final online = await isOnline;

    return {
      'isOnline': online,
      'databaseStats': dbStats,
      'pendingSyncCount': pendingSync.length,
      'lastSyncTime': await _localDb.getMetadata('last_sync_time'),
    };
  }

  /// Get cached data by key
  Future<dynamic> getCachedData(String key) async {
    final cached = await _localDb.getCache(key);
    if (cached != null) {
      return jsonDecode(cached);
    }
    return null;
  }

  /// Force refresh all cached data
  Future<void> forceRefreshCache() async {
    await _localDb.clearCache();
    await _localDb.clearExpiredCache();
  }

  /// Remove operation from sync queue by ID
  Future<void> removeFromSyncQueue(String operationId) async {
    await _localDb.removeFromSyncQueue(int.parse(operationId));
  }
}

// Singleton instance
final offlineService = OfflineService();

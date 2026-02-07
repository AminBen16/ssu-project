import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test/services/student_offline_sync_service.dart';

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  final StudentOfflineSyncService _syncService = StudentOfflineSyncService();
  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final queue = await _syncService.getPendingOperations();
      if (mounted) {
        setState(() {
          _queue = queue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncAll() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await _syncService.syncNow();
      await _loadQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Queue'),
        actions: [
          if (_queue.isNotEmpty)
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('All caught up!', style: TextStyle(fontSize: 18)),
                      Text('No pending operations.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _queue.length,
                  itemBuilder: (context, index) {
                    final item = _queue[index];
                    final timestamp = item['timestamp'] as int? ?? 0;
                    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                    final type = item['type'] as String? ?? 'Unknown';
                    final data = item['data'] as Map<String, dynamic>? ?? {};

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.schedule,
                              color: Colors.orange.shade800),
                        ),
                        title: Text(type.toUpperCase()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('MMM d, y HH:mm').format(date)),
                            if (data.isNotEmpty)
                              Text(
                                data.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            // Implement delete logic if supported by service
                            // For now just refresh
                            await _loadQueue();
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

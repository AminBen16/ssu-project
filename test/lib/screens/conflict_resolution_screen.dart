import 'package:flutter/material.dart';
import 'package:test/services/offline_service.dart';

class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  List<Map<String, dynamic>> _pendingConflicts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingConflicts();
  }

  Future<void> _loadPendingConflicts() async {
    setState(() => _isLoading = true);
    try {
      _pendingConflicts = await offlineService.getPendingConflicts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conflicts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Data Conflicts'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingConflicts.isEmpty
              ? _buildEmptyState()
              : _buildConflictsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Conflicts to Resolve',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'All data conflicts have been resolved.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConflictsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingConflicts.length,
      itemBuilder: (context, index) {
        final conflict = _pendingConflicts[index];
        return _buildConflictCard(conflict);
      },
    );
  }

  Widget _buildConflictCard(Map<String, dynamic> conflict) {
    final tableName = conflict['tableName'] as String? ?? 'Unknown';
    final recordId = conflict['recordId'] as String? ?? 'Unknown';
    final serverData = conflict['serverData'] as Map<String, dynamic>? ?? {};
    final localData = conflict['localData'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data Conflict',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    tableName.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.blue.shade100,
                  labelStyle: TextStyle(color: Colors.blue.shade800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Record ID: $recordId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose which version to keep:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDataOption(
                    title: 'Server Version',
                    subtitle: 'Latest from school server',
                    data: serverData,
                    icon: Icons.cloud_download,
                    color: Colors.blue,
                    onTap: () => _resolveConflict(
                      conflict,
                      useServerData: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataOption(
                    title: 'Local Version',
                    subtitle: 'Your offline changes',
                    data: localData,
                    icon: Icons.phone_android,
                    color: Colors.green,
                    onTap: () => _resolveConflict(
                      conflict,
                      useServerData: false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataOption({
    required String title,
    required String subtitle,
    required Map<String, dynamic> data,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(77)),
          borderRadius: BorderRadius.circular(8),
          color: color.withAlpha(13),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildDataPreview(data),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPreview(Map<String, dynamic> data) {
    // Show key fields based on data type
    final previewFields = <String>[];

    if (data.containsKey('title')) {
      previewFields.add('Title: ${data['title']}');
    }
    if (data.containsKey('message')) {
      previewFields.add('Message: ${data['message']}');
    }
    if (data.containsKey('name')) {
      previewFields.add('Name: ${data['name']}');
    }
    if (data.containsKey('amount')) {
      previewFields.add('Amount: ${data['amount']}');
    }
    if (data.containsKey('updatedAt')) {
      final date = DateTime.tryParse(data['updatedAt']?.toString() ?? '');
      if (date != null) {
        previewFields.add('Updated: ${date.toString().split(' ')[0]}');
      }
    }

    if (previewFields.isEmpty) {
      return Text(
        'No preview available',
        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: previewFields
          .take(2)
          .map((field) => Text(
                field,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))
          .toList(),
    );
  }

  Future<void> _resolveConflict(Map<String, dynamic> conflict,
      {required bool useServerData}) async {
    final tableName = conflict['tableName'] as String;
    final recordId = conflict['recordId'] as String;
    final resolvedData = useServerData
        ? conflict['serverData'] as Map<String, dynamic>
        : conflict['localData'] as Map<String, dynamic>;

    try {
      await offlineService.resolveManualConflict(
        tableName,
        recordId,
        resolvedData,
        !useServerData, // If using local data, update server
      );

      // Remove from local list
      setState(() {
        _pendingConflicts.remove(conflict);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Conflict resolved using ${useServerData ? 'server' : 'local'} data'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve conflict: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

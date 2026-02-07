import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/curriculum_integrity_audit_service.dart';

/// Curriculum Integrity Audit Screen
class CurriculumIntegrityAuditScreen extends StatefulWidget {
  const CurriculumIntegrityAuditScreen({Key? key}) : super(key: key);

  @override
  _CurriculumIntegrityAuditScreenState createState() => _CurriculumIntegrityAuditScreenState();
}

class _CurriculumIntegrityAuditScreenState extends State<CurriculumIntegrityAuditScreen> {
  bool _isAuditing = false;
  String _auditProgress = '';
  Map<String, dynamic>? _auditResults;
  Map<String, dynamic>? _healthCheck;

  @override
  void initState() {
    super.initState();
    _loadHealthCheck();
  }

  Future<void> _loadHealthCheck() async {
    final healthCheck = await CurriculumIntegrityAuditService.getQuickHealthCheck();
    setState(() {
      _healthCheck = healthCheck;
    });
  }

  Future<void> _performFullAudit() async {
    setState(() {
      _isAuditing = true;
      _auditProgress = 'Starting comprehensive integrity audit...';
      _auditResults = null;
    });

    try {
      final results = await CurriculumIntegrityAuditService.performFullAudit();
      
      setState(() {
        _auditResults = results;
        _isAuditing = false;
        _auditProgress = 'Audit completed successfully!';
      });

      // Show results dialog
      _showAuditResults();
    } catch (e) {
      setState(() {
        _isAuditing = false;
        _auditProgress = 'Audit failed: $e';
      });
    }
  }

  void _showAuditResults() {
    if (_auditResults == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _auditResults!['overallStatus'] == 'PASS' 
                  ? Icons.check_circle 
                  : Icons.error,
              color: _auditResults!['overallStatus'] == 'PASS' 
                  ? Colors.green 
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Audit Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Overall Status: ${_auditResults!['overallStatus']}'),
              Text('Total Checks: ${_auditResults!['totalChecks']}'),
              Text('Passed: ${_auditResults!['passedChecks']}'),
              Text('Failed: ${_auditResults!['failedChecks']}'),
              const SizedBox(height: 16),
              const Text('Validation Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(_auditResults!['validationResults'] as Map<String, dynamic>).entries.map((entry) {
                final validation = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        validation['status'] == 'PASS' 
                            ? Icons.check_circle 
                            : validation['status'] == 'WARN' 
                                ? Icons.warning 
                                : Icons.error,
                        color: validation['status'] == 'PASS' 
                            ? Colors.green 
                            : validation['status'] == 'WARN' 
                                ? Colors.orange 
                                : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(validation['checkName'])),
                    ],
                  ),
                );
              }).toList(),
              if (_auditResults!['errors'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ...(_auditResults!['errors'] as List<String>).take(5).map((error) => 
                  Text('• $error', style: const TextStyle(color: Colors.red, fontSize: 12))
                ).toList(),
                if ((_auditResults!['errors'] as List<String>).length > 5)
                  Text('... and ${(_auditResults!['errors'] as List<String>).length - 5} more errors'),
              ],
              if (_auditResults!['warnings'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ...(_auditResults!['warnings'] as List<String>).take(5).map((warning) => 
                  Text('• $warning', style: const TextStyle(color: Colors.orange, fontSize: 12))
                ).toList(),
                if ((_auditResults!['warnings'] as List<String>).length > 5)
                  Text('... and ${(_auditResults!['warnings'] as List<String>).length - 5} more warnings'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateReport();
            },
            child: const Text('Generate Report'),
          ),
        ],
      ),
    );
  }

  void _generateReport() {
    if (_auditResults == null) return;

    final report = CurriculumIntegrityAuditService.generateAuditReport(_auditResults!);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(report),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum Integrity Audit'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthStatusCard(),
            const SizedBox(height: 16),
            _buildAuditActionsCard(),
            const SizedBox(height: 16),
            if (_auditProgress.isNotEmpty) _buildProgressCard(),
            const SizedBox(height: 16),
            if (_auditResults != null) _buildAuditSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    if (_healthCheck == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final status = _healthCheck!['status'] as String;
    final totalIssues = _healthCheck!['totalIssues'] as int;
    final issues = _healthCheck!['issues'] as List<String>;

    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'HEALTHY':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'WARNING':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'CRITICAL':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Health',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadHealthCheck,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Health Check',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalIssues > 0) ...[
              Text(
                'Issues Found ($totalIssues):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...issues.map((issue) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(issue)),
                  ],
                ),
              )).toList(),
            ] else ...[
              const Text(
                'All systems operating normally',
                style: TextStyle(color: Colors.green),
              ),
            ],
            if (_healthCheck!['statistics'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Database Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatRow('Subjects', _healthCheck!['statistics']['subjects']),
              _buildStatRow('Strands', _healthCheck!['statistics']['strands']),
              _buildStatRow('Topics', _healthCheck!['statistics']['topics']),
              _buildStatRow('Learning Outcomes', _healthCheck!['statistics']['learningOutcomes']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:'),
          ),
          Text(
            value?.toString() ?? '0',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Integrity Audit Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Perform comprehensive integrity checks to validate curriculum data quality, consistency, and NCDC standards compliance.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAuditing ? null : _performFullAudit,
                icon: _isAuditing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.security),
                label: Text(_isAuditing ? 'Auditing...' : 'Perform Full Audit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The full audit includes:\n'
              '• Database structure validation\n'
              '• Data completeness checks\n'
              '• Data consistency verification\n'
              '• NCDC standards compliance\n'
              '• Relationship integrity\n'
              '• Content quality assessment\n'
              '• Performance metrics validation',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audit in Progress',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_auditProgress),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditSummaryCard() {
    if (_auditResults == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Audit Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Overall Status',
                    _auditResults!['overallStatus'],
                    _auditResults!['overallStatus'] == 'PASS' ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Checks',
                    _auditResults!['totalChecks'].toString(),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Passed',
                    _auditResults!['passedChecks'].toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Failed',
                    _auditResults!['failedChecks'].toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.description),
                label: const Text('Generate Detailed Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

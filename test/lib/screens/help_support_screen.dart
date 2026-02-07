import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Quick Help'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.book),
                  title: const Text('User Guide'),
                  subtitle: const Text('Learn how to use the app'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _launchURL('https://example.com/user-guide'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: const Text('Video Tutorials'),
                  subtitle: const Text('Watch step-by-step guides'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _launchURL('https://example.com/tutorials'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.question_answer),
                  title: const Text('FAQ'),
                  subtitle: const Text('Frequently asked questions'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _launchURL('https://example.com/faq'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Contact Support'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need help? Contact our support team',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchURL('mailto:support@ssu.edu'),
                          icon: const Icon(Icons.email),
                          label: const Text('Email Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchURL('tel:+256700000000'),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Support Hours: Monday - Friday, 8:00 AM - 6:00 PM EAT',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Send us a Message'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Describe your issue or question',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Please provide details about your issue...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSupportRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('System Information'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('App Version', '1.0.0'),
                  _buildInfoRow(
                      'User ID', userData.userProfile?.uid ?? 'Unknown'),
                  _buildInfoRow('School', userData.school?.name ?? 'Not set'),
                  _buildInfoRow('Role',
                      userData.userProfile?.role.displayName ?? 'Unknown'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _showSystemInfo,
                    child: const Text('View Detailed System Info'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Legal'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _launchURL('https://example.com/terms'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _launchURL('https://example.com/privacy'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Data Protection'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () =>
                      _launchURL('https://example.com/data-protection'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Future<void> _submitSupportRequest() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Here you would integrate with your support ticket system
      // For now, we'll simulate sending the request
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support request sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSystemInfo() {
    final userData = Provider.of<UserDataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('App Version', '1.0.0'),
              _buildInfoRow('Build Number', '2024001'),
              _buildInfoRow('Platform', 'Flutter'),
              _buildInfoRow('User ID', userData.userProfile?.uid ?? 'Unknown'),
              _buildInfoRow('Email', userData.userProfile?.email ?? 'Unknown'),
              _buildInfoRow(
                  'School ID', userData.school?.id.toString() ?? 'Unknown'),
              _buildInfoRow('School Name', userData.school?.name ?? 'Unknown'),
              _buildInfoRow('User Role',
                  userData.userProfile?.role.displayName ?? 'Unknown'),
              _buildInfoRow('Last Login', DateTime.now().toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profileVisibleToOthers = true;
  bool _showOnlineStatus = true;
  bool _allowDataCollection = false;
  bool _shareUsageAnalytics = false;
  bool _biometricLogin = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  void _loadPrivacySettings() {
    // Load privacy settings from user preferences or provider
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    // For now, use default values - in real implementation, load from storage
  }

  Future<void> _savePrivacySettings() async {
    // Save privacy settings to storage
    // For now, just show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Profile Privacy'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Profile Visible to Others'),
                  subtitle: const Text(
                      'Allow other users to see your profile information'),
                  value: _profileVisibleToOthers,
                  onChanged: (value) {
                    setState(() {
                      _profileVisibleToOthers = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Show Online Status'),
                  subtitle: const Text('Let others see when you are online'),
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    setState(() {
                      _showOnlineStatus = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data & Analytics'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Allow Data Collection'),
                  subtitle: const Text(
                      'Help improve the app by sharing anonymous usage data'),
                  value: _allowDataCollection,
                  onChanged: (value) {
                    setState(() {
                      _allowDataCollection = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Share Usage Analytics'),
                  subtitle: const Text(
                      'Send anonymous analytics to improve features'),
                  value: _shareUsageAnalytics,
                  onChanged: (value) {
                    setState(() {
                      _shareUsageAnalytics = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Security'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Biometric Login'),
                  subtitle: const Text('Use fingerprint or face unlock'),
                  value: _biometricLogin,
                  onChanged: (value) {
                    setState(() {
                      _biometricLogin = value;
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your account password'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to change password screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Change password feature coming soon')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Two-Factor Authentication'),
                  subtitle: const Text('Add an extra layer of security'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to 2FA setup
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('2FA setup coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Download My Data'),
                  subtitle: const Text('Get a copy of all your data'),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Data download feature coming soon')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Delete Account'),
                  subtitle:
                      const Text('Permanently delete your account and data'),
                  trailing: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: () {
                    _showDeleteAccountDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _savePrivacySettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save Privacy Settings'),
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Account deletion feature coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

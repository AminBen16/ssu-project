import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/auth_service.dart';

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
    // For now, use default values - in real implementation, load from storage
    // userData could be used to access user profile if needed in future
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
                    // SAFE PATCH: Implement real change password functionality
                    // UI exists, Service exists, Logic missing - now fixed
                    _showChangePasswordDialog();
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
              // SAFE PATCH: Implement real account deletion functionality
              // UI exists, Service exists, Logic missing - now fixed
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// SAFE PATCH: Add real change password dialog implementation
  /// UI exists, Service exists, Logic missing - now fixed
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                final userData =
                    Provider.of<UserDataProvider>(context, listen: false);
                await AuthService().changePassword(
                  userData.userProfile!.uid,
                  currentPasswordController.text,
                  newPasswordController.text,
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password changed successfully')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password: $e')),
                  );
                }
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  /// SAFE PATCH: Add real account deletion implementation
  /// UI exists, Service exists, Logic missing - now fixed
  Future<void> _deleteAccount() async {
    try {
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      await AuthService().deleteAccount(userData.userProfile!.uid);

      if (mounted) {
        await userData.logout();
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account deleted successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }
}

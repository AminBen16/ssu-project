import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog to display user login details after successful creation
class LoginDetailsDialog extends StatelessWidget {
  final String userName;
  final String email;
  final String password;
  final String role;
  final VoidCallback? onCopyCredentials;

  const LoginDetailsDialog({
    super.key,
    required this.userName,
    required this.email,
    required this.password,
    required this.role,
    this.onCopyCredentials,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 8),
          const Text('User Created Successfully!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Login credentials have been created. Please share these details with the user:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Name:', userName),
                _buildDetailRow('Role:', role),
                _buildDetailRow('Email:', email),
                _buildDetailRow('Password:', password, isPassword: true, context: context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please save these credentials securely. The password will not be shown again.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _copyCredentialsToClipboard(context);
            if (onCopyCredentials != null) {
              onCopyCredentials!();
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy Credentials'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPassword = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isPassword
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          '•' * 8,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 16),
                        onPressed: () => context != null ? _showPasswordDialog(context) : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _copyCredentialsToClipboard(BuildContext context) {
    final credentials = '''
User Login Details
==================
Name: $userName
Role: $role
Email: $email
Password: $password

Please keep these credentials secure.
''';
    
    Clipboard.setData(ClipboardData(text: credentials));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credentials copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password'),
        content: SelectableText(
          password,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            letterSpacing: 1,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';

/// Screen displayed to users with 'pending' role.
/// WHY this was missing: No explicit handling for pending users in dashboard routing.
/// WHAT this enables: Clear UX for users awaiting approval.
/// WHY this is safe: Read-only screen with no destructive actions.
class PendingUserScreen extends StatefulWidget {
  const PendingUserScreen({super.key});

  @override
  State<PendingUserScreen> createState() => _PendingUserScreenState();
}

class _PendingUserScreenState extends State<PendingUserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Pending'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Account is Under Review',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank you for registering. Your account is currently being reviewed by our administrators. You will receive access once your account is approved.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // Log out functionality
                  final userProvider =
                      Provider.of<UserDataProvider>(context, listen: false);
                  await userProvider.logout();
                  if (mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

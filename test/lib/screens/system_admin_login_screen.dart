import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:test/services/auth_service.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/widgets/auth_wrapper.dart';

class SystemAdminLoginScreen extends StatefulWidget {
  const SystemAdminLoginScreen({super.key});

  @override
  State<SystemAdminLoginScreen> createState() => _SystemAdminLoginScreenState();
}

class _SystemAdminLoginScreenState extends State<SystemAdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final String enteredEmail = _usernameController.text.trim();
      final String enteredPassword = _passwordController.text.trim();

      // Use the AuthService for admin login with role validation
      await _authService.signInAdmin(
        email: enteredEmail,
        password: enteredPassword,
      );

      if (!mounted) return;
      // On success, AuthWrapper will handle navigation.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(Uri url) async {
    // Use `launchUrl` to open the URL. `externalApplication` mode is often
    // best for things like mail, phone, or WhatsApp.
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch ${url.toString()}')),
        );
      }
    }
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Help & Support',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('support@school.com'),
                subtitle: const Text('Contact Email'),
                onTap: () {
                  _launchUrl(Uri.parse('mailto:support@school.com'));
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      onPressed: () => _launchUrl(Uri.parse('tel:+1234567890')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: const Text('WhatsApp'),
                      onPressed: () => _launchUrl(
                        Uri.parse(
                          'https://wa.me/1234567890?text=Hello,%20I%20need%20help.',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Systems Admin Portal')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.security,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, Systems Admin!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'Use the Username and Password provided by the School Owner or Senior System Admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _signIn,
                text: 'Sign In',
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _showHelpSheet(context),
                child: const Text('Need Help?'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

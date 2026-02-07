import 'package:flutter/material.dart';

/// A modern, branded splash screen shown while the app is initializing.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ugandan Flag Emoji
              const Text('🇺🇬', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                'SMART SCHOOLS SYSTEM UGANDA',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('(SSU)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

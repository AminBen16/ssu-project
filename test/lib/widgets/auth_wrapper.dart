import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/admin_setup_screen.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/screens/login_screen.dart';
import 'package:test/screens/dashboard_screen.dart';

/// A widget that wraps the entire app and directs users to the correct screen
/// based on their authentication status and user profile data.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen for changes in the UserDataProvider.
    // This will rebuild the widget tree whenever the user's auth state or profile changes.
    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, child) {
        // Check the provider's status to determine what to show.
        switch (userDataProvider.status) {
          case UserDataStatus.uninitialized:
          case UserDataStatus.loading:
            // While the provider is initializing or loading data, show a loading screen.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          case UserDataStatus.unauthenticated:
            // If the provider confirms the user is not authenticated, show the login screen.
            return const LoginScreen();

          case UserDataStatus.authenticated:
            // If user is authenticated, check their profile.
            final userProfile = userDataProvider.userProfile;

            if (userProfile == null) {
              // This is an error state: authenticated but no profile.
              // Log them out to return to a clean state.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                userDataProvider.logout();
              });
              return const Scaffold(
                body: Center(child: Text('Profile not found. Logging out...')),
              );
            }

            developer.log('AuthWrapper - userProfile.role: ${userProfile.role}');
            developer.log('AuthWrapper - userProfile.isFirstTimeSetupComplete: ${userProfile.isFirstTimeSetupComplete}');
            developer.log('AuthWrapper - is chief admin: ${userProfile.role == UserRole.chiefAdmin}');
            developer.log('AuthWrapper - is school admin: ${userProfile.role == UserRole.schoolAdmin}');
            developer.log('AuthWrapper - is teacher: ${userProfile.role == UserRole.teacher || userProfile.role == UserRole.classTeacher}');
            developer.log('AuthWrapper - should show setup: ${userProfile.role == UserRole.chiefAdmin && !userProfile.isFirstTimeSetupComplete}');

            // Check if admin has completed the initial setup.
            // Only redirect to setup if we're certain the profile is fully loaded
            if (userProfile.role == UserRole.chiefAdmin &&
                userProfile.isFirstTimeSetupComplete == false) {
              developer.log('AuthWrapper - showing AdminSetupScreen');
              return const AdminSetupScreen();
            }

            // The user is fully authenticated and set up, route to the correct dashboard.
            developer.log('AuthWrapper - showing DashboardScreen');
            return const DashboardScreen();
        }
      },
    );
  }
}


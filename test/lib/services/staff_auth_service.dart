import 'dart:developer' as developer;

import 'package:test/services/auth_service.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Service to handle staff-specific authentication flows and routing
class StaffAuthService {
  static final StaffAuthService _instance = StaffAuthService._internal();
  factory StaffAuthService() => _instance;
  StaffAuthService._internal();

  final AuthService _authService = AuthService();

  /// Authenticate staff user and route to appropriate dashboard
  Future<void> authenticateStaff({
    required String email,
    required String password,
    required BuildContext context,
    UserRole? specificRole,
  }) async {
    try {
      developer.log('StaffAuthService: Authenticating staff user: $email');
      if (specificRole != null) {
        developer.log(
            'StaffAuthService: Specific role provided: ${specificRole.displayName}');
      }

      // Use the existing login endpoint which handles all user types
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      developer.log(
          'StaffAuthService: Authentication successful, triggering user switch');

      // PATCH: Guard navigation until profile is fully loaded
      if (context.mounted) {
        await Provider.of<UserDataProvider>(context, listen: false)
            .switchUser();
        
        // CRITICAL: Wait for profile hydration before allowing navigation
        final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
        int attempts = 0;
        while (userDataProvider.userProfile == null && attempts < 10) {
          await Future.delayed(Duration(milliseconds: 500));
          attempts++;
        }
        
        if (userDataProvider.userProfile == null) {
          throw Exception('Profile loading timeout - please try again');
        }
      }

      developer.log(
          'StaffAuthService: User switch completed, AuthWrapper will handle routing');
    } catch (e) {
      developer.log('StaffAuthService: Authentication failed: $e');
      rethrow;
    }
  }

  /// Attempts to log in using biometrics if available and configured.
  /// Returns true if authentication and session refresh were successful.
  Future<bool> loginWithBiometrics(BuildContext context) async {
    final userDataProvider =
        Provider.of<UserDataProvider>(context, listen: false);

    // 1. Check availability
    if (!await userDataProvider.isBiometricsAvailable) {
      developer.log('Biometrics not available or not configured.');
      return false;
    }

    // 2. Authenticate
    final authenticated = await userDataProvider.authenticateWithBiometrics();
    if (!authenticated) {
      developer.log('Biometric authentication failed or cancelled.');
      return false;
    }

    // 3. Refresh Session
    // If auth is successful, we try to refresh the user profile (using stored refresh token)
    // to ensure we have a valid session.
    await userDataProvider.refreshUserProfile();

    // 4. Check if we are now authenticated
    return userDataProvider.status == UserDataStatus.authenticated;
  }

  /// Get the appropriate dashboard route for a staff role
  String getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.chiefAdmin:
        return '/system-admin-dashboard';
      case UserRole.headTeacher:
      case UserRole.director:
      case UserRole.deputyHeadTeacher:
      case UserRole.systemAdmin:
      case UserRole.schoolAdmin:
        return '/admin-dashboard';
      case UserRole.teacher:
      case UserRole.classTeacher:
      case UserRole.headOfDepartment:
      case UserRole.directorOfStudies:
        return '/teacher-dashboard';
      case UserRole.student:
        return '/student-dashboard';
      case UserRole.parent:
        return '/parent-dashboard';
      case UserRole.nonTeachingStaff:
      case UserRole.bursar:
      case UserRole.schoolSecretary:
      case UserRole.librarian:
      case UserRole.labTechnician:
      case UserRole.computerLabAttendant:
      case UserRole.schoolNurse:
      case UserRole.counselor:
      case UserRole.securityGuard:
      case UserRole.caretaker:
      case UserRole.cook:
      case UserRole.driver:
      case UserRole.storeKeeper:
      case UserRole.boardingMaster:
        return '/staff-dashboard';
      default:
        return '/dashboard';
    }
  }

  /// Check if a role is considered staff
  bool isStaffRole(UserRole role) {
    return UserRole.allStaffRoles.contains(role);
  }

  /// Check if a role is teaching staff
  bool isTeachingRole(UserRole role) {
    return UserRole.allTeachingRoles.contains(role);
  }

  /// Check if a role is administrative staff
  bool isAdminRole(UserRole role) {
    return UserRole.adminRoles.contains(role);
  }

  /// Get role-specific welcome message
  String getWelcomeMessage(UserRole role, String firstName) {
    if (isTeachingRole(role)) {
      return 'Welcome back, $firstName! Ready to inspire minds?';
    } else if (isAdminRole(role)) {
      return 'Welcome back, $firstName! Ready to lead?';
    } else if (role == UserRole.nonTeachingStaff) {
      return 'Welcome back, $firstName! Ready to support?';
    } else {
      return 'Welcome back, $firstName!';
    }
  }

  /// Get role-specific dashboard title
  String getDashboardTitle(UserRole role) {
    switch (role) {
      case UserRole.teacher:
      case UserRole.classTeacher:
        return 'Teacher Dashboard';
      case UserRole.headTeacher:
        return 'Head Teacher Dashboard';
      case UserRole.director:
        return 'Director Dashboard';
      case UserRole.deputyHeadTeacher:
        return 'Deputy Head Teacher Dashboard';
      case UserRole.schoolAdmin:
        return 'School Admin Dashboard';
      case UserRole.systemAdmin:
        return 'System Admin Dashboard';
      case UserRole.chiefAdmin:
        return 'Chief Admin Dashboard';
      case UserRole.headOfDepartment:
        return 'HOD Dashboard';
      case UserRole.directorOfStudies:
        return 'Director of Studies Dashboard';
      case UserRole.parent:
        return 'Parent Dashboard';
      case UserRole.nonTeachingStaff:
        return 'Staff Dashboard';
      case UserRole.bursar:
        return 'Bursar Dashboard';
      case UserRole.schoolSecretary:
        return 'School Secretary Dashboard';
      case UserRole.librarian:
        return 'Librarian Dashboard';
      case UserRole.labTechnician:
        return 'Lab Technician Dashboard';
      case UserRole.computerLabAttendant:
        return 'Computer Lab Dashboard';
      case UserRole.schoolNurse:
        return 'School Nurse Dashboard';
      case UserRole.counselor:
        return 'Counselor Dashboard';
      case UserRole.securityGuard:
        return 'Security Dashboard';
      case UserRole.caretaker:
        return 'Caretaker Dashboard';
      case UserRole.cook:
        return 'Kitchen Dashboard';
      case UserRole.driver:
        return 'Driver Dashboard';
      case UserRole.storeKeeper:
        return 'Store Dashboard';
      case UserRole.boardingMaster:
        return 'Boarding Master Dashboard';
      default:
        return 'Dashboard';
    }
  }

  /// Returns a list of feature keys available for the specific role.
  /// This allows the generic StaffDashboard to render relevant widgets dynamically.
  List<String> getRoleFeatures(UserRole role) {
    return role.defaultFeatures;
  }
}


import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/models/school.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/services/auth_service.dart';
import 'package:test/services/database_service.dart';
import 'package:test/services/school_service.dart';
import 'package:test/services/user_profile_service.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/student_offline_sync_service.dart';

/// Token storage constants
const String _jwtTokenKey = 'jwt_token';
const String _refreshTokenKey = 'refresh_token';

/// Enum to represent the current state of user data and authentication.
enum UserDataStatus {
  /// The provider has not yet started its initialization process.
  uninitialized,

  /// The provider is currently checking auth status or fetching user data.
  loading,

  /// The user is authenticated, and their profile data is available.
  authenticated,

  /// The user is not authenticated.
  unauthenticated,
}

/// A provider that manages the user's authentication state and profile data.
///
/// This class is the single source of truth for whether a user is logged in
/// and what their profile information is. It listens for auth state changes
/// and fetches/clears user data accordingly.
class UserDataProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final SchoolService _schoolService = SchoolService();
  final DatabaseService _databaseService = DatabaseService();
  final ApiClient _apiClient = ApiClient();
  final StudentOfflineSyncService _syncService = StudentOfflineSyncService();
  final _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserDataStatus _status = UserDataStatus.uninitialized;
  UserProfile? _userProfile;
  School? _school;

  /// The current authentication and data loading status.
  UserDataStatus get status => _status;

  /// The profile of the currently authenticated user. Null if not authenticated.
  UserProfile? get userProfile => _userProfile;

  /// The school of the currently authenticated user. Null if not authenticated.
  School? get school => _school;

  /// Initializes the provider by checking the authentication state on app startup.
  Future<void> initialize() async {
    _updateStatus(UserDataStatus.loading);

    try {
      final token = await _secureStorage.read(key: _jwtTokenKey);

      if (token != null && token.isNotEmpty) {
        try {
          debugPrint(
              'Checking token expiration: ${token.substring(0, min(50, token.length))}...');
          // Only decode to check expiration, don't verify signature on client
          final decoded = JWT.decode(token);
          final String? userId =
              decoded.subject; // 'sub' is standard for user ID
          debugPrint('Decoded token subject: $userId');
          debugPrint(
              'Decoded token payload keys: ${decoded.payload.keys.toList()}');

          // Check if token is expired
          final exp = decoded.payload['exp'] as int?;
          if (exp != null) {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            if (now >= exp) {
              debugPrint('Token has expired');
              // Attempt to refresh the session instead of logging out immediately
              await refreshUserProfile();
              return;
            }
          }
          String? userIdToUse = userId;
          if (userIdToUse == null) {
            // Try alternative claims, handling both String and int types
            final userIdValue = decoded.payload['userId'];
            if (userIdValue != null) {
              userIdToUse = userIdValue.toString();
            }
            if (userIdToUse == null) {
              final idValue = decoded.payload['id'];
              if (idValue != null) {
                userIdToUse = idValue.toString();
              }
            }
            if (userIdToUse == null) {
              final userIdValue2 = decoded.payload['user_id'];
              if (userIdValue2 != null) {
                userIdToUse = userIdValue2.toString();
              }
            }
          }
          if (userIdToUse != null) {
            await _loadUserProfile(userIdToUse);
            return;
          } else {
            debugPrint(
                'Token subject and alternative claims are null, invalid token');
            await _secureStorage.delete(
                key: _jwtTokenKey); // Clear invalid token
          }
        } on FormatException catch (e) {
          debugPrint('Invalid JWT format: $e');
          await _secureStorage.delete(key: _jwtTokenKey); // Clear invalid token
        } catch (e) {
          debugPrint('Error decoding token: $e');
          await _secureStorage.delete(key: _jwtTokenKey); // Clear invalid token
        }
      }
      // If no token, it's expired, or there's an error, the user is unauthenticated.
      _updateStatus(UserDataStatus.unauthenticated);
    } catch (e) {
      debugPrint('Error initializing user data: $e');
      _updateStatus(UserDataStatus.unauthenticated);
    }
  }

  /// Fetches the user profile from the backend and updates the state.
  Future<void> _loadUserProfile(String uid) async {
    try {
      final profile = await _userProfileService.getUser(uid);
      if (profile != null) {
        _userProfile = profile;
        if (profile.schoolId != null && profile.schoolId!.isNotEmpty) {
          try {
            debugPrint('Loading school data for schoolId: ${profile.schoolId}');
            _school = await _schoolService.getSchool(profile.schoolId!);
            debugPrint('School data loaded: ${_school?.name}');
          } catch (e) {
            debugPrint('Failed to load school data: $e');
          }
        } else {
          debugPrint('No schoolId found in user profile');
        }
        _updateStatus(UserDataStatus.authenticated);

        // Perform bulk sync for student data if user is a student
        if (profile.role == UserRole.student && profile.schoolId != null) {
          try {
            await _syncService.performBulkSync(
              userId: profile.uid,
              schoolId: profile.schoolId!,
            );
          } catch (e) {
            debugPrint('Bulk sync failed during initialization: $e');
            // Don't fail initialization if sync fails
          }
        }
      } else {
        // Authenticated with a token, but profile fetch failed.
        // This is an error state, so we log the user out.
        await logout();
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      // An error occurred, treat as unauthenticated.
      await logout();
    }
  }

  /// Refreshes the current user's profile data from the backend.
  Future<void> refreshUserProfile() async {
    if (_userProfile != null) {
      _updateStatus(UserDataStatus.loading);
      await _loadUserProfile(_userProfile!.uid);
    } else {
      try {
        final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
        if (refreshToken == null) {
          debugPrint('No refresh token available');
          _updateStatus(UserDataStatus.unauthenticated);
        } else {
          final response = await _apiClient.post(
            '/auth/refresh',
            body: {'refreshToken': refreshToken},
          );

          final newToken = response['token'] as String?;
          if (newToken != null) {
            await _secureStorage.write(key: _jwtTokenKey, value: newToken);

            // Decode new token to get user ID (no signature verification on client)
            try {
              final decoded = JWT.decode(newToken);
              final userId = decoded.subject;
              if (userId != null) {
                await _loadUserProfile(userId);
                return;
              }
            } catch (e) {
              debugPrint('Error decoding new token: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
        // Clear both tokens on refresh failure
        await _secureStorage.delete(key: _jwtTokenKey);
        await _secureStorage.delete(key: _refreshTokenKey);
      }

      _updateStatus(UserDataStatus.unauthenticated);
    }
  }

  /// Refreshes the current user's school data from the backend.
  Future<void> refreshSchoolData() async {
    if (_userProfile != null &&
        _userProfile!.schoolId != null &&
        _userProfile!.schoolId!.isNotEmpty) {
      try {
        debugPrint(
            'Refreshing school data for schoolId: ${_userProfile!.schoolId}');
        _school = await _schoolService.getSchool(_userProfile!.schoolId!);
        debugPrint('School data refreshed: ${_school?.name}');
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to refresh school data: $e');
      }
    }
  }

  /// Logs user out, clears all session data, and updates state.
  Future<void> logout() async {
    await _authService.signOut();
    _userProfile = null;
    _school = null;
    _updateStatus(UserDataStatus.unauthenticated);
  }

  /// Clears current user data and reinitializes with new user
  Future<void> switchUser() async {
    // Clear all current state
    _userProfile = null;
    _school = null;

    // Reinitialize to load new user data
    await initialize();
  }

  /// Deletes an item from the database.
  Future<void> delete(String itemId, String itemType) async {
    try {
      await _databaseService.delete(itemId, itemType);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item: $e');
      // Optionally, re-throw the exception to be handled by the UI
      throw Exception('Failed to delete item');
    }
  }

  /// Refreshes the school data from the server.
  Future<void> refreshSchool() async {
    if (_userProfile?.schoolId != null) {
      try {
        final school = await _schoolService.getSchool(_userProfile!.schoolId!);
        _school = school;
        notifyListeners();
      } catch (e) {
        debugPrint('Error refreshing school data: $e');
      }
    }
  }

  /// A centralized method to update the status and notify listeners.
  void _updateStatus(UserDataStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      // Use WidgetsBinding to ensure listeners are notified after the current frame.
      // This prevents errors if the status is updated during a build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // --- Role-Based Access Control (RBAC) Helpers ---

  /// Checks if the current user has a specific role.
  bool hasRole(UserRole role) {
    return _userProfile?.role == role;
  }

  /// Checks if the current user has any of the provided roles.
  bool hasAnyRole(List<UserRole> roles) {
    return _userProfile != null && roles.contains(_userProfile!.role);
  }

  /// Checks if the user has administrative privileges (Chief, System, or School Admin).
  bool get isAdmin => hasAnyRole(
      [UserRole.chiefAdmin, UserRole.systemAdmin, UserRole.schoolAdmin]);

  /// Checks if the current user has access to a specific feature.
  /// This combines role-based defaults with potential future user-specific overrides.
  bool canAccess(String featureKey) {
    if (_userProfile == null) return false;
    // In the future, check _userProfile.customPermissions here for overrides.
    // For now, return the default features for the role.
    return _userProfile!.role.defaultFeatures.contains(featureKey);
  }

  // --- Biometric Authentication ---

  /// Attempts to authenticate the user using device biometrics (FaceID, TouchID).
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access SSU Dashboard',
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Checks if the device supports biometrics and if they are configured.
  /// Useful for UI to decide whether to show biometric options.
  Future<bool> get isBiometricsAvailable async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }
}

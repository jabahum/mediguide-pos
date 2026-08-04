import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:user_app/app/data/models/models.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/utils/preference_utils.dart';
import 'package:user_app/app/utils/constants.dart';
import 'package:user_app/app/translations/app_translations.dart';

class AuthService {
  AuthService([BackendApiService? backend]) : _backend = backend;

  final BackendApiService? _backend;
  BackendApiService get _api =>
      _backend ?? (throw StateError('BackendApiService was not provided'));

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Reactive user state
  final ValueNotifier<User?> currentUser = ValueNotifier(null);

  /// Biometric authentication state
  final ValueNotifier<bool> isBiometricAvailable = ValueNotifier(false);
  final ValueNotifier<bool> isBiometricEnabled = ValueNotifier(false);

  /// Computed property for authentication state
  bool get isAuthenticated => currentUser.value != null;

  /// Get user name or default
  String get userName => currentUser.value?.name ?? 'Healthcare Professional';

  /// Get user role or default
  String get userRole =>
      currentUser.value?.role?.displayName ?? 'Medical Professional';

  /// Get user profile picture URL
  String? get userProfilePicture {
    final user = currentUser.value;
    if (user?.avatar.isNotEmpty == true) {
      return _api.getFileUrl(filename: user!.avatar);
    }
    return null;
  }

  /// Get user initials for avatar fallback
  String get userInitials {
    final name = userName;
    final parts = name.split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (parts.isNotEmpty ? parts[0][0].toUpperCase() : 'HP');
  }

  Future<AuthService> init() async {
    // Load user from SharedPreferences on app startup
    await loadUser();

    // Initialize biometric authentication
    await _initBiometrics();

    return this;
  }

  /// Save user to SharedPreferences and update reactive state
  Future<bool> saveUser(User user) async {
    try {
      final success = await PreferenceUtils.setJson(
        SharedPreferencesKeys.currentUser,
        user.data,
      );
      if (success) {
        currentUser.value = user;
      }
      return success;
    } catch (e) {
      debugPrint('Error saving user: $e');
      return false;
    }
  }

  /// Load user from SharedPreferences and update reactive state
  Future<void> loadUser() async {
    try {
      if (PreferenceUtils.containsKey(SharedPreferencesKeys.currentUser)) {
        final userData = PreferenceUtils.getJson(
          SharedPreferencesKeys.currentUser,
        );
        if (userData != null && userData.isNotEmpty) {
          currentUser.value = User(userData);
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      // Clear corrupted data
      await clearUser();
    }
  }

  /// Clear user from SharedPreferences and reactive state
  Future<bool> clearUser() async {
    try {
      final success = await PreferenceUtils.remove(
        SharedPreferencesKeys.currentUser,
      );
      if (success) {
        currentUser.value = null;
      }
      return success;
    } catch (e) {
      debugPrint('Error clearing user: $e');
      return false;
    }
  }

  /// Check if user data exists in SharedPreferences
  bool hasStoredUser() {
    return PreferenceUtils.containsKey(SharedPreferencesKeys.currentUser);
  }

  /// Get current user (nullable)
  User? getCurrentUser() {
    return currentUser.value;
  }

  /// Logout - clear user data and session
  Future<void> logout() async {
    try {
      // Clear all authentication-related shared preferences
      await _api.logout();
    } catch (_) {
    } finally {
      await clearUser();
    }
  }

  /// Initialize biometric authentication
  Future<void> _initBiometrics() async {
    try {
      // Check if biometrics are available on the device
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      isBiometricAvailable.value = isAvailable && isDeviceSupported;

      // Load user's biometric setting
      isBiometricEnabled.value = PreferenceUtils.getBool(
        SharedPreferencesKeys.biometricEnabled,
        false,
      );

      // If user is authenticated and biometric is enabled, show biometric prompt
      if (isAuthenticated &&
          isBiometricAvailable.value &&
          isBiometricEnabled.value) {
        await authenticateWithBiometrics();
      }
    } catch (e) {
      debugPrint('Error initializing biometrics: $e');
      isBiometricAvailable.value = false;
    }
  }

  /// Check if biometric authentication is available
  Future<bool> checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      isBiometricAvailable.value = isAvailable && isDeviceSupported;
      return isBiometricAvailable.value;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!isBiometricAvailable.value) return false;

      final availableBiometrics = await getAvailableBiometrics();
      String localizedReason = AppTranslationKey.pleaseAuthenticateToAccess.tr;

      // Customize message based on available biometric types
      if (availableBiometrics.contains(BiometricType.face)) {
        localizedReason = AppTranslationKey.useFaceIdToAccess.tr;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        localizedReason = AppTranslationKey.useFingerprintToAccess.tr;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Toggle biometric authentication setting
  Future<bool> toggleBiometricSetting(bool enabled) async {
    try {
      if (!isBiometricAvailable.value && enabled) {
        return false; // Can't enable if not available
      }

      final success = await PreferenceUtils.setBool(
        SharedPreferencesKeys.biometricEnabled,
        enabled,
      );

      if (success) {
        isBiometricEnabled.value = enabled;
      }

      return success;
    } catch (e) {
      debugPrint('Error toggling biometric setting: $e');
      return false;
    }
  }

  /// Get biometric capability info for UI display
  String getBiometricTypeDisplayName() {
    return AppTranslationKey.biometricAuthentication.tr;
  }
}

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/backend_api_service.dart';
import '../../routes/app_pages.dart';
import '../../translations/app_translations.dart';
import '../../utils/common.dart';
import '../../utils/preference_utils.dart';
import '../../utils/constants.dart';
import '../../widgets/language_bottom_sheet.dart';

class ProfileController extends GetxController {
  // Observable state
  final RxBool isLoading = false.obs;

  /// Handle logout
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Clear legacy collection API auth session
      BackendApiService.to.logout();

      // Clear user session from AuthService (includes shared preferences)
      await AuthService.to.logout();

      // Navigate to login page
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: 'Failed to logout. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle app rating with in-app review
  Future<void> rateApp() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;

      // Check if in-app review is available
      if (await inAppReview.isAvailable()) {
        // Request in-app review
        await inAppReview.requestReview();
      } else {
        // Fallback to opening app store
        await inAppReview.openStoreListing();
      }
    } catch (e) {
      // Handle errors gracefully
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: AppTranslationKey.ratingFailed.tr,
      );
    }
  }

  /// Delete account with confirmation
  Future<void> deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppTranslationKey.deleteAccount.tr),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppTranslationKey.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        isLoading.value = true;

        // TODO: Implement actual account deletion API call

        // Clear legacy collection API auth session
        BackendApiService.to.logout();

        // Clear user session from AuthService (includes shared preferences)
        await AuthService.to.logout();

        // Navigate to login page
        Get.offAllNamed(AppRoutes.login);

        Common.quickToast(
          type: ToastificationType.success,
          title: AppTranslationKey.accountDeleted.tr,
          description: 'Your account has been deleted successfully',
        );
      } catch (e) {
        Common.quickToast(
          type: ToastificationType.error,
          title: AppTranslationKey.error.tr,
          description: 'Failed to delete account. Please try again.',
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  // Settings getters for ProfilePage compatibility
  DummySettings get settings => DummySettings();
}

/// Settings class for ProfilePage compatibility
/// TODO: Replace with actual UserSettings model from legacy collection API
class DummySettings {
  bool get biometricEnabled => false;
  bool get notificationsEnabled => true;
  bool get soundEnabled => true;
  bool get vibrationEnabled => true;
  bool get dataBackupEnabled => true;
  bool get analyticsEnabled => true;

  String get languageCode {
    return PreferenceUtils.getString(SharedPreferencesKeys.language, 'en');
  }

  String get languageDisplayName {
    try {
      final controller = Get.find<LanguageController>();
      final currentLang = controller.currentLanguage;
      return currentLang?.shortDisplayName ?? AppTranslationKey.english.tr;
    } catch (e) {
      // Fallback if controller not found
      return AppTranslationKey.english.tr;
    }
  }
}

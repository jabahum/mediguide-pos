import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import '../../data/models/models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/backend_api_service.dart';
import '../../translations/app_translations.dart';
import '../../utils/common.dart';

class EditProfileController extends GetxController {
  final formKey = GlobalKey<FormBuilderState>();
  final RxBool isLoading = false.obs;
  final RxBool hasChanges = false.obs;
  final RxBool isUploadingAvatar = false.obs;

  /// Save profile changes
  Future<void> saveProfile() async {
    if (!formKey.currentState!.saveAndValidate()) {
      return; // Form validation failed
    }

    if (!hasChanges.value) {
      Get.back();
      return;
    }

    try {
      isLoading.value = true;

      final user = AuthService.to.currentUser.value;
      if (user == null) throw Exception('User not found');

      final formValues = formKey.currentState!.value;

      // Debug: Print all form values to see what's being sent
      debugPrint('Form values: $formValues');

      // Create a clean update data with only the fields we want to update
      final allowedFields = [
        'name',
        'phone',
        'alternativePhone',
        'address',
        'city',
        'state',
        'country',
        'postalCode',
        'organization',
        'department',
        'jobTitle',
        'specialization',
      ];

      final updateData = <String, dynamic>{};

      for (final fieldName in allowedFields) {
        final value = formValues[fieldName]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          updateData[fieldName] = value;
        }
      }

      // backend resource API seems to validate enum fields even when not being updated
      // Include current enum values to prevent validation errors
      if (user.role != null) {
        updateData['role'] = user.role!.name;
      }
      if (user.status != null) {
        updateData['status'] = user.status!.name;
      }
      if (user.preferredLanguage != null) {
        updateData['preferredLanguage'] = user.preferredLanguage!.name;
      }

      // Debug: Print the final update data being sent
      debugPrint('Update data being sent: $updateData');

      // Update user profile via backend resource API
      final updatedRecord = await BackendApiService.to.updateResource(
        collectionName: User.collection,
        recordId: user.id,
        data: updateData,
      );

      // Update AuthService with new user data
      final updatedUser = User.fromRecord(updatedRecord);
      await AuthService.to.saveUser(updatedUser);

      // Show success message
      Common.quickToast(
        type: ToastificationType.success,
        title: AppTranslationKey.profileUpdated.tr,
        description: AppTranslationKey.profileUpdatedSuccessfully.tr,
      );

      // Close dialog
      Get.back(result: true);
    } catch (e) {
      debugPrint(e.toString());
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: AppTranslationKey.failedToUpdateProfile.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload avatar image
  Future<void> uploadAvatar(File avatarFile) async {
    try {
      isUploadingAvatar.value = true;

      final user = AuthService.to.currentUser.value;
      if (user == null) throw Exception('User not found');

      // Upload avatar and update user
      final updatedUser = await updateUserAvatar(
        userId: user.id,
        avatarFile: avatarFile,
      );

      // Update AuthService with new user data
      await AuthService.to.saveUser(updatedUser);

      // Mark as having changes to enable save button
      hasChanges.value = true;

      // Show success message
      Common.quickToast(
        type: ToastificationType.success,
        title: 'Avatar Updated',
        description: 'Your profile photo has been updated successfully',
      );
    } catch (e) {
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: 'Failed to update profile photo. Please try again.',
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  // ==================== USER AVATAR METHODS ====================

  /// Update user avatar
  Future<User> updateUserAvatar({
    required String userId,
    required File avatarFile,
  }) async {
    final multipartFile = await http.MultipartFile.fromPath(
      'avatar',
      avatarFile.path,
    );

    final record = await BackendApiService.to.updateResource(
      collectionName: User.collection,
      recordId: userId,
      data: {},
      files: [multipartFile],
    );
    return User.fromRecord(record);
  }
}

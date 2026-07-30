import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../routes/app_pages.dart';
import '../../translations/app_translations.dart';
import '../../data/models/models.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/common.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormBuilderState>();
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;

  /// Validate if license number is required (required for healthcare providers)
  String? licenseNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }
    if (value.trim().length < 3) {
      return 'License number must be at least 3 characters';
    }
    return null;
  }

  Future<void> onSubmit() async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;

      if (formData['agreeToTerms'] != true) {
        Common.quickToast(
          type: ToastificationType.error,
          title: AppTranslationKey.registrationError,
          description: AppTranslationKey.pleaseAgreeToTerms,
        );
        return;
      }

      isLoading.value = true;

      try {
        final userData = User.forCreate(
          email: formData['email'] as String,
          password: formData['password'] as String,
          name: formData['fullName'] as String,
          role: UserRole.healthcareProvider,
          status: UserStatus.pendingActivation,
          phone: formData['phoneNumber'] as String?,
          alternativePhone: formData['alternativePhone'] as String?,
          licenseNumber: formData['licenseNumber'] as String?,
          specialization: formData['specialization'] as String?,
          preferredLanguage: PreferredLanguage.english,
        );

        final userRecord = await BackendApiService.to.register(
          email: formData['email'] as String,
          password: formData['password'] as String,
          passwordConfirm: formData['password'] as String,
          additionalData: userData,
        );

        final user = User.fromRecord(userRecord);
        await AuthService.to.saveUser(user);

        Get.offNamed(AppRoutes.main);
      } catch (e) {
        Common.quickToast(
          type: ToastificationType.error,
          title: AppTranslationKey.registrationError,
          description: Common.parseApiError(e),
        );
      } finally {
        isLoading.value = false;
      }
    }
  }
}

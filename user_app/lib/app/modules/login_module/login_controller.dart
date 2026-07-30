import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../routes/app_pages.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/models.dart';
import '../../translations/app_translations.dart';
import '../../utils/common.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormBuilderState>();
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;

  static const String emailField = 'email';
  static const String passwordField = 'password';

  Future<void> onSubmit() async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      isLoading.value = true;
      final formData = formKey.currentState!.value;

      try {
        final email = formData[emailField] as String;
        final password = formData[passwordField] as String;

        final userRecord = await BackendApiService.to.login(
          email: email,
          password: password,
        );

        final user = User.fromRecord(userRecord);
        await AuthService.to.saveUser(user);

        Get.offAllNamed(AppRoutes.main);
      } catch (e) {
        Common.quickToast(
          type: ToastificationType.error,
          title: AppTranslationKey.loginError,
          description: Common.parseApiError(e),
        );
      } finally {
        isLoading.value = false;
      }
    }
  }
}

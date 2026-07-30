import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../../utils/app_spacing.dart';
import '../../utils/common.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_button.dart';
import '../../data/services/backend_api_service.dart';
import '../../translations/app_translations.dart';

/// Controller for password change bottom sheet
class ChangePasswordController extends GetxController {
  final formKey = GlobalKey<FormBuilderState>();
  final RxBool isLoading = false.obs;
  final RxBool obscureCurrentPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  /// Change password
  Future<void> changePassword() async {
    if (!formKey.currentState!.saveAndValidate()) {
      return; // Form validation failed
    }

    try {
      isLoading.value = true;

      final formValues = formKey.currentState!.value;

      await BackendApiService.to.changePassword(
        currentPassword: formValues['currentPassword']?.toString() ?? '',
        newPassword: formValues['newPassword']?.toString() ?? '',
        newPasswordConfirm: formValues['confirmPassword']?.toString() ?? '',
      );

      // Success
      Common.quickToast(
        type: ToastificationType.success,
        title: AppTranslationKey.success.tr,
        description: AppTranslationKey.passwordChangedSuccessfully.tr,
      );

      // Close bottom sheet
      Get.back(result: true);
    } catch (e) {
      // Error handling
      String errorMessage = AppTranslationKey.passwordChangeError.tr;

      if (e.toString().contains('current password')) {
        errorMessage = AppTranslationKey.currentPasswordIncorrect.tr;
      } else if (e.toString().contains('validation')) {
        errorMessage = AppTranslationKey.passwordValidationError.tr;
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = AppTranslationKey.networkError.tr;
      }

      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: errorMessage,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate password match
  String? validatePasswordMatch(String? value) {
    final formValues = formKey.currentState?.instantValue;
    final newPassword = formValues?['newPassword']?.toString();

    if (value != newPassword) {
      return AppTranslationKey.passwordsDoNotMatch.tr;
    }

    return null;
  }

  /// Validate new password is different from current
  String? validateNewPasswordDifferent(String? value) {
    final formValues = formKey.currentState?.instantValue;
    final currentPassword = formValues?['currentPassword']?.toString();

    if (value == currentPassword) {
      return AppTranslationKey.newPasswordSameAsCurrent.tr;
    }

    return null;
  }
}

class ChangePasswordBottomSheet extends StatelessWidget {
  const ChangePasswordBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChangePasswordController>(
      init: ChangePasswordController(),
      builder: (controller) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: context.responsiveHorizontalPadding,
            right: context.responsiveHorizontalPadding,
            top: context.responsiveVerticalPadding,
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                context.responsiveVerticalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: Responsive.iconSize(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    ),
                    color: context.theme.colorScheme.primary,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      AppTranslationKey.changePassword.tr,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontSize: Responsive.fontSize(
                          context,
                          mobile: 20.0,
                          tablet: 22.0,
                          desktop: 24.0,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(LucideIcons.x),
                    tooltip: AppTranslationKey.close.tr,
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.sm),

              // Description
              Text(
                AppTranslationKey.updateSecurityCredentials.tr,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              // Form
              FormBuilder(
                key: controller.formKey,
                child: Column(
                  children: [
                    // Current Password Field
                    Obx(
                      () => FormBuilderTextField(
                        name: 'currentPassword',
                        obscureText: controller.obscureCurrentPassword.value,
                        decoration: InputDecoration(
                          labelText: AppTranslationKey.currentPassword.tr,
                          hintText: AppTranslationKey.enterCurrentPassword.tr,
                          prefixIcon: Icon(LucideIcons.lock),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                controller.obscureCurrentPassword.toggle(),
                            icon: Icon(
                              controller.obscureCurrentPassword.value
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                            ),
                          ),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                            errorText:
                                AppTranslationKey.currentPasswordRequired.tr,
                          ),
                        ]),
                        textInputAction: TextInputAction.next,
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // New Password Field
                    Obx(
                      () => FormBuilderTextField(
                        name: 'newPassword',
                        obscureText: controller.obscureNewPassword.value,
                        decoration: InputDecoration(
                          labelText: AppTranslationKey.newPassword.tr,
                          hintText: AppTranslationKey.enterNewPassword.tr,
                          prefixIcon: Icon(LucideIcons.key),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                controller.obscureNewPassword.toggle(),
                            icon: Icon(
                              controller.obscureNewPassword.value
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                            ),
                          ),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                            errorText: AppTranslationKey.newPasswordRequired.tr,
                          ),
                          FormBuilderValidators.minLength(
                            8,
                            errorText: AppTranslationKey.passwordMinLength.tr,
                          ),
                          controller.validateNewPasswordDifferent,
                        ]),
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          // Re-validate confirm password when new password changes
                          controller
                              .formKey
                              .currentState
                              ?.fields['confirmPassword']
                              ?.validate();
                        },
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // Confirm Password Field
                    Obx(
                      () => FormBuilderTextField(
                        name: 'confirmPassword',
                        obscureText: controller.obscureConfirmPassword.value,
                        decoration: InputDecoration(
                          labelText: AppTranslationKey.confirmNewPassword.tr,
                          hintText: AppTranslationKey.enterConfirmPassword.tr,
                          prefixIcon: Icon(LucideIcons.shieldCheck),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                controller.obscureConfirmPassword.toggle(),
                            icon: Icon(
                              controller.obscureConfirmPassword.value
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                            ),
                          ),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                            errorText:
                                AppTranslationKey.confirmPasswordRequired.tr,
                          ),
                          controller.validatePasswordMatch,
                        ]),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.changePassword(),
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    // Password Requirements Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 16,
                                color: context.theme.colorScheme.primary,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                AppTranslationKey.passwordRequirements.tr,
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            AppTranslationKey.passwordRequirementsDetails.tr,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButtonVariants.outlined(
                      text: AppTranslationKey.cancel.tr,
                      onPressed: controller.isLoading.value
                          ? null
                          : () => Get.back(),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Obx(
                      () => AppButton(
                        text: AppTranslationKey.changePassword.tr,
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.changePassword,
                        isLoading: controller.isLoading.value,
                        loadingText: AppTranslationKey.changing.tr,
                        icon: LucideIcons.save,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

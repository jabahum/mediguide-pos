import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_button.dart';
import 'package:user_app/features/authentication/presentation/controllers/change_password_controller.dart';

class ChangePasswordBottomSheet extends ConsumerStatefulWidget {
  const ChangePasswordBottomSheet({super.key});

  @override
  ConsumerState<ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState
    extends ConsumerState<ChangePasswordBottomSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _validatePasswordMatch(String? value) {
    final newPassword = _formKey.currentState?.instantValue['newPassword']
        ?.toString();
    return value == newPassword
        ? null
        : AppTranslationKey.passwordsDoNotMatch.tr;
  }

  String? _validateNewPasswordDifferent(String? value) {
    final currentPassword = _formKey
        .currentState
        ?.instantValue['currentPassword']
        ?.toString();
    return value == currentPassword
        ? AppTranslationKey.newPasswordSameAsCurrent.tr
        : null;
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    try {
      final changed = await ref
          .read(changePasswordControllerProvider.notifier)
          .changePassword(
            currentPassword: values['currentPassword']?.toString() ?? '',
            newPassword: values['newPassword']?.toString() ?? '',
            newPasswordConfirm: values['confirmPassword']?.toString() ?? '',
          );
      if (!changed || !mounted) return;
      Common.quickToast(
        type: ToastificationType.success,
        title: AppTranslationKey.success.tr,
        description: AppTranslationKey.passwordChangedSuccessfully.tr,
      );
      AppNavigator.pop(result: true);
    } catch (error) {
      if (!mounted) return;
      var message = AppTranslationKey.passwordChangeError.tr;
      final detail = error.toString().toLowerCase();
      if (detail.contains('current password')) {
        message = AppTranslationKey.currentPasswordIncorrect.tr;
      } else if (detail.contains('validation')) {
        message = AppTranslationKey.passwordValidationError.tr;
      } else if (detail.contains('network') || detail.contains('connection')) {
        message = AppTranslationKey.networkError.tr;
      }
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(changePasswordControllerProvider).isLoading;
    return Container(
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
                  onPressed: () => AppNavigator.pop(),
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
              key: _formKey,
              child: Column(
                children: [
                  // Current Password Field
                  FormBuilderTextField(
                    name: 'currentPassword',
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: AppTranslationKey.currentPassword.tr,
                      hintText: AppTranslationKey.enterCurrentPassword.tr,
                      prefixIcon: Icon(LucideIcons.lock),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureCurrentPassword =
                              !_obscureCurrentPassword,
                        ),
                        icon: Icon(
                          _obscureCurrentPassword
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                        ),
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: AppTranslationKey.currentPasswordRequired.tr,
                      ),
                    ]),
                    textInputAction: TextInputAction.next,
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // New Password Field
                  FormBuilderTextField(
                    name: 'newPassword',
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: AppTranslationKey.newPassword.tr,
                      hintText: AppTranslationKey.enterNewPassword.tr,
                      prefixIcon: Icon(LucideIcons.key),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                        icon: Icon(
                          _obscureNewPassword
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
                      _validateNewPasswordDifferent,
                    ]),
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      // Re-validate confirm password when new password changes
                      _formKey.currentState?.fields['confirmPassword']
                          ?.validate();
                    },
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // Confirm Password Field
                  FormBuilderTextField(
                    name: 'confirmPassword',
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: AppTranslationKey.confirmNewPassword.tr,
                      hintText: AppTranslationKey.enterConfirmPassword.tr,
                      prefixIcon: Icon(LucideIcons.shieldCheck),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                        ),
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: AppTranslationKey.confirmPasswordRequired.tr,
                      ),
                      _validatePasswordMatch,
                    ]),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _changePassword(),
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
                    onPressed: isLoading ? null : () => AppNavigator.pop(),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: AppTranslationKey.changePassword.tr,
                    onPressed: isLoading ? null : _changePassword,
                    isLoading: isLoading,
                    loadingText: AppTranslationKey.changing.tr,
                    icon: LucideIcons.save,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

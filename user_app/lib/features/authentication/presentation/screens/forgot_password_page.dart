import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_button.dart';

import 'package:user_app/features/authentication/presentation/controllers/password_recovery_controller.dart';

import 'package:user_app/shared/widgets/app_logo.dart';
import 'package:user_app/shared/widgets/copyright_terms_widget.dart';
import 'package:user_app/shared/widgets/glass_card.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const String _emailField = 'email';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null) {
      return;
    }

    final isValid = form.saveAndValidate();

    if (!isValid) {
      return;
    }

    final email = form.value[_emailField]?.toString().trim();

    if (email == null || email.isEmpty) {
      return;
    }

    try {
      final result = await ref
          .read(passwordRecoveryControllerProvider.notifier)
          .requestReset(email);

      if (!mounted) {
        return;
      }

      if (result == null || !result.accepted) {
        return;
      }

      _showSuccess('checkEmailForReset'.tr);

      AppNavigator.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('errorSendingResetLink'.tr);
    }
  }

  void _showSuccess(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.success(context, message);
  }

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(passwordRecoveryControllerProvider);

    final isLoading = recoveryState.isLoading;

    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FlexColorScheme.themedSystemNavigationBar(
        context,
        noAppBar: true,
        systemNavBarStyle: FlexSystemNavBarStyle.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          padding: EdgeInsets.symmetric(
            vertical: Responsive.verticalPadding(context),
            horizontal: Responsive.horizontalPadding(context),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.05),
                colorScheme.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(logoSize: 200),

                    AppSpacing.gapXl,

                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.value<double>(
                          context,
                          mobile: double.infinity,
                          tablet: 500,
                          desktop: 450,
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: GlassCard.auth(
                          child: FormBuilder(
                            key: _formKey,
                            enabled: !isLoading,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppTranslationKey.resetPassword.tr,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                        fontSize: Responsive.fontSize(
                                          context,
                                          mobile: 24,
                                          tablet: 28,
                                          desktop: 32,
                                        ),
                                      ),
                                ),

                                AppSpacing.contentGap,

                                Text(
                                  AppTranslationKey.resetPasswordDescription.tr,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                    fontSize: Responsive.fontSize(
                                      context,
                                      mobile: 14,
                                      tablet: 15,
                                      desktop: 16,
                                    ),
                                  ),
                                ),

                                AppSpacing.contentGap,

                                FormBuilderTextField(
                                  name: _emailField,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  onSubmitted: (_) {
                                    if (!isLoading) {
                                      _submit();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: AppTranslationKey.email.tr,
                                    hintText: AppTranslationKey.email.tr,
                                    prefixIcon: Icon(
                                      LucideIcons.mail,
                                      color: colorScheme.primary,
                                      size: Responsive.iconSize(
                                        context,
                                        mobile: 20,
                                        tablet: 22,
                                        desktop: 24,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.email(),
                                  ]),
                                ),

                                AppSpacing.elementGap,

                                AppButton.large(
                                  text: AppTranslationKey.sendResetLink.tr,
                                  onPressed: isLoading ? null : _submit,
                                  isLoading: isLoading,
                                  loadingText:
                                      AppTranslationKey.sendingResetLink.tr,
                                  width: double.infinity,
                                ),

                                AppSpacing.fieldGap,

                                AppButtonVariants.textButton(
                                  text: AppTranslationKey.backToLogin.tr,
                                  onPressed: isLoading
                                      ? null
                                      : AppNavigator.pop,
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    AppSpacing.gapXl,

                    const CopyrightTermsWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

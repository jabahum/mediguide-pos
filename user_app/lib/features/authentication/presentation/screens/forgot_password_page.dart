import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/features/authentication/presentation/controllers/password_recovery_controller.dart';
import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/shared/widgets/copyright_terms_widget.dart';
import 'package:user_app/shared/widgets/app_logo.dart';
import 'package:user_app/core/widgets/app_button.dart';
import 'package:user_app/shared/widgets/glass_card.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const _emailField = 'email';
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final email = _formKey.currentState!.value[_emailField] as String;
    try {
      final result = await ref
          .read(passwordRecoveryControllerProvider.notifier)
          .requestReset(email);
      if (result == null || !result.accepted || !mounted) return;
      Common.quickToast(
        type: ToastificationType.success,
        title: AppTranslationKey.passwordResetSent,
        description: result.deliveryAccepted
            ? AppTranslationKey.checkEmailForReset
            : result.hasDevelopmentToken
            ? 'Request accepted in development mode. Email delivery is not configured.'
            : 'If the account exists, the request was accepted. Email delivery is not currently confirmed.',
      );
      AppNavigator.pop();
    } catch (error) {
      if (!mounted) return;
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.passwordResetError,
        description: Common.parseApiError(error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(passwordRecoveryControllerProvider).isLoading;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

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
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.secondary.withValues(alpha: 0.05),
                theme.colorScheme.surface,
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
                    // App Logo
                    const AppLogo(logoSize: 200),
                    AppSpacing.gapXl,

                    // Forgot Password Form Card
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: Responsive.value<double>(
                          context,
                          mobile: double.infinity,
                          tablet: 500,
                          desktop: 450,
                        ),
                      ),
                      child: GlassCard.auth(
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Form Title
                              Text(
                                AppTranslationKey.resetPassword.tr,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: Responsive.fontSize(
                                    context,
                                    mobile: 24.0,
                                    tablet: 28.0,
                                    desktop: 32.0,
                                  ),
                                ),
                              ),

                              AppSpacing.contentGap,

                              // Description
                              Text(
                                AppTranslationKey.resetPasswordDescription.tr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: Responsive.fontSize(
                                    context,
                                    mobile: 14.0,
                                    tablet: 15.0,
                                    desktop: 16.0,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              AppSpacing.contentGap,

                              // Email Field
                              FormBuilderTextField(
                                name: _emailField,
                                decoration: InputDecoration(
                                  labelText: AppTranslationKey.email.tr,
                                  hintText: AppTranslationKey.email.tr,
                                  prefixIcon: Icon(
                                    LucideIcons.mail,
                                    color: theme.colorScheme.primary,
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
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
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

                              // Send Reset Button
                              AppButton.large(
                                text: AppTranslationKey.sendResetLink.tr,
                                onPressed: isLoading ? null : _submit,
                                isLoading: isLoading,
                                loadingText:
                                    AppTranslationKey.sendingResetLink.tr,
                                width: double.infinity,
                              ),

                              AppSpacing.fieldGap,

                              // Back to Login Button
                              AppButtonVariants.textButton(
                                text: AppTranslationKey.backToLogin.tr,
                                onPressed: AppNavigator.pop,
                                width: double.infinity,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    AppSpacing.gapXl,

                    // Copyright and Terms
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

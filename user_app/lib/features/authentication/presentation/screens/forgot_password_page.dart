import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
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

part '../widgets/forgot_password_page_widgets.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const String _emailField = 'email';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;
  String _submittedEmail = '';

  // ==========================================================================
  // SUBMIT
  // ==========================================================================

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final form = _formKey.currentState;

    if (form == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!form.saveAndValidate()) {
      return;
    }

    final email =
        form.value[_emailField]?.toString().trim().toLowerCase() ?? '';

    if (email.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref
          .read(passwordRecoveryControllerProvider.notifier)
          .requestReset(email);

      if (!mounted) {
        return;
      }

      //
      // Password-reset screens should avoid revealing whether
      // an account exists for a supplied email address.
      //
      // If the backend accepted the request, show a neutral success state.
      //
      if (result != null && result.accepted) {
        TextInput.finishAutofillContext();

        setState(() {
          _submittedSuccessfully = true;
          _submittedEmail = email;
        });

        return;
      }

      //
      // If your API intentionally returns rejected requests for
      // validation/rate-limiting reasons, show a generic error.
      //
      _showError(
        'Unable to process the reset request right now. Please try again.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('errorSendingResetLink'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ==========================================================================
  // RESEND
  // ==========================================================================

  Future<void> _resend() async {
    if (_submittedEmail.trim().isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(passwordRecoveryControllerProvider.notifier)
          .requestReset(_submittedEmail);

      if (!mounted) {
        return;
      }

      _showSuccess(
        'If an account exists for that email, a new reset link has been sent.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('errorSendingResetLink'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ==========================================================================
  // MESSAGES
  // ==========================================================================

  void _showSuccess(String message) {
    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null || !navigatorContext.mounted) {
      return;
    }

    AppMessage.success(navigatorContext, message);
  }

  void _showError(String message) {
    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null || !navigatorContext.mounted) {
      return;
    }

    AppMessage.error(navigatorContext, message);
  }

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  void _backToLogin() {
    AppNavigator.go(AppRoutes.login);
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(passwordRecoveryControllerProvider);

    final controllerLoading = recoveryState.isLoading;

    final isLoading = controllerLoading || _isSubmitting;

    final theme = context.theme;
    final colors = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FlexColorScheme.themedSystemNavigationBar(
        context,
        noAppBar: true,
        systemNavBarStyle: FlexSystemNavBarStyle.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colors.surface,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: 0.10),
                  colors.secondary.withValues(alpha: 0.05),
                  colors.surface,
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final verticalPadding = Responsive.verticalPadding(context);

                  final horizontalPadding = Responsive.horizontalPadding(
                    context,
                  );

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            (constraints.maxHeight - (verticalPadding * 2))
                                .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Responsive.value<double>(
                              context,
                              mobile: double.infinity,
                              tablet: 500,
                              desktop: 460,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ==============================================
                              // LOGO
                              // ==============================================
                              const Center(child: AppLogo(logoSize: 160)),

                              AppSpacing.gapLg,

                              // ==============================================
                              // CARD
                              // ==============================================
                              GlassCard.auth(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _submittedSuccessfully
                                      ? _ResetRequestSent(
                                          key: const ValueKey('reset-success'),
                                          email: _submittedEmail,
                                          isLoading: isLoading,
                                          onResend: _resend,
                                          onBackToLogin: _backToLogin,
                                        )
                                      : _ResetRequestForm(
                                          key: const ValueKey('reset-form'),
                                          formKey: _formKey,
                                          isLoading: isLoading,
                                          onSubmit: _submit,
                                          onBackToLogin: _backToLogin,
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// RESET FORM
// ============================================================================

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_button.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';

import 'package:user_app/shared/widgets/app_logo.dart';
import 'package:user_app/shared/widgets/copyright_terms_widget.dart';
import 'package:user_app/shared/widgets/glass_card.dart';

part '../widgets/login_page_widgets.dart';

final _passwordVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const String _emailField = 'email';
  static const String _passwordField = 'password';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  bool _isSubmitting = false;

  // ==========================================================================
  // ROUTE CONTEXT
  // ==========================================================================

  String? get _redirect {
    final value = GoRouterState.of(
      context,
    ).uri.queryParameters['redirect']?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? get _reason {
    final value = GoRouterState.of(
      context,
    ).uri.queryParameters['reason']?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  bool get _authenticationRequired {
    return _reason == 'authentication_required';
  }

  // ==========================================================================
  // LOGIN
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

    final valid = form.saveAndValidate();

    if (!valid) {
      return;
    }

    final email = form.value[_emailField]?.toString().trim() ?? '';

    final password = form.value[_passwordField]?.toString() ?? '';

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final loggedIn = await ref
          .read(authControllerProvider.notifier)
          .login(email: email, password: password);

      if (!mounted) {
        return;
      }

      if (!loggedIn) {
        _showLoginError();

        return;
      }

      // Tell Android/iOS that the autofill login session completed.
      TextInput.finishAutofillContext();

      final destination = AppRoutes.safeDestination(_redirect);

      AppNavigator.go(destination);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showLoginError();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showLoginError() {
    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null || !navigatorContext.mounted) {
      return;
    }

    AppMessage.error(
      navigatorContext,
      'Unable to sign in. Check your email and password and try again.',
    );
  }

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  void _openForgotPassword() {
    final redirect = _redirect;

    if (redirect == null) {
      AppNavigator.push(AppRoutes.forgotPassword);

      return;
    }

    AppNavigator.push(
      '${AppRoutes.forgotPassword}'
      '?redirect=${Uri.encodeQueryComponent(redirect)}',
    );
  }

  void _openRegister() {
    final redirect = _redirect;

    if (redirect == null) {
      AppNavigator.push(AppRoutes.register);

      return;
    }

    AppNavigator.push(
      '${AppRoutes.register}'
      '?redirect=${Uri.encodeQueryComponent(redirect)}',
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final auth = authState.valueOrNull;

    final controllerLoading = auth?.phase == AuthPhase.authenticating;

    final isLoading = controllerLoading || _isSubmitting;

    final isPasswordVisible = ref.watch(_passwordVisibleProvider);

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
                stops: const [0, 0.45, 1],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.horizontalPadding(context),
                      vertical: Responsive.verticalPadding(context),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight -
                            (Responsive.verticalPadding(context) * 2),
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
                          child: AutofillGroup(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ============================================
                                // LOGO
                                // ============================================
                                const Center(child: AppLogo(logoSize: 160)),

                                AppSpacing.gapLg,

                                // ============================================
                                // AUTHENTICATION REQUIRED
                                // ============================================
                                if (_authenticationRequired) ...[
                                  const _AuthenticationRequiredBanner(),

                                  AppSpacing.gapMd,
                                ],

                                // ============================================
                                // LOGIN CARD
                                // ============================================
                                GlassCard.auth(
                                  child: FormBuilder(
                                    key: _formKey,
                                    enabled: !isLoading,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // ------------------------------------
                                        // HEADER
                                        // ------------------------------------
                                        Text(
                                          AppTranslationKey.signIn.tr,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: colors.onSurface,
                                                fontSize: Responsive.fontSize(
                                                  context,
                                                  mobile: 24,
                                                  tablet: 28,
                                                  desktop: 30,
                                                ),
                                              ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          'Sign in to access your saved guidelines, '
                                          'notes, downloads and clinical tools.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                        ),

                                        AppSpacing.gapLg,

                                        // ------------------------------------
                                        // EMAIL
                                        // ------------------------------------
                                        FormBuilderTextField(
                                          name: _emailField,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.username,
                                            AutofillHints.email,
                                          ],
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          decoration: _inputDecoration(
                                            context,
                                            label: AppTranslationKey.email.tr,
                                            hint: 'name@example.com',
                                            icon: LucideIcons.mail,
                                          ),
                                          validator: FormBuilderValidators.compose([
                                            FormBuilderValidators.required(
                                              errorText: 'Email is required.',
                                            ),
                                            FormBuilderValidators.email(
                                              errorText:
                                                  'Enter a valid email address.',
                                            ),
                                          ]),
                                        ),

                                        AppSpacing.fieldGap,

                                        // ------------------------------------
                                        // PASSWORD
                                        // ------------------------------------
                                        FormBuilderTextField(
                                          name: _passwordField,
                                          obscureText: !isPasswordVisible,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          enableSuggestions: false,
                                          autocorrect: false,
                                          onSubmitted: (_) {
                                            if (!isLoading) {
                                              _submit();
                                            }
                                          },
                                          decoration: _inputDecoration(
                                            context,
                                            label:
                                                AppTranslationKey.password.tr,
                                            hint: 'Enter your password',
                                            icon: LucideIcons.lock,
                                            suffixIcon: IconButton(
                                              tooltip: isPasswordVisible
                                                  ? 'Hide password'
                                                  : 'Show password',
                                              onPressed: isLoading
                                                  ? null
                                                  : () {
                                                      final notifier = ref.read(
                                                        _passwordVisibleProvider
                                                            .notifier,
                                                      );

                                                      notifier.state =
                                                          !isPasswordVisible;
                                                    },
                                              icon: Icon(
                                                isPasswordVisible
                                                    ? LucideIcons.eyeOff
                                                    : LucideIcons.eye,
                                                color: colors.primary,
                                              ),
                                            ),
                                          ),

                                          // Login should generally not enforce
                                          // the password creation policy.
                                          validator:
                                              FormBuilderValidators.required(
                                                errorText:
                                                    'Password is required.',
                                              ),
                                        ),

                                        // ------------------------------------
                                        // FORGOT PASSWORD
                                        // ------------------------------------
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: isLoading
                                                ? null
                                                : _openForgotPassword,
                                            child: Text(
                                              AppTranslationKey
                                                  .forgotPassword
                                                  .tr,
                                              style: TextStyle(
                                                color: colors.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: Responsive.fontSize(
                                                  context,
                                                  mobile: 14,
                                                  tablet: 15,
                                                  desktop: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        AppSpacing.gapSm,

                                        // ------------------------------------
                                        // SIGN IN
                                        // ------------------------------------
                                        AppButton.large(
                                          text: AppTranslationKey.signIn.tr,
                                          onPressed: isLoading ? null : _submit,
                                          isLoading: isLoading,
                                          loadingText:
                                              AppTranslationKey.signingIn.tr,
                                          width: double.infinity,
                                        ),

                                        AppSpacing.gapMd,

                                        // ------------------------------------
                                        // DIVIDER
                                        // ------------------------------------
                                        const _OrDivider(),

                                        AppSpacing.gapMd,

                                        // ------------------------------------
                                        // REGISTER
                                        // ------------------------------------
                                        AppButtonVariants.outlined(
                                          text: AppTranslationKey
                                              .createAccount
                                              .tr,
                                          onPressed: isLoading
                                              ? null
                                              : _openRegister,
                                          width: double.infinity,
                                          height: Responsive.doubleValue(
                                            context,
                                            mobile: 52,
                                            tablet: 56,
                                            desktop: 60,
                                          ),
                                        ),
                                      ],
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // INPUT DECORATION
  // ==========================================================================

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    final colors = context.theme.colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: colors.surface.withValues(alpha: 0.76),
      prefixIcon: Icon(
        icon,
        color: colors.primary,
        size: Responsive.iconSize(context, mobile: 20, tablet: 22, desktop: 24),
      ),
      suffixIcon: suffixIcon,
      border: _border(context),
      enabledBorder: _border(context),
      focusedBorder: _border(context, color: colors.primary, width: 1.7),
      errorBorder: _border(context, color: colors.error),
      focusedErrorBorder: _border(context, color: colors.error, width: 1.7),
    );
  }

  OutlineInputBorder _border(
    BuildContext context, {
    Color? color,
    double width = 1,
  }) {
    final colors = context.theme.colorScheme;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color ?? colors.outlineVariant.withValues(alpha: 0.7),
        width: width,
      ),
    );
  }
}

// ============================================================================
// AUTHENTICATION REQUIRED BANNER
// ============================================================================

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_button.dart';
import 'package:user_app/shared/widgets/app_logo.dart';
import 'package:user_app/shared/widgets/copyright_terms_widget.dart';
import 'package:user_app/shared/widgets/glass_card.dart';

final _passwordVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _emailField = 'email';
  static const _passwordField = 'password';
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final formData = _formKey.currentState!.value;
    try {
      final loggedIn = await ref
          .read(authControllerProvider.notifier)
          .login(
            email: formData[_emailField] as String,
            password: formData[_passwordField] as String,
          );
      if (loggedIn && mounted) {
        AppNavigator.go(AppRoutes.main);
      }
    } catch (error) {
      if (!mounted) return;
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.loginError,
        description: Common.parseApiError(error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final isLoading = auth?.phase == AuthPhase.authenticating;
    final isPasswordVisible = ref.watch(_passwordVisibleProvider);
    final theme = context.theme;
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FlexColorScheme.themedSystemNavigationBar(
        context,
        noAppBar: true,
        systemNavBarStyle: FlexSystemNavBarStyle.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: FocusScope.of(context).unfocus,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.10),
                  cs.secondary.withValues(alpha: 0.05),
                  cs.surface,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.verticalPadding(context),
                      horizontal: Responsive.horizontalPadding(context),
                    ),
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
                        children: [
                          // ───────────────── Logo & Branding ─────────────────
                          const AppLogo(logoSize: 180),

                          // ───────────────── Login Card ─────────────────
                          GlassCard.auth(
                            child: FormBuilder(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppTranslationKey.signIn.tr,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                          fontSize: Responsive.fontSize(
                                            context,
                                            mobile: 24,
                                            tablet: 28,
                                            desktop: 30,
                                          ),
                                        ),
                                  ),

                                  AppSpacing.contentGap,

                                  // ───────────────── Email ─────────────────
                                  FormBuilderTextField(
                                    name: _emailField,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    decoration: _inputDecoration(
                                      context,
                                      label: AppTranslationKey.email.tr,
                                      icon: LucideIcons.mail,
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.email(),
                                    ]),
                                  ),

                                  AppSpacing.fieldGap,

                                  // ───────────────── Password ─────────────────
                                  FormBuilderTextField(
                                    name: _passwordField,
                                    obscureText: !isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onSubmitted: (_) => _submit(),
                                    decoration: _inputDecoration(
                                      context,
                                      label: AppTranslationKey.password.tr,
                                      icon: LucideIcons.lock,
                                      suffixIcon: IconButton(
                                        tooltip: isPasswordVisible
                                            ? 'Hide password'
                                            : 'Show password',
                                        icon: Icon(
                                          isPasswordVisible
                                              ? LucideIcons.eyeOff
                                              : LucideIcons.eye,
                                          color: cs.primary,
                                        ),
                                        onPressed: () =>
                                            ref
                                                    .read(
                                                      _passwordVisibleProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                !isPasswordVisible,
                                      ),
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.minLength(6),
                                    ]),
                                  ),

                                  AppSpacing.gapSm,

                                  // ───────────────── Forgot Password ─────────────────
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => AppNavigator.pushNamed(
                                        AppRoutes.forgotPassword,
                                      ),
                                      child: Text(
                                        AppTranslationKey.forgotPassword.tr,
                                        style: TextStyle(
                                          color: cs.primary,
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

                                  AppSpacing.elementGap,

                                  // ───────────────── Sign In ─────────────────
                                  AppButton.large(
                                    text: AppTranslationKey.signIn.tr,
                                    onPressed: isLoading ? null : _submit,
                                    isLoading: isLoading,
                                    loadingText: AppTranslationKey.signingIn.tr,
                                    width: double.infinity,
                                  ),

                                  AppSpacing.fieldGap,

                                  // ───────────────── Register ─────────────────
                                  AppButtonVariants.outlined(
                                    text: AppTranslationKey.createAccount.tr,
                                    onPressed: () => AppNavigator.pushNamed(
                                      AppRoutes.register,
                                    ),
                                    width: double.infinity,
                                    height: Responsive.doubleValue(
                                      context,
                                      mobile: 52.0,
                                      tablet: 56.0,
                                      desktop: 60.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          AppSpacing.gapXl,

                          // ───────────────── Copyright ─────────────────
                          const CopyrightTermsWidget(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surface.withValues(alpha: 0.72),

      prefixIcon: Icon(
        icon,
        color: cs.primary,
        size: Responsive.iconSize(context, mobile: 20, tablet: 22, desktop: 24),
      ),

      suffixIcon: suffixIcon,

      border: _border(context),
      enabledBorder: _border(context),

      focusedBorder: _border(context, color: cs.primary, width: 2),

      errorBorder: _border(context, color: cs.error),

      focusedErrorBorder: _border(context, color: cs.error, width: 2),
    );
  }

  OutlineInputBorder _border(
    BuildContext context, {
    Color? color,
    double width = 1,
  }) {
    final cs = context.theme.colorScheme;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color ?? cs.outlineVariant.withValues(alpha: 0.7),
        width: width,
      ),
    );
  }
}

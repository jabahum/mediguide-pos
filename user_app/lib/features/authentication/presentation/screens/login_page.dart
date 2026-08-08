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

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';

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
  static const String _emailField = 'email';
  static const String _passwordField = 'password';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null) {
      return;
    }

    if (!(form.saveAndValidate())) {
      return;
    }

    final email = form.value[_emailField]?.toString().trim();

    final password = form.value[_passwordField]?.toString() ?? '';

    if (email == null || email.isEmpty || password.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      final loggedIn = await ref
          .read(authControllerProvider.notifier)
          .login(email: email, password: password);

      if (!mounted || !loggedIn) {
        return;
      }

      AppNavigator.go(AppRoutes.main);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showLoginError(error);
    }
  }

  void _showLoginError(Object error) {
    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null) {
      return;
    }

    AppMessage.error(navigatorContext, '${'loginFailed'.tr}: $error');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final auth = authState.valueOrNull;

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
                          const AppLogo(logoSize: 180),

                          AppSpacing.gapLg,

                          GlassCard.auth(
                            child: FormBuilder(
                              key: _formKey,
                              enabled: !isLoading,
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

                                  FormBuilderTextField(
                                    name: _emailField,
                                    keyboardType: TextInputType.emailAddress,
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
                                      icon: LucideIcons.mail,
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.email(),
                                    ]),
                                  ),

                                  AppSpacing.fieldGap,

                                  FormBuilderTextField(
                                    name: _passwordField,
                                    obscureText: !isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onSubmitted: (_) {
                                      if (!isLoading) {
                                        _submit();
                                      }
                                    },
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
                                      ),
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.minLength(6),
                                    ]),
                                  ),

                                  AppSpacing.gapSm,

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              AppNavigator.push(
                                                AppRoutes.forgotPassword,
                                              );
                                            },
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

                                  AppButton.large(
                                    text: AppTranslationKey.signIn.tr,
                                    onPressed: isLoading ? null : _submit,
                                    isLoading: isLoading,
                                    loadingText: AppTranslationKey.signingIn.tr,
                                    width: double.infinity,
                                  ),

                                  AppSpacing.fieldGap,

                                  AppButtonVariants.outlined(
                                    text: AppTranslationKey.createAccount.tr,
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            AppNavigator.push(
                                              AppRoutes.register,
                                            );
                                          },
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
    final cs = context.theme.colorScheme;

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

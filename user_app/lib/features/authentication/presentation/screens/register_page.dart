import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_phone_field/form_builder_phone_field.dart';
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

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/app_logo.dart';
import 'package:user_app/shared/widgets/copyright_terms_widget.dart';
import 'package:user_app/shared/widgets/glass_card.dart';

part '../widgets/register_page_widgets.dart';

final _registerPasswordVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  static const String _fullNameField = 'fullName';
  static const String _emailField = 'email';
  static const String _phoneField = 'phoneNumber';
  static const String _alternativePhoneField = 'alternativePhone';
  static const String _licenseField = 'licenseNumber';
  static const String _specializationField = 'specialization';
  static const String _passwordField = 'password';
  static const String _termsField = 'agreeToTerms';

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

  // ==========================================================================
  // VALIDATORS
  // ==========================================================================

  String? _licenseNumberValidator(String? value) {
    final license = value?.trim() ?? '';

    if (license.isEmpty) {
      return 'License number is required';
    }

    if (license.length < 3) {
      return 'License number must be at least 3 characters';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return 'Password must contain at least one letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

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

    final valid = form.saveAndValidate();

    if (!valid) {
      return;
    }

    final values = form.value;

    if (values[_termsField] != true) {
      _showError('agreeToTermsError'.tr);

      return;
    }

    final email = values[_emailField]?.toString().trim() ?? '';

    final password = values[_passwordField]?.toString() ?? '';

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    final userData =
        <String, dynamic>{
          'name': values[_fullNameField]?.toString().trim(),

          'role': UserRole.healthcareProvider.name,

          'status': UserStatus.pendingActivation.name,

          'phone': values[_phoneField]?.toString().trim(),

          'alternative_phone': values[_alternativePhoneField]
              ?.toString()
              .trim(),

          'license_number': values[_licenseField]?.toString().trim(),

          'specialization': values[_specializationField]?.toString().trim(),

          'preferred_language': PreferredLanguage.english.name,
        }..removeWhere(
          (_, value) => value == null || (value is String && value.isEmpty),
        );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final registered = await ref
          .read(authControllerProvider.notifier)
          .register(
            email: email,
            password: password,
            passwordConfirm: password,
            additionalData: userData,
          );

      if (!mounted) {
        return;
      }

      if (!registered) {
        _showError(
          'Unable to create your account. Please review your details and try again.',
        );

        return;
      }

      TextInput.finishAutofillContext();

      final destination = AppRoutes.safeDestination(_redirect);

      AppNavigator.go(destination);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('registrationFailed'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ==========================================================================
  // ERROR
  // ==========================================================================

  void _showError(String message) {
    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null || !navigatorContext.mounted) {
      return;
    }

    AppMessage.error(navigatorContext, message);
  }

  // ==========================================================================
  // BACK TO LOGIN
  // ==========================================================================

  void _backToLogin() {
    final redirect = _redirect;

    if (redirect == null) {
      AppNavigator.go(AppRoutes.login);

      return;
    }

    AppNavigator.go(
      '${AppRoutes.login}'
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

    final isPasswordVisible = ref.watch(_registerPasswordVisibleProvider);

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
                                // ==========================================
                                // LOGO
                                // ==========================================
                                const Center(child: AppLogo(logoSize: 160)),

                                AppSpacing.gapLg,

                                // ==========================================
                                // INTRO
                                // ==========================================
                                const _RegisterIntroCard(),

                                AppSpacing.gapMd,

                                // ==========================================
                                // FORM
                                // ==========================================
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
                                        Text(
                                          AppTranslationKey.createAccount.tr,
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
                                          'Create your MediGuide account to sync bookmarks, '
                                          'reading progress, notes and offline content.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                        ),

                                        AppSpacing.gapLg,

                                        // ==================================
                                        // PERSONAL INFORMATION
                                        // ==================================
                                        const _FormSectionHeader(
                                          icon: LucideIcons.user,
                                          title: 'Personal information',
                                        ),

                                        AppSpacing.gapMd,

                                        FormBuilderTextField(
                                          name: _fullNameField,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          textCapitalization:
                                              TextCapitalization.words,
                                          decoration: _inputDecoration(
                                            context,
                                            label:
                                                AppTranslationKey.fullName.tr,
                                            hint: 'Enter your full name',
                                            icon: LucideIcons.user,
                                          ),
                                          validator:
                                              FormBuilderValidators.compose([
                                                FormBuilderValidators.required(
                                                  errorText:
                                                      'Full name is required',
                                                ),
                                                FormBuilderValidators.minLength(
                                                  2,
                                                  errorText:
                                                      'Enter your full name',
                                                ),
                                              ]),
                                        ),

                                        AppSpacing.fieldGap,

                                        FormBuilderTextField(
                                          name: _emailField,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
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
                                              errorText: 'Email is required',
                                            ),
                                            FormBuilderValidators.email(
                                              errorText:
                                                  'Enter a valid email address',
                                            ),
                                          ]),
                                        ),

                                        AppSpacing.fieldGap,

                                        FormBuilderPhoneField(
                                          name: _phoneField,
                                          decoration: _phoneDecoration(
                                            context,
                                            label: AppTranslationKey
                                                .phoneNumber
                                                .tr,
                                          ),
                                          iconSelector: const SizedBox.shrink(),
                                          countryPicker: (flag, code) =>
                                              _CountryPickerLabel(
                                                flag: flag,
                                                code: code,
                                              ),
                                          defaultSelectedCountryIsoCode: 'UG',
                                          priorityListByIsoCode: const [
                                            'UG',
                                            'KE',
                                            'TZ',
                                            'RW',
                                          ],
                                          validator:
                                              FormBuilderValidators.required(
                                                errorText:
                                                    'Phone number is required',
                                              ),
                                        ),

                                        AppSpacing.fieldGap,

                                        FormBuilderPhoneField(
                                          name: _alternativePhoneField,
                                          decoration: _phoneDecoration(
                                            context,
                                            label: 'Alternative phone',
                                            hint: 'Optional',
                                          ),
                                          iconSelector: const SizedBox.shrink(),
                                          countryPicker: (flag, code) =>
                                              _CountryPickerLabel(
                                                flag: flag,
                                                code: code,
                                              ),
                                          defaultSelectedCountryIsoCode: 'UG',
                                          priorityListByIsoCode: const [
                                            'UG',
                                            'KE',
                                            'TZ',
                                            'RW',
                                          ],
                                        ),

                                        AppSpacing.gapXl,

                                        // ==================================
                                        // PROFESSIONAL INFORMATION
                                        // ==================================
                                        const _FormSectionHeader(
                                          icon: LucideIcons.stethoscope,
                                          title: 'Professional information',
                                        ),

                                        AppSpacing.gapMd,

                                        FormBuilderTextField(
                                          name: _licenseField,
                                          textInputAction: TextInputAction.next,
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          decoration: _inputDecoration(
                                            context,
                                            label: 'License number',
                                            hint:
                                                'Enter professional license number',
                                            icon: LucideIcons.badgeCheck,
                                          ),
                                          validator: _licenseNumberValidator,
                                        ),

                                        AppSpacing.fieldGap,

                                        FormBuilderDropdown<String>(
                                          name: _specializationField,
                                          decoration:
                                              _inputDecoration(
                                                context,
                                                label: AppTranslationKey
                                                    .specialization
                                                    .tr,
                                                icon: LucideIcons
                                                    .briefcaseMedical,
                                              ).copyWith(
                                                hintText: AppTranslationKey
                                                    .selectSpecialization
                                                    .tr,
                                              ),
                                          items: Specialization.values
                                              .map((specialization) {
                                                return DropdownMenuItem<String>(
                                                  value: specialization.name,
                                                  child: Text(
                                                    specialization.label,
                                                  ),
                                                );
                                              })
                                              .toList(growable: false),
                                          validator:
                                              FormBuilderValidators.required(
                                                errorText:
                                                    'Select your specialization',
                                              ),
                                        ),

                                        AppSpacing.gapXl,

                                        // ==================================
                                        // SECURITY
                                        // ==================================
                                        const _FormSectionHeader(
                                          icon: LucideIcons.shieldCheck,
                                          title: 'Account security',
                                        ),

                                        AppSpacing.gapMd,

                                        FormBuilderTextField(
                                          name: _passwordField,
                                          obscureText: !isPasswordVisible,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          onSubmitted: (_) {
                                            if (!isLoading) {
                                              _submit();
                                            }
                                          },
                                          decoration: _inputDecoration(
                                            context,
                                            label:
                                                AppTranslationKey.password.tr,
                                            hint: 'Create a secure password',
                                            icon: LucideIcons.lock,
                                            suffixIcon: IconButton(
                                              tooltip: isPasswordVisible
                                                  ? 'Hide password'
                                                  : 'Show password',
                                              onPressed: isLoading
                                                  ? null
                                                  : () {
                                                      final notifier = ref.read(
                                                        _registerPasswordVisibleProvider
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
                                          validator: _passwordValidator,
                                        ),

                                        const SizedBox(height: 7),

                                        const _PasswordRequirements(),

                                        AppSpacing.gapMd,

                                        // ==================================
                                        // TERMS
                                        // ==================================
                                        FormBuilderCheckbox(
                                          name: _termsField,
                                          initialValue: false,
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          validator:
                                              FormBuilderValidators.equal(
                                                true,
                                                errorText:
                                                    'agreeToTermsError'.tr,
                                              ),
                                          title: _TermsText(
                                            onTermsTap: () {
                                              AppNavigator.push(
                                                AppRoutes.termsAndConditions,
                                              );
                                            },
                                            onPrivacyTap: () {
                                              AppNavigator.push(
                                                AppRoutes.termsAndConditions,
                                              );
                                            },
                                          ),
                                        ),

                                        AppSpacing.gapMd,

                                        // ==================================
                                        // CREATE
                                        // ==================================
                                        AppButton.large(
                                          text: AppTranslationKey
                                              .createAccount
                                              .tr,
                                          onPressed: isLoading ? null : _submit,
                                          isLoading: isLoading,
                                          loadingText: AppTranslationKey
                                              .creatingAccount
                                              .tr,
                                          width: double.infinity,
                                        ),

                                        AppSpacing.gapMd,

                                        const _OrDivider(),

                                        AppSpacing.gapMd,

                                        AppButtonVariants.textButton(
                                          text:
                                              AppTranslationKey.backToLogin.tr,
                                          onPressed: isLoading
                                              ? null
                                              : _backToLogin,
                                          width: double.infinity,
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
  // INPUT
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

  InputDecoration _phoneDecoration(
    BuildContext context, {
    required String label,
    String? hint,
  }) {
    final colors = context.theme.colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint ?? '7XX XXX XXX',
      isDense: true,
      filled: true,
      fillColor: colors.surface.withValues(alpha: 0.76),
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
// REGISTER INTRO
// ============================================================================

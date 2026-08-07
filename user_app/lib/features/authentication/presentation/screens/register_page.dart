import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_phone_field/form_builder_phone_field.dart';
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

import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/app_logo.dart';
import 'package:user_app/shared/widgets/copyright_terms_widget.dart';
import 'package:user_app/shared/widgets/glass_card.dart';

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

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null) {
      return;
    }

    if (!form.saveAndValidate()) {
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

    FocusScope.of(context).unfocus();

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

    try {
      final registered = await ref
          .read(authControllerProvider.notifier)
          .register(
            email: email,
            password: password,
            passwordConfirm: password,
            additionalData: userData,
          );

      if (!mounted || !registered) {
        return;
      }

      AppNavigator.go(AppRoutes.main);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('registrationFailed'.tr);
    }
  }

  void _showError(String message) {
    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null) {
      return;
    }

    AppMessage.error(navigatorContext, message);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final auth = authState.valueOrNull;

    final isLoading = auth?.phase == AuthPhase.authenticating;

    final isPasswordVisible = ref.watch(_registerPasswordVisibleProvider);

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
          child: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.10),
                  cs.secondary.withValues(alpha: 0.05),
                  cs.surface,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
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
                        desktop: 450,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(logoSize: 200),

                        AppSpacing.gapXl,

                        SizedBox(
                          width: double.infinity,
                          child: GlassCard.auth(
                            child: FormBuilder(
                              key: _formKey,
                              enabled: !isLoading,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppTranslationKey.createAccount.tr,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                          fontSize: Responsive.fontSize(
                                            context,
                                            mobile: 24,
                                            tablet: 28,
                                            desktop: 32,
                                          ),
                                        ),
                                  ),

                                  AppSpacing.contentGap,

                                  FormBuilderTextField(
                                    name: _fullNameField,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: _inputDecoration(
                                      context,
                                      label: AppTranslationKey.fullName.tr,
                                      icon: LucideIcons.user,
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.minLength(2),
                                    ]),
                                  ),

                                  AppSpacing.fieldGap,

                                  FormBuilderTextField(
                                    name: _emailField,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
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

                                  FormBuilderPhoneField(
                                    name: _phoneField,
                                    decoration: _phoneDecoration(
                                      context,
                                      label: AppTranslationKey.phoneNumber.tr,
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
                                    validator: FormBuilderValidators.required(),
                                  ),

                                  AppSpacing.fieldGap,

                                  FormBuilderPhoneField(
                                    name: _alternativePhoneField,
                                    decoration: _phoneDecoration(
                                      context,
                                      label: 'Alternative Phone (Optional)',
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

                                  AppSpacing.fieldGap,

                                  FormBuilderTextField(
                                    name: _licenseField,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      context,
                                      label: AppTranslationKey.licenseNumber,
                                      icon: LucideIcons.fileText,
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
                                          icon: LucideIcons.userCheck,
                                        ).copyWith(
                                          hintText: AppTranslationKey
                                              .selectSpecialization
                                              .tr,
                                        ),
                                    items: Specialization.values
                                        .map((specialization) {
                                          return DropdownMenuItem(
                                            value: specialization.name,
                                            child: Text(specialization.label),
                                          );
                                        })
                                        .toList(growable: false),
                                    validator: FormBuilderValidators.required(),
                                  ),

                                  AppSpacing.gapMd,

                                  FormBuilderTextField(
                                    name: _passwordField,
                                    obscureText: !isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
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
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.minLength(8),
                                    ]),
                                  ),

                                  AppSpacing.fieldGap,

                                  FormBuilderCheckbox(
                                    name: _termsField,
                                    initialValue: false,
                                    validator: FormBuilderValidators.equal(
                                      true,
                                      errorText: 'agreeToTermsError'.tr,
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

                                  AppButton.large(
                                    text: AppTranslationKey.createAccount.tr,
                                    onPressed: isLoading ? null : _submit,
                                    isLoading: isLoading,
                                    loadingText:
                                        AppTranslationKey.creatingAccount.tr,
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

  InputDecoration _phoneDecoration(
    BuildContext context, {
    required String label,
  }) {
    final cs = context.theme.colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: '7XX XXX XXX',
      isDense: true,
      filled: true,
      fillColor: cs.surface.withValues(alpha: 0.72),
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

class _CountryPickerLabel extends StatelessWidget {
  const _CountryPickerLabel({required this.flag, required this.code});

  final Widget flag;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 20, height: 14, child: flag),
        const SizedBox(width: 4),
        Text(code, style: context.textTheme.bodyMedium),
      ],
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'I agree to the ', style: theme.textTheme.bodySmall),
          TextSpan(
            text: 'Terms of Service',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTermsTap,
          ),
          TextSpan(text: ' and ', style: theme.textTheme.bodySmall),
          TextSpan(
            text: 'Privacy Policy',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
          ),
        ],
      ),
    );
  }
}

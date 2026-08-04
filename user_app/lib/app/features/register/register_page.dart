import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:form_builder_phone_field/form_builder_phone_field.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:user_app/app/core/navigation/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:toastification/toastification.dart';
import '../../data/models/models.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../../core/navigation/app_router.dart';
import '../../translations/app_translations.dart';
import '../../utils/app_spacing.dart';
import '../../utils/responsive.dart';
import '../../utils/common.dart';
import '../../widgets/copyright_terms_widget.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_button.dart';
import '../../widgets/glass_card.dart';

final _registerPasswordVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  String? _licenseNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }
    if (value.trim().length < 3) {
      return 'License number must be at least 3 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final formData = _formKey.currentState!.value;
    if (formData['agreeToTerms'] != true) {
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.registrationError,
        description: AppTranslationKey.pleaseAgreeToTerms,
      );
      return;
    }

    try {
      final userData = User.forCreate(
        email: formData['email'] as String,
        password: formData['password'] as String,
        name: formData['fullName'] as String,
        role: UserRole.healthcareProvider,
        status: UserStatus.pendingActivation,
        phone: formData['phoneNumber'] as String?,
        alternativePhone: formData['alternativePhone'] as String?,
        licenseNumber: formData['licenseNumber'] as String?,
        specialization: formData['specialization'] as String?,
        preferredLanguage: PreferredLanguage.english,
      );
      final registered = await ref
          .read(authControllerProvider.notifier)
          .register(
            email: formData['email'] as String,
            password: formData['password'] as String,
            passwordConfirm: formData['password'] as String,
            additionalData: userData,
          );
      if (registered && mounted) AppNavigator.go(AppRoutes.main);
    } catch (error) {
      if (!mounted) return;
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.registrationError,
        description: Common.parseApiError(error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final isLoading = auth?.phase == AuthPhase.authenticating;
    final isPasswordVisible = ref.watch(_registerPasswordVisibleProvider);
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

                    // Register Form Card
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
                                AppTranslationKey.createAccount.tr,
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

                              // Full Name Field
                              FormBuilderTextField(
                                name: 'fullName',
                                decoration: InputDecoration(
                                  labelText: AppTranslationKey.fullName.tr,
                                  prefixIcon: Icon(
                                    LucideIcons.user,
                                    color: theme.colorScheme.primary,
                                    size: Responsive.iconSize(
                                      context,
                                      mobile: 20.0,
                                      tablet: 22.0,
                                      desktop: 24.0,
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
                                  FormBuilderValidators.minLength(2),
                                ]),
                              ),

                              AppSpacing.fieldGap,

                              // Email Field
                              FormBuilderTextField(
                                name: 'email',
                                decoration: InputDecoration(
                                  labelText: AppTranslationKey.email.tr,
                                  prefixIcon: Icon(
                                    LucideIcons.mail,
                                    color: theme.colorScheme.primary,
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

                              AppSpacing.fieldGap,

                              // Phone Number Field
                              FormBuilderPhoneField(
                                name: 'phoneNumber',
                                decoration: InputDecoration(
                                  labelText: AppTranslationKey.phoneNumber.tr,
                                  hintText: '7XX XXX XXX',
                                  isDense: true,
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
                                iconSelector: const SizedBox.shrink(),
                                countryPicker: (flag, code) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 14,
                                      child: flag,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      code,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                defaultSelectedCountryIsoCode: 'UG',
                                priorityListByIsoCode: ['UG', 'KE', 'TZ', 'RW'],
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                ]),
                              ),

                              AppSpacing.fieldGap,

                              // Alternative Phone Field
                              FormBuilderPhoneField(
                                name: 'alternativePhone',
                                decoration: InputDecoration(
                                  labelText: 'Alternative Phone (Optional)',
                                  hintText: '7XX XXX XXX',
                                  isDense: true,
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
                                iconSelector: const SizedBox.shrink(),
                                countryPicker: (flag, code) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 14,
                                      child: flag,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      code,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                defaultSelectedCountryIsoCode: 'UG',
                                priorityListByIsoCode: ['UG', 'KE', 'TZ', 'RW'],
                              ),

                              AppSpacing.fieldGap,

                              // License Number Field
                              FormBuilderTextField(
                                name: 'licenseNumber',
                                decoration: InputDecoration(
                                  labelText: AppTranslationKey.licenseNumber,
                                  prefixIcon: Icon(
                                    LucideIcons.fileText,
                                    color: theme.colorScheme.primary,
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
                                validator: _licenseNumberValidator,
                              ),

                              AppSpacing.fieldGap,

                              // Specialization Dropdown Field
                              FormBuilderDropdown<String>(
                                name: 'specialization',
                                decoration: InputDecoration(
                                  labelText:
                                      AppTranslationKey.specialization.tr,
                                  hintText:
                                      AppTranslationKey.selectSpecialization.tr,
                                  prefixIcon: Icon(
                                    LucideIcons.userCheck,
                                    color: theme.colorScheme.primary,
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
                                items: Specialization.values
                                    .map(
                                      (specialization) => DropdownMenuItem(
                                        value: specialization.name,
                                        child: Text(specialization.label),
                                      ),
                                    )
                                    .toList(),
                                validator: FormBuilderValidators.required(),
                              ),

                              AppSpacing.gapMd,

                              // Password Field
                              FormBuilderTextField(
                                name: 'password',
                                obscureText: !isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: AppTranslationKey.password.tr,
                                  prefixIcon: Icon(
                                    LucideIcons.lock,
                                    color: theme.colorScheme.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordVisible
                                          ? LucideIcons.eyeOff
                                          : LucideIcons.eye,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onPressed: () =>
                                        ref
                                                .read(
                                                  _registerPasswordVisibleProvider
                                                      .notifier,
                                                )
                                                .state =
                                            !isPasswordVisible,
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
                                  FormBuilderValidators.minLength(8),
                                ]),
                              ),

                              AppSpacing.fieldGap,

                              // Terms and Conditions Checkbox
                              FormBuilderCheckbox(
                                name: 'agreeToTerms',
                                title: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'I agree to the ',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () =>
                                              AppNavigator.pushNamed(
                                                AppRoutes.termsAndConditions,
                                              ),
                                      ),
                                      TextSpan(
                                        text: ' and ',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () =>
                                              AppNavigator.pushNamed(
                                                AppRoutes.termsAndConditions,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              AppSpacing.gapMd,

                              // Register Button
                              AppButton.large(
                                text: AppTranslationKey.createAccount.tr,
                                onPressed: isLoading ? null : _submit,
                                isLoading: isLoading,
                                loadingText:
                                    AppTranslationKey.creatingAccount.tr,
                                width: double.infinity,
                              ),

                              AppSpacing.fieldGap,

                              // Back to Login Button
                              AppButtonVariants.textButton(
                                text: AppTranslationKey.backToLogin.tr,
                                onPressed: () => AppNavigator.pop(),
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

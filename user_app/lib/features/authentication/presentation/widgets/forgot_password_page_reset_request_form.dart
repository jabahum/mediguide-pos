part of '../screens/forgot_password_page.dart';

class _ResetRequestForm extends StatelessWidget {
  const _ResetRequestForm({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.onSubmit,
    required this.onBackToLogin,
  });

  final GlobalKey<FormBuilderState> formKey;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colorScheme;

    return FormBuilder(
      key: formKey,
      enabled: !isLoading,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------------------------------------
          // ICON
          // ------------------------------------------------------------------
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                LucideIcons.keyRound,
                color: colors.primary,
                size: 22,
              ),
            ),
          ),

          AppSpacing.gapMd,

          // ------------------------------------------------------------------
          // TITLE
          // ------------------------------------------------------------------
          Text(
            AppTranslationKey.resetPassword.tr,
            style: theme.textTheme.headlineSmall?.copyWith(
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
            'Enter the email address associated with your MediGuide '
            'account. If an account exists, we will send instructions '
            'for resetting your password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),

          AppSpacing.gapLg,

          // ------------------------------------------------------------------
          // EMAIL
          // ------------------------------------------------------------------
          FormBuilderTextField(
            name: _ForgotPasswordPageState._emailField,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) {
              if (!isLoading) {
                onSubmit();
              }
            },
            decoration: _AuthInputDecoration.build(
              context,
              label: AppTranslationKey.email.tr,
              hint: 'name@example.com',
              icon: LucideIcons.mail,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Email is required'),
              FormBuilderValidators.email(
                errorText: 'Enter a valid email address',
              ),
            ]),
          ),

          AppSpacing.gapMd,

          // ------------------------------------------------------------------
          // SECURITY NOTE
          // ------------------------------------------------------------------
          const _PasswordResetSecurityNotice(),

          AppSpacing.gapLg,

          // ------------------------------------------------------------------
          // SUBMIT
          // ------------------------------------------------------------------
          AppButton.large(
            text: AppTranslationKey.sendResetLink.tr,
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            loadingText: AppTranslationKey.sendingResetLink.tr,
            width: double.infinity,
          ),

          AppSpacing.gapMd,

          AppButtonVariants.textButton(
            text: AppTranslationKey.backToLogin.tr,
            onPressed: isLoading ? null : onBackToLogin,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SUCCESS STATE
// ============================================================================

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

class _ResetRequestSent extends StatelessWidget {
  const _ResetRequestSent({
    super.key,
    required this.email,
    required this.isLoading,
    required this.onResend,
    required this.onBackToLogin,
  });

  final String email;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ------------------------------------------------------------------
        // SUCCESS ICON
        // ------------------------------------------------------------------
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              LucideIcons.mailCheck,
              color: colors.onTertiaryContainer,
              size: 25,
            ),
          ),
        ),

        AppSpacing.gapMd,

        Text(
          'Check your email',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 6),

        Text(
          'If a MediGuide account is associated with this email address, '
          'password reset instructions have been sent.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),

        if (email.trim().isNotEmpty) ...[
          AppSpacing.gapMd,

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.mail, size: 18, color: colors.primary),

                AppSpacing.hGapSm,

                Expanded(
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        AppSpacing.gapLg,

        FilledButton.icon(
          onPressed: isLoading ? null : onBackToLogin,
          icon: const Icon(LucideIcons.logIn, size: 18),
          label: const Text('Back to Sign In'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),

        AppSpacing.gapSm,

        TextButton.icon(
          onPressed: isLoading ? null : onResend,
          icon: isLoading
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.refreshCw, size: 17),
          label: Text(isLoading ? 'Sending...' : 'Send another reset link'),
        ),

        AppSpacing.gapSm,

        Text(
          'Check your spam or junk folder if the message does not '
          'appear after a few minutes.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ============================================================================
// SECURITY NOTICE
// ============================================================================

class _PasswordResetSecurityNotice extends StatelessWidget {
  const _PasswordResetSecurityNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.shieldCheck,
            size: 18,
            color: colors.onSecondaryContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              'For your security, MediGuide does not reveal whether '
              'an email address is registered.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AUTH INPUT DECORATION
// ============================================================================

abstract final class _AuthInputDecoration {
  static InputDecoration build(
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

  static OutlineInputBorder _border(
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

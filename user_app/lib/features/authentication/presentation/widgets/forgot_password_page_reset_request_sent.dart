part of '../screens/forgot_password_page.dart';

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

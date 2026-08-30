part of '../screens/register_page.dart';

class _RegisterIntroCard extends StatelessWidget {
  const _RegisterIntroCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              LucideIcons.userRoundPlus,
              size: 19,
              color: colors.primary,
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              'Create a professional account to personalize MediGuide and '
              'keep your clinical content synchronized across devices.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
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
// FORM SECTION
// ============================================================================

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: colors.primary),
        ),

        AppSpacing.hGapSm,

        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PASSWORD REQUIREMENTS
// ============================================================================

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 14, color: colors.onSurfaceVariant),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            'Use at least 8 characters with a letter and a number.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// COUNTRY PICKER
// ============================================================================

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

// ============================================================================
// TERMS
// ============================================================================

class _TermsText extends StatefulWidget {
  const _TermsText({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_TermsText> createState() => _TermsTextState();
}

class _TermsTextState extends State<_TermsText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();

    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;

    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void didUpdateWidget(covariant _TermsText oldWidget) {
    super.didUpdateWidget(oldWidget);

    _termsRecognizer.onTap = widget.onTermsTap;

    _privacyRecognizer.onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final normalStyle = theme.textTheme.bodySmall;

    final linkStyle = normalStyle?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'I agree to the ', style: normalStyle),

          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),

          TextSpan(text: ' and ', style: normalStyle),

          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// OR DIVIDER
// ============================================================================

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.outlineVariant)),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Already registered?',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),

        Expanded(child: Divider(color: colors.outlineVariant)),
      ],
    );
  }
}

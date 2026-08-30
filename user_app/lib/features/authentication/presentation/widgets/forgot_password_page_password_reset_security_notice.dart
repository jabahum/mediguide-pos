part of '../screens/forgot_password_page.dart';

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

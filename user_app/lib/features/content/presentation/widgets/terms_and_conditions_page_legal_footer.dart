part of '../screens/terms_and_conditions_page.dart';

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;

    return Column(
      children: [
        Icon(LucideIcons.shieldCheck, size: 22, color: colors.primary),

        AppSpacing.gapSm,

        Text(
          'MediGuide',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 4),

        Text(
          '© $currentYear Ministry of Health Uganda. All rights reserved.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),

        const SizedBox(height: 4),

        Text(
          'Technical implementation and ownership statements should follow the approved MediGuide governance arrangement.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

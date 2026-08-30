part of '../screens/about_us_page.dart';

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(LucideIcons.heartPulse, size: 22, color: colors.primary),

        AppSpacing.gapSm,

        Text(
          'MediGuide',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 3),

        Text(
          'Supporting access to trusted clinical guidance.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

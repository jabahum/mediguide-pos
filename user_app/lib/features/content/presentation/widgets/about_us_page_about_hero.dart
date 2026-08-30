part of '../screens/about_us_page.dart';

class _AboutHero extends StatelessWidget {
  const _AboutHero({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final versionLabel = version.isEmpty
        ? 'Loading version...'
        : buildNumber.isEmpty
        ? 'Version $version'
        : 'Version $version ($buildNumber)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: Responsive.doubleValue(
              context,
              mobile: 76,
              tablet: 84,
              desktop: 92,
            ),
            height: Responsive.doubleValue(
              context,
              mobile: 76,
              tablet: 84,
              desktop: 92,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Image.asset('assets/coat_of_arms.png', fit: BoxFit.contain),
          ),

          AppSpacing.hGapLg,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MediGuide',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Uganda clinical guidance and reference platform',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                AppSpacing.gapSm,

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _MetadataBadge(
                      icon: LucideIcons.package,
                      label: versionLabel,
                    ),
                    const _MetadataBadge(
                      icon: LucideIcons.landmark,
                      label: 'Ministry of Health Uganda',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SECTION
// ===========================================================================

part of '../screens/guest_home_page.dart';

class _ActiveOutbreakCard extends StatelessWidget {
  const _ActiveOutbreakCard({
    required this.outbreak,
    required this.activeCount,
  });

  final PublicOutbreak outbreak;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Active outbreak. ${outbreak.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(AppRoutes.outbreak(outbreak.id));
          },
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.error.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        LucideIcons.siren,
                        color: colors.error,
                        size: 20,
                      ),
                    ),

                    AppSpacing.hGapSm,

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE OUTBREAK',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.error,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                          ),
                          if (activeCount > 1)
                            Text(
                              '$activeCount active outbreak alerts',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onErrorContainer),
                            ),
                        ],
                      ),
                    ),

                    const Icon(LucideIcons.chevronRight),
                  ],
                ),

                AppSpacing.gapMd,

                Text(
                  outbreak.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (outbreak.geographicArea.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 14),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          outbreak.geographicArea,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],

                if (outbreak.summary.trim().isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Text(
                    outbreak.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],

                AppSpacing.gapMd,

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Open response hub',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.arrowUpRight,
                      size: 18,
                      color: colors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PUBLICATIONS
// =============================================================================

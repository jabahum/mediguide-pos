part of '../screens/home_page.dart';

class _LoggedInOutbreakBanner extends StatelessWidget {
  const _LoggedInOutbreakBanner({required this.outbreak});

  final PublicOutbreak outbreak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Active outbreak: ${outbreak.title}',
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => AppNavigator.push(AppRoutes.outbreak(outbreak.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.siren, color: colors.onErrorContainer),
                AppSpacing.md.gap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE OUTBREAK',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outbreak.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (outbreak.geographicArea.isNotEmpty)
                        Text(
                          outbreak.geographicArea,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onErrorContainer),
                        ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: colors.onErrorContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

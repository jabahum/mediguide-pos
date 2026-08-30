part of '../screens/guidelines_page.dart';

class _ActiveGuidelineContext extends StatelessWidget {
  const _ActiveGuidelineContext({
    required this.title,
    required this.hasPermanentFilter,
    required this.hasFilters,
    required this.searchQuery,
    required this.showHighPriorityOnly,
    required this.isEmergencyRoute,
    required this.targetPopulation,
    required this.onClearFilters,
    required this.onShowAll,
  });

  final String title;
  final bool hasPermanentFilter;
  final bool hasFilters;

  final String searchQuery;
  final bool showHighPriorityOnly;
  final bool isEmergencyRoute;
  final String targetPopulation;

  final VoidCallback onClearFilters;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSpecificFilters =
        searchQuery.trim().isNotEmpty ||
        showHighPriorityOnly ||
        isEmergencyRoute ||
        targetPopulation.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPermanentFilter
                    ? LucideIcons.folderOpen
                    : LucideIcons.listFilter,
                size: 17,
                color: colors.onSecondaryContainer,
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  hasPermanentFilter ? title : 'Filters applied',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (hasFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear'),
                ),

              if (hasPermanentFilter)
                TextButton(onPressed: onShowAll, child: const Text('Show all')),
            ],
          ),

          if (hasSpecificFilters)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (searchQuery.trim().isNotEmpty)
                  _ContextBadge(
                    icon: LucideIcons.search,
                    label: '"${searchQuery.trim()}"',
                  ),

                if (showHighPriorityOnly)
                  const _ContextBadge(
                    icon: LucideIcons.triangleAlert,
                    label: 'High Priority',
                  ),

                if (isEmergencyRoute)
                  const _ContextBadge(
                    icon: LucideIcons.siren,
                    label: 'Emergency',
                  ),

                if (targetPopulation.trim().isNotEmpty)
                  _ContextBadge(
                    icon: LucideIcons.users,
                    label: targetPopulation,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

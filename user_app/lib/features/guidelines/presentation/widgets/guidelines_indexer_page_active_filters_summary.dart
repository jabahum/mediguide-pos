part of '../screens/guidelines_indexer_page.dart';

class _ActiveFiltersSummary extends StatelessWidget {
  const _ActiveFiltersSummary({
    required this.filters,
    required this.resultCount,
    required this.onClearSearch,
    required this.onClearLevel,
    required this.onToggleParents,
    required this.onReset,
  });

  final GuidelinesTreeFilter filters;
  final int resultCount;

  final VoidCallback onClearSearch;
  final VoidCallback onClearLevel;
  final VoidCallback onToggleParents;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                LucideIcons.listFilter,
                size: 17,
                color: colors.onSecondaryContainer,
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  'Filters applied',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              TextButton(onPressed: onReset, child: const Text('Clear all')),
            ],
          ),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (filters.search.trim().isNotEmpty)
                InputChip(
                  avatar: const Icon(LucideIcons.search, size: 14),
                  label: Text('"${filters.search}"'),
                  onDeleted: onClearSearch,
                ),

              if (filters.level != null)
                InputChip(
                  avatar: const Icon(LucideIcons.layers, size: 14),
                  label: Text(
                    filters.level == 1 ? 'Top level' : 'Level ${filters.level}',
                  ),
                  onDeleted: onClearLevel,
                ),

              if (filters.showOnlyParents)
                InputChip(
                  avatar: const Icon(LucideIcons.listTree, size: 14),
                  label: const Text('Parents only'),
                  onDeleted: onToggleParents,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TREE CONTAINER
// ===========================================================================

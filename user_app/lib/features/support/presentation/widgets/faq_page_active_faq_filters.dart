part of '../screens/faq_page.dart';

class _ActiveFaqFilters extends StatelessWidget {
  const _ActiveFaqFilters({
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onClearSearch,
    required this.onClearAll,
    required this.onEdit,
  });

  final String searchQuery;
  final bool hasActiveFilters;

  final VoidCallback onClearSearch;
  final VoidCallback onClearAll;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = searchQuery.trim().isNotEmpty;

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
                  hasSearch ? 'FAQ search active' : 'FAQ filters active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              TextButton(onPressed: onEdit, child: const Text('Edit')),

              if (hasActiveFilters)
                TextButton(
                  onPressed: onClearAll,
                  child: const Text('Clear all'),
                ),
            ],
          ),

          if (hasSearch)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: _FaqActiveFilterChip(
                label: searchQuery.trim(),
                onClear: onClearSearch,
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ACTIVE FILTER CHIP
// ===========================================================================

part of '../screens/notifications_page.dart';

class _ActiveNotificationFilters extends StatelessWidget {
  const _ActiveNotificationFilters({
    required this.selectedType,
    required this.selectedPriority,
    required this.onClearType,
    required this.onClearPriority,
    required this.onEdit,
    required this.onClearAll,
  });

  final String selectedType;
  final String selectedPriority;

  final VoidCallback onClearType;
  final VoidCallback onClearPriority;
  final VoidCallback onEdit;
  final VoidCallback onClearAll;

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
                  'Notification filters',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              TextButton(onPressed: onEdit, child: const Text('Edit')),

              TextButton(onPressed: onClearAll, child: const Text('Clear all')),
            ],
          ),

          if (selectedType.isNotEmpty || selectedPriority.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (selectedType.isNotEmpty)
                    _ActiveNotificationFilterChip(
                      icon: LucideIcons.bell,
                      label: _formatFilterLabel(selectedType),
                      onClear: onClearType,
                    ),

                  if (selectedPriority.isNotEmpty)
                    _ActiveNotificationFilterChip(
                      icon: LucideIcons.triangleAlert,
                      label: _formatFilterLabel(selectedPriority),
                      onClear: onClearPriority,
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
// ACTIVE CHIP
// ===========================================================================

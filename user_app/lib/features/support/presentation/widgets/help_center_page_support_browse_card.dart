part of '../screens/help_center_page.dart';

class _SupportBrowseCard extends StatelessWidget {
  const _SupportBrowseCard({
    required this.hasFilters,
    required this.onCreateTicket,
    required this.onOpenFilters,
  });

  final bool hasFilters;
  final VoidCallback onCreateTicket;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.headphones,
              color: colors.primary,
              size: 21,
            ),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 3),

                Text(
                  hasFilters
                      ? 'Filters are active. You can adjust them or submit a new support request.'
                      : 'Create a support ticket when you need technical or account assistance.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                AppSpacing.gapMd,

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onCreateTicket,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Create ticket'),
                    ),

                    OutlinedButton.icon(
                      onPressed: onOpenFilters,
                      icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
                      label: const Text('Filter'),
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
// ACTIVE FILTERS
// ===========================================================================

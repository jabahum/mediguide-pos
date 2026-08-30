part of '../screens/guidelines_indexer_page.dart';

class _TreeSectionHeader extends StatelessWidget {
  const _TreeSectionHeader({required this.state, required this.visibleCount});

  final GuidelinesIndexerState state;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.hasActiveFilters
                    ? 'Matching sections'
                    : 'Browse sections',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                state.hasActiveFilters
                    ? 'Showing sections matching your current filters'
                    : state.pageSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SEARCH
// ===========================================================================

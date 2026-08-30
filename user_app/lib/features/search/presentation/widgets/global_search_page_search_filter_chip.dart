part of '../screens/global_search_page.dart';

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({
    required this.category,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final SearchCategory category;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) {
        onTap();
      },
      avatar: Icon(_SearchResultTile.iconFor(category), size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.displayName),

          if (count > 0) ...[
            const SizedBox(width: 5),

            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ===========================================================================
/// RESULTS
/// ===========================================================================

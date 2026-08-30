part of '../screens/global_search_page.dart';

class _SearchGroupHeader extends StatelessWidget {
  const _SearchGroupHeader({required this.category, required this.count});

  final SearchCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _SearchResultTile.iconFor(category),
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              category == SearchCategory.outbreaks
                  ? 'Outbreaks · Top results'
                  : category.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

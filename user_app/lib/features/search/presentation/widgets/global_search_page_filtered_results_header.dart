part of '../screens/global_search_page.dart';

class _FilteredResultsHeader extends StatelessWidget {
  const _FilteredResultsHeader({required this.category, required this.count});

  final SearchCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _SearchResultTile.iconFor(category),
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            category.displayName,
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
    );
  }
}

part of '../screens/global_search_page.dart';

class _SearchCategoryLabel extends StatelessWidget {
  const _SearchCategoryLabel({required this.category});

  final SearchCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _SearchResultTile.iconFor(category),
            size: 11,
            color: colors.onSecondaryContainer,
          ),

          const SizedBox(width: 4),

          Text(
            category.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===========================================================================
/// HIGHLIGHTED SEARCH TEXT
/// ===========================================================================

part of '../screens/global_search_page.dart';

class _GroupedSearchResults extends StatelessWidget {
  const _GroupedSearchResults({
    required this.results,
    required this.query,
    required this.selectedCategory,
  });

  final List<SearchResult> results;
  final String query;
  final SearchCategory selectedCategory;

  @override
  Widget build(BuildContext context) {
    final groups = <SearchCategory, List<SearchResult>>{};

    for (final result in results) {
      groups.putIfAbsent(result.category, () => []).add(result);
    }
    final orderedCategories = groups.keys.toList()
      ..sort((left, right) {
        final leftScore = groups[left]!
            .map((result) => result.relevanceScore)
            .reduce((a, b) => a > b ? a : b);
        final rightScore = groups[right]!
            .map((result) => result.relevanceScore)
            .reduce((a, b) => a > b ? a : b);
        return rightScore.compareTo(leftScore);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedCategory != SearchCategory.all)
          _FilteredResultsHeader(
            category: selectedCategory,
            count: results.length,
          )
        else
          Text(
            '${results.length} ${results.length == 1 ? 'result' : 'results'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

        AppSpacing.gapMd,

        for (final category in orderedCategories)
          if (groups[category]?.isNotEmpty == true) ...[
            if (selectedCategory == SearchCategory.all) ...[
              _SearchGroupHeader(
                category: category,
                count: groups[category]!.length,
              ),

              AppSpacing.gapSm,
            ],

            for (var index = 0; index < groups[category]!.length; index++) ...[
              _SearchResultTile(result: groups[category]![index], query: query),

              if (index != groups[category]!.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],

            AppSpacing.gapLg,
          ],
      ],
    );
  }
}

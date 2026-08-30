part of '../screens/global_search_page.dart';

class _SearchCategoryFilters extends StatelessWidget {
  const _SearchCategoryFilters({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final SearchCategory selected;

  final Map<SearchCategory, int> counts;

  final ValueChanged<SearchCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (
            var index = 0;
            index < SearchCategory.values.length;
            index++
          ) ...[
            _SearchFilterChip(
              category: SearchCategory.values[index],
              selected: selected == SearchCategory.values[index],
              count: counts[SearchCategory.values[index]] ?? 0,
              onTap: () {
                onSelected(SearchCategory.values[index]);
              },
            ),

            if (index != SearchCategory.values.length - 1)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

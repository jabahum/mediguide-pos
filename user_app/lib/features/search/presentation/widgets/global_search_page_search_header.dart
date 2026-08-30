part of '../screens/global_search_page.dart';

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({this.resultCount});

  final int? resultCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search', style: Theme.of(context).textTheme.headlineMedium),

              const SizedBox(height: 3),

              Text(
                'Search across MediGuide clinical resources',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),

        if (resultCount != null) _ResultCountBadge(count: resultCount!),
      ],
    );
  }
}

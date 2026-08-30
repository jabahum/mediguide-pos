part of '../screens/publication_catalogue_page.dart';

class _CatalogueEmptyState extends StatelessWidget {
  const _CatalogueEmptyState({
    required this.search,
    required this.programArea,
    required this.onClear,
    required this.onRefresh,
  });

  final String search;
  final String programArea;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (search.isNotEmpty) {
      return EmptyState.noResults(
        title: 'No published guidelines found',
        description:
            'No published guideline matched “$search”. Try another term.',
        actionLabel: 'Clear search',
        onAction: onClear,
      );
    }

    if (programArea.isNotEmpty) {
      return EmptyState.noData(
        title: 'No $programArea guidelines',
        description: 'There are no published guidelines in this category yet.',
        actionLabel: 'Refresh',
        onAction: () {
          onRefresh();
        },
      );
    }

    return EmptyState.noData(
      title: 'No published guidelines',
      description:
          'Published clinical guidance will appear here when available.',
      actionLabel: 'Refresh',
      onAction: () {
        onRefresh();
      },
    );
  }
}

part of '../screens/publication_catalogue_page.dart';

class _CatalogueSearchField extends StatelessWidget {
  const _CatalogueSearchField({
    required this.controller,
    required this.hasSearch,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasSearch;

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SearchBar(
      controller: controller,
      hintText: 'Search published guidelines',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (hasSearch)
          IconButton(
            tooltip: 'Clear search',
            onPressed: onClear,
            icon: const Icon(LucideIcons.x),
          ),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
      side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}

class _PublicationCatalogueCard extends StatelessWidget {
  const _PublicationCatalogueCard({required this.publication});

  final GuidelinePublication publication;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final metadata = <String>[
      if (publication.programArea.trim().isNotEmpty)
        publication.programArea.trim(),
      if (publication.sourceOrganization.trim().isNotEmpty)
        publication.sourceOrganization.trim(),
      if (publication.version.trim().isNotEmpty)
        'v${publication.version.trim()}',
    ];

    return Semantics(
      button: true,
      label: publication.title,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push(AppRoutes.publicGuideline(publication.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ClinicalIconTile(icon: LucideIcons.bookOpenText),

                AppSpacing.hGapMd,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),

                      if (publication.programArea.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        _CatalogueCategoryBadge(
                          label: publication.programArea.trim(),
                        ),
                      ],

                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          metadata.join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],

                      if (publication.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          publication.description.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),

                AppSpacing.hGapSm,

                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueCategoryBadge extends StatelessWidget {
  const _CatalogueCategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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

class _CatalogueSkeleton extends StatelessWidget {
  const _CatalogueSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        0,
        Responsive.horizontalPadding(context),
        AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          for (var index = 0; index < 6; index++) ...[
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(height: 42, width: 42),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton(height: 18, width: 240),
                          AppSpacing.gapSm,
                          AppSkeleton(height: 13, width: 160),
                          AppSpacing.gapSm,
                          AppSkeleton(height: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index < 5) AppSpacing.gapSm,
          ],
        ],
      ),
    );
  }
}

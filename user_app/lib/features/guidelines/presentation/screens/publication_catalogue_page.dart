import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_skeleton.dart';
import 'package:user_app/core/widgets/empty_state.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

final _publicationCatalogueProvider = FutureProvider.autoDispose
    .family<List<GuidelinePublication>, ({String search, String programArea})>((
      ref,
      query,
    ) async {
      final page = await ref
          .watch(guidelinePublicationRepositoryProvider)
          .publications(
            search: query.search.trim(),
            programArea: query.programArea.trim(),
            page: 1,
            perPage: 100,
          );

      return page.items;
    });

class PublicationCataloguePage extends ConsumerStatefulWidget {
  const PublicationCataloguePage({
    super.key,
    this.embedded = false,
    this.programArea = '',
  });

  final bool embedded;
  final String programArea;

  @override
  ConsumerState<PublicationCataloguePage> createState() =>
      _PublicationCataloguePageState();
}

class _PublicationCataloguePageState
    extends ConsumerState<PublicationCataloguePage> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  ({String search, String programArea}) get _query =>
      (search: _search, programArea: widget.programArea.trim());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    final normalized = value.trim();

    if (normalized == _search) {
      return;
    }

    setState(() {
      _search = normalized;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    if (_search.isEmpty) {
      setState(() {});
      return;
    }

    setState(() {
      _search = '';
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(_publicationCatalogueProvider(_query));

    await ref.read(_publicationCatalogueProvider(_query).future);
  }

  @override
  Widget build(BuildContext context) {
    final programArea = widget.programArea.trim();
    final publications = ref.watch(_publicationCatalogueProvider(_query));

    final body = RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                AppSpacing.md,
                Responsive.horizontalPadding(context),
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.embedded) ...[
                    Text(
                      programArea.isEmpty
                          ? 'All Guidelines'
                          : '$programArea Guidelines',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      programArea.isEmpty
                          ? 'Browse published clinical guidance'
                          : 'Published guidance in $programArea',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],

                  _CatalogueSearchField(
                    controller: _searchController,
                    hasSearch: _searchController.text.trim().isNotEmpty,
                    onChanged: (_) {
                      setState(() {});
                    },
                    onSubmitted: _submitSearch,
                    onClear: _clearSearch,
                  ),

                  AppSpacing.gapLg,
                ],
              ),
            ),
          ),

          publications.when(
            loading: () =>
                const SliverToBoxAdapter(child: _CatalogueSkeleton()),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: AppErrorView(
                error: error,
                title: 'Failed to load guidelines',
                message: 'The publication catalogue could not be loaded.',
                onRetry: () {
                  ref.invalidate(_publicationCatalogueProvider(_query));
                },
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _CatalogueEmptyState(
                    search: _search,
                    programArea: programArea,
                    onClear: _clearSearch,
                    onRefresh: _refresh,
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(context),
                  0,
                  Responsive.horizontalPadding(context),
                  AppSpacing.xxxl,
                ),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                  itemBuilder: (context, index) {
                    return _PublicationCatalogueCard(publication: items[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              programArea.isEmpty
                  ? 'All Guidelines'
                  : '$programArea Guidelines',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              _search.isEmpty
                  ? programArea.isEmpty
                        ? 'Published clinical guidance'
                        : 'Published guidance in $programArea'
                  : programArea.isEmpty
                  ? 'Results for “$_search”'
                  : 'Results for “$_search” in $programArea',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}

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

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

part '../widgets/publication_catalogue_page_widgets.dart';

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

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
    .family<List<GuidelinePublication>, String>((ref, search) async {
      final page = await ref
          .watch(guidelinePublicationRepositoryProvider)
          .publications(search: search);
      return page.items;
    });

class PublicationCataloguePage extends ConsumerStatefulWidget {
  const PublicationCataloguePage({super.key, this.embedded = false});
  final bool embedded;

  @override
  ConsumerState<PublicationCataloguePage> createState() =>
      _PublicationCataloguePageState();
}

class _PublicationCataloguePageState
    extends ConsumerState<PublicationCataloguePage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final publications = ref.watch(_publicationCatalogueProvider(_search));
    final body = publications.when(
      loading: () => const _CatalogueSkeleton(),
      error: (error, _) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(_publicationCatalogueProvider(_search)),
      ),
      data: (items) => items.isEmpty
          ? EmptyState.noResults(
              title: 'No published guidelines',
              description: _search.isEmpty
                  ? 'No guideline publications are available yet.'
                  : 'No published guideline matched “$_search”.',
              actionLabel: _search.isEmpty ? null : 'Clear search',
              onAction: _search.isEmpty
                  ? null
                  : () => setState(() => _search = ''),
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(_publicationCatalogueProvider(_search)),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(context),
                  AppSpacing.md,
                  Responsive.horizontalPadding(context),
                  AppSpacing.xxxl,
                ),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: SearchBar(
                        hintText: 'Search published guidelines',
                        leading: const Icon(LucideIcons.search),
                        onSubmitted: (value) =>
                            setState(() => _search = value.trim()),
                      ),
                    );
                  }
                  final item = items[index - 1];
                  return Semantics(
                    button: true,
                    label: '${item.title}, version ${item.version}',
                    child: Card(
                      child: ListTile(
                        minVerticalPadding: AppSpacing.md,
                        leading: const ClinicalIconTile(
                          icon: LucideIcons.bookOpenText,
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          [
                            item.programArea,
                            if (item.sourceOrganization.isNotEmpty)
                              item.sourceOrganization,
                            if (item.version.isNotEmpty)
                              'Version ${item.version}',
                          ].where((value) => value.isNotEmpty).join(' · '),
                        ),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () =>
                            context.push(AppRoutes.publicGuideline(item.id)),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Guidelines')),
            body: body,
          );
  }
}

class _CatalogueSkeleton extends StatelessWidget {
  const _CatalogueSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: EdgeInsets.symmetric(
      horizontal: Responsive.horizontalPadding(context),
      vertical: AppSpacing.md,
    ),
    itemCount: 6,
    separatorBuilder: (_, _) => AppSpacing.gapMd,
    itemBuilder: (_, index) => const Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton(height: 22, width: 240),
            AppSpacing.gapSm,
            AppSkeleton(height: 14),
          ],
        ),
      ),
    ),
  );
}

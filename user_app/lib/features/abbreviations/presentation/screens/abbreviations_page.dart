import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
import 'package:user_app/features/abbreviations/presentation/controllers/abbreviations_controller.dart';
import 'package:user_app/features/abbreviations/presentation/widgets/abbreviation_card.dart';

import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

class AbbreviationsPage extends ConsumerWidget {
  const AbbreviationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(abbreviationsControllerProvider);

    final controller = ref.read(abbreviationsControllerProvider.notifier);

    final colors = Theme.of(context).colorScheme;

    final query = state.query;

    final hasSearch = query.search.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslationKey.medicalAbbreviations,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              hasSearch
                  ? 'Results for “${query.search.trim()}”'
                  : 'Medical terms and short forms',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          FilterButton(
            hasActiveFilters: query.hasFilters,
            onPressed: () {
              controller.showFilterModal(context);
            },
            onReset: query.hasFilters ? controller.clearAllFilters : null,
            tooltip: 'Filter abbreviations',
          ),
          AppSpacing.hGapXs,
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // CONTEXT
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AbbreviationBrowseCard(
                      hasSearch: hasSearch,
                      searchQuery: query.search,
                      hasFilters: query.hasFilters,
                      onOpenFilters: () {
                        controller.showFilterModal(context);
                      },
                    ),

                    if (query.hasFilters) ...[
                      AppSpacing.gapMd,

                      _ActiveAbbreviationFilters(
                        searchQuery: query.search,
                        onEdit: () {
                          controller.showFilterModal(context);
                        },
                        onClear: controller.clearAllFilters,
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      query.hasFilters
                          ? 'Matching abbreviations'
                          : 'Abbreviations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      query.hasFilters
                          ? 'Showing terms matching your current search and filters.'
                          : 'Browse medical abbreviations and their meanings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    AppSpacing.gapSm,
                  ],
                ),
              ),
            ),

            // =================================================================
            // LIST
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, Abbreviation>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, Abbreviation>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Abbreviation>(
                      // =====================================================
                      // ITEM
                      // =====================================================
                      itemBuilder: (context, item, index) {
                        return _AbbreviationCardShell(
                          child: AbbreviationCard(
                            abbreviation: item,
                            onTap: () {
                              controller.showAbbreviationDetail(context, item);
                            },
                          ),
                        );
                      },

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading medical abbreviations...',
                        );
                      },

                      // =====================================================
                      // NEXT PAGE LOADING
                      // =====================================================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // =====================================================
                      // FIRST PAGE ERROR
                      // =====================================================
                      firstPageErrorIndicatorBuilder: (_) {
                        return AppErrorView(
                          error:
                              pagingState.error ??
                              'Unable to load abbreviations',
                          title: AppTranslationKey.failedToLoadAbbreviations,
                          message: AppTranslationKey
                              .pleaseCheckConnectionAndTryAgain,
                          onRetry: fetchNextPage,
                        );
                      },

                      // =====================================================
                      // NEXT PAGE ERROR
                      // =====================================================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title:
                              AppTranslationKey.failedToLoadMoreAbbreviations,
                          icon: LucideIcons.bookOpen,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (query.hasFilters) {
                          return EmptyState.noResults(
                            title:
                                AppTranslationKey.noAbbreviationsMatchFilters,
                            description:
                                AppTranslationKey.tryAdjustingSearchOrFilters,
                            actionLabel: AppTranslationKey.clearFilters,
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: AppTranslationKey.noAbbreviationsFound,
                          description:
                              AppTranslationKey.abbreviationsWillAppearHere,
                        );
                      },

                      // =====================================================
                      // END
                      // =====================================================
                      noMoreItemsIndicatorBuilder: (_) {
                        return Padding(
                          padding: AppSpacing.vPaddingMd,
                          child: PaginationIndicators.noMoreItems(),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// BROWSE / FILTER CARD
// ===========================================================================

class _AbbreviationBrowseCard extends StatelessWidget {
  const _AbbreviationBrowseCard({
    required this.hasSearch,
    required this.searchQuery,
    required this.hasFilters,
    required this.onOpenFilters,
  });

  final bool hasSearch;
  final String searchQuery;
  final bool hasFilters;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenFilters,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.wholeWord,
                  color: colors.primary,
                  size: 21,
                ),
              ),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSearch
                          ? 'Searching abbreviations'
                          : 'Find an abbreviation',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasSearch
                          ? 'Current search: “${searchQuery.trim()}”'
                          : hasFilters
                          ? 'Filters are applied. Tap to adjust them.'
                          : 'Search by abbreviation, full meaning or category.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.hGapSm,

              Icon(
                LucideIcons.slidersHorizontal,
                size: 20,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ACTIVE FILTERS
// ===========================================================================

class _ActiveAbbreviationFilters extends StatelessWidget {
  const _ActiveAbbreviationFilters({
    required this.searchQuery,
    required this.onEdit,
    required this.onClear,
  });

  final String searchQuery;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.listFilter,
            size: 18,
            color: colors.onSecondaryContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters applied',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (searchQuery.trim().isNotEmpty)
                  Text(
                    'Search: ${searchQuery.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
              ],
            ),
          ),

          TextButton(onPressed: onEdit, child: const Text('Edit')),

          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

// ===========================================================================
// CARD SHELL
// ===========================================================================

class _AbbreviationCardShell extends StatelessWidget {
  const _AbbreviationCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

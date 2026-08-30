import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/drugs/presentation/controllers/drug_index_controller.dart';
import 'package:user_app/features/drugs/presentation/widgets/drug_card.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

part '../widgets/drug_index_page_drug_search_field.dart';
part '../widgets/drug_index_page_drug_search_field_state.dart';
part '../widgets/drug_index_page_active_drug_filters_banner.dart';
part '../widgets/drug_index_page_drug_card_shell.dart';

class DrugIndexPage extends ConsumerStatefulWidget {
  const DrugIndexPage({super.key});

  @override
  ConsumerState<DrugIndexPage> createState() => _DrugIndexPageState();
}

class _DrugIndexPageState extends ConsumerState<DrugIndexPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(drugIndexControllerProvider);

    final controller = ref.read(drugIndexControllerProvider.notifier);

    final colors = Theme.of(context).colorScheme;

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
              AppTranslationKey.drugIndex.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Reviewed medicine references',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          FilterButton(
            hasActiveFilters: state.hasActiveFilters,
            onPressed: () {
              controller.showFilterModal(context);
            },
            onReset: state.hasActiveFilters ? controller.clearAllFilters : null,
          ),
          AppSpacing.hGapXs,
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // SEARCH + FILTER CONTEXT
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
                    _DrugSearchField(
                      controller: _searchController,
                      onChanged: (value) {
                        //
                        // If your controller already exposes a search method,
                        // replace this with that method.
                        //
                        // Example:
                        // controller.setSearchQuery(value);
                      },
                      onSubmitted: (value) {
                        //
                        // Replace with your controller search submit method.
                        //
                        // Example:
                        // controller.submitSearchQuery(value);
                      },
                      onClear: () {
                        _searchController.clear();

                        //
                        // Replace with your controller's clear search method.
                        //
                        // Example:
                        // controller.setSearchQuery('');
                        // controller.submitSearchQuery('');
                        //

                        setState(() {});
                      },
                    ),

                    if (state.hasActiveFilters) ...[
                      AppSpacing.gapMd,
                      _ActiveDrugFiltersBanner(
                        onClear: controller.clearAllFilters,
                        onOpenFilters: () {
                          controller.showFilterModal(context);
                        },
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      state.hasActiveFilters
                          ? 'Matching medicines'
                          : 'Medicines',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      state.hasActiveFilters
                          ? 'Showing medicines matching the current filters.'
                          : 'Browse medicine indications, dosage guidance and safety information.',
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
            // PAGINATED MEDICINES
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, Drug>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, Drug>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Drug>(
                      // =====================================================
                      // ITEM
                      // =====================================================
                      itemBuilder: (context, drug, index) {
                        return _DrugCardShell(
                          child: DrugCard(
                            drug: drug,
                            onTap: () {
                              controller.navigateToDrugDetail(drug);
                            },
                            onBookmarkTap: () {
                              controller.toggleBookmark(drug);
                            },
                          ),
                        );
                      },

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading medicines...',
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
                              pagingState.error ?? 'Unable to load medicines',
                          title: 'failedToLoadDrugs'.tr,
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
                          title: 'failedToLoadMoreDrugs'.tr,
                          icon: LucideIcons.pill,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: AppTranslationKey.noDrugsMatchFilters,
                            description:
                                AppTranslationKey.tryAdjustingSearchOrFilters,
                            actionLabel: AppTranslationKey.clearFilters,
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: 'noDrugsFound'.tr,
                          description: AppTranslationKey.drugsWillAppearHere,
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
// SEARCH
// ===========================================================================

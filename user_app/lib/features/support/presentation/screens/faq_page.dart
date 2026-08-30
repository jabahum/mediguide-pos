import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/support/presentation/controllers/faq_controller.dart';
import 'package:user_app/features/support/presentation/widgets/faq_expansion_item.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

part '../widgets/faq_page_faq_browse_card.dart';
part '../widgets/faq_page_active_faq_filters.dart';
part '../widgets/faq_page_faq_active_filter_chip.dart';
part '../widgets/faq_page_faq_item_shell.dart';

class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faqControllerProvider);

    final controller = ref.read(faqControllerProvider.notifier);

    final colors = Theme.of(context).colorScheme;

    final hasSearch = state.searchQuery.trim().isNotEmpty;

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
              AppTranslationKey.frequentlyAskedQuestions.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Help and common questions',
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
          controller.refreshFAQs();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =================================================================
            // SEARCH / FILTER CONTEXT
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
                    _FaqBrowseCard(
                      searchQuery: state.searchQuery,
                      hasActiveFilters: state.hasActiveFilters,
                      onOpenFilters: () {
                        controller.showFilterModal(context);
                      },
                    ),

                    if (hasSearch || state.hasActiveFilters) ...[
                      AppSpacing.gapMd,

                      _ActiveFaqFilters(
                        searchQuery: state.searchQuery,
                        hasActiveFilters: state.hasActiveFilters,
                        onClearSearch: controller.clearSearch,
                        onClearAll: controller.clearAllFilters,
                        onEdit: () {
                          controller.showFilterModal(context);
                        },
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      hasSearch || state.hasActiveFilters
                          ? 'Matching questions'
                          : 'Common questions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasSearch
                          ? 'Showing answers related to “${state.searchQuery.trim()}”.'
                          : state.hasActiveFilters
                          ? 'Showing FAQs matching your current filters.'
                          : 'Browse frequently asked questions about MediGuide.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
            // FAQ LIST
            // =================================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, FAQ>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, FAQ>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<FAQ>(
                      // =====================================================
                      // ITEM
                      // =====================================================
                      itemBuilder: (context, faq, index) {
                        return _FaqItemShell(child: FaqExpansionItem(faq: faq));
                      },

                      // =====================================================
                      // FIRST PAGE LOADING
                      // =====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(message: 'Loading FAQs...');
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
                          error: pagingState.error ?? 'Failed to load FAQs',
                          title: 'Unable to load FAQs',
                          message:
                              'Please check your connection and try again.',
                          onRetry: fetchNextPage,
                        );
                      },

                      // =====================================================
                      // NEXT PAGE ERROR
                      // =====================================================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: AppTranslationKey.errorLoadingMore.tr,
                          icon: LucideIcons.messageCircleQuestion,
                        );
                      },

                      // =====================================================
                      // EMPTY
                      // =====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (hasSearch || state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: AppTranslationKey.noFAQsFound.tr,
                            description:
                                AppTranslationKey.tryDifferentSearchTerm.tr,
                            actionLabel: hasSearch
                                ? AppTranslationKey.clearSearch.tr
                                : 'Clear filters',
                            onAction: hasSearch
                                ? controller.clearSearch
                                : controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: AppTranslationKey.noFAQsAvailable.tr,
                          description: AppTranslationKey.faqsWillAppearHere.tr,
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
// BROWSE CARD
// ===========================================================================

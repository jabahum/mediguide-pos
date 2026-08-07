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

class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faqControllerProvider);

    final controller = ref.read(faqControllerProvider.notifier);

    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.frequentlyAskedQuestions.tr,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          FilterButton(
            hasActiveFilters: state.hasActiveFilters,
            onPressed: () {
              controller.showFilterModal(context);
            },
            onReset: state.hasActiveFilters ? controller.clearAllFilters : null,
          ),
          AppSpacing.xs.gap,
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshFAQs();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // =================================================
            // HEADER
            // =================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _FaqHeaderCard(
                  searchQuery: state.searchQuery,
                  hasFilters: state.hasActiveFilters,
                  onOpenFilters: () {
                    controller.showFilterModal(context);
                  },
                  onClearFilters: controller.clearAllFilters,
                ),
              ),
            ),

            // =================================================
            // FAQ LIST
            // =================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, FAQ>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, FAQ>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<FAQ>(
                      itemBuilder: (context, faq, index) {
                        return _FaqItemShell(child: FaqExpansionItem(faq: faq));
                      },

                      // =========================
                      // FIRST PAGE LOADING
                      // =========================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(message: 'Loading FAQs...');
                      },

                      // =========================
                      // NEXT PAGE LOADING
                      // =========================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // =========================
                      // FIRST PAGE ERROR
                      // =========================
                      firstPageErrorIndicatorBuilder: (_) {
                        return AppErrorView(
                          error: pagingState.error ?? 'Failed to load FAQs',
                          onRetry: fetchNextPage,
                        );
                      },

                      // =========================
                      // NEXT PAGE ERROR
                      // =========================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: AppTranslationKey.errorLoadingMore.tr,
                          icon: LucideIcons.messageCircleQuestion,
                        );
                      },

                      // =========================
                      // EMPTY
                      // =========================
                      noItemsFoundIndicatorBuilder: (_) {
                        final hasSearch = state.searchQuery.trim().isNotEmpty;

                        if (hasSearch || state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: AppTranslationKey.noFAQsFound.tr,
                            description:
                                AppTranslationKey.tryDifferentSearchTerm.tr,
                            actionLabel: hasSearch
                                ? AppTranslationKey.clearSearch.tr
                                : 'Clear Filters',
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

                      // =========================
                      // END
                      // =========================
                      noMoreItemsIndicatorBuilder: (_) {
                        return PaginationIndicators.noMoreItems();
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

// =========================================================
// HEADER
// =========================================================

class _FaqHeaderCard extends StatelessWidget {
  const _FaqHeaderCard({
    required this.searchQuery,
    required this.hasFilters,
    required this.onOpenFilters,
    required this.onClearFilters,
  });

  final String searchQuery;
  final bool hasFilters;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final hasSearch = searchQuery.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              LucideIcons.messageCircleQuestion,
              color: cs.primary,
              size: 28,
            ),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.frequentlyAskedQuestions.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  hasSearch
                      ? 'Showing answers matching "$searchQuery".'
                      : 'Find quick answers about MediGuide, guidelines, tools and support.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                if (hasFilters) ...[
                  const SizedBox(height: 10),

                  _FaqActiveFilterChip(
                    label: hasSearch ? searchQuery : 'Filters active',
                    onClear: onClearFilters,
                  ),
                ],
              ],
            ),
          ),

          AppSpacing.sm.gap,

          IconButton.filledTonal(
            onPressed: onOpenFilters,
            icon: const Icon(LucideIcons.slidersHorizontal),
            tooltip: 'Filter FAQs',
          ),
        ],
      ),
    );
  }
}

// =========================================================
// ACTIVE FILTER CHIP
// =========================================================

class _FaqActiveFilterChip extends StatelessWidget {
  const _FaqActiveFilterChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return InputChip(
      avatar: Icon(LucideIcons.search, size: 14, color: cs.primary),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onDeleted: onClear,
      deleteIcon: const Icon(LucideIcons.x, size: 14),
      backgroundColor: cs.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
      labelStyle: context.textTheme.labelSmall?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// =========================================================
// FAQ ITEM SHELL
// =========================================================

class _FaqItemShell extends StatelessWidget {
  const _FaqItemShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/models.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_button.dart';
import '../../widgets/pagination_indicators.dart';
import 'faq_controller.dart';
import 'widgets/faq_expansion_item.dart';

class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(faqControllerProvider);
    return Scaffold(
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
            hasActiveFilters: controller.hasActiveFilters,
            onPressed: () => controller.showFilterModal(context),
            onReset: controller.hasActiveFilters
                ? controller.clearAllFilters
                : null,
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.refreshFAQs(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _FaqHeaderCard(
                  onOpenFilters: () => controller.showFilterModal(context),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: PagingListener<int, FAQ>(
                controller: controller.pagingController,
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, FAQ>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<FAQ>(
                      itemBuilder: (context, faq, index) {
                        return _FaqItemShell(child: FaqExpansionItem(faq: faq));
                      },
                      firstPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageError(
                            onRetry: fetchNextPage,
                            title: AppTranslationKey.failedToLoadFAQs.tr,
                            subtitle:
                                AppTranslationKey.checkInternetAndRetry.tr,
                            icon: LucideIcons.messageCircle,
                          ),
                      firstPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageProgress(),
                      newPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageProgress(),
                      newPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageError(
                            onRetry: fetchNextPage,
                            title: AppTranslationKey.errorLoadingMore.tr,
                            icon: LucideIcons.messageCircle,
                          ),
                      noItemsFoundIndicatorBuilder: (context) {
                        final hasSearchQuery = controller.searchQuery
                            .trim()
                            .isNotEmpty;
                        final hasFilters = controller.hasActiveFilters;

                        return _EmptyFaqState(
                          hasSearchQuery: hasSearchQuery,
                          hasFilters: hasFilters,
                          onClearSearch: controller.clearSearch,
                          onClearFilters: controller.clearAllFilters,
                        );
                      },
                      noMoreItemsIndicatorBuilder: (context) =>
                          PaginationIndicators.noMoreItems(),
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

class _FaqHeaderCard extends StatelessWidget {
  final VoidCallback onOpenFilters;

  const _FaqHeaderCard({required this.onOpenFilters});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
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
                  'Find quick answers about MediGuide, guidelines, tools and support.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
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

class _FaqItemShell extends StatelessWidget {
  final Widget child;

  const _FaqItemShell({required this.child});

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

class _EmptyFaqState extends StatelessWidget {
  final bool hasSearchQuery;
  final bool hasFilters;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilters;

  const _EmptyFaqState({
    required this.hasSearchQuery,
    required this.hasFilters,
    required this.onClearSearch,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final hasAnyFilter = hasSearchQuery || hasFilters;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              hasAnyFilter ? LucideIcons.searchX : LucideIcons.messageCircle,
              color: cs.primary,
              size: 34,
            ),
          ),

          AppSpacing.md.gap,

          Text(
            hasAnyFilter
                ? AppTranslationKey.noFAQsFound.tr
                : AppTranslationKey.noFAQsAvailable.tr,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            hasAnyFilter
                ? AppTranslationKey.tryDifferentSearchTerm.tr
                : AppTranslationKey.faqsWillAppearHere.tr,
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          if (hasAnyFilter) ...[
            AppSpacing.lg.gap,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                if (hasSearchQuery)
                  FilledButton.icon(
                    onPressed: onClearSearch,
                    icon: const Icon(LucideIcons.x),
                    label: Text(AppTranslationKey.clearSearch.tr),
                  ),
                if (hasFilters)
                  OutlinedButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(LucideIcons.slidersHorizontal),
                    label: const Text('Clear Filters'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

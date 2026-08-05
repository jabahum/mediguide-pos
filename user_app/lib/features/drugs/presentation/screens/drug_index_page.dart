import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';
import 'package:user_app/features/drugs/presentation/controllers/drug_index_controller.dart';
import 'package:user_app/features/drugs/presentation/widgets/drug_card.dart';

class DrugIndexPage extends ConsumerWidget {
  const DrugIndexPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(drugIndexControllerProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.drugIndex.tr,
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
        onRefresh: () => Future.sync(controller.refreshData),
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
                child: _DrugIndexHeaderCard(
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
              sliver: PagingListener<int, Drug>(
                controller: controller.pagingController,
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, Drug>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Drug>(
                      itemBuilder: (context, drug, index) {
                        return _DrugCardShell(
                          child: DrugCard(
                            drug: drug,
                            onTap: () => controller.navigateToDrugDetail(drug),
                            onBookmarkTap: () =>
                                controller.toggleBookmark(drug),
                          ),
                        );
                      },
                      firstPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageError(
                            onRetry: fetchNextPage,
                            title: 'failedToLoadDrugs'.tr,
                            subtitle: AppTranslationKey
                                .pleaseCheckConnectionAndTryAgain,
                            icon: LucideIcons.pill,
                          ),
                      newPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageError(
                            onRetry: fetchNextPage,
                            title: 'failedToLoadMoreDrugs'.tr,
                            icon: LucideIcons.pill,
                          ),
                      firstPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageProgress(),
                      newPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageProgress(),
                      noItemsFoundIndicatorBuilder: (context) {
                        return _EmptyDrugState(
                          hasFilters: controller.hasActiveFilters,
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

class _DrugIndexHeaderCard extends StatelessWidget {
  final VoidCallback onOpenFilters;

  const _DrugIndexHeaderCard({required this.onOpenFilters});

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
            child: Icon(LucideIcons.pill, color: cs.primary, size: 28),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.drugIndex.tr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search medicines, review indications, dosage guidance and safety information.',
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
            tooltip: 'Filter drugs',
          ),
        ],
      ),
    );
  }
}

class _DrugCardShell extends StatelessWidget {
  final Widget child;

  const _DrugCardShell({required this.child});

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

class _EmptyDrugState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyDrugState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final title = hasFilters
        ? AppTranslationKey.noDrugsMatchFilters
        : 'noDrugsFound'.tr;

    final subtitle = hasFilters
        ? AppTranslationKey.tryAdjustingSearchOrFilters
        : AppTranslationKey.drugsWillAppearHere;

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
              hasFilters ? LucideIcons.searchX : LucideIcons.pill,
              color: cs.primary,
              size: 34,
            ),
          ),

          AppSpacing.md.gap,

          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          if (hasFilters) ...[
            AppSpacing.lg.gap,
            FilledButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(LucideIcons.x),
              label: Text(AppTranslationKey.clearFilters),
            ),
          ],
        ],
      ),
    );
  }
}

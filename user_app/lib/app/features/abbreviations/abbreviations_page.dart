import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/abbreviation.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_button.dart';
import '../../widgets/pagination_indicators.dart';
import 'abbreviations_controller.dart';
import 'widgets/abbreviation_card.dart';

class AbbreviationsPage extends ConsumerWidget {
  const AbbreviationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(abbreviationsControllerProvider);
    final cs = context.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          AppTranslationKey.medicalAbbreviations,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          FilterButton(
            hasActiveFilters: controller.query.hasFilters,
            onPressed: () => controller.showFilterModal(context),
            onReset: controller.query.hasFilters
                ? controller.clearAllFilters
                : null,
            tooltip: 'Filter abbreviations',
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.pagingController.refresh();
        },
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
                child: Builder(
                  builder: (context) {
                    final query = controller.query;

                    return _AbbreviationsHeaderCard(
                      searchQuery: query.search,
                      hasFilters: query.hasFilters,
                      onOpenFilters: () => controller.showFilterModal(context),
                      onClearFilters: controller.clearAllFilters,
                    );
                  },
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
              sliver: PagingListener<int, Abbreviation>(
                controller: controller.pagingController,
                builder: (context, state, fetchNextPage) {
                  return PagedSliverList<int, Abbreviation>.separated(
                    state: state,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Abbreviation>(
                      itemBuilder: (context, item, index) {
                        return _AbbreviationCardShell(
                          child: AbbreviationCard(
                            abbreviation: item,
                            onTap: () => controller.showAbbreviationDetail(
                              context,
                              item,
                            ),
                          ),
                        );
                      },

                      // =========================
                      // LOADING STATES
                      // =========================
                      firstPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageProgress(),

                      newPageProgressIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageProgress(),

                      // =========================
                      // ERROR STATES
                      // =========================
                      firstPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.firstPageError(
                            onRetry: fetchNextPage,
                            title: AppTranslationKey.failedToLoadAbbreviations,
                            subtitle: AppTranslationKey
                                .pleaseCheckConnectionAndTryAgain,
                            icon: LucideIcons.bookOpen,
                          ),

                      newPageErrorIndicatorBuilder: (context) =>
                          PaginationIndicators.newPageError(
                            onRetry: fetchNextPage,
                            title:
                                AppTranslationKey.failedToLoadMoreAbbreviations,
                            icon: LucideIcons.bookOpen,
                          ),

                      // =========================
                      // EMPTY STATE
                      // =========================
                      noItemsFoundIndicatorBuilder: (context) {
                        final query = controller.query;
                        final isFiltered = query.hasFilters;

                        return _EmptyAbbreviationsState(
                          isFiltered: isFiltered,
                          onClearFilters: controller.clearAllFilters,
                        );
                      },

                      // =========================
                      // END STATE
                      // =========================
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
      backgroundColor: cs.surface,
    );
  }
}

class _AbbreviationsHeaderCard extends StatelessWidget {
  final String searchQuery;
  final bool hasFilters;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;

  const _AbbreviationsHeaderCard({
    required this.searchQuery,
    required this.hasFilters,
    required this.onOpenFilters,
    required this.onClearFilters,
  });

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
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(LucideIcons.bookOpen, color: cs.primary, size: 28),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslationKey.medicalAbbreviations,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  hasSearch
                      ? 'Showing results for "$searchQuery"'
                      : 'Find medical short forms, meanings and clinical terms.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                if (hasFilters) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ActiveFilterChip(
                        label: hasSearch ? searchQuery : 'Filters active',
                        onClear: onClearFilters,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          AppSpacing.sm.gap,

          IconButton.filledTonal(
            onPressed: onOpenFilters,
            icon: const Icon(LucideIcons.slidersHorizontal),
            tooltip: 'Filter abbreviations',
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _ActiveFilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.search, size: 13, color: cs.primary),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(LucideIcons.x, size: 13, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _AbbreviationCardShell extends StatelessWidget {
  final Widget child;

  const _AbbreviationCardShell({required this.child});

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

class _EmptyAbbreviationsState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onClearFilters;

  const _EmptyAbbreviationsState({
    required this.isFiltered,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final title = isFiltered
        ? AppTranslationKey.noAbbreviationsMatchFilters
        : AppTranslationKey.noAbbreviationsFound;

    final subtitle = isFiltered
        ? AppTranslationKey.tryAdjustingSearchOrFilters
        : AppTranslationKey.abbreviationsWillAppearHere;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isFiltered ? LucideIcons.searchX : LucideIcons.bookOpen,
              color: cs.primary,
              size: 36,
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

          if (isFiltered) ...[
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

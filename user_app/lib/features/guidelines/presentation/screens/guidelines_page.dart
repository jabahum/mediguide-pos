import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/guidelines/data/models/guideline.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_controller.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_state.dart';
import 'package:user_app/features/guidelines/presentation/widgets/guideline_card.dart';

import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

part '../widgets/guidelines_page_guidelines_search_box.dart';
part '../widgets/guidelines_page_guidelines_search_box_state.dart';
part '../widgets/guidelines_page_quick_filters.dart';
part '../widgets/guidelines_page_quick_filter_chip.dart';
part '../widgets/guidelines_page_active_guideline_context.dart';
part '../widgets/guidelines_page_context_badge.dart';
part '../widgets/guidelines_page_guideline_card_shell.dart';

class GuidelinesPage extends ConsumerStatefulWidget {
  const GuidelinesPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<GuidelinesPage> createState() => _GuidelinesPageState();
}

class _GuidelinesPageState extends ConsumerState<GuidelinesPage> {
  late final Object? _routeArguments;

  @override
  void initState() {
    super.initState();

    _routeArguments = widget.arguments;
  }

  @override
  Widget build(BuildContext context) {
    final provider = guidelinesControllerProvider(_routeArguments);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

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
              state.effectivePageTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              _pageSubtitle(state),
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

          if (state.hasPermanentFilter)
            IconButton(
              tooltip: 'Show all guidelines',
              onPressed: controller.showAllGuidelines,
              icon: const Icon(LucideIcons.listRestart),
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
            // SEARCH + FILTERS
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
                    _GuidelinesSearchBox(
                      searchQuery: state.searchQuery,
                      onChanged: controller.setSearchQuery,
                      onSubmitted: controller.submitSearchQuery,
                    ),

                    AppSpacing.gapMd,

                    _QuickFilters(
                      hasPermanentFilter: state.hasPermanentFilter,
                      hasActiveFilters: state.hasActiveFilters,
                      showHighPriorityOnly: state.showHighPriorityOnly,
                      isEmergencyRoute: state.isEmergencyRoute,
                      targetPopulation: state.selectedTargetPopulation,
                      onShowAll: controller.showAllGuidelines,
                      onToggleHighPriority: controller.toggleHighPriorityOnly,
                      onEmergency: controller.openEmergencyGuidelines,
                      onTargetPopulation: controller.setTargetPopulation,
                    ),

                    if (state.hasPermanentFilter || state.hasActiveFilters) ...[
                      AppSpacing.gapMd,

                      _ActiveGuidelineContext(
                        title: state.effectivePageTitle,
                        hasPermanentFilter: state.hasPermanentFilter,
                        hasFilters: state.hasActiveFilters,
                        searchQuery: state.searchQuery,
                        showHighPriorityOnly: state.showHighPriorityOnly,
                        isEmergencyRoute: state.isEmergencyRoute,
                        targetPopulation: state.selectedTargetPopulation,
                        onClearFilters: controller.clearAllFilters,
                        onShowAll: controller.showAllGuidelines,
                      ),
                    ],

                    AppSpacing.gapLg,

                    Text(
                      state.hasActiveFilters
                          ? 'Matching guidelines'
                          : 'Published guidelines',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      state.hasActiveFilters
                          ? 'Showing guidance matching your current search and filters.'
                          : 'Browse currently available clinical guidance.',
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
            // PAGED LIST
            // =================================================================
            PagingListener<int, Guideline>(
              controller: controller.pagingController,
              builder: (context, pagingState, fetchNextPage) {
                return PagedSliverList<int, Guideline>.separated(
                  state: pagingState,
                  fetchNextPage: fetchNextPage,
                  separatorBuilder: (_, _) => AppSpacing.sm.gap,
                  builderDelegate: PagedChildBuilderDelegate<Guideline>(
                    itemBuilder: (context, item, index) {
                      return Padding(
                        padding: AppSpacing.hPaddingMd,
                        child: _GuidelineCardShell(
                          onTap: () {
                            _openGuideline(item);
                          },
                          child: IgnorePointer(
                            child: GuidelineCard(guideline: item, onTap: () {}),
                          ),
                        ),
                      );
                    },

                    // =========================================================
                    // FIRST PAGE LOADING
                    // =========================================================
                    firstPageProgressIndicatorBuilder: (_) {
                      return const AppLoadingView(
                        message: 'Loading guidelines...',
                      );
                    },

                    // =========================================================
                    // NEXT PAGE LOADING
                    // =========================================================
                    newPageProgressIndicatorBuilder: (_) {
                      return PaginationIndicators.newPageProgress();
                    },

                    // =========================================================
                    // FIRST PAGE ERROR
                    // =========================================================
                    firstPageErrorIndicatorBuilder: (_) {
                      return AppErrorView(
                        error: pagingState.error ?? 'Unable to load guidelines',
                        title: 'Failed to load guidelines',
                        message: 'Check your connection and try again.',
                        onRetry: fetchNextPage,
                      );
                    },

                    // =========================================================
                    // NEXT PAGE ERROR
                    // =========================================================
                    newPageErrorIndicatorBuilder: (_) {
                      return PaginationIndicators.newPageError(
                        onRetry: fetchNextPage,
                        title: 'Failed to load more guidelines',
                        icon: LucideIcons.stethoscope,
                      );
                    },

                    // =========================================================
                    // EMPTY
                    // =========================================================
                    noItemsFoundIndicatorBuilder: (_) {
                      return _buildEmptyState(
                        state: state,
                        controller: controller,
                      );
                    },

                    // =========================================================
                    // END
                    // =========================================================
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

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  String _pageSubtitle(GuidelinesState state) {
    if (state.isEmergencyRoute) {
      return 'Emergency clinical guidance';
    }

    if (state.isInCategoryMode) {
      return 'Guidelines in this clinical category';
    }

    if (state.isInTagMode) {
      return 'Guidelines linked to this topic';
    }

    if (state.isInIndexMode) {
      return 'Guidelines in this section';
    }

    return 'Published clinical guidance';
  }

  Widget _buildEmptyState({
    required GuidelinesState state,
    required GuidelinesController controller,
  }) {
    final title = _getEmptyTitle(state);

    final description = _getEmptySubtitle(state);

    if (state.hasActiveFilters) {
      return EmptyState.noResults(
        title: title,
        description: description,
        actionLabel: 'Clear filters',
        onAction: controller.clearAllFilters,
      );
    }

    if (state.hasPermanentFilter) {
      return EmptyState(
        icon: _getEmptyIcon(state),
        title: title,
        description: description,
        actionLabel: 'Show all guidelines',
        onAction: controller.showAllGuidelines,
      );
    }

    return EmptyState.noData(title: title, description: description);
  }

  void _openGuideline(Guideline guideline) {
    AppNavigator.push(AppRoutes.guideline(guideline.id), extra: guideline);
  }

  IconData _getEmptyIcon(GuidelinesState state) {
    if (state.isInCategoryMode) {
      return LucideIcons.folderOpen;
    }

    if (state.isInTagMode) {
      return LucideIcons.tags;
    }

    if (state.isInIndexMode) {
      return LucideIcons.bookOpenText;
    }

    return LucideIcons.stethoscope;
  }

  String _getEmptyTitle(GuidelinesState state) {
    if (state.hasActiveFilters) {
      return 'No matching guidelines';
    }

    if (state.isInCategoryMode) {
      return 'No guidelines in this category';
    }

    if (state.isInTagMode) {
      return 'No guidelines with this tag';
    }

    if (state.isInIndexMode) {
      return 'No guidelines in this section';
    }

    return 'No guidelines found';
  }

  String _getEmptySubtitle(GuidelinesState state) {
    if (state.hasActiveFilters) {
      return 'Try adjusting your search or filters.';
    }

    if (state.isInCategoryMode) {
      return 'This category does not have published guidelines yet.';
    }

    if (state.isInTagMode) {
      return 'No published guidelines are currently linked to this tag.';
    }

    if (state.isInIndexMode) {
      return 'No published guidelines are currently linked to this section.';
    }

    return 'Published clinical guidelines will appear here once available.';
  }
}

// ===========================================================================
// SEARCH
// ===========================================================================

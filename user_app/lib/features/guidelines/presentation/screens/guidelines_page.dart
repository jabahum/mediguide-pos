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

class _GuidelinesSearchBox extends StatefulWidget {
  const _GuidelinesSearchBox({
    required this.searchQuery,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String searchQuery;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_GuidelinesSearchBox> createState() => _GuidelinesSearchBoxState();
}

class _GuidelinesSearchBoxState extends State<_GuidelinesSearchBox> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _GuidelinesSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_textController.text == widget.searchQuery) {
      return;
    }

    _textController.value = TextEditingValue(
      text: widget.searchQuery,
      selection: TextSelection.collapsed(offset: widget.searchQuery.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _textController.clear();

    widget.onChanged('');

    widget.onSubmitted('');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = _textController.text.trim().isNotEmpty;

    return SearchBar(
      controller: _textController,
      hintText: 'Search guidelines, conditions, ICD codes…',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (hasSearch)
          IconButton(
            tooltip: 'Clear search',
            onPressed: _clearSearch,
            icon: const Icon(LucideIcons.x),
          ),
      ],
      onChanged: (value) {
        widget.onChanged(value);

        setState(() {});
      },
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
      side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}

// ===========================================================================
// QUICK FILTERS
// ===========================================================================

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({
    required this.hasPermanentFilter,
    required this.hasActiveFilters,
    required this.showHighPriorityOnly,
    required this.isEmergencyRoute,
    required this.targetPopulation,
    required this.onShowAll,
    required this.onToggleHighPriority,
    required this.onEmergency,
    required this.onTargetPopulation,
  });

  final bool hasPermanentFilter;
  final bool hasActiveFilters;
  final bool showHighPriorityOnly;
  final bool isEmergencyRoute;
  final String targetPopulation;

  final VoidCallback onShowAll;
  final VoidCallback onToggleHighPriority;
  final VoidCallback onEmergency;
  final ValueChanged<String> onTargetPopulation;

  @override
  Widget build(BuildContext context) {
    final normalizedPopulation = targetPopulation.toLowerCase();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: LucideIcons.library,
            selected: !hasPermanentFilter && !hasActiveFilters,
            onTap: onShowAll,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'High Priority',
            icon: LucideIcons.triangleAlert,
            selected: showHighPriorityOnly,
            onTap: onToggleHighPriority,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Emergency',
            icon: LucideIcons.siren,
            selected: isEmergencyRoute,
            onTap: onEmergency,
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Children',
            icon: LucideIcons.baby,
            selected: normalizedPopulation.contains('children'),
            onTap: () {
              onTargetPopulation(
                normalizedPopulation.contains('children') ? '' : 'Children',
              );
            },
          ),

          AppSpacing.hGapSm,

          _QuickFilterChip(
            label: 'Adults',
            icon: LucideIcons.user,
            selected: normalizedPopulation.contains('adult'),
            onTap: () {
              onTargetPopulation(
                normalizedPopulation.contains('adult') ? '' : 'Adults',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        onTap();
      },
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? colors.onPrimary : colors.primary,
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? colors.onPrimary : colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceContainerLowest,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

// ===========================================================================
// ACTIVE CONTEXT
// ===========================================================================

class _ActiveGuidelineContext extends StatelessWidget {
  const _ActiveGuidelineContext({
    required this.title,
    required this.hasPermanentFilter,
    required this.hasFilters,
    required this.searchQuery,
    required this.showHighPriorityOnly,
    required this.isEmergencyRoute,
    required this.targetPopulation,
    required this.onClearFilters,
    required this.onShowAll,
  });

  final String title;
  final bool hasPermanentFilter;
  final bool hasFilters;

  final String searchQuery;
  final bool showHighPriorityOnly;
  final bool isEmergencyRoute;
  final String targetPopulation;

  final VoidCallback onClearFilters;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSpecificFilters =
        searchQuery.trim().isNotEmpty ||
        showHighPriorityOnly ||
        isEmergencyRoute ||
        targetPopulation.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPermanentFilter
                    ? LucideIcons.folderOpen
                    : LucideIcons.listFilter,
                size: 17,
                color: colors.onSecondaryContainer,
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  hasPermanentFilter ? title : 'Filters applied',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (hasFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear'),
                ),

              if (hasPermanentFilter)
                TextButton(onPressed: onShowAll, child: const Text('Show all')),
            ],
          ),

          if (hasSpecificFilters)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (searchQuery.trim().isNotEmpty)
                  _ContextBadge(
                    icon: LucideIcons.search,
                    label: '"${searchQuery.trim()}"',
                  ),

                if (showHighPriorityOnly)
                  const _ContextBadge(
                    icon: LucideIcons.triangleAlert,
                    label: 'High Priority',
                  ),

                if (isEmergencyRoute)
                  const _ContextBadge(
                    icon: LucideIcons.siren,
                    label: 'Emergency',
                  ),

                if (targetPopulation.trim().isNotEmpty)
                  _ContextBadge(
                    icon: LucideIcons.users,
                    label: targetPopulation,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContextBadge extends StatelessWidget {
  const _ContextBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSecondaryContainer),

          const SizedBox(width: 4),

          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CLICKABLE CARD SHELL
// ===========================================================================

class _GuidelineCardShell extends StatelessWidget {
  const _GuidelineCardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

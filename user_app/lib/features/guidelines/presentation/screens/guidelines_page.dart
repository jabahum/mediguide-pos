import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
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

    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          state.effectivePageTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.hPaddingSm + AppSpacing.vPaddingSm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GuidelinesHeader(
                      title: state.effectivePageTitle,
                      hasPermanentFilter: state.hasPermanentFilter,
                    ),

                    AppSpacing.md.gap,

                    _GuidelinesSearchBox(
                      searchQuery: state.searchQuery,
                      onChanged: controller.setSearchQuery,
                      onSubmitted: controller.submitSearchQuery,
                    ),

                    AppSpacing.md.gap,

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

                    if (state.hasPermanentFilter || state.hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _ActiveGuidelineContext(
                          title: state.effectivePageTitle,
                          hasPermanentFilter: state.hasPermanentFilter,
                          hasFilters: state.hasActiveFilters,
                          onClearFilters: controller.clearAllFilters,
                          onShowAll: controller.showAllGuidelines,
                        ),
                      ),

                    AppSpacing.md.gap,
                  ],
                ),
              ),
            ),

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
                        padding: AppSpacing.hPaddingSm,
                        child: GuidelineCard(
                          guideline: item,
                          onTap: () {
                            _openGuideline(item);
                          },
                        ),
                      );
                    },

                    // =========================
                    // FIRST PAGE LOADING
                    // =========================
                    firstPageProgressIndicatorBuilder: (_) {
                      return const AppLoadingView(
                        message: 'Loading guidelines...',
                      );
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
                        error: pagingState.error ?? 'Unable to load guidelines',
                        title: 'Failed to load guidelines',
                        message: 'Check your connection and try again.',
                        onRetry: fetchNextPage,
                      );
                    },

                    // =========================
                    // NEXT PAGE ERROR
                    // =========================
                    newPageErrorIndicatorBuilder: (_) {
                      return PaginationIndicators.newPageError(
                        onRetry: fetchNextPage,
                        title: 'Failed to load more guidelines',
                        icon: LucideIcons.stethoscope,
                      );
                    },

                    // =========================
                    // EMPTY
                    // =========================
                    noItemsFoundIndicatorBuilder: (_) {
                      return _buildEmptyState(
                        state: state,
                        controller: controller,
                      );
                    },

                    // =========================
                    // END
                    // =========================
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

class _GuidelinesHeader extends StatelessWidget {
  const _GuidelinesHeader({
    required this.title,
    required this.hasPermanentFilter,
  });

  final String title;
  final bool hasPermanentFilter;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
              hasPermanentFilter ? LucideIcons.folderOpen : LucideIcons.library,
              color: cs.primary,
            ),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  hasPermanentFilter
                      ? 'Browse guidelines in this section or search within results.'
                      : 'Search and browse all published clinical guidelines.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    widget.onSubmitted('');
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final hasSearch = widget.searchQuery.trim().isNotEmpty;

    return TextField(
      controller: _textController,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: 'Search guidelines, conditions, ICD codes...',
        prefixIcon: const Icon(LucideIcons.search),
        suffixIcon: hasSearch
            ? IconButton(
                onPressed: _clearSearch,
                icon: const Icon(LucideIcons.x),
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.primary),
        ),
      ),
    );
  }
}

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: LucideIcons.library,
            selected: !hasPermanentFilter && !hasActiveFilters,
            onTap: onShowAll,
          ),

          AppSpacing.sm.gap,

          _QuickFilterChip(
            label: 'High Priority',
            icon: LucideIcons.triangleAlert,
            selected: showHighPriorityOnly,
            onTap: onToggleHighPriority,
          ),

          AppSpacing.sm.gap,

          _QuickFilterChip(
            label: 'Emergency',
            icon: LucideIcons.siren,
            selected: isEmergencyRoute,
            onTap: onEmergency,
          ),

          AppSpacing.sm.gap,

          _QuickFilterChip(
            label: 'Children',
            icon: LucideIcons.baby,
            selected: normalizedPopulation.contains('children'),
            onTap: () {
              onTargetPopulation('Children');
            },
          ),

          AppSpacing.sm.gap,

          _QuickFilterChip(
            label: 'Adults',
            icon: LucideIcons.user,
            selected: normalizedPopulation.contains('adult'),
            onTap: () {
              onTargetPopulation('Adults');
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
    return FilterChip(
      selected: selected,
      onSelected: (_) {
        onTap();
      },
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _ActiveGuidelineContext extends StatelessWidget {
  const _ActiveGuidelineContext({
    required this.title,
    required this.hasPermanentFilter,
    required this.hasFilters,
    required this.onClearFilters,
    required this.onShowAll,
  });

  final String title;
  final bool hasPermanentFilter;
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            hasPermanentFilter ? LucideIcons.folderOpen : LucideIcons.filter,
            size: 18,
            color: cs.primary,
          ),

          AppSpacing.sm.gap,

          Expanded(
            child: Text(
              hasPermanentFilter ? 'Showing: $title' : 'Filters applied',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (hasFilters)
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),

          if (hasPermanentFilter)
            TextButton(onPressed: onShowAll, child: const Text('Show all')),
        ],
      ),
    );
  }
}

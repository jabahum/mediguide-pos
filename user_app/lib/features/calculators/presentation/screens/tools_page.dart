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

import 'package:user_app/features/calculators/presentation/controllers/tools_controller.dart';
import 'package:user_app/features/calculators/presentation/widgets/calculator_card.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

class ToolsPage extends ConsumerStatefulWidget {
  const ToolsPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends ConsumerState<ToolsPage> {
  late final Object? _routeArguments;

  static const List<_ToolTypeFilter> _toolFilters = [
    _ToolTypeFilter(label: 'All', icon: LucideIcons.layoutGrid, tabIndex: 0),
    _ToolTypeFilter(
      label: 'Calculators',
      icon: LucideIcons.calculator,
      tabIndex: 1,
    ),
    _ToolTypeFilter(
      label: 'Decision Tools',
      icon: LucideIcons.gitBranch,
      tabIndex: 2,
    ),
    _ToolTypeFilter(
      label: 'Checklists',
      icon: LucideIcons.listChecks,
      tabIndex: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _routeArguments = widget.arguments;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(toolsControllerProvider(_routeArguments));

    final controller = ref.read(
      toolsControllerProvider(_routeArguments).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Text(
          'Tools'.tr,
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
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshData();
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
                child: _ToolsHeaderCard(
                  onOpenFilters: () {
                    controller.showFilterModal(context);
                  },
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DestinationGroup(
                      title: 'References',
                      items: [
                        _Destination(
                          icon: LucideIcons.pill,
                          title: 'Drug Index',
                          description: 'Reviewed medicine references',
                          route: AppRoutes.drugIndex,
                        ),
                        _Destination(
                          icon: LucideIcons.wholeWord,
                          title: 'Abbreviations',
                          description: 'Medical abbreviations and meanings',
                          route: AppRoutes.abbreviations,
                        ),
                        _Destination(
                          icon: LucideIcons.workflow,
                          title: 'Clinical algorithms',
                          description: 'Reviewed guideline algorithms',
                          route: AppRoutes.publicGuidelines,
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,
                    _DestinationGroup(
                      title: 'Other',
                      items: [
                        _Destination(
                          icon: LucideIcons.hospital,
                          title: 'Health Facilities',
                          description: 'Find facilities and services',
                          route: AppRoutes.healthFacilities,
                        ),
                        _Destination(
                          icon: LucideIcons.landmark,
                          title: 'Ministry Directory',
                          description: 'Official contacts and departments',
                          route: AppRoutes.ministryDirectory,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _ToolTypeFilterBar(
                  filters: _toolFilters,
                  selectedIndex: state.selectedTabIndex,
                  onChanged: controller.onTabChanged,
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
              sliver: PagingListener<int, Calculator>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, Calculator>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (context, index) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Calculator>(
                      itemBuilder: (context, calculator, index) {
                        return _ToolCardShell(
                          child: CalculatorTile(
                            calculator: calculator,
                            onTap: () {
                              AppNavigator.push(
                                AppRoutes.calculator(calculator.id),
                                extra: calculator,
                              );
                            },
                            showDivider: false,
                          ),
                        );
                      },

                      // =====================
                      // FIRST PAGE LOADING
                      // =====================
                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading clinical tools...',
                        );
                      },

                      // =====================
                      // NEXT PAGE LOADING
                      // =====================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // =====================
                      // FIRST PAGE ERROR
                      // =====================
                      firstPageErrorIndicatorBuilder: (_) {
                        return AppErrorView(
                          error: pagingState.error ?? 'Unable to load tools',
                          title: 'Failed to load tools',
                          message:
                              'Please check your connection and try again.',
                          onRetry: fetchNextPage,
                        );
                      },

                      // =====================
                      // NEXT PAGE ERROR
                      // =====================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'Failed to load more tools',
                          icon: LucideIcons.calculator,
                        );
                      },

                      // =====================
                      // EMPTY
                      // =====================
                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No tools match filters',
                            description:
                                'Try adjusting your search or filters.',
                            actionLabel: 'Clear Filters',
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: 'No tools found',
                          description: 'Tools will appear here when available.',
                        );
                      },

                      // =====================
                      // END
                      // =====================
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

class _Destination {
  const _Destination({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String description;
  final String route;
}

class _DestinationGroup extends StatelessWidget {
  const _DestinationGroup({required this.title, required this.items});
  final String title;
  final List<_Destination> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      AppSpacing.gapSm,
      Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              ListTile(
                minTileHeight: 60,
                leading: ClinicalIconTile(icon: items[index].icon),
                title: Text(items[index].title),
                subtitle: Text(items[index].description),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => AppNavigator.push(items[index].route),
              ),
              if (index < items.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    ],
  );
}

class _ToolsHeaderCard extends StatelessWidget {
  const _ToolsHeaderCard({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

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
            child: Icon(LucideIcons.calculator, color: cs.primary, size: 28),
          ),
          AppSpacing.md.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Tools',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use calculators, decision tools and checklists to support clinical care.',
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
            tooltip: 'Filter tools',
          ),
        ],
      ),
    );
  }
}

class _ToolTypeFilterBar extends StatelessWidget {
  const _ToolTypeFilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<_ToolTypeFilter> filters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => AppSpacing.sm.gap,
        itemBuilder: (context, index) {
          final filter = filters[index];

          final selected = selectedIndex == filter.tabIndex;

          return _ToolTypeChip(
            label: filter.label,
            icon: filter.icon,
            selected: selected,
            onTap: () {
              if (selected) {
                return;
              }

              onChanged(filter.tabIndex);
            },
          );
        },
      ),
    );
  }
}

class _ToolTypeChip extends StatelessWidget {
  const _ToolTypeChip({
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
    final cs = context.theme.colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16, color: selected ? cs.onPrimary : cs.primary),
      label: Text(label),
      labelStyle: context.textTheme.labelMedium?.copyWith(
        color: selected ? cs.onPrimary : cs.onSurface,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerLowest,
      side: BorderSide(
        color: selected
            ? cs.primary
            : cs.outlineVariant.withValues(alpha: 0.45),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _ToolCardShell extends StatelessWidget {
  const _ToolCardShell({required this.child});

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

class _ToolTypeFilter {
  const _ToolTypeFilter({
    required this.label,
    required this.icon,
    required this.tabIndex,
  });

  final String label;
  final IconData icon;
  final int tabIndex;
}

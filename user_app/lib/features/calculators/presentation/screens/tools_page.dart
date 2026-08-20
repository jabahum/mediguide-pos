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
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';
import 'package:user_app/shared/widgets/filter_button.dart';
import 'package:user_app/shared/widgets/pagination_indicators.dart';

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

  bool get _isHub {
    final arguments = _routeArguments;

    return arguments is! Map || arguments['initialTab'] is! int;
  }

  @override
  Widget build(BuildContext context) {
    if (_isHub) {
      return _buildHub(context);
    }

    return _buildCatalogue(context);
  }

  // ========================================================================
  // HUB
  // ========================================================================

  Widget _buildHub(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tools'.tr,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Clinical tools and references',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              AppNavigator.push(AppRoutes.search);
            },
            icon: const Icon(LucideIcons.search),
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxxl,
        ),
        children: const [
          _DestinationGroup(
            title: 'Clinical tools',
            description:
                'Interactive calculators and clinical decision support.',
            items: [
              _Destination(
                icon: LucideIcons.calculator,
                title: 'Calculators',
                description: 'Scores, doses, conversions and assessments',
                route: AppRoutes.tools,
                arguments: {'initialTab': 1},
              ),
              _Destination(
                icon: LucideIcons.gitBranch,
                title: 'Decision Tools',
                description: 'Algorithms and structured decision support',
                route: AppRoutes.tools,
                arguments: {'initialTab': 2},
              ),
              _Destination(
                icon: LucideIcons.listChecks,
                title: 'Checklists',
                description: 'Clinical and procedural checklists',
                route: AppRoutes.tools,
                arguments: {'initialTab': 3},
              ),
            ],
          ),

          AppSpacing.gapXl,

          _DestinationGroup(
            title: 'References',
            description: 'Quick access to commonly used clinical references.',
            items: [
              _Destination(
                icon: LucideIcons.pill,
                title: 'Drug Index',
                description: 'Reviewed medicine information',
                route: AppRoutes.drugIndex,
              ),
              _Destination(
                icon: LucideIcons.wholeWord,
                title: 'Abbreviations',
                description: 'Medical terms and abbreviations',
                route: AppRoutes.abbreviations,
              ),
              _Destination(
                icon: LucideIcons.workflow,
                title: 'Clinical algorithms',
                description: 'Reviewed algorithms from published guidelines',
                route: AppRoutes.publicGuidelines,
              ),
            ],
          ),

          AppSpacing.gapXl,

          _DestinationGroup(
            title: 'Directories',
            description: 'Find health services and official contacts.',
            items: [
              _Destination(
                icon: LucideIcons.hospital,
                title: 'Health Facilities',
                description: 'Find facilities and available services',
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
    );
  }

  // ========================================================================
  // CATALOGUE
  // ========================================================================

  Widget _buildCatalogue(BuildContext context) {
    final provider = toolsControllerProvider(_routeArguments);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          _catalogueTitle(state.selectedTabIndex),
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search tools',
            onPressed: () {
              AppNavigator.push(AppRoutes.search);
            },
            icon: const Icon(LucideIcons.search),
          ),

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
            // ---------------------------------------------------------------
            // Tool filters
            // ---------------------------------------------------------------
            SliverPersistentHeader(
              pinned: true,
              delegate: _ToolsFilterHeaderDelegate(
                child: Material(
                  color: context.theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _ToolTypeFilterBar(
                      filters: _toolFilters,
                      selectedIndex: state.selectedTabIndex,
                      onChanged: controller.onTabChanged,
                    ),
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Active filters
            // ---------------------------------------------------------------
            if (state.hasActiveFilters)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ActiveFilterBanner(
                    onClear: controller.clearAllFilters,
                  ),
                ),
              ),

            // ---------------------------------------------------------------
            // Paginated tools
            // ---------------------------------------------------------------
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              sliver: PagingListener<int, Calculator>(
                controller: controller.pagingController,
                builder: (context, pagingState, fetchNextPage) {
                  return PagedSliverList<int, Calculator>.separated(
                    state: pagingState,
                    fetchNextPage: fetchNextPage,
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Calculator>(
                      itemBuilder: (context, calculator, index) {
                        return _ToolCardShell(
                          onTap: () {
                            AppNavigator.push(
                              AppRoutes.calculator(calculator.id),
                              extra: calculator,
                            );
                          },
                          child: IgnorePointer(
                            child: CalculatorTile(
                              calculator: calculator,
                              onTap: () {},
                              showDivider: false,
                            ),
                          ),
                        );
                      },

                      firstPageProgressIndicatorBuilder: (_) {
                        return const AppLoadingView(
                          message: 'Loading clinical tools...',
                        );
                      },

                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      firstPageErrorIndicatorBuilder: (_) {
                        return AppErrorView(
                          error: pagingState.error ?? 'Unable to load tools',
                          title: 'Failed to load tools',
                          message:
                              'Please check your connection and try again.',
                          onRetry: fetchNextPage,
                        );
                      },

                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title: 'Failed to load more tools',
                          icon: LucideIcons.calculator,
                        );
                      },

                      noItemsFoundIndicatorBuilder: (_) {
                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No tools match filters',
                            description:
                                'Try adjusting or clearing the active filters.',
                            actionLabel: 'Clear Filters',
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title:
                              'No ${_catalogueTitle(state.selectedTabIndex).toLowerCase()} found',
                          description:
                              'Clinical tools will appear here when available.',
                        );
                      },

                      noMoreItemsIndicatorBuilder: (_) {
                        return PaginationIndicators.noMoreItems();
                      },
                    ),
                  );
                },
              ),
            ),

            // ---------------------------------------------------------------
            // Related references
            // ---------------------------------------------------------------
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: const SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.gapLg,

                    _DestinationGroup(
                      title: 'Related references',
                      description:
                          'Additional clinical information you may need.',
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

                    AppSpacing.gapLg,

                    _DestinationGroup(
                      title: 'Directories',
                      description: 'Health services and official contacts.',
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
          ],
        ),
      ),
    );
  }

  String _catalogueTitle(int tabIndex) => switch (tabIndex) {
    1 => 'Calculators',
    2 => 'Decision Tools',
    3 => 'Checklists',
    _ => 'Clinical Tools',
  };
}

// ===========================================================================
// DESTINATIONS
// ===========================================================================

class _Destination {
  const _Destination({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    this.arguments,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Object? arguments;
}

class _DestinationGroup extends StatelessWidget {
  const _DestinationGroup({
    required this.title,
    required this.items,
    this.description,
  });

  final String title;
  final String? description;
  final List<_Destination> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              if (description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 2),

                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        AppSpacing.gapSm,

        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _DestinationTile(destination: items[index]),

                if (index < items.length - 1)
                  const Divider(height: 1, indent: 68),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${destination.title}. ${destination.description}',
      child: InkWell(
        onTap: () {
          AppNavigator.push(destination.route, extra: destination.arguments);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ClinicalIconTile(icon: destination.icon),

              AppSpacing.hGapMd,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      destination.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.hGapSm,

              const Icon(LucideIcons.chevronRight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// FILTERS
// ===========================================================================

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
    final colors = context.theme.colorScheme;

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
      labelStyle: context.textTheme.labelMedium?.copyWith(
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

// ===========================================================================
// TOOL CARD
// ===========================================================================

class _ToolCardShell extends StatelessWidget {
  const _ToolCardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
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
    );
  }
}

// ===========================================================================
// ACTIVE FILTER BANNER
// ===========================================================================

class _ActiveFilterBanner extends StatelessWidget {
  const _ActiveFilterBanner({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.listFilter,
            size: 18,
            color: colors.onSecondaryContainer,
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              'Filters are applied',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

// ===========================================================================
// PINNED FILTER HEADER
// ===========================================================================

class _ToolsFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ToolsFilterHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ToolsFilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

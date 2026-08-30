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
import 'package:user_app/shared/widgets/pagination_indicators.dart';

part '../widgets/tools_page_destination.dart';
part '../widgets/tools_page_destination_group.dart';
part '../widgets/tools_page_destination_tile.dart';
part '../widgets/tools_page_catalogue_header_card.dart';
part '../widgets/tools_page_tool_type_filter_bar.dart';
part '../widgets/tools_page_tool_type_chip.dart';
part '../widgets/tools_page_tool_type_filter.dart';
part '../widgets/tools_page_tool_card_shell.dart';
part '../widgets/tools_page_active_filter_banner.dart';
part '../widgets/tools_page_tools_filter_header_delegate.dart';

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

  // ==========================================================================
  // HUB
  // ==========================================================================

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
          // ------------------------------------------------------------------
          // CLINICAL TOOLS
          // ------------------------------------------------------------------
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

          // ------------------------------------------------------------------
          // REFERENCES
          // ------------------------------------------------------------------
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

          // ------------------------------------------------------------------
          // DIRECTORIES
          // ------------------------------------------------------------------
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

  // ==========================================================================
  // CATALOGUE
  // ==========================================================================

  Widget _buildCatalogue(BuildContext context) {
    final provider = toolsControllerProvider(_routeArguments);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

    final colors = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _catalogueTitle(state.selectedTabIndex),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _catalogueSubtitle(state.selectedTabIndex),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search tools',
            onPressed: () {
              AppNavigator.push(AppRoutes.search);
            },
            icon: const Icon(LucideIcons.search),
          ),

          // FilterButton(
          //   hasActiveFilters: state.hasActiveFilters,
          //   onPressed: () {
          //     controller.showFilterModal(context);
          //   },
          //   onReset: state.hasActiveFilters ? controller.clearAllFilters : null,
          // ),
          AppSpacing.xs.gap,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // ==============================================================
            // TOOL TYPE FILTERS
            // ==============================================================
            SliverPersistentHeader(
              pinned: true,
              delegate: _ToolsFilterHeaderDelegate(
                child: Material(
                  color: colors.surface,
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

            // ==============================================================
            // ACTIVE FILTERS
            // ==============================================================
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

            // ==============================================================
            // CURRENT CATALOGUE CONTEXT
            // ==============================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _CatalogueHeaderCard(
                  icon: _catalogueIcon(state.selectedTabIndex),
                  title: _catalogueTitle(state.selectedTabIndex),
                  description: _catalogueDescription(state.selectedTabIndex),
                ),
              ),
            ),

            // ==============================================================
            // PAGINATED TOOLS
            // ==============================================================
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
                    separatorBuilder: (_, _) => AppSpacing.sm.gap,
                    builderDelegate: PagedChildBuilderDelegate<Calculator>(
                      // ====================================================
                      // ITEM
                      // ====================================================
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

                      // ====================================================
                      // FIRST PAGE LOADING
                      // ====================================================
                      firstPageProgressIndicatorBuilder: (_) {
                        return AppLoadingView(
                          message: _loadingMessage(state.selectedTabIndex),
                        );
                      },

                      // ====================================================
                      // NEXT PAGE LOADING
                      // ====================================================
                      newPageProgressIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageProgress();
                      },

                      // ====================================================
                      // FIRST PAGE ERROR
                      // ====================================================
                      firstPageErrorIndicatorBuilder: (_) {
                        return AppErrorView(
                          error:
                              pagingState.error ??
                              'Unable to load '
                                  '${_catalogueTitle(state.selectedTabIndex).toLowerCase()}',
                          title:
                              'Failed to load '
                              '${_catalogueTitle(state.selectedTabIndex).toLowerCase()}',
                          message:
                              'Please check your connection and try again.',
                          onRetry: fetchNextPage,
                        );
                      },

                      // ====================================================
                      // NEXT PAGE ERROR
                      // ====================================================
                      newPageErrorIndicatorBuilder: (_) {
                        return PaginationIndicators.newPageError(
                          onRetry: fetchNextPage,
                          title:
                              'Failed to load more '
                              '${_catalogueTitle(state.selectedTabIndex).toLowerCase()}',
                          icon: _catalogueIcon(state.selectedTabIndex),
                        );
                      },

                      // ====================================================
                      // EMPTY
                      // ====================================================
                      noItemsFoundIndicatorBuilder: (_) {
                        final title = _catalogueTitle(state.selectedTabIndex);

                        if (state.hasActiveFilters) {
                          return EmptyState.noResults(
                            title: 'No $title match filters',
                            description:
                                'Try adjusting or clearing the active filters.',
                            actionLabel: 'Clear Filters',
                            onAction: controller.clearAllFilters,
                          );
                        }

                        return EmptyState.noData(
                          title: 'No ${title.toLowerCase()} found',
                          description: _emptyDescription(
                            state.selectedTabIndex,
                          ),
                        );
                      },

                      // ====================================================
                      // END
                      // ====================================================
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

            //
            // IMPORTANT:
            //
            // No Related References section here.
            // No Directories section here.
            //
            // Those remain only on the main Tools hub.
            //
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // CATALOGUE METADATA
  // ==========================================================================

  String _catalogueTitle(int tabIndex) => switch (tabIndex) {
    1 => 'Calculators',
    2 => 'Decision Tools',
    3 => 'Checklists',
    _ => 'Clinical Tools',
  };

  String _catalogueSubtitle(int tabIndex) => switch (tabIndex) {
    1 => 'Clinical scores, doses and calculations',
    2 => 'Structured clinical decision support',
    3 => 'Clinical and procedural checklists',
    _ => 'Clinical calculators and decision support',
  };

  String _catalogueDescription(int tabIndex) => switch (tabIndex) {
    1 =>
      'Use reviewed calculators for clinical scores, '
          'dose calculations, conversions and assessments.',
    2 =>
      'Use structured tools that support clinical '
          'assessment and decision-making.',
    3 =>
      'Follow structured clinical and procedural '
          'checklists at the point of care.',
    _ =>
      'Browse available clinical calculators, '
          'decision tools and checklists.',
  };

  String _loadingMessage(int tabIndex) => switch (tabIndex) {
    1 => 'Loading calculators...',
    2 => 'Loading decision tools...',
    3 => 'Loading checklists...',
    _ => 'Loading clinical tools...',
  };

  String _emptyDescription(int tabIndex) => switch (tabIndex) {
    1 => 'Clinical calculators will appear here when available.',
    2 => 'Decision support tools will appear here when available.',
    3 => 'Clinical checklists will appear here when available.',
    _ => 'Clinical tools will appear here when available.',
  };

  IconData _catalogueIcon(int tabIndex) => switch (tabIndex) {
    1 => LucideIcons.calculator,
    2 => LucideIcons.gitBranch,
    3 => LucideIcons.listChecks,
    _ => LucideIcons.layoutGrid,
  };
}

// ============================================================================
// DESTINATION MODEL
// ============================================================================

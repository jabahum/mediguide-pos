import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/guidelines/data/models/guideline_index.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_indexer_controller.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_indexer_state.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_tree_filter.dart';
import 'package:user_app/features/guidelines/presentation/widgets/guideline_tree_tile.dart';

part '../widgets/guidelines_indexer_page_tree_section_header.dart';
part '../widgets/guidelines_indexer_page_search_field.dart';
part '../widgets/guidelines_indexer_page_search_field_state.dart';
part '../widgets/guidelines_indexer_page_quick_filter_chips.dart';
part '../widgets/guidelines_indexer_page_browse_chip.dart';
part '../widgets/guidelines_indexer_page_active_filters_summary.dart';
part '../widgets/guidelines_indexer_page_guideline_tree_container.dart';

class GuidelinesIndexerPage extends ConsumerStatefulWidget {
  const GuidelinesIndexerPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<GuidelinesIndexerPage> createState() =>
      _GuidelinesIndexerPageState();
}

class _GuidelinesIndexerPageState extends ConsumerState<GuidelinesIndexerPage> {
  String? _channel;

  @override
  void initState() {
    super.initState();

    final arguments = widget.arguments;

    _channel = arguments is Map ? arguments['channel']?.toString() : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref
          .read(guidelinesIndexerControllerProvider.notifier)
          .initialize(channel: _channel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guidelinesIndexerControllerProvider);

    final controller = ref.read(guidelinesIndexerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.channelTitle.isNotEmpty ? state.channelTitle : 'Guidelines',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (!state.isLoading)
              Text(
                state.totalSections > 0
                    ? '${state.totalSections} sections'
                    : 'Browse clinical guidance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (state.hasActiveFilters)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: controller.resetFilters,
              icon: const Icon(LucideIcons.x),
            ),
          AppSpacing.hGapXs,
        ],
      ),
      body: _buildBody(context: context, state: state, controller: controller),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required GuidelinesIndexerState state,
    required GuidelinesIndexerController controller,
  }) {
    // =======================================================================
    // INITIAL LOADING
    // =======================================================================

    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading guideline sections...');
    }

    // =======================================================================
    // LOAD ERROR
    // =======================================================================

    if (state.hasLoadError) {
      return AppErrorView(
        error: state.errorMessage ?? 'Unable to load guideline sections',
        title: 'Failed to load guidelines',
        message: 'Please check your connection and try again.',
        onRetry: controller.refreshData,
      );
    }

    final tree = state.visibleTree;

    // =======================================================================
    // CONTENT
    // =======================================================================

    return RefreshIndicator(
      onRefresh: controller.refreshData,
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
                  _SearchField(
                    search: state.filters.search,
                    onChanged: controller.updateSearch,
                    onClear: controller.clearSearch,
                  ),

                  AppSpacing.gapMd,

                  _QuickFilterChips(
                    filters: state.filters,
                    onReset: controller.resetFilters,
                    onLevelChanged: controller.setLevelFilter,
                    onToggleParents: controller.toggleParentsOnly,
                  ),

                  if (state.hasActiveFilters) ...[
                    AppSpacing.gapMd,
                    _ActiveFiltersSummary(
                      filters: state.filters,
                      resultCount: tree.childrenAsList.length,
                      onClearSearch: controller.clearSearch,
                      onClearLevel: () {
                        controller.setLevelFilter(null);
                      },
                      onToggleParents: controller.toggleParentsOnly,
                      onReset: controller.resetFilters,
                    ),
                  ],

                  AppSpacing.gapLg,

                  _TreeSectionHeader(
                    state: state,
                    visibleCount: tree.childrenAsList.length,
                  ),

                  AppSpacing.gapSm,
                ],
              ),
            ),
          ),

          // =================================================================
          // EMPTY TREE
          // =================================================================
          if (tree.childrenAsList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: state.hasActiveFilters
                  ? EmptyState.noResults(
                      title: 'No guideline sections found',
                      description:
                          'Try another search term or adjust the current filters.',
                      actionLabel: 'Reset filters',
                      onAction: controller.resetFilters,
                    )
                  : EmptyState.noData(
                      title: 'No guideline sections',
                      description:
                          'Published guideline sections will appear here when available.',
                      actionLabel: 'Refresh',
                      onAction: controller.refreshData,
                    ),
            )
          // =================================================================
          // TREE
          // =================================================================
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              sliver: SliverToBoxAdapter(
                child: _GuidelineTreeContainer(
                  child:
                      TreeView.simpleTyped<
                        GuidelineIndex,
                        TreeNode<GuidelineIndex>
                      >(
                        tree: tree,
                        showRootNode: false,
                        expansionBehavior: ExpansionBehavior.none,
                        indentation: const Indentation(
                          style: IndentStyle.squareJoint,
                        ),
                        onTreeReady: (treeController) {
                          controller.initializeTreeController(treeController);
                        },
                        onItemTap: (node) {
                          final data = node.data;

                          if (data == null) {
                            return;
                          }

                          controller.openIndex(data);
                        },
                        builder: (context, node) {
                          return GuidelineTreeTile(node: node);
                        },
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TREE SECTION HEADER
// ===========================================================================

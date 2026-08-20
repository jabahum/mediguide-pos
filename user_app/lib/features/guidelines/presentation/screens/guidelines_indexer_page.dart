import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/guidelines/data/models/guideline_index.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_indexer_controller.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_indexer_state.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_tree_filter.dart';
import 'package:user_app/features/guidelines/presentation/widgets/guideline_tree_tile.dart';

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

class _TreeSectionHeader extends StatelessWidget {
  const _TreeSectionHeader({required this.state, required this.visibleCount});

  final GuidelinesIndexerState state;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.hasActiveFilters
                    ? 'Matching sections'
                    : 'Browse sections',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                state.hasActiveFilters
                    ? 'Showing sections matching your current filters'
                    : state.pageSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SEARCH
// ===========================================================================

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.search,
    required this.onChanged,
    required this.onClear,
  });

  final String search;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.search);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.search == _textController.text) {
      return;
    }

    _textController.value = TextEditingValue(
      text: widget.search,
      selection: TextSelection.collapsed(offset: widget.search.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _textController.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = _textController.text.trim().isNotEmpty;

    return SearchBar(
      controller: _textController,
      hintText: 'Search guideline sections',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (hasSearch)
          IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _clearSearch();
              setState(() {});
            },
            icon: const Icon(LucideIcons.x),
          ),
      ],
      onChanged: (value) {
        widget.onChanged(value);

        //
        // Rebuild so the clear icon appears/disappears
        // immediately while typing.
        //
        setState(() {});
      },
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

class _QuickFilterChips extends StatelessWidget {
  const _QuickFilterChips({
    required this.filters,
    required this.onReset,
    required this.onLevelChanged,
    required this.onToggleParents,
  });

  final GuidelinesTreeFilter filters;

  final VoidCallback onReset;
  final ValueChanged<int?> onLevelChanged;
  final VoidCallback onToggleParents;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _BrowseChip(
            label: 'All',
            icon: LucideIcons.layers,
            selected: !filters.hasFilters,
            onTap: onReset,
          ),

          AppSpacing.hGapSm,

          _BrowseChip(
            label: 'Top level',
            icon: LucideIcons.folder,
            selected: filters.level == 1,
            onTap: () {
              onLevelChanged(filters.level == 1 ? null : 1);
            },
          ),

          AppSpacing.hGapSm,

          _BrowseChip(
            label: 'Subsections',
            icon: LucideIcons.folderOpen,
            selected: filters.level == 2,
            onTap: () {
              onLevelChanged(filters.level == 2 ? null : 2);
            },
          ),

          AppSpacing.hGapSm,

          _BrowseChip(
            label: 'Parents only',
            icon: LucideIcons.listTree,
            selected: filters.showOnlyParents,
            onTap: onToggleParents,
          ),
        ],
      ),
    );
  }
}

class _BrowseChip extends StatelessWidget {
  const _BrowseChip({
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
// ACTIVE FILTERS
// ===========================================================================

class _ActiveFiltersSummary extends StatelessWidget {
  const _ActiveFiltersSummary({
    required this.filters,
    required this.resultCount,
    required this.onClearSearch,
    required this.onClearLevel,
    required this.onToggleParents,
    required this.onReset,
  });

  final GuidelinesTreeFilter filters;
  final int resultCount;

  final VoidCallback onClearSearch;
  final VoidCallback onClearLevel;
  final VoidCallback onToggleParents;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                LucideIcons.listFilter,
                size: 17,
                color: colors.onSecondaryContainer,
              ),

              AppSpacing.hGapSm,

              Expanded(
                child: Text(
                  'Filters applied',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              TextButton(onPressed: onReset, child: const Text('Clear all')),
            ],
          ),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (filters.search.trim().isNotEmpty)
                InputChip(
                  avatar: const Icon(LucideIcons.search, size: 14),
                  label: Text('"${filters.search}"'),
                  onDeleted: onClearSearch,
                ),

              if (filters.level != null)
                InputChip(
                  avatar: const Icon(LucideIcons.layers, size: 14),
                  label: Text(
                    filters.level == 1 ? 'Top level' : 'Level ${filters.level}',
                  ),
                  onDeleted: onClearLevel,
                ),

              if (filters.showOnlyParents)
                InputChip(
                  avatar: const Icon(LucideIcons.listTree, size: 14),
                  label: const Text('Parents only'),
                  onDeleted: onToggleParents,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TREE CONTAINER
// ===========================================================================

class _GuidelineTreeContainer extends StatelessWidget {
  const _GuidelineTreeContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

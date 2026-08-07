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
      appBar: AppBar(),
      body: _buildBody(context: context, state: state, controller: controller),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required GuidelinesIndexerState state,
    required GuidelinesIndexerController controller,
  }) {
    // =====================================================
    // LOADING
    // =====================================================

    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading guideline sections...');
    }

    // =====================================================
    // ERROR
    // =====================================================

    if (state.hasLoadError) {
      return AppErrorView(
        error: state.errorMessage ?? 'Unable to load guideline sections',
        title: 'Failed to load guidelines',
        message: 'Please check your connection and try again.',
        onRetry: () {
          controller.refreshData();
        },
      );
    }

    final tree = state.visibleTree;

    // =====================================================
    // CONTENT
    // =====================================================

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.hPaddingMd + AppSpacing.vPaddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrowseHeader(state: state),

                  AppSpacing.md.gap,

                  _SearchField(
                    search: state.filters.search,
                    onChanged: controller.updateSearch,
                    onClear: controller.clearSearch,
                  ),

                  AppSpacing.md.gap,

                  _QuickFilterChips(
                    filters: state.filters,
                    onReset: controller.resetFilters,
                    onLevelChanged: controller.setLevelFilter,
                    onToggleParents: controller.toggleParentsOnly,
                  ),

                  _ActiveFiltersBar(
                    filters: state.filters,
                    onClearSearch: controller.clearSearch,
                    onClearLevel: () {
                      controller.setLevelFilter(null);
                    },
                    onToggleParents: controller.toggleParentsOnly,
                    onReset: controller.resetFilters,
                  ),
                ],
              ),
            ),
          ),

          // =================================================
          // EMPTY TREE
          // =================================================
          if (tree.childrenAsList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: state.hasActiveFilters
                  ? EmptyState.noResults(
                      title: 'No Guidelines Found',
                      description: 'No matching guideline sections were found.',
                      actionLabel: 'Reset Filters',
                      onAction: controller.resetFilters,
                    )
                  : EmptyState.noData(
                      title: 'No Guidelines Found',
                      description: 'No guideline sections are available yet.',
                      actionLabel: 'Refresh',
                      onAction: () {
                        controller.refreshData();
                      },
                    ),
            )
          else
            SliverFillRemaining(
              child: Padding(
                padding: AppSpacing.hPaddingMd,
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

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader({required this.state});

  final GuidelinesIndexerState state;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
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
            child: Icon(LucideIcons.bookOpenText, color: cs.primary),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.channelTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  state.pageSubtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  state.totalSections > 0
                      ? '${state.totalSections} sections available'
                      : 'No sections available',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
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
    final cs = context.theme.colorScheme;

    final hasSearch = widget.search.trim().isNotEmpty;

    return TextField(
      controller: _textController,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search guideline sections...',
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BrowseChip(
            label: 'All',
            icon: LucideIcons.layers,
            selected: !filters.hasFilters,
            onTap: onReset,
          ),

          AppSpacing.sm.gap,

          _BrowseChip(
            label: 'Level 1',
            icon: LucideIcons.folder,
            selected: filters.level == 1,
            onTap: () {
              onLevelChanged(filters.level == 1 ? null : 1);
            },
          ),

          AppSpacing.sm.gap,

          _BrowseChip(
            label: 'Level 2',
            icon: LucideIcons.folderOpen,
            selected: filters.level == 2,
            onTap: () {
              onLevelChanged(filters.level == 2 ? null : 2);
            },
          ),

          AppSpacing.sm.gap,

          _BrowseChip(
            label: 'Parents',
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
    return FilterChip(
      selected: selected,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onSelected: (_) {
        onTap();
      },
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.filters,
    required this.onClearSearch,
    required this.onClearLevel,
    required this.onToggleParents,
    required this.onReset,
  });

  final GuidelinesTreeFilter filters;

  final VoidCallback onClearSearch;
  final VoidCallback onClearLevel;
  final VoidCallback onToggleParents;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (!filters.hasFilters) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (filters.search.trim().isNotEmpty)
            InputChip(
              label: Text('Search: ${filters.search}'),
              onDeleted: onClearSearch,
            ),

          if (filters.level != null)
            InputChip(
              label: Text('Level ${filters.level}'),
              onDeleted: onClearLevel,
            ),

          if (filters.showOnlyParents)
            InputChip(
              label: const Text('Parents only'),
              onDeleted: onToggleParents,
            ),

          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(LucideIcons.x, size: 16),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

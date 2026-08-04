import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/data/models/guideline_index.dart';
import 'package:user_app/app/utils/app_spacing.dart';
import 'package:user_app/app/widgets/empty_state.dart';

import 'guidelines_indexer_controller.dart';
import 'widgets/guideline_tree_tile.dart';

class GuidelinesIndexerPage extends ConsumerStatefulWidget {
  const GuidelinesIndexerPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<GuidelinesIndexerPage> createState() =>
      _GuidelinesIndexerPageState();
}

class _GuidelinesIndexerPageState extends ConsumerState<GuidelinesIndexerPage> {
  @override
  void initState() {
    super.initState();
    final arguments = widget.arguments;
    final channel = arguments is Map ? arguments['channel']?.toString() : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(guidelinesIndexerControllerProvider)
            .initialize(channel: channel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(guidelinesIndexerControllerProvider);
    return Scaffold(
      appBar: AppBar(),
      body: Builder(
        builder: (context) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.hasLoadError) {
            return EmptyState.noData(
              title: 'Failed to load guidelines',
              description: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: controller.refreshData,
            );
          }

          final tree = controller.visibleTree;

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
                        _BrowseHeader(controller: controller),
                        AppSpacing.md.gap,
                        _SearchField(controller: controller),
                        AppSpacing.md.gap,
                        _QuickFilterChips(controller: controller),
                        _ActiveFiltersBar(controller: controller),
                      ],
                    ),
                  ),
                ),

                if (tree.childrenAsList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState.noData(
                      title: 'No Guidelines Found',
                      description: controller.hasActiveFilters
                          ? 'No matching guideline sections were found.'
                          : 'No guideline sections are available yet.',
                      actionLabel: controller.hasActiveFilters
                          ? 'Reset Filters'
                          : 'Refresh',
                      onAction: controller.hasActiveFilters
                          ? controller.resetFilters
                          : controller.refreshData,
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
                              controller.initializeTreeController(
                                treeController,
                              );
                            },
                            onItemTap: (node) {
                              final data = node.data;

                              if (data == null) return;

                              controller.openIndex(data);
                            },
                            builder: (context, node) {
                              return GuidelineTreeTile(node: node);
                            },
                          ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  final GuidelinesIndexerController controller;

  const _BrowseHeader({required this.controller});

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
                  controller.channelTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.pageSubtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  controller.totalSections > 0
                      ? '${controller.totalSections} sections available'
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
  final GuidelinesIndexerController controller;

  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text: widget.controller.filters.search,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _textController.clear();
    widget.controller.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final search = widget.controller.filters.search;
    final hasSearch = search.trim().isNotEmpty;

    if (_textController.text != search) {
      _textController.text = search;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    return TextField(
      controller: _textController,
      textInputAction: TextInputAction.search,
      onChanged: widget.controller.updateSearch,
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
  final GuidelinesIndexerController controller;

  const _QuickFilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = controller.filters;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BrowseChip(
            label: 'All',
            icon: LucideIcons.layers,
            selected: !filters.hasFilters,
            onTap: controller.resetFilters,
          ),
          AppSpacing.sm.gap,
          _BrowseChip(
            label: 'Level 1',
            icon: LucideIcons.folder,
            selected: filters.level == 1,
            onTap: () =>
                controller.setLevelFilter(filters.level == 1 ? null : 1),
          ),
          AppSpacing.sm.gap,
          _BrowseChip(
            label: 'Level 2',
            icon: LucideIcons.folderOpen,
            selected: filters.level == 2,
            onTap: () =>
                controller.setLevelFilter(filters.level == 2 ? null : 2),
          ),
          AppSpacing.sm.gap,
          _BrowseChip(
            label: 'Parents',
            icon: LucideIcons.listTree,
            selected: filters.showOnlyParents,
            onTap: controller.toggleParentsOnly,
          ),
        ],
      ),
    );
  }
}

class _BrowseChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BrowseChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final GuidelinesIndexerController controller;

  const _ActiveFiltersBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = controller.filters;

    if (!filters.hasFilters) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    if (filters.search.trim().isNotEmpty) {
      chips.add(
        InputChip(
          label: Text('Search: ${filters.search}'),
          onDeleted: controller.clearSearch,
        ),
      );
    }

    if (filters.level != null) {
      chips.add(
        InputChip(
          label: Text('Level ${filters.level}'),
          onDeleted: () => controller.setLevelFilter(null),
        ),
      );
    }

    if (filters.showOnlyParents) {
      chips.add(
        InputChip(
          label: const Text('Parents only'),
          onDeleted: controller.toggleParentsOnly,
        ),
      );
    }

    chips.add(
      TextButton.icon(
        onPressed: controller.resetFilters,
        icon: const Icon(LucideIcons.x, size: 16),
        label: const Text('Reset'),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips,
      ),
    );
  }
}

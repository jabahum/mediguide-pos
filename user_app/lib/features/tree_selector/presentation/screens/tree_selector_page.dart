import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';
import 'package:user_app/l10n/app_translations.dart';

import 'package:user_app/features/tree_selector/data/models/tree_selector_models.dart';
import 'package:user_app/features/tree_selector/presentation/controllers/tree_selector_controller.dart';
import 'package:user_app/features/tree_selector/presentation/controllers/tree_selector_state.dart';
import 'package:user_app/features/tree_selector/presentation/widgets/tree_selector_tile.dart';

part '../widgets/tree_selector_page_tree_search_field.dart';
part '../widgets/tree_selector_page_tree_search_field_state.dart';
part '../widgets/tree_selector_page_selector_info_card.dart';
part '../widgets/tree_selector_page_tree_surface.dart';

class TreeSelectorPage extends ConsumerStatefulWidget {
  const TreeSelectorPage({super.key, required this.config});

  final TreeSelectorConfig config;

  static Future<TreeSelectionResult?> show({
    required TreeSelectorConfig config,
  }) {
    return AppNavigator.dialog<TreeSelectionResult>(
      child: Dialog.fullscreen(child: TreeSelectorPage(config: config)),
      barrierDismissible: config.barrierDismissible,
    );
  }

  @override
  ConsumerState<TreeSelectorPage> createState() => _TreeSelectorPageState();
}

class _TreeSelectorPageState extends ConsumerState<TreeSelectorPage> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = treeSelectorControllerProvider(widget.config);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

    final hasNodes = state.rootTreeNode.childrenAsList.isNotEmpty;

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        leading: IconButton(
          tooltip: AppTranslationKey.close.tr,
          onPressed: () {
            AppNavigator.pop();
          },
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.config.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.config.allowParentSelection
                  ? 'Select an item or eligible parent'
                  : 'Select an item',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: _buildBody(
          context: context,
          state: state,
          controller: controller,
          hasNodes: hasNodes,
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required TreeSelectorState state,
    required TreeSelectorController controller,
    required bool hasNodes,
  }) {
    // =======================================================================
    // INITIAL LOADING
    // =======================================================================

    if (state.isLoading && !hasNodes) {
      return const AppLoadingView(message: 'Loading options...');
    }

    // =======================================================================
    // INITIAL ERROR
    // =======================================================================

    if (state.hasLoadError && !hasNodes) {
      return AppErrorView(
        error: state.errorMessage ?? 'Failed to load selector data',
        title: 'Unable to load options',
        message: 'The available options could not be loaded. Please try again.',
        onRetry: controller.loadRootNodes,
      );
    }

    // =======================================================================
    // EMPTY
    // =======================================================================

    if (!hasNodes) {
      return EmptyState.noData(
        title: 'noItemsFound'.tr,
        description: 'No selectable items are currently available.',
        actionLabel: AppTranslationKey.retry.tr,
        onAction: controller.loadRootNodes,
      );
    }

    // =======================================================================
    // CONTENT
    // =======================================================================

    return RefreshIndicator(
      onRefresh: controller.loadRootNodes,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // =================================================================
          // SEARCH
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
                  _TreeSearchField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _search = value.trim();
                      });
                    },
                    onClear: () {
                      _searchController.clear();

                      setState(() {
                        _search = '';
                      });
                    },
                  ),

                  AppSpacing.gapMd,

                  _SelectorInfoCard(
                    allowParentSelection: widget.config.allowParentSelection,
                  ),

                  AppSpacing.gapLg,

                  Text(
                    _search.isEmpty ? 'Available options' : 'Matching options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _search.isEmpty
                        ? 'Expand groups to find the item you need.'
                        : 'Showing items matching “$_search”.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  AppSpacing.gapSm,
                ],
              ),
            ),
          ),

          // =================================================================
          // TREE
          // =================================================================
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            sliver: SliverToBoxAdapter(
              child: _TreeSurface(
                child:
                    TreeView.simpleTyped<
                      TreeSelectorNodeModel,
                      TreeNode<TreeSelectorNodeModel>
                    >(
                      tree: state.rootTreeNode,
                      showRootNode: false,

                      indentation: const Indentation(
                        style: IndentStyle.squareJoint,
                      ),

                      expansionBehavior: ExpansionBehavior.collapseOthers,

                      // =========================================================
                      // NODE TAP
                      // =========================================================
                      onItemTap: (node) async {
                        final data = node.data;

                        if (data == null) {
                          return;
                        }

                        if (!_matchesSearch(data)) {
                          return;
                        }

                        final result = await controller.onNodeTap(node);

                        if (result == null || !context.mounted) {
                          return;
                        }

                        Navigator.of(context).pop(result);
                      },

                      // =========================================================
                      // NODE
                      // =========================================================
                      builder: (context, node) {
                        final data = node.data;

                        if (data == null) {
                          return const SizedBox.shrink();
                        }

                        if (!_matchesSearch(data)) {
                          return const SizedBox.shrink();
                        }

                        final isLoading = state.loadingNodes.contains(node.key);

                        return Semantics(
                          button: true,
                          label: _nodeSemanticLabel(data),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            child: TreeSelectorTile(
                              node: node,
                              isNodeLoading: isLoading,
                              showParentSelectAction:
                                  widget.config.allowParentSelection &&
                                  data.hasChildren,
                              onSelectParent: () {
                                final result = controller.selectParentNode(
                                  node,
                                );

                                if (result == null) {
                                  return;
                                }

                                Navigator.of(context).pop(result);
                              },
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SEARCH MATCHING
  // =========================================================================

  bool _matchesSearch(TreeSelectorNodeModel node) {
    final needle = _search.trim().toLowerCase();

    if (needle.isEmpty) {
      return true;
    }

    //
    // Adjust these properties if your model uses different names.
    //
    final searchable = <String>[
      node.title,
      node.subtitle,
    ].join(' ').toLowerCase();

    return searchable.contains(needle);
  }

  String _nodeSemanticLabel(TreeSelectorNodeModel node) {
    final parts = <String>[
      node.title.trim(),
      if (node.subtitle.trim().isNotEmpty) node.subtitle.trim(),
      if (node.hasChildren) 'Contains child items',
    ];

    return parts.join('. ');
  }
}

// ===========================================================================
// SEARCH
// ===========================================================================

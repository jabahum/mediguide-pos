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
import 'package:user_app/features/tree_selector/presentation/controllers/tree_selector_state.dart';
import 'package:user_app/l10n/app_translations.dart';

import 'package:user_app/features/tree_selector/data/models/tree_selector_models.dart';
import 'package:user_app/features/tree_selector/presentation/controllers/tree_selector_controller.dart';
import 'package:user_app/features/tree_selector/presentation/widgets/tree_selector_tile.dart';

class TreeSelectorPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = treeSelectorControllerProvider(config);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

    final hasNodes = state.rootTreeNode.childrenAsList.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          tooltip: AppTranslationKey.close.tr,
          onPressed: () {
            AppNavigator.pop();
          },
        ),
      ),
      body: SafeArea(
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
    // =====================================================
    // INITIAL LOADING
    // =====================================================

    if (state.isLoading && !hasNodes) {
      return const AppLoadingView(message: 'Loading options...');
    }

    // =====================================================
    // INITIAL ERROR
    // =====================================================

    if (state.hasLoadError && !hasNodes) {
      return AppErrorView(
        error: state.error ?? 'Failed to load selector data',
        onRetry: controller.loadRootNodes,
      );
    }

    // =====================================================
    // EMPTY
    // =====================================================

    if (!hasNodes) {
      return EmptyState.noData(
        title: 'noItemsFound'.tr,
        description: 'No selectable items are available.',
        actionLabel: AppTranslationKey.retry.tr,
        onAction: controller.loadRootNodes,
      );
    }

    // =====================================================
    // TREE
    // =====================================================

    return RefreshIndicator(
      onRefresh: controller.loadRootNodes,
      child:
          TreeView.simpleTyped<
            TreeSelectorNodeModel,
            TreeNode<TreeSelectorNodeModel>
          >(
            tree: state.rootTreeNode,
            showRootNode: false,
            indentation: const Indentation(style: IndentStyle.squareJoint),
            expansionBehavior: ExpansionBehavior.collapseOthers,

            // ===============================================
            // NODE TAP
            // ===============================================
            onItemTap: (node) async {
              final result = await controller.onNodeTap(node);

              if (result == null || !context.mounted) {
                return;
              }

              Navigator.of(context).pop(result);
            },

            // ===============================================
            // NODE BUILDER
            // ===============================================
            builder: (context, node) {
              final data = node.data;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: TreeSelectorTile(
                  node: node,
                  isNodeLoading: state.loadingNodes.contains(node.key),
                  showParentSelectAction:
                      config.allowParentSelection && data?.hasChildren == true,
                  onSelectParent: () {
                    final result = controller.selectParentNode(node);

                    if (result == null) {
                      return;
                    }

                    Navigator.of(context).pop(result);
                  },
                ),
              );
            },
          ),
    );
  }
}

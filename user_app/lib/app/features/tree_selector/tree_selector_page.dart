import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:user_app/app/core/navigation/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../translations/app_translations.dart';
import '../../utils/app_spacing.dart';
import '../../utils/loading.dart';
import '../../widgets/empty_state.dart';
import 'models/tree_selector_models.dart';
import 'tree_selector_controller.dart';
import 'widgets/tree_selector_tile.dart';

class TreeSelectorPage extends ConsumerWidget {
  final TreeSelectorConfig config;

  const TreeSelectorPage({super.key, required this.config});

  static Future<TreeSelectionResult?> show({
    required TreeSelectorConfig config,
  }) async {
    return AppNavigator.dialog<TreeSelectionResult>(
      Dialog.fullscreen(child: TreeSelectorPage(config: config)),
      barrierDismissible: config.barrierDismissible,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(treeSelectorControllerProvider(config));

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.config.title),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          tooltip: AppTranslationKey.close.tr,
          onPressed: AppNavigator.pop,
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final hasNodes = controller.rootTreeNode.childrenAsList.isNotEmpty;

            if (controller.isLoading && !hasNodes) {
              return const CenteredLoading(loading: Loading.large());
            }

            if (controller.hasLoadError && !hasNodes) {
              return EmptyState.error(
                title: 'failedToLoadData'.tr,
                description: 'pleaseCheckConnectionAndTryAgain'.tr,
                actionLabel: AppTranslationKey.retry.tr,
                onAction: controller.loadRootNodes,
              );
            }

            if (!hasNodes) {
              return EmptyState.noData(
                title: 'noItemsFound'.tr,
                description: 'guidelinesWillAppearHere'.tr,
                actionLabel: AppTranslationKey.retry.tr,
                onAction: controller.loadRootNodes,
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadRootNodes,
              child:
                  TreeView.simpleTyped<
                    TreeSelectorNodeModel,
                    TreeNode<TreeSelectorNodeModel>
                  >(
                    tree: controller.rootTreeNode,
                    showRootNode: false,
                    indentation: const Indentation(
                      style: IndentStyle.squareJoint,
                    ),
                    expansionBehavior: ExpansionBehavior.collapseOthers,
                    onItemTap: (node) async {
                      final result = await controller.onNodeTap(node);
                      if (result != null && context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                    builder: (context, node) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Builder(
                          builder: (context) {
                            final data = node.data;

                            return TreeSelectorTile(
                              node: node,
                              isNodeLoading: controller.isNodeLoading(node),
                              showParentSelectAction:
                                  controller.config.allowParentSelection &&
                                  data?.hasChildren == true,
                              onSelectParent: () {
                                final result = controller.selectParentNode(
                                  node,
                                );
                                if (result != null) {
                                  Navigator.pop(context, result);
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
            );
          },
        ),
      ),
    );
  }
}

// tree_selector_state.dart

import 'package:animated_tree_view/tree_view/tree_node.dart';

import 'package:user_app/features/tree_selector/data/models/tree_selector_models.dart';

final class TreeSelectorState {
  const TreeSelectorState({
    required this.rootTreeNode,
    this.isLoading = true,
    this.hasLoadError = false,
    this.loadingNodes = const {},
    this.errorMessage,
  });

  final TreeNode<TreeSelectorNodeModel> rootTreeNode;

  final bool isLoading;
  final bool hasLoadError;

  final Set<String> loadingNodes;

  final String? errorMessage;

  bool isNodeLoading(TreeNode<TreeSelectorNodeModel> node) {
    return loadingNodes.contains(node.key);
  }

  TreeSelectorState copyWith({
    TreeNode<TreeSelectorNodeModel>? rootTreeNode,
    bool? isLoading,
    bool? hasLoadError,
    Set<String>? loadingNodes,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TreeSelectorState(
      rootTreeNode: rootTreeNode ?? this.rootTreeNode,
      isLoading: isLoading ?? this.isLoading,
      hasLoadError: hasLoadError ?? this.hasLoadError,
      loadingNodes: loadingNodes ?? this.loadingNodes,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

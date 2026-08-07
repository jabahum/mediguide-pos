// tree_selector_controller.dart

import 'dart:async';
import 'dart:convert';

import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/tree_selector/data/models/tree_selector_models.dart';
import 'package:user_app/features/tree_selector/presentation/controllers/tree_selector_state.dart';

part 'tree_selector_controller.g.dart';

@riverpod
class TreeSelectorController extends _$TreeSelectorController {
  /// Cache prevents repeated fetches for the same node.
  final Map<String, List<TreeSelectorNodeModel>> _nodeCache = {};

  /// Deduplicates concurrent requests for the same node.
  final Map<String, Future<List<TreeSelectorNodeModel>>> _pendingRequests = {};

  BackendApiService get _api => ref.read(backendApiServiceProvider);

  @override
  TreeSelectorState build(TreeSelectorConfig config) {
    final root = TreeNode<TreeSelectorNodeModel>.root();

    Future.microtask(loadRootNodes);

    ref.onDispose(() {
      _nodeCache.clear();
      _pendingRequests.clear();
    });

    return TreeSelectorState(rootTreeNode: root);
  }

  // ======================================================
  // ROOT
  // ======================================================

  Future<void> loadRootNodes() async {
    state = state.copyWith(
      isLoading: true,
      hasLoadError: false,
      clearErrorMessage: true,
    );

    try {
      final nodes = await _fetchNodes(
        level: 0,
        filters: const {},
        cacheKey: 'root',
      );

      final root = TreeNode<TreeSelectorNodeModel>.root();

      _addChildrenBatch(root, nodes);

      state = state.copyWith(rootTreeNode: root, hasLoadError: false);
    } catch (error) {
      final message = 'Failed to load data: $error';

      state = state.copyWith(
        rootTreeNode: TreeNode<TreeSelectorNodeModel>.root(),
        hasLoadError: true,
        errorMessage: message,
      );

      _showError(message);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    _nodeCache.clear();
    _pendingRequests.clear();

    await loadRootNodes();
  }

  // ======================================================
  // NODE TAP
  // ======================================================

  Future<TreeSelectionResult?> onNodeTap(
    TreeNode<TreeSelectorNodeModel> node,
  ) async {
    final data = node.data;

    if (data == null) {
      return null;
    }

    if (!data.hasChildren) {
      return _selectionFor(node);
    }

    await loadChildren(node);

    return null;
  }

  // ======================================================
  // CHILDREN
  // ======================================================

  Future<void> loadChildren(TreeNode<TreeSelectorNodeModel> node) async {
    final data = node.data;

    if (data == null || !data.hasChildren) {
      return;
    }

    // Already loaded.
    if (node.childrenAsList.isNotEmpty) {
      return;
    }

    final cacheKey = _cacheKey(data);

    final cached = _nodeCache[cacheKey];

    if (cached != null) {
      _addChildrenBatch(node, cached);

      _publishTreeChange();

      return;
    }

    _setNodeLoading(node.key, true);

    try {
      final children = await _fetchNodes(
        level: data.level + 1,
        filters: data.filters,
        cacheKey: cacheKey,
      );

      _addChildrenBatch(node, children);

      _publishTreeChange();
    } catch (error) {
      _showError('Failed to load more data: $error');
    } finally {
      _setNodeLoading(node.key, false);
    }
  }

  bool isNodeLoading(TreeNode<TreeSelectorNodeModel> node) {
    return state.loadingNodes.contains(node.key);
  }

  void _setNodeLoading(String key, bool loading) {
    final updated = <String>{...state.loadingNodes};

    if (loading) {
      updated.add(key);
    } else {
      updated.remove(key);
    }

    state = state.copyWith(loadingNodes: Set<String>.unmodifiable(updated));
  }

  // ======================================================
  // SELECTION
  // ======================================================

  TreeSelectionResult? selectParentNode(TreeNode<TreeSelectorNodeModel> node) {
    if (!config.allowParentSelection) {
      return null;
    }

    return _selectionFor(node);
  }

  TreeSelectionResult? _selectionFor(TreeNode<TreeSelectorNodeModel> node) {
    final data = node.data;

    if (data == null) {
      return null;
    }

    return TreeSelectionResult(
      selectedNode: data,
      filters: Map<String, dynamic>.from(data.filters),
    );
  }

  // ======================================================
  // TREE
  // ======================================================

  void _addChildrenBatch(
    TreeNode<TreeSelectorNodeModel> parent,
    List<TreeSelectorNodeModel> models,
  ) {
    for (final model in models) {
      parent.add(_toTreeNode(model));
    }
  }

  TreeNode<TreeSelectorNodeModel> _toTreeNode(TreeSelectorNodeModel model) {
    return TreeNode<TreeSelectorNodeModel>(
      key: '${model.level}-${model.id}',
      data: model,
    );
  }

  /// TreeNode is mutable. Assigning the same root object would not
  /// necessarily trigger consumers, so publish a new state instance
  /// after mutating child nodes.
  void _publishTreeChange() {
    state = state.copyWith(rootTreeNode: state.rootTreeNode);
  }

  // ======================================================
  // CACHE
  // ======================================================

  String _cacheKey(TreeSelectorNodeModel model) {
    return '${model.level}-'
        '${_stableJson(model.filters)}';
  }

  String _stableJson(Map<String, dynamic> value) {
    final sorted = Map<String, dynamic>.fromEntries(
      value.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return jsonEncode(sorted);
  }

  // ======================================================
  // FETCH
  // ======================================================

  Future<List<TreeSelectorNodeModel>> _fetchNodes({
    required int level,
    required Map<String, dynamic> filters,
    required String cacheKey,
  }) {
    final cached = _nodeCache[cacheKey];

    if (cached != null) {
      return Future.value(cached);
    }

    final pending = _pendingRequests[cacheKey];

    if (pending != null) {
      return pending;
    }

    final future = _executeFetch(level, filters, cacheKey);

    _pendingRequests[cacheKey] = future;

    return future.whenComplete(() {
      _pendingRequests.remove(cacheKey);
    });
  }

  Future<List<TreeSelectorNodeModel>> _executeFetch(
    int level,
    Map<String, dynamic> filters,
    String cacheKey,
  ) async {
    final query = <String, dynamic>{
      'level': level.toString(),

      if (filters.isNotEmpty) 'filters': jsonEncode(filters),

      if (config.context.isNotEmpty) 'context': jsonEncode(config.context),
    };

    final response = await _api.getCustomEndpoint(
      path: config.endpointPath,
      query: query,
    );

    if (response['success'] == false) {
      throw StateError(response['error']?.toString() ?? 'Unknown error');
    }

    final raw = response['data'] ?? response['nodes'] ?? response['items'];

    if (raw is! List) {
      _nodeCache[cacheKey] = const [];

      return const [];
    }

    final result = raw
        .whereType<Map>()
        .map(
          (item) =>
              TreeSelectorNodeModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    _nodeCache[cacheKey] = result;

    return result;
  }

  // ======================================================
  // ERROR
  // ======================================================

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }
}

import 'dart:convert';
import 'dart:async';
import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';

import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/features/tree_selector/data/models/tree_selector_models.dart';

final treeSelectorControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TreeSelectorController, TreeSelectorConfig>(
      (ref, config) =>
          TreeSelectorController(config, ref.watch(backendApiServiceProvider)),
    );

class TreeSelectorController extends ChangeNotifier {
  final TreeSelectorConfig config;
  final BackendApiService _api;

  TreeSelectorController(this.config, this._api) {
    unawaited(loadRootNodes());
  }

  final rootTreeNode = TreeNode<TreeSelectorNodeModel>.root();

  bool isLoading = true;
  bool hasLoadError = false;

  /// Faster than `Map<String, bool>` for reactive checks
  final Set<String> loadingNodes = {};

  /// Cache prevents re-fetching same node twice
  final Map<String, List<TreeSelectorNodeModel>> _nodeCache = {};

  /// Prevent duplicate API calls for same request
  final Map<String, Future<List<TreeSelectorNodeModel>>> _pendingRequests = {};
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadRootNodes() async {
    isLoading = true;
    hasLoadError = false;
    _notify();

    try {
      rootTreeNode.clear();

      final nodes = await _fetchNodes(
        level: 0,
        filters: const {},
        cacheKey: 'root',
      );

      _addChildrenBatch(rootTreeNode, nodes);
    } catch (e) {
      hasLoadError = true;

      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'Failed to load data: $e',
      );
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<TreeSelectionResult?> onNodeTap(
    TreeNode<TreeSelectorNodeModel> node,
  ) async {
    final data = node.data;
    if (data == null) return null;

    if (!data.hasChildren) {
      return _selectionFor(node);
    }

    await loadChildren(node);
    return null;
  }

  Future<void> loadChildren(TreeNode<TreeSelectorNodeModel> node) async {
    final data = node.data;
    if (data == null || !data.hasChildren) return;

    // already loaded
    if (node.childrenAsList.isNotEmpty) return;

    final cacheKey = _cacheKey(data);

    // use cache if available
    if (_nodeCache.containsKey(cacheKey)) {
      _addChildrenBatch(node, _nodeCache[cacheKey]!);
      return;
    }

    loadingNodes.add(node.key);
    _notify();

    try {
      final children = await _fetchNodes(
        level: data.level + 1,
        filters: data.filters,
        cacheKey: cacheKey,
      );

      _addChildrenBatch(node, children);
    } catch (e) {
      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'Failed to load more data: $e',
      );
    } finally {
      loadingNodes.remove(node.key);
      _notify();
    }
  }

  bool isNodeLoading(TreeNode<TreeSelectorNodeModel> node) {
    return loadingNodes.contains(node.key);
  }

  TreeSelectionResult? selectParentNode(TreeNode<TreeSelectorNodeModel> node) {
    if (!config.allowParentSelection) return null;
    return _selectionFor(node);
  }

  TreeSelectionResult? _selectionFor(TreeNode<TreeSelectorNodeModel> node) {
    final data = node.data;
    if (data == null) return null;

    return TreeSelectionResult(
      selectedNode: data,
      filters: Map<String, dynamic>.from(data.filters),
    );
  }

  /// 🔥 Batch insert = 1 reactive update instead of N updates
  void _addChildrenBatch(
    TreeNode<TreeSelectorNodeModel> parent,
    List<TreeSelectorNodeModel> models,
  ) {
    for (final model in models) {
      parent.add(_toTreeNode(model));
    }
    _notify();
  }

  TreeNode<TreeSelectorNodeModel> _toTreeNode(TreeSelectorNodeModel model) {
    return TreeNode<TreeSelectorNodeModel>(
      key: '${model.level}-${model.id}',
      data: model,
    );
  }

  String _cacheKey(TreeSelectorNodeModel model) {
    return '${model.level}-${jsonEncode(model.filters)}';
  }

  Future<List<TreeSelectorNodeModel>> _fetchNodes({
    required int level,
    required Map<String, dynamic> filters,
    required String cacheKey,
  }) {
    // return cache immediately if available
    if (_nodeCache.containsKey(cacheKey)) {
      return Future.value(_nodeCache[cacheKey]);
    }

    // deduplicate requests
    if (_pendingRequests.containsKey(cacheKey)) {
      return _pendingRequests[cacheKey]!;
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
      throw Exception(response['error'] ?? 'Unknown error');
    }

    final raw = response['data'] ?? response['nodes'] ?? response['items'];

    final List<TreeSelectorNodeModel> result = (raw is List)
        ? raw
              .whereType<Map>()
              .map(
                (e) => TreeSelectorNodeModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : const [];

    _nodeCache[cacheKey] = result;
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

import 'dart:convert';
import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:get/get.dart';

import '../../data/services/backend_api_service.dart';
import '../../translations/app_translations.dart';
import '../../utils/common.dart';
import 'models/tree_selector_models.dart';

class TreeSelectorController extends GetxController {
  final TreeSelectorConfig config;

  TreeSelectorController(this.config);

  final rootTreeNode = TreeNode<TreeSelectorNodeModel>.root();

  final RxBool isLoading = true.obs;
  final RxBool hasLoadError = false.obs;

  /// Faster than `Map<String, bool>` for reactive checks
  final RxSet<String> loadingNodes = <String>{}.obs;

  /// Cache prevents re-fetching same node twice
  final Map<String, List<TreeSelectorNodeModel>> _nodeCache = {};

  /// Prevent duplicate API calls for same request
  final Map<String, Future<List<TreeSelectorNodeModel>>> _pendingRequests = {};

  @override
  void onInit() {
    super.onInit();
    loadRootNodes();
  }

  Future<void> loadRootNodes() async {
    isLoading.value = true;
    hasLoadError.value = false;

    try {
      rootTreeNode.clear();

      final nodes = await _fetchNodes(
        level: 0,
        filters: const {},
        cacheKey: 'root',
      );

      _addChildrenBatch(rootTreeNode, nodes);
    } catch (e) {
      hasLoadError.value = true;
      Common.quickToast(
        title: AppTranslationKey.error,
        description: 'failedToLoadData'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onNodeTap(TreeNode<TreeSelectorNodeModel> node) async {
    final data = node.data;
    if (data == null) return;

    if (!data.hasChildren) {
      _selectNode(node);
      return;
    }

    await loadChildren(node);
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

    try {
      final children = await _fetchNodes(
        level: data.level + 1,
        filters: data.filters,
        cacheKey: cacheKey,
      );

      _addChildrenBatch(node, children);
    } catch (e) {
      Common.quickToast(
        title: AppTranslationKey.error,
        description: 'errorLoadingMore'.tr,
      );
    } finally {
      loadingNodes.remove(node.key);
    }
  }

  bool isNodeLoading(TreeNode<TreeSelectorNodeModel> node) {
    return loadingNodes.contains(node.key);
  }

  void selectParentNode(TreeNode<TreeSelectorNodeModel> node) {
    if (!config.allowParentSelection) return;
    _selectNode(node);
  }

  void _selectNode(TreeNode<TreeSelectorNodeModel> node) {
    final data = node.data;
    if (data == null) return;

    Get.back(
      result: TreeSelectionResult(
        selectedNode: data,
        filters: Map<String, dynamic>.from(data.filters),
      ),
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

    final response = await BackendApiService.to.getCustomEndpoint(
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
}

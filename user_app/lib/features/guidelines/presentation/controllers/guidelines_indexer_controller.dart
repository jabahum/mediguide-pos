// guidelines_indexer_controller.dart

import 'dart:async';

import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:animated_tree_view/tree_view/tree_view.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';

import 'package:user_app/features/guidelines/data/models/guideline_index.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_indexer_state.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_tree_filter.dart';

import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'guidelines_indexer_controller.g.dart';

@riverpod
class GuidelinesIndexerController extends _$GuidelinesIndexerController {
  Timer? _searchDebounce;

  TreeViewController<GuidelineIndex, TreeNode<GuidelineIndex>>? _treeController;

  GuidelineContentRepository get _repository =>
      ref.read(guidelineContentRepositoryProvider);

  @override
  GuidelinesIndexerState build() {
    ref.onDispose(() {
      _searchDebounce?.cancel();
    });

    return GuidelinesIndexerState(
      rootTree: TreeNode<GuidelineIndex>.root(),
      visibleTree: TreeNode<GuidelineIndex>.root(),
    );
  }

  // ======================================================
  // INITIALIZATION
  // ======================================================

  Future<void> initialize({String? channel}) async {
    if (state.allRecords.isNotEmpty || state.isLoading == false) {
      if (state.channel == channel) {
        return;
      }
    }

    state = state.copyWith(channel: channel);

    await loadAllData();
  }

  void initializeTreeController(
    TreeViewController<GuidelineIndex, TreeNode<GuidelineIndex>> controller,
  ) {
    _treeController = controller;

    Future.delayed(const Duration(milliseconds: 150), _expandTopLevel);
  }

  // ======================================================
  // DATA LOADING
  // ======================================================

  Future<void> loadAllData() async {
    state = state.copyWith(
      isLoading: true,
      hasLoadError: false,
      clearErrorMessage: true,
    );

    try {
      final result = await _repository.index(perPage: 500);

      final records = List<GuidelineIndex>.unmodifiable(result.items);

      if (records.isEmpty) {
        final emptyRoot = TreeNode<GuidelineIndex>.root();

        state = state.copyWith(
          rootTree: emptyRoot,
          visibleTree: TreeNode<GuidelineIndex>.root(),
          allRecords: const [],
          isLoading: false,
        );

        return;
      }

      final rootRecord = _resolveRootRecord(records);

      final rootTree = rootRecord == null
          ? _buildTreeFromAllRootRecords(records)
          : _buildTreeFromRoot(rootRecord, records);

      state = state.copyWith(rootTree: rootTree, allRecords: records);

      _applyFilters();
    } catch (error) {
      debugPrint('Error loading guideline index: $error');

      state = state.copyWith(
        rootTree: TreeNode<GuidelineIndex>.root(),
        visibleTree: TreeNode<GuidelineIndex>.root(),
        allRecords: const [],
        hasLoadError: true,
        errorMessage: error.toString(),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshData() {
    return loadAllData();
  }

  // ======================================================
  // ROOT RESOLUTION
  // ======================================================

  GuidelineIndex? _resolveRootRecord(List<GuidelineIndex> records) {
    final channel = state.channel?.trim() ?? '';

    if (channel.isNotEmpty) {
      final channelQuery = channel.toLowerCase();

      for (final record in records) {
        if (record.level == 0 &&
            record.title.toLowerCase().contains(channelQuery)) {
          return record;
        }
      }
    }

    final rootItems = records
        .where((record) => record.level == 0)
        .toList(growable: false);

    if (rootItems.length == 1) {
      return rootItems.first;
    }

    return null;
  }

  // ======================================================
  // TREE BUILDING
  // ======================================================

  TreeNode<GuidelineIndex> _buildTreeFromAllRootRecords(
    List<GuidelineIndex> records,
  ) {
    final root = TreeNode<GuidelineIndex>.root();

    final rootRecords =
        records
            .where(
              (record) =>
                  record.level == 0 || record.parentId?.isEmpty != false,
            )
            .toList()
          ..sort(_sortIndexRecords);

    for (final item in rootRecords) {
      root.add(_buildNode(item, records));
    }

    return root;
  }

  TreeNode<GuidelineIndex> _buildTreeFromRoot(
    GuidelineIndex rootRecord,
    List<GuidelineIndex> records,
  ) {
    final root = TreeNode<GuidelineIndex>.root();

    final hierarchy = _collectHierarchy(rootRecord.id, records);

    final children =
        hierarchy.where((record) => record.parentId == rootRecord.id).toList()
          ..sort(_sortIndexRecords);

    for (final item in children) {
      root.add(_buildNode(item, hierarchy));
    }

    return root;
  }

  List<GuidelineIndex> _collectHierarchy(
    String rootId,
    List<GuidelineIndex> records,
  ) {
    final results = <GuidelineIndex>[];

    var parentIds = <String>[rootId];

    while (parentIds.isNotEmpty) {
      final children =
          records
              .where((record) => parentIds.contains(record.parentId))
              .toList()
            ..sort(_sortIndexRecords);

      results.addAll(children);

      parentIds = children.map((record) => record.id).toList(growable: false);
    }

    return results;
  }

  TreeNode<GuidelineIndex> _buildNode(
    GuidelineIndex item,
    List<GuidelineIndex> records,
  ) {
    final node = TreeNode<GuidelineIndex>(key: item.id, data: item);

    final children =
        records.where((record) => record.parentId == item.id).toList()
          ..sort(_sortIndexRecords);

    for (final child in children) {
      node.add(_buildNode(child, records));
    }

    return node;
  }

  int _sortIndexRecords(GuidelineIndex a, GuidelineIndex b) {
    final levelCompare = a.level.compareTo(b.level);

    if (levelCompare != 0) {
      return levelCompare;
    }

    final orderCompare = a.order.compareTo(b.order);

    if (orderCompare != 0) {
      return orderCompare;
    }

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  // ======================================================
  // FILTER SHEET
  // ======================================================

  Future<void> showFilterBottomSheet(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final current = state.filters;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: AppTranslationKey.filterGuidelines,
      fields: [
        FilterField.text(
          'search',
          AppTranslationKey.searchGuidelines,
          hint: AppTranslationKey.searchGuidelinesHint,
        ),
        FilterField.dropdown('level', AppTranslationKey.level, const [
          '1',
          '2',
          '3',
          '4',
          '5',
        ]),
        FilterField.boolean('parentsOnly', AppTranslationKey.showOnlyParents),
      ],
      initialValues: {
        if (current.search.trim().isNotEmpty) 'search': current.search,
        if (current.level != null) 'level': current.level.toString(),
        if (current.showOnlyParents) 'parentsOnly': true,
      },
    );

    if (result == null) {
      return;
    }

    applyFilterResult(result);
  }

  void applyFilterResult(FilterResult result) {
    final levelValue = result.getValue<String>('level');

    state = state.copyWith(
      filters: GuidelinesTreeFilter(
        search: result.getValue<String>('search')?.trim() ?? '',
        level: int.tryParse(levelValue ?? ''),
        showOnlyParents: result.getValue<bool>('parentsOnly') ?? false,
      ),
    );

    _debouncedApplyFilters();
  }

  // ======================================================
  // FILTER ACTIONS
  // ======================================================

  void updateSearch(String value) {
    state = state.copyWith(
      filters: state.filters.copyWith(search: value.trim()),
    );

    _debouncedApplyFilters();
  }

  void clearSearch() {
    state = state.copyWith(filters: state.filters.copyWith(search: ''));

    _applyFilters();
  }

  void setLevelFilter(int? level) {
    state = state.copyWith(
      filters: state.filters.copyWith(level: level, clearLevel: level == null),
    );

    _applyFilters();
  }

  void toggleParentsOnly() {
    state = state.copyWith(
      filters: state.filters.copyWith(
        showOnlyParents: !state.filters.showOnlyParents,
      ),
    );

    _applyFilters();
  }

  void resetFilters() {
    state = state.copyWith(filters: GuidelinesTreeFilter.empty);

    _applyFilters();
  }

  void _debouncedApplyFilters() {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(AppConstants.searchDebounce, _applyFilters);
  }

  // ======================================================
  // APPLY FILTERS
  // ======================================================

  void _applyFilters() {
    final filters = state.filters;

    if (!filters.hasFilters) {
      state = state.copyWith(visibleTree: _deepCopy(state.rootTree));

      _expandTopLevel();

      return;
    }

    final filtered = TreeNode<GuidelineIndex>.root();

    for (final child in state.rootTree.childrenAsList) {
      final typedChild = child as TreeNode<GuidelineIndex>;

      final filteredChild = _filterNode(typedChild, filters);

      if (filteredChild != null) {
        filtered.add(filteredChild);
      }
    }

    state = state.copyWith(visibleTree: filtered);

    _expandAll();
  }

  TreeNode<GuidelineIndex>? _filterNode(
    TreeNode<GuidelineIndex> node,
    GuidelinesTreeFilter filters,
  ) {
    final data = node.data;

    if (data == null) {
      return null;
    }

    var matches = true;

    if (filters.search.trim().isNotEmpty) {
      final query = filters.search.toLowerCase();

      matches =
          data.title.toLowerCase().contains(query) ||
          data.description.toLowerCase().contains(query);
    }

    if (matches && filters.level != null) {
      matches = data.level == filters.level;
    }

    if (matches && filters.showOnlyParents) {
      matches = data.hasChildren || node.childrenAsList.isNotEmpty;
    }

    final matchingChildren = <TreeNode<GuidelineIndex>>[];

    for (final child in node.childrenAsList) {
      final result = _filterNode(child as TreeNode<GuidelineIndex>, filters);

      if (result != null) {
        matchingChildren.add(result);
      }
    }

    if (!matches && matchingChildren.isEmpty) {
      return null;
    }

    final copied = TreeNode<GuidelineIndex>(key: node.key, data: data);

    for (final child in matchingChildren) {
      copied.add(child);
    }

    return copied;
  }

  // ======================================================
  // TREE HELPERS
  // ======================================================

  TreeNode<GuidelineIndex> _deepCopy(TreeNode<GuidelineIndex> node) {
    final copied = TreeNode<GuidelineIndex>(key: node.key, data: node.data);

    for (final child in node.childrenAsList) {
      copied.add(_deepCopy(child as TreeNode<GuidelineIndex>));
    }

    return copied;
  }

  void expandAll() {
    _expandAll();
  }

  void collapseAll() {
    try {
      final visible = state.filters.hasFilters
          ? _buildFilteredTree(state.filters)
          : _deepCopy(state.rootTree);

      state = state.copyWith(visibleTree: visible);
    } catch (_) {
      // Tree collapse is best effort.
    }
  }

  TreeNode<GuidelineIndex> _buildFilteredTree(GuidelinesTreeFilter filters) {
    final filtered = TreeNode<GuidelineIndex>.root();

    for (final child in state.rootTree.childrenAsList) {
      final result = _filterNode(child as TreeNode<GuidelineIndex>, filters);

      if (result != null) {
        filtered.add(result);
      }
    }

    return filtered;
  }

  void _expandTopLevel() {
    final controller = _treeController;

    if (controller == null) {
      return;
    }

    try {
      controller.expandAllChildren(state.visibleTree);
    } catch (_) {
      // Tree UI operation is best effort.
    }
  }

  void _expandAll() {
    final controller = _treeController;

    if (controller == null) {
      return;
    }

    try {
      controller.expandAllChildren(state.visibleTree);
    } catch (_) {
      // Tree UI operation is best effort.
    }
  }

  // ======================================================
  // NAVIGATION
  // ======================================================

  void openIndex(GuidelineIndex index) {
    AppNavigator.push(
      AppRoutes.guidelines,
      extra: {
        'filterType': 'index',
        'indexItemId': index.id,
        'title': index.title,
      },
    );
  }
}

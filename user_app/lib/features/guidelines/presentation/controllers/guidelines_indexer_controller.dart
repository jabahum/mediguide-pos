import 'dart:async';

import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:animated_tree_view/tree_view/tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/features/guidelines/data/models/guideline_index.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

class GuidelinesTreeFilter {
  final String search;
  final int? level;
  final bool showOnlyParents;

  const GuidelinesTreeFilter({
    this.search = '',
    this.level,
    this.showOnlyParents = false,
  });

  bool get hasFilters {
    return search.trim().isNotEmpty || level != null || showOnlyParents;
  }

  GuidelinesTreeFilter copyWith({
    String? search,
    int? level,
    bool? showOnlyParents,
    bool clearLevel = false,
  }) {
    return GuidelinesTreeFilter(
      search: search ?? this.search,
      level: clearLevel ? null : level ?? this.level,
      showOnlyParents: showOnlyParents ?? this.showOnlyParents,
    );
  }

  static const empty = GuidelinesTreeFilter();
}

final guidelinesIndexerControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => GuidelinesIndexerController(
    ref.watch(guidelineContentRepositoryProvider),
  ),
);

class GuidelinesIndexerController extends ChangeNotifier {
  GuidelinesIndexerController(this._repository) {
    rootTree = TreeNode<GuidelineIndex>.root();
    visibleTree = TreeNode<GuidelineIndex>.root();
  }

  final GuidelineContentRepository _repository;
  // =========================
  // TREE
  // =========================
  late TreeViewController<GuidelineIndex, TreeNode<GuidelineIndex>>
  treeController;

  late TreeNode<GuidelineIndex> rootTree;

  late TreeNode<GuidelineIndex> visibleTree;

  // =========================
  // STATE
  // =========================
  bool isLoading = true;
  bool hasLoadError = false;

  GuidelinesTreeFilter filters = GuidelinesTreeFilter.empty;
  List<GuidelineIndex> allRecords = [];

  String? channel;
  Timer? _searchDebounce;
  bool _disposed = false;
  bool _initialized = false;

  // =========================
  // INIT
  // =========================
  Future<void> initialize({String? channel}) async {
    if (_initialized) return;
    _initialized = true;
    this.channel = channel;
    await loadAllData();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }

  void initializeTreeController(
    TreeViewController<GuidelineIndex, TreeNode<GuidelineIndex>> controller,
  ) {
    treeController = controller;

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_disposed) {
        _expandTopLevel();
      }
    });
  }

  // =========================
  // DATA LOADING
  // =========================
  Future<void> loadAllData() async {
    try {
      isLoading = true;
      hasLoadError = false;
      _notify();

      final result = await _repository.index(perPage: 500);

      final records = result.items;

      allRecords = records;

      if (records.isEmpty) {
        rootTree = TreeNode<GuidelineIndex>.root();
        visibleTree = TreeNode<GuidelineIndex>.root();
        return;
      }

      final rootRecord = _resolveRootRecord(records);

      if (rootRecord == null) {
        rootTree = _buildTreeFromAllRootRecords(records);
      } else {
        rootTree = _buildTreeFromRoot(rootRecord);
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading guideline index: $e');
      hasLoadError = true;
      rootTree = TreeNode<GuidelineIndex>.root();
      visibleTree = TreeNode<GuidelineIndex>.root();
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> refreshData() async {
    await loadAllData();
  }

  GuidelineIndex? _resolveRootRecord(List<GuidelineIndex> records) {
    if ((channel ?? '').trim().isNotEmpty) {
      final channelQuery = channel!.toLowerCase();

      final matched = records
          .where(
            (record) =>
                record.level == 0 &&
                record.title.toLowerCase().contains(channelQuery),
          )
          .firstOrNull;

      if (matched != null) {
        return matched;
      }
    }

    final rootItems = records.where((record) => record.level == 0).toList();

    if (rootItems.length == 1) {
      return rootItems.first;
    }

    return null;
  }

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

  TreeNode<GuidelineIndex> _buildTreeFromRoot(GuidelineIndex rootRecord) {
    final root = TreeNode<GuidelineIndex>.root();

    final hierarchy = _collectHierarchy(rootRecord.id);

    final children =
        hierarchy.where((record) => record.parentId == rootRecord.id).toList()
          ..sort(_sortIndexRecords);

    for (final item in children) {
      root.add(_buildNode(item, hierarchy));
    }

    return root;
  }

  List<GuidelineIndex> _collectHierarchy(String rootId) {
    final results = <GuidelineIndex>[];
    var parentIds = <String>[rootId];

    while (parentIds.isNotEmpty) {
      final children =
          allRecords
              .where((record) => parentIds.contains(record.parentId))
              .toList()
            ..sort(_sortIndexRecords);

      results.addAll(children);

      parentIds = children.map((record) => record.id).toList();
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

  // =========================
  // FILTERS
  // =========================
  Future<void> showFilterBottomSheet(BuildContext context) async {
    if (!context.mounted) return;

    final current = filters;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: AppTranslationKey.filterGuidelines,
      fields: [
        FilterField.text(
          'search',
          AppTranslationKey.searchGuidelines,
          hint: AppTranslationKey.searchGuidelinesHint,
        ),
        FilterField.dropdown('level', AppTranslationKey.level, [
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

    if (result == null) return;

    applyFilterResult(result);
  }

  void applyFilterResult(FilterResult result) {
    final levelString = result.getValue<String>('level');

    filters = GuidelinesTreeFilter(
      search: result.getValue<String>('search')?.trim() ?? '',
      level: int.tryParse(levelString ?? ''),
      showOnlyParents: result.getValue<bool>('parentsOnly') ?? false,
    );

    _debouncedApplyFilters();
  }

  void updateSearch(String value) {
    filters = filters.copyWith(search: value.trim());
    _notify();
    _debouncedApplyFilters();
  }

  void clearSearch() {
    filters = filters.copyWith(search: '');
    _applyFilters();
  }

  void setLevelFilter(int? level) {
    filters = filters.copyWith(level: level, clearLevel: level == null);

    _applyFilters();
  }

  void toggleParentsOnly() {
    filters = filters.copyWith(showOnlyParents: !filters.showOnlyParents);

    _applyFilters();
  }

  void resetFilters() {
    filters = GuidelinesTreeFilter.empty;
    _applyFilters();
  }

  void _debouncedApplyFilters() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  void _applyFilters() {
    final currentFilters = filters;

    if (!currentFilters.hasFilters) {
      visibleTree = _deepCopy(rootTree);
      _notify();
      _expandTopLevel();
      return;
    }

    final filtered = TreeNode<GuidelineIndex>.root();

    for (final child in rootTree.childrenAsList) {
      final typedChild = child as TreeNode<GuidelineIndex>;
      final filteredChild = _filterNode(typedChild, currentFilters);

      if (filteredChild != null) {
        filtered.add(filteredChild);
      }
    }

    visibleTree = filtered;
    _notify();
    _expandAll();
  }

  TreeNode<GuidelineIndex>? _filterNode(
    TreeNode<GuidelineIndex> node,
    GuidelinesTreeFilter filters,
  ) {
    final data = node.data;

    if (data == null) return null;

    bool matches = true;

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
      final typedChild = child as TreeNode<GuidelineIndex>;
      final result = _filterNode(typedChild, filters);

      if (result != null) {
        matchingChildren.add(result);
      }
    }

    if (matches || matchingChildren.isNotEmpty) {
      final copied = TreeNode<GuidelineIndex>(key: node.key, data: data);

      for (final child in matchingChildren) {
        copied.add(child);
      }

      return copied;
    }

    return null;
  }

  // =========================
  // TREE HELPERS
  // =========================
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
      if (!filters.hasFilters) {
        visibleTree = _deepCopy(rootTree);
        _notify();
        return;
      }

      final currentFilters = filters;
      final filtered = TreeNode<GuidelineIndex>.root();

      for (final child in rootTree.childrenAsList) {
        final typedChild = child as TreeNode<GuidelineIndex>;
        final filteredChild = _filterNode(typedChild, currentFilters);

        if (filteredChild != null) {
          filtered.add(filteredChild);
        }
      }

      visibleTree = filtered;
      _notify();
    } catch (_) {}
  }

  void _expandTopLevel() {
    try {
      treeController.expandAllChildren(visibleTree);
    } catch (_) {}
  }

  void _expandAll() {
    try {
      treeController.expandAllChildren(visibleTree);
    } catch (_) {}
  }

  // =========================
  // NAVIGATION
  // =========================
  void openIndex(GuidelineIndex index) {
    AppNavigator.pushNamed(
      '/guidelines',
      extra: {
        'filterType': 'index',
        'indexItemId': index.id,
        'title': index.title,
      },
    );
  }

  // =========================
  // COMPUTED
  // =========================
  bool get hasActiveFilters => filters.hasFilters;

  int get totalSections => allRecords.length;

  String get channelTitle {
    final value = channel?.toLowerCase() ?? '';

    if (value.contains('red')) {
      return 'Red Channel';
    }

    if (value.contains('blue')) {
      return 'Blue Channel';
    }

    return 'Browse Guidelines';
  }

  String get pageSubtitle {
    if (hasActiveFilters) {
      return 'Showing matching guideline sections';
    }

    return 'Choose a section to view related guidelines';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

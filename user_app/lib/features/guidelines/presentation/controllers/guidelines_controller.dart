import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/shared/models/filter_models.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

enum GuidelineRouteFilterType { all, category, categoryTree, indexItem, tag }

final guidelinesControllerProvider = ChangeNotifierProvider.autoDispose
    .family<GuidelinesController, Object?>((ref, arguments) {
      return GuidelinesController(
        ref.watch(guidelineContentRepositoryProvider),
        arguments,
      );
    });

class GuidelinesController extends ChangeNotifier {
  GuidelinesController(this._contentRepository, Object? arguments) {
    pagingController = PagingController<int, Guideline>(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
      fetchPage: _loadPage,
    );
    _readRouteArguments(arguments);
    unawaited(_loadFilterOptions());
    _updateFilterState();
  }

  final GuidelineContentRepository _contentRepository;
  // ==================== CONSTANTS ====================
  static const Set<String> emergencyCategoryNames = {
    'emergencies and trauma',
    'common medical emergencies',
  };

  // ==================== PAGINATION ====================
  late final PagingController<int, Guideline> pagingController;

  // ==================== PAGE STATE ====================
  String pageTitle = 'All Guidelines';
  GuidelineRouteFilterType routeFilterType = GuidelineRouteFilterType.all;

  // ==================== INDEX MODE / ROUTE FILTERS ====================
  GuidelineIndex? selectedIndex;
  bool isInIndexMode = false;

  String routeCategoryId = '';
  List<String> routeCategoryIds = [];
  bool isInCategoryMode = false;

  String selectedTagId = '';
  bool isInTagMode = false;

  // ==================== USER FILTER STATE ====================
  String searchQuery = '';
  String selectedCategoryId = '';
  List<String> selectedTagIds = [];
  String selectedPriority = '';
  String selectedHealthcareLevel = '';
  String selectedTargetPopulation = '';
  bool showHighPriorityOnly = false;

  bool hasActiveFilters = false;

  // ==================== DATA ====================
  List<GuidelineCategory> availableCategories = [];
  List<GuidelineTag> availableTags = [];
  bool isLoadingFilters = false;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    pagingController.dispose();
    super.dispose();
  }

  // ==================== COMPUTED STATE ====================
  String get effectivePageTitle {
    if (isInIndexMode) {
      return selectedIndex?.title ?? pageTitle;
    }

    return pageTitle;
  }

  bool get hasPermanentFilter {
    return isInIndexMode || isInCategoryMode || isInTagMode;
  }

  bool get isEmergencyRoute {
    return isInCategoryMode && pageTitle == 'Emergency Guidelines';
  }

  bool get _hasFilters {
    return searchQuery.trim().isNotEmpty ||
        selectedCategoryId.isNotEmpty ||
        selectedTagIds.isNotEmpty ||
        selectedPriority.isNotEmpty ||
        selectedHealthcareLevel.isNotEmpty ||
        selectedTargetPopulation.isNotEmpty ||
        showHighPriorityOnly;
  }

  // ==================== ROUTE ARGUMENTS ====================
  void _readRouteArguments(Object? args) {
    if (args == null) {
      _applyAllRoute(title: 'All Guidelines');
      return;
    }

    if (args is GuidelineIndex) {
      _applyIndexRoute(index: args, title: args.title);
      return;
    }

    if (args is! Map) {
      _applyAllRoute(title: 'All Guidelines');
      return;
    }

    final filterType = _parseFilterType(args['filterType']?.toString());
    final title = args['title']?.toString().trim();

    switch (filterType) {
      case GuidelineRouteFilterType.all:
        _applyAllRoute(title: title);
        break;

      case GuidelineRouteFilterType.category:
        final categoryId = _firstNonEmpty([
          args['categoryId'],
          args['category'],
        ]);

        _applyCategoryRoute(
          categoryId: categoryId,
          title: title,
          includeChildren: false,
        );
        break;

      case GuidelineRouteFilterType.categoryTree:
        final categoryId = _firstNonEmpty([
          args['categoryId'],
          args['category'],
        ]);

        _applyCategoryRoute(
          categoryId: categoryId,
          title: title,
          includeChildren: true,
        );
        break;

      case GuidelineRouteFilterType.indexItem:
        final indexItemId = _firstNonEmpty([
          args['indexItemId'],
          args['index_item'],
          args['indexItem'],
        ]);

        _applyIndexIdRoute(indexItemId: indexItemId, title: title);
        break;

      case GuidelineRouteFilterType.tag:
        final tagId = _firstNonEmpty([args['tagId'], args['tag']]);

        _applyTagRoute(tagId: tagId, title: title);
        break;
    }
  }

  GuidelineRouteFilterType _parseFilterType(String? value) {
    switch (value?.trim()) {
      case 'category':
        return GuidelineRouteFilterType.category;
      case 'categoryTree':
        return GuidelineRouteFilterType.categoryTree;
      case 'index':
      case 'indexItem':
        return GuidelineRouteFilterType.indexItem;
      case 'tag':
        return GuidelineRouteFilterType.tag;
      case 'all':
      default:
        return GuidelineRouteFilterType.all;
    }
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  void _applyAllRoute({String? title}) {
    routeFilterType = GuidelineRouteFilterType.all;
    pageTitle = _safeTitle(title, fallback: 'All Guidelines');

    selectedIndex = null;
    isInIndexMode = false;

    routeCategoryId = '';
    routeCategoryIds.clear();
    isInCategoryMode = false;

    selectedTagId = '';
    isInTagMode = false;
  }

  void _applyCategoryRoute({
    required String categoryId,
    required String? title,
    required bool includeChildren,
  }) {
    if (categoryId.isEmpty) {
      _applyAllRoute(title: title);
      return;
    }

    routeFilterType = includeChildren
        ? GuidelineRouteFilterType.categoryTree
        : GuidelineRouteFilterType.category;

    routeCategoryId = categoryId;
    routeCategoryIds = [categoryId];
    isInCategoryMode = true;

    selectedCategoryId = '';

    selectedIndex = null;
    isInIndexMode = false;

    selectedTagId = '';
    isInTagMode = false;

    pageTitle = _safeTitle(
      title,
      fallback: includeChildren ? 'Guideline Category' : 'Guidelines',
    );

    if (includeChildren) {
      _loadChildCategoryIds(categoryId);
    }
  }

  void _applyIndexRoute({
    required GuidelineIndex index,
    required String? title,
  }) {
    routeFilterType = GuidelineRouteFilterType.indexItem;

    selectedIndex = index;
    isInIndexMode = true;

    routeCategoryId = '';
    routeCategoryIds.clear();
    isInCategoryMode = false;
    selectedCategoryId = '';

    selectedTagId = '';
    isInTagMode = false;

    pageTitle = _safeTitle(title, fallback: index.title);
  }

  void _applyIndexIdRoute({
    required String indexItemId,
    required String? title,
  }) {
    if (indexItemId.isEmpty) {
      _applyAllRoute(title: title);
      return;
    }

    final resolvedTitle = _safeTitle(title, fallback: 'Guidelines');

    routeFilterType = GuidelineRouteFilterType.indexItem;

    selectedIndex = GuidelineIndex({
      'id': indexItemId,
      'title': resolvedTitle,
      'description': '',
      'parent': '',
      'level': 0,
      'order': 0,
      'hasChildren': false,
    });

    isInIndexMode = true;

    routeCategoryId = '';
    routeCategoryIds.clear();
    isInCategoryMode = false;
    selectedCategoryId = '';

    selectedTagId = '';
    isInTagMode = false;

    pageTitle = resolvedTitle;
  }

  void _applyTagRoute({required String tagId, required String? title}) {
    if (tagId.isEmpty) {
      _applyAllRoute(title: title);
      return;
    }

    routeFilterType = GuidelineRouteFilterType.tag;

    selectedTagId = tagId;
    isInTagMode = true;

    selectedIndex = null;
    isInIndexMode = false;

    routeCategoryId = '';
    routeCategoryIds.clear();
    isInCategoryMode = false;
    selectedCategoryId = '';

    pageTitle = _safeTitle(title, fallback: 'Tagged Guidelines');
  }

  String _safeTitle(String? value, {required String fallback}) {
    final title = value?.trim() ?? '';
    return title.isEmpty ? fallback : title;
  }

  Future<void> _loadChildCategoryIds(String parentCategoryId) async {
    try {
      final result = await _contentRepository.categories(
        parentId: parentCategoryId,
      );

      final childIds = result.items
          .map((record) => GuidelineCategory.fromRecord(record).id)
          .where((id) => id.isNotEmpty)
          .toList();

      routeCategoryIds = <String>{parentCategoryId, ...childIds}.toList();
      notifyListeners();

      pagingController.refresh();
    } catch (_) {
      routeCategoryIds = [parentCategoryId];
      notifyListeners();
    }
  }

  Future<void> _loadChildCategoryIdsForParents(
    List<String> parentCategoryIds,
  ) async {
    final allIds = <String>{...parentCategoryIds};

    for (final parentCategoryId in parentCategoryIds) {
      try {
        final result = await _contentRepository.categories(
          parentId: parentCategoryId,
        );

        final childIds = result.items
            .map((record) => GuidelineCategory.fromRecord(record).id)
            .where((id) => id.isNotEmpty)
            .toList();

        allIds.addAll(childIds);
      } catch (_) {
        allIds.add(parentCategoryId);
      }
    }

    routeCategoryIds = allIds.toList();
    notifyListeners();
    pagingController.refresh();
  }

  // ==================== QUICK FILTER ACTIONS ====================
  void setSearchQuery(String value) {
    searchQuery = value;
    _updateFilterState();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      pagingController.refresh();
    });
  }

  void submitSearchQuery(String value) {
    _searchDebounce?.cancel();
    searchQuery = value;
    _updateFilterState();
    pagingController.refresh();
  }

  void toggleHighPriorityOnly() {
    showHighPriorityOnly = !showHighPriorityOnly;
    _updateFilterState();
    pagingController.refresh();
  }

  void setTargetPopulation(String value) {
    final current = selectedTargetPopulation.toLowerCase();
    final next = value.trim();

    if (current == next.toLowerCase()) {
      selectedTargetPopulation = '';
    } else {
      selectedTargetPopulation = next;
    }

    _updateFilterState();
    pagingController.refresh();
  }

  void openEmergencyGuidelines() {
    if (availableCategories.isEmpty) {
      unawaited(
        _loadFilterOptions().then((_) {
          openEmergencyGuidelines();
        }),
      );
      return;
    }

    final emergencyIds = _resolveEmergencyCategoryIds();
    if (emergencyIds.isEmpty) {
      Common.quickToast(title: 'Emergency guidelines category not found');
      return;
    }

    routeFilterType = GuidelineRouteFilterType.categoryTree;

    routeCategoryId = emergencyIds.first;
    routeCategoryIds = List.of(emergencyIds);
    isInCategoryMode = true;

    selectedIndex = null;
    isInIndexMode = false;

    selectedTagId = '';
    isInTagMode = false;

    selectedCategoryId = '';
    pageTitle = 'Emergency Guidelines';

    unawaited(_loadChildCategoryIdsForParents(emergencyIds));

    _updateFilterState();
    pagingController.refresh();
  }

  // ==================== PAGE LOADING ====================
  Future<List<Guideline>> _loadPage(int pageKey) async {
    try {
      final categoryIds = <String>{
        ...routeCategoryIds,
        if (selectedCategoryId.isNotEmpty) selectedCategoryId,
      };
      final tagIds = <String>{
        if (selectedTagId.isNotEmpty) selectedTagId,
        ...selectedTagIds,
      };
      final result = await _contentRepository.guidelines(
        page: pageKey,
        perPage: pageSize,
        search: searchQuery,
        published: true,
        status: 'published',
        indexId: isInIndexMode ? selectedIndex?.id : null,
        categoryId: categoryIds.isEmpty ? null : categoryIds.join(','),
        tagId: tagIds.isEmpty ? null : tagIds.join(','),
        priority: selectedPriority.isNotEmpty
            ? selectedPriority
            : (showHighPriorityOnly ? 'high' : null),
        healthcareLevel: selectedHealthcareLevel,
        targetPopulation: selectedTargetPopulation,
      );

      return result.items
          .map((record) => Guideline.fromRecord(record))
          .toList();
    } catch (e) {
      debugPrint('Failed to load guidelines: $e');
      Common.quickToast(title: 'errorLoadingGuidelines'.tr);
      rethrow;
    }
  }

  void _updateFilterState() {
    hasActiveFilters = _hasFilters;
    notifyListeners();
  }

  // ==================== CLEAR ====================
  void clearAllFilters() {
    searchQuery = '';
    selectedCategoryId = '';
    selectedTagIds.clear();
    selectedPriority = '';
    selectedHealthcareLevel = '';
    selectedTargetPopulation = '';
    showHighPriorityOnly = false;

    _updateFilterState();
    pagingController.refresh();
  }

  void clearIndexFilter() {
    selectedIndex = null;
    isInIndexMode = false;

    if (!hasPermanentFilter) {
      pageTitle = 'All Guidelines';
      routeFilterType = GuidelineRouteFilterType.all;
    }

    notifyListeners();
    pagingController.refresh();
  }

  void clearRouteCategoryFilter() {
    routeCategoryId = '';
    routeCategoryIds.clear();
    selectedCategoryId = '';
    isInCategoryMode = false;

    if (!hasPermanentFilter) {
      pageTitle = 'All Guidelines';
      routeFilterType = GuidelineRouteFilterType.all;
    }

    _updateFilterState();
    pagingController.refresh();
  }

  void clearTagFilter() {
    selectedTagId = '';
    isInTagMode = false;

    if (!hasPermanentFilter) {
      pageTitle = 'All Guidelines';
      routeFilterType = GuidelineRouteFilterType.all;
    }

    notifyListeners();
    pagingController.refresh();
  }

  void showAllGuidelines() {
    routeFilterType = GuidelineRouteFilterType.all;

    selectedIndex = null;
    isInIndexMode = false;

    routeCategoryId = '';
    routeCategoryIds.clear();
    selectedCategoryId = '';
    isInCategoryMode = false;

    selectedTagId = '';
    isInTagMode = false;

    searchQuery = '';
    selectedTagIds.clear();
    selectedPriority = '';
    selectedHealthcareLevel = '';
    selectedTargetPopulation = '';
    showHighPriorityOnly = false;

    pageTitle = 'All Guidelines';

    _updateFilterState();
    pagingController.refresh();
  }

  // ==================== FILTER MODAL ====================
  Future<void> showFilterModal(BuildContext context) async {
    if (availableCategories.isEmpty || availableTags.isEmpty) {
      await _loadFilterOptions();
    }

    final fields = <FilterField>[
      FilterField.text(
        'search',
        'search'.tr,
        hint: 'Condition, ICD code, definition...',
      ),
      FilterField.dropdown(
        'category',
        'Category',
        availableCategories.map((category) => category.displayName).toList(),
      ),
      FilterField.multiSelect(
        'tags',
        'Tags',
        availableTags.map((tag) => tag.displayName).toList(),
      ),
      FilterField.dropdown('priority', 'Priority', const [
        'critical',
        'high',
        'medium',
        'low',
      ]),
      FilterField.text(
        'healthcareLevel',
        'Healthcare Level',
        hint: 'HC2, HC3, HC4, Hospital...',
      ),
      FilterField.text(
        'targetPopulation',
        'Target Population',
        hint: 'Adults, Children, Pregnant Mothers...',
      ),
      FilterField.boolean('showHighPriorityOnly', 'High Priority Only'),
    ];

    final values = <String, dynamic>{
      if (searchQuery.trim().isNotEmpty) 'search': searchQuery.trim(),
      if (selectedCategoryId.isNotEmpty)
        'category': _categoryNameForId(selectedCategoryId),
      if (selectedTagIds.isNotEmpty) 'tags': _tagNamesForIds(selectedTagIds),
      if (selectedPriority.isNotEmpty) 'priority': selectedPriority,
      if (selectedHealthcareLevel.isNotEmpty)
        'healthcareLevel': selectedHealthcareLevel,
      if (selectedTargetPopulation.isNotEmpty)
        'targetPopulation': selectedTargetPopulation,
      if (showHighPriorityOnly) 'showHighPriorityOnly': true,
    };

    if (!context.mounted) return;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'Filter Guidelines',
      fields: fields,
      initialValues: values,
    );

    if (result != null) {
      _applyFilters(result);
    }
  }

  void _applyFilters(FilterResult result) {
    searchQuery = '';
    selectedCategoryId = '';
    selectedTagIds.clear();
    selectedPriority = '';
    selectedHealthcareLevel = '';
    selectedTargetPopulation = '';
    showHighPriorityOnly = false;

    final search = result.getValue<String>('search');
    if (search != null && search.trim().isNotEmpty) {
      searchQuery = search.trim();
    }

    final categoryName = result.getValue<String>('category');
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      final category = availableCategories.firstWhereOrNull(
        (item) => item.displayName == categoryName.trim(),
      );
      if (category != null) {
        selectedCategoryId = category.id;
      }
    }

    selectedTagIds = _tagIdsFromFilterResult(result);

    final priority = result.getValue<String>('priority');
    if (priority != null && priority.trim().isNotEmpty) {
      selectedPriority = priority.trim();
    }

    final healthcareLevel = result.getValue<String>('healthcareLevel');
    if (healthcareLevel != null && healthcareLevel.trim().isNotEmpty) {
      selectedHealthcareLevel = healthcareLevel.trim();
    }

    final targetPopulation = result.getValue<String>('targetPopulation');
    if (targetPopulation != null && targetPopulation.trim().isNotEmpty) {
      selectedTargetPopulation = targetPopulation.trim();
    }

    final high = result.getValue<bool>('showHighPriorityOnly');
    if (high == true) {
      showHighPriorityOnly = true;
    }

    _updateFilterState();
    pagingController.refresh();
  }

  // ==================== FILTER OPTIONS ====================
  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters = true;

      final categories = await getGuidelineCategories();
      final tags = await getGuidelineTags();

      availableCategories = categories;
      availableTags = tags;
    } finally {
      isLoadingFilters = false;
      notifyListeners();
    }
  }

  Future<List<GuidelineCategory>> getGuidelineCategories() async {
    final result = await _contentRepository.categories();

    return result.items.map((e) => GuidelineCategory.fromRecord(e)).toList();
  }

  Future<List<GuidelineTag>> getGuidelineTags() async {
    final result = await _contentRepository.tags();

    return result.items.map((e) => GuidelineTag.fromRecord(e)).toList();
  }

  String? _categoryNameForId(String id) {
    final category = availableCategories.firstWhereOrNull(
      (item) => item.id == id,
    );
    return category?.displayName;
  }

  List<String> _tagNamesForIds(List<String> ids) {
    final selected = ids.toSet();
    return availableTags
        .where((item) => selected.contains(item.id))
        .map((item) => item.displayName)
        .toList();
  }

  List<String> _tagIdsFromFilterResult(FilterResult result) {
    final selectedNames = (result.getValue<List>('tags') ?? []).cast<String>();
    if (selectedNames.isEmpty) {
      return const <String>[];
    }

    final selected = selectedNames.toSet();
    return availableTags
        .where((item) => selected.contains(item.displayName))
        .map((item) => item.id)
        .toList();
  }

  List<String> _resolveEmergencyCategoryIds() {
    return availableCategories
        .where(
          (category) => emergencyCategoryNames.contains(
            category.displayName.trim().toLowerCase(),
          ),
        )
        .map((category) => category.id)
        .where((id) => id.isNotEmpty)
        .toList();
  }
}

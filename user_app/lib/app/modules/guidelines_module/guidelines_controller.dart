import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/filter_models.dart';

import '../../data/models/models.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';

enum GuidelineRouteFilterType { all, category, categoryTree, indexItem, tag }

class GuidelinesController extends GetxController {
  // ==================== CONSTANTS ====================
  static const Set<String> emergencyCategoryNames = {
    'emergencies and trauma',
    'common medical emergencies',
  };

  // ==================== PAGINATION ====================
  late final PagingController<int, Guideline> pagingController;

  // ==================== PAGE STATE ====================
  final RxString pageTitle = 'All Guidelines'.obs;
  final Rx<GuidelineRouteFilterType> routeFilterType =
      GuidelineRouteFilterType.all.obs;

  // ==================== INDEX MODE / ROUTE FILTERS ====================
  final Rx<GuidelineIndex?> selectedIndex = Rx<GuidelineIndex?>(null);
  final RxBool isInIndexMode = false.obs;

  final RxString routeCategoryId = ''.obs;
  final RxList<String> routeCategoryIds = <String>[].obs;
  final RxBool isInCategoryMode = false.obs;

  final RxString selectedTagId = ''.obs;
  final RxBool isInTagMode = false.obs;

  // ==================== USER FILTER STATE ====================
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryId = ''.obs;
  final RxList<String> selectedTagIds = <String>[].obs;
  final RxString selectedPriority = ''.obs;
  final RxString selectedHealthcareLevel = ''.obs;
  final RxString selectedTargetPopulation = ''.obs;
  final RxBool showHighPriorityOnly = false.obs;

  final RxBool hasActiveFilters = false.obs;

  // ==================== DATA ====================
  final RxList<GuidelineCategory> availableCategories =
      <GuidelineCategory>[].obs;
  final RxList<GuidelineTag> availableTags = <GuidelineTag>[].obs;
  final RxBool isLoadingFilters = false.obs;

  Timer? _searchDebounce;

  // ==================== INIT ====================
  @override
  void onInit() {
    super.onInit();

    pagingController = PagingController<int, Guideline>(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
      fetchPage: _loadPage,
    );

    _readRouteArguments();
    _loadFilterOptions();
    _updateFilterState();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    pagingController.dispose();
    super.onClose();
  }

  // ==================== COMPUTED STATE ====================
  String get effectivePageTitle {
    if (isInIndexMode.value) {
      return selectedIndex.value?.title ?? pageTitle.value;
    }

    return pageTitle.value;
  }

  bool get hasPermanentFilter {
    return isInIndexMode.value || isInCategoryMode.value || isInTagMode.value;
  }

  bool get isEmergencyRoute {
    return isInCategoryMode.value && pageTitle.value == 'Emergency Guidelines';
  }

  bool get _hasFilters {
    return searchQuery.value.trim().isNotEmpty ||
        selectedCategoryId.value.isNotEmpty ||
        selectedTagIds.isNotEmpty ||
        selectedPriority.value.isNotEmpty ||
        selectedHealthcareLevel.value.isNotEmpty ||
        selectedTargetPopulation.value.isNotEmpty ||
        showHighPriorityOnly.value;
  }

  // ==================== ROUTE ARGUMENTS ====================
  void _readRouteArguments() {
    final args = Get.arguments;

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
    routeFilterType.value = GuidelineRouteFilterType.all;
    pageTitle.value = _safeTitle(title, fallback: 'All Guidelines');

    selectedIndex.value = null;
    isInIndexMode.value = false;

    routeCategoryId.value = '';
    routeCategoryIds.clear();
    isInCategoryMode.value = false;

    selectedTagId.value = '';
    isInTagMode.value = false;
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

    routeFilterType.value = includeChildren
        ? GuidelineRouteFilterType.categoryTree
        : GuidelineRouteFilterType.category;

    routeCategoryId.value = categoryId;
    routeCategoryIds.assignAll([categoryId]);
    isInCategoryMode.value = true;

    selectedCategoryId.value = '';

    selectedIndex.value = null;
    isInIndexMode.value = false;

    selectedTagId.value = '';
    isInTagMode.value = false;

    pageTitle.value = _safeTitle(
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
    routeFilterType.value = GuidelineRouteFilterType.indexItem;

    selectedIndex.value = index;
    isInIndexMode.value = true;

    routeCategoryId.value = '';
    routeCategoryIds.clear();
    isInCategoryMode.value = false;
    selectedCategoryId.value = '';

    selectedTagId.value = '';
    isInTagMode.value = false;

    pageTitle.value = _safeTitle(title, fallback: index.title);
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

    routeFilterType.value = GuidelineRouteFilterType.indexItem;

    selectedIndex.value = GuidelineIndex({
      'id': indexItemId,
      'title': resolvedTitle,
      'description': '',
      'parent': '',
      'level': 0,
      'order': 0,
      'hasChildren': false,
    });

    isInIndexMode.value = true;

    routeCategoryId.value = '';
    routeCategoryIds.clear();
    isInCategoryMode.value = false;
    selectedCategoryId.value = '';

    selectedTagId.value = '';
    isInTagMode.value = false;

    pageTitle.value = resolvedTitle;
  }

  void _applyTagRoute({required String tagId, required String? title}) {
    if (tagId.isEmpty) {
      _applyAllRoute(title: title);
      return;
    }

    routeFilterType.value = GuidelineRouteFilterType.tag;

    selectedTagId.value = tagId;
    isInTagMode.value = true;

    selectedIndex.value = null;
    isInIndexMode.value = false;

    routeCategoryId.value = '';
    routeCategoryIds.clear();
    isInCategoryMode.value = false;
    selectedCategoryId.value = '';

    pageTitle.value = _safeTitle(title, fallback: 'Tagged Guidelines');
  }

  String _safeTitle(String? value, {required String fallback}) {
    final title = value?.trim() ?? '';
    return title.isEmpty ? fallback : title;
  }

  Future<void> _loadChildCategoryIds(String parentCategoryId) async {
    try {
      final result = await BackendApiService.to.getResourceList(
        collectionName: GuidelineCategory.collection,
        perPage: 100,
        filter:
            'status="active" && parent_category="${BackendApiService.escapeFilterValue(parentCategoryId)}"',
        sort: 'sort_order,name',
      );

      final childIds = result.items
          .map((record) => GuidelineCategory.fromRecord(record).id)
          .where((id) => id.isNotEmpty)
          .toList();

      routeCategoryIds.assignAll(<String>{parentCategoryId, ...childIds});

      pagingController.refresh();
    } catch (_) {
      routeCategoryIds.assignAll([parentCategoryId]);
    }
  }

  Future<void> _loadChildCategoryIdsForParents(
    List<String> parentCategoryIds,
  ) async {
    final allIds = <String>{...parentCategoryIds};

    for (final parentCategoryId in parentCategoryIds) {
      try {
        final result = await BackendApiService.to.getResourceList(
          collectionName: GuidelineCategory.collection,
          perPage: 100,
          filter:
              'status="active" && parent_category="${BackendApiService.escapeFilterValue(parentCategoryId)}"',
          sort: 'sort_order,name',
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

    routeCategoryIds.assignAll(allIds.toList());
    pagingController.refresh();
  }

  // ==================== QUICK FILTER ACTIONS ====================
  void setSearchQuery(String value) {
    searchQuery.value = value;
    _updateFilterState();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      pagingController.refresh();
    });
  }

  void submitSearchQuery(String value) {
    _searchDebounce?.cancel();
    searchQuery.value = value;
    _updateFilterState();
    pagingController.refresh();
  }

  void toggleHighPriorityOnly() {
    showHighPriorityOnly.value = !showHighPriorityOnly.value;
    _updateFilterState();
    pagingController.refresh();
  }

  void setTargetPopulation(String value) {
    final current = selectedTargetPopulation.value.toLowerCase();
    final next = value.trim();

    if (current == next.toLowerCase()) {
      selectedTargetPopulation.value = '';
    } else {
      selectedTargetPopulation.value = next;
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

    routeFilterType.value = GuidelineRouteFilterType.categoryTree;

    routeCategoryId.value = emergencyIds.first;
    routeCategoryIds.assignAll(emergencyIds);
    isInCategoryMode.value = true;

    selectedIndex.value = null;
    isInIndexMode.value = false;

    selectedTagId.value = '';
    isInTagMode.value = false;

    selectedCategoryId.value = '';
    pageTitle.value = 'Emergency Guidelines';

    unawaited(_loadChildCategoryIdsForParents(emergencyIds));

    _updateFilterState();
    pagingController.refresh();
  }

  // ==================== PAGE LOADING ====================
  Future<List<Guideline>> _loadPage(int pageKey) async {
    try {
      final filter = _buildFilter();

      debugPrint('Guidelines filter: $filter');

      final result = await BackendApiService.to.getResourceList(
        collectionName: Guideline.collection,
        page: pageKey,
        perPage: pageSize,
        filter: filter,
        sort: '-updated',
        expand: 'categories,tags,index_item',
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

  String _buildFilter() {
    final filters = <String>[];

    filters.add('is_published=true');
    filters.add('status="published"');

    if (isInIndexMode.value && selectedIndex.value != null) {
      filters.add(
        'index_item="${BackendApiService.escapeFilterValue(selectedIndex.value!.id)}"',
      );
    }

    if (isInCategoryMode.value) {
      final categoryIds = routeCategoryIds.isNotEmpty
          ? routeCategoryIds
          : routeCategoryId.value.isNotEmpty
          ? <String>[routeCategoryId.value]
          : <String>[];

      if (categoryIds.isNotEmpty) {
        final categoryFilter = categoryIds
            .map(
              (id) => 'categories~"${BackendApiService.escapeFilterValue(id)}"',
            )
            .join(' || ');

        filters.add('($categoryFilter)');
      }
    }

    if (!isInCategoryMode.value && selectedCategoryId.value.isNotEmpty) {
      filters.add(
        'categories~"${BackendApiService.escapeFilterValue(selectedCategoryId.value)}"',
      );
    }

    if (isInTagMode.value && selectedTagId.value.isNotEmpty) {
      filters.add(
        'tags~"${BackendApiService.escapeFilterValue(selectedTagId.value)}"',
      );
    }

    final search = searchQuery.value.trim();
    if (search.isNotEmpty) {
      final q = BackendApiService.escapeFilterValue(search);

      filters.add(
        '('
        'condition_name~"$q" || '
        'definition~"$q" || '
        'clinical_features~"$q" || '
        'causes~"$q" || '
        'icd10_code~"$q" || '
        'icd11_code~"$q"'
        ')',
      );
    }

    if (selectedTagIds.isNotEmpty) {
      final tagFilter = selectedTagIds
          .map((id) => 'tags~"${BackendApiService.escapeFilterValue(id)}"')
          .join(' || ');

      filters.add('($tagFilter)');
    }

    if (selectedPriority.value.isNotEmpty) {
      filters.add(
        'priority="${BackendApiService.escapeFilterValue(selectedPriority.value)}"',
      );
    }

    if (selectedHealthcareLevel.value.isNotEmpty) {
      filters.add(
        'healthcare_level_required~"${BackendApiService.escapeFilterValue(selectedHealthcareLevel.value)}"',
      );
    }

    if (selectedTargetPopulation.value.isNotEmpty) {
      filters.add(
        'target_population~"${BackendApiService.escapeFilterValue(selectedTargetPopulation.value)}"',
      );
    }

    if (showHighPriorityOnly.value) {
      filters.add('(priority="critical" || priority="high")');
    }

    return filters.join(' && ');
  }

  void _updateFilterState() {
    hasActiveFilters.value = _hasFilters;
  }

  // ==================== CLEAR ====================
  void clearAllFilters() {
    searchQuery.value = '';
    selectedCategoryId.value = '';
    selectedTagIds.clear();
    selectedPriority.value = '';
    selectedHealthcareLevel.value = '';
    selectedTargetPopulation.value = '';
    showHighPriorityOnly.value = false;

    _updateFilterState();
    pagingController.refresh();
  }

  void clearIndexFilter() {
    selectedIndex.value = null;
    isInIndexMode.value = false;

    if (!hasPermanentFilter) {
      pageTitle.value = 'All Guidelines';
      routeFilterType.value = GuidelineRouteFilterType.all;
    }

    pagingController.refresh();
  }

  void clearRouteCategoryFilter() {
    routeCategoryId.value = '';
    routeCategoryIds.clear();
    selectedCategoryId.value = '';
    isInCategoryMode.value = false;

    if (!hasPermanentFilter) {
      pageTitle.value = 'All Guidelines';
      routeFilterType.value = GuidelineRouteFilterType.all;
    }

    _updateFilterState();
    pagingController.refresh();
  }

  void clearTagFilter() {
    selectedTagId.value = '';
    isInTagMode.value = false;

    if (!hasPermanentFilter) {
      pageTitle.value = 'All Guidelines';
      routeFilterType.value = GuidelineRouteFilterType.all;
    }

    pagingController.refresh();
  }

  void showAllGuidelines() {
    routeFilterType.value = GuidelineRouteFilterType.all;

    selectedIndex.value = null;
    isInIndexMode.value = false;

    routeCategoryId.value = '';
    routeCategoryIds.clear();
    selectedCategoryId.value = '';
    isInCategoryMode.value = false;

    selectedTagId.value = '';
    isInTagMode.value = false;

    searchQuery.value = '';
    selectedTagIds.clear();
    selectedPriority.value = '';
    selectedHealthcareLevel.value = '';
    selectedTargetPopulation.value = '';
    showHighPriorityOnly.value = false;

    pageTitle.value = 'All Guidelines';

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
      if (searchQuery.value.trim().isNotEmpty)
        'search': searchQuery.value.trim(),
      if (selectedCategoryId.value.isNotEmpty)
        'category': _categoryNameForId(selectedCategoryId.value),
      if (selectedTagIds.isNotEmpty) 'tags': _tagNamesForIds(selectedTagIds),
      if (selectedPriority.value.isNotEmpty) 'priority': selectedPriority.value,
      if (selectedHealthcareLevel.value.isNotEmpty)
        'healthcareLevel': selectedHealthcareLevel.value,
      if (selectedTargetPopulation.value.isNotEmpty)
        'targetPopulation': selectedTargetPopulation.value,
      if (showHighPriorityOnly.value) 'showHighPriorityOnly': true,
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
    searchQuery.value = '';
    selectedCategoryId.value = '';
    selectedTagIds.clear();
    selectedPriority.value = '';
    selectedHealthcareLevel.value = '';
    selectedTargetPopulation.value = '';
    showHighPriorityOnly.value = false;

    final search = result.getValue<String>('search');
    if (search != null && search.trim().isNotEmpty) {
      searchQuery.value = search.trim();
    }

    final categoryName = result.getValue<String>('category');
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      final category = availableCategories.firstWhereOrNull(
        (item) => item.displayName == categoryName.trim(),
      );
      if (category != null) {
        selectedCategoryId.value = category.id;
      }
    }

    selectedTagIds.assignAll(_tagIdsFromFilterResult(result));

    final priority = result.getValue<String>('priority');
    if (priority != null && priority.trim().isNotEmpty) {
      selectedPriority.value = priority.trim();
    }

    final healthcareLevel = result.getValue<String>('healthcareLevel');
    if (healthcareLevel != null && healthcareLevel.trim().isNotEmpty) {
      selectedHealthcareLevel.value = healthcareLevel.trim();
    }

    final targetPopulation = result.getValue<String>('targetPopulation');
    if (targetPopulation != null && targetPopulation.trim().isNotEmpty) {
      selectedTargetPopulation.value = targetPopulation.trim();
    }

    final high = result.getValue<bool>('showHighPriorityOnly');
    if (high == true) {
      showHighPriorityOnly.value = true;
    }

    _updateFilterState();
    pagingController.refresh();
  }

  // ==================== FILTER OPTIONS ====================
  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      final categories = await getGuidelineCategories();
      final tags = await getGuidelineTags();

      availableCategories.assignAll(categories);
      availableTags.assignAll(tags);
    } finally {
      isLoadingFilters.value = false;
    }
  }

  Future<List<GuidelineCategory>> getGuidelineCategories() async {
    final result = await BackendApiService.to.getResourceList(
      collectionName: GuidelineCategory.collection,
      perPage: 100,
      filter: 'status="active"',
      sort: 'sort_order,name',
    );

    return result.items.map((e) => GuidelineCategory.fromRecord(e)).toList();
  }

  Future<List<GuidelineTag>> getGuidelineTags() async {
    final result = await BackendApiService.to.getResourceList(
      collectionName: GuidelineTag.collection,
      perPage: 100,
      sort: 'name',
    );

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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_query.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_route_state.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_state.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'guidelines_controller.g.dart';

@riverpod
class GuidelinesController extends _$GuidelinesController {
  static const Set<String> emergencyCategoryNames = {
    'emergencies and trauma',
    'common medical emergencies',
  };

  Timer? _searchDebounce;

  late final PagingController<int, Guideline> pagingController;

  GuidelineContentRepository get _contentRepository =>
      ref.read(guidelineContentRepositoryProvider);

  void refresh() {
    pagingController.refresh();
  }

  @override
  GuidelinesState build(Object? arguments) {
    final route = _routeFromArguments(arguments);

    pagingController = PagingController<int, Guideline>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: _loadPage,
    );

    ref.onDispose(() {
      _searchDebounce?.cancel();
      pagingController.dispose();
    });

    Future.microtask(() async {
      await _loadFilterOptions();

      if (route.filterType == GuidelineRouteFilterType.categoryTree &&
          route.routeCategoryId.isNotEmpty) {
        await _loadChildCategoryIds(route.routeCategoryId);
      }
    });

    return GuidelinesState(route: route);
  }

  // ======================================================
  // ROUTE PARSING
  // ======================================================

  GuidelinesRouteState _routeFromArguments(Object? arguments) {
    if (arguments == null) {
      return const GuidelinesRouteState();
    }

    if (arguments is GuidelineIndex) {
      return GuidelinesRouteState(
        pageTitle: arguments.title,
        filterType: GuidelineRouteFilterType.indexItem,
        selectedIndex: arguments,
      );
    }

    if (arguments is! Map) {
      return const GuidelinesRouteState();
    }

    final filterType = _parseFilterType(arguments['filterType']?.toString());

    final title = arguments['title']?.toString().trim();

    switch (filterType) {
      case GuidelineRouteFilterType.category:
        final categoryId = _firstNonEmpty([
          arguments['categoryId'],
          arguments['category'],
        ]);

        if (categoryId.isEmpty) {
          return GuidelinesRouteState(
            pageTitle: _safeTitle(title, fallback: 'All Guidelines'),
          );
        }

        return GuidelinesRouteState(
          pageTitle: _safeTitle(title, fallback: 'Guidelines'),
          filterType: GuidelineRouteFilterType.category,
          routeCategoryId: categoryId,
          routeCategoryIds: [categoryId],
        );

      case GuidelineRouteFilterType.categoryTree:
        final categoryId = _firstNonEmpty([
          arguments['categoryId'],
          arguments['category'],
        ]);

        if (categoryId.isEmpty) {
          return GuidelinesRouteState(
            pageTitle: _safeTitle(title, fallback: 'All Guidelines'),
          );
        }

        return GuidelinesRouteState(
          pageTitle: _safeTitle(title, fallback: 'Guideline Category'),
          filterType: GuidelineRouteFilterType.categoryTree,
          routeCategoryId: categoryId,
          routeCategoryIds: [categoryId],
        );

      case GuidelineRouteFilterType.indexItem:
        final indexItemId = _firstNonEmpty([
          arguments['indexItemId'],
          arguments['index_item'],
          arguments['indexItem'],
        ]);

        if (indexItemId.isEmpty) {
          return const GuidelinesRouteState();
        }

        final resolvedTitle = _safeTitle(title, fallback: 'Guidelines');

        return GuidelinesRouteState(
          pageTitle: resolvedTitle,
          filterType: GuidelineRouteFilterType.indexItem,
          selectedIndex: GuidelineIndex(id: indexItemId, title: resolvedTitle),
        );

      case GuidelineRouteFilterType.tag:
        final tagId = _firstNonEmpty([arguments['tagId'], arguments['tag']]);

        if (tagId.isEmpty) {
          return const GuidelinesRouteState();
        }

        return GuidelinesRouteState(
          pageTitle: _safeTitle(title, fallback: 'Tagged Guidelines'),
          filterType: GuidelineRouteFilterType.tag,
          selectedTagId: tagId,
        );

      case GuidelineRouteFilterType.all:
        return GuidelinesRouteState(
          pageTitle: _safeTitle(title, fallback: 'All Guidelines'),
        );
    }
  }

  GuidelineRouteFilterType _parseFilterType(String? value) {
    return switch (value?.trim()) {
      'category' => GuidelineRouteFilterType.category,
      'categoryTree' => GuidelineRouteFilterType.categoryTree,
      'index' || 'indexItem' => GuidelineRouteFilterType.indexItem,
      'tag' => GuidelineRouteFilterType.tag,
      _ => GuidelineRouteFilterType.all,
    };
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

  String _safeTitle(String? value, {required String fallback}) {
    final title = value?.trim() ?? '';

    return title.isEmpty ? fallback : title;
  }

  // ======================================================
  // PAGINATION
  // ======================================================

  Future<List<Guideline>> _loadPage(int pageKey) async {
    try {
      final query = state.query;
      final route = state.route;

      final categoryIds = <String>{
        ...route.routeCategoryIds,
        if (query.selectedCategoryId.isNotEmpty) query.selectedCategoryId,
      };

      final tagIds = <String>{
        if (route.selectedTagId.isNotEmpty) route.selectedTagId,
        ...query.selectedTagIds,
      };

      final result = await _contentRepository.guidelines(
        page: pageKey,
        perPage: AppConstants.pageSize,
        search: query.search,
        published: true,
        status: 'published',
        indexId: route.isInIndexMode ? route.selectedIndex?.id : null,
        categoryId: categoryIds.isEmpty ? null : categoryIds.join(','),
        tagId: tagIds.isEmpty ? null : tagIds.join(','),
        priority: query.selectedPriority.isNotEmpty
            ? query.selectedPriority
            : query.showHighPriorityOnly
            ? 'high'
            : null,
        healthcareLevel: query.selectedHealthcareLevel,
        targetPopulation: query.selectedTargetPopulation,
      );

      return result.items;
    } catch (error) {
      _showError('Failed to load guidelines: $error');

      rethrow;
    }
  }

  // ======================================================
  // CHILD CATEGORIES
  // ======================================================

  Future<void> _loadChildCategoryIds(String parentCategoryId) async {
    try {
      final result = await _contentRepository.categories(
        parentId: parentCategoryId,
      );

      final ids = <String>{
        parentCategoryId,
        ...result.items
            .map((category) => category.id)
            .where((id) => id.isNotEmpty),
      };

      state = state.copyWith(
        route: state.route.copyWith(
          routeCategoryIds: List<String>.unmodifiable(ids),
        ),
      );

      pagingController.refresh();
    } catch (_) {
      state = state.copyWith(
        route: state.route.copyWith(routeCategoryIds: [parentCategoryId]),
      );
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

        allIds.addAll(
          result.items
              .map((category) => category.id)
              .where((id) => id.isNotEmpty),
        );
      } catch (_) {
        allIds.add(parentCategoryId);
      }
    }

    state = state.copyWith(
      route: state.route.copyWith(
        routeCategoryIds: List<String>.unmodifiable(allIds),
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // SEARCH
  // ======================================================

  void setSearchQuery(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value));

    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      AppConstants.searchDebounce,
      pagingController.refresh,
    );
  }

  void submitSearchQuery(String value) {
    _searchDebounce?.cancel();

    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    pagingController.refresh();
  }

  // ======================================================
  // QUICK FILTERS
  // ======================================================

  void toggleHighPriorityOnly() {
    state = state.copyWith(
      query: state.query.copyWith(
        showHighPriorityOnly: !state.query.showHighPriorityOnly,
      ),
    );

    pagingController.refresh();
  }

  void setTargetPopulation(String value) {
    final next = value.trim();

    final current = state.query.selectedTargetPopulation;

    state = state.copyWith(
      query: state.query.copyWith(
        selectedTargetPopulation: current.toLowerCase() == next.toLowerCase()
            ? ''
            : next,
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // EMERGENCY ROUTE
  // ======================================================

  Future<void> openEmergencyGuidelines() async {
    if (state.availableCategories.isEmpty) {
      await _loadFilterOptions();
    }

    final emergencyIds = _resolveEmergencyCategoryIds();

    if (emergencyIds.isEmpty) {
      _showError('Emergency guidelines category not found');
      return;
    }

    state = state.copyWith(
      query: state.query.copyWith(selectedCategoryId: ''),
      route: GuidelinesRouteState(
        pageTitle: 'Emergency Guidelines',
        filterType: GuidelineRouteFilterType.categoryTree,
        routeCategoryId: emergencyIds.first,
        routeCategoryIds: List<String>.unmodifiable(emergencyIds),
      ),
    );

    pagingController.refresh();

    await _loadChildCategoryIdsForParents(emergencyIds);
  }

  // ======================================================
  // CLEAR / ROUTE RESET
  // ======================================================

  void clearAllFilters() {
    state = state.copyWith(query: GuidelinesQuery.empty);

    pagingController.refresh();
  }

  void clearIndexFilter() {
    var route = state.route.copyWith(clearSelectedIndex: true);

    if (!route.isInCategoryMode && !route.isInTagMode) {
      route = const GuidelinesRouteState();
    } else {
      route = route.copyWith(
        filterType: route.isInCategoryMode
            ? GuidelineRouteFilterType.category
            : GuidelineRouteFilterType.tag,
      );
    }

    state = state.copyWith(route: route);

    pagingController.refresh();
  }

  void clearRouteCategoryFilter() {
    var route = state.route.copyWith(
      routeCategoryId: '',
      routeCategoryIds: const [],
    );

    if (!route.isInIndexMode && !route.isInTagMode) {
      route = const GuidelinesRouteState();
    }

    state = state.copyWith(
      query: state.query.copyWith(selectedCategoryId: ''),
      route: route,
    );

    pagingController.refresh();
  }

  void clearTagFilter() {
    var route = state.route.copyWith(selectedTagId: '');

    if (!route.isInIndexMode && !route.isInCategoryMode) {
      route = const GuidelinesRouteState();
    }

    state = state.copyWith(route: route);

    pagingController.refresh();
  }

  void showAllGuidelines() {
    _searchDebounce?.cancel();

    state = const GuidelinesState();

    pagingController.refresh();
  }

  // ======================================================
  // FILTER MODAL
  // ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (state.availableCategories.isEmpty || state.availableTags.isEmpty) {
      await _loadFilterOptions();
    }

    if (!context.mounted) {
      return;
    }

    final query = state.query;

    final fields = <FilterField>[
      FilterField.text(
        'search',
        'search'.tr,
        hint: 'Condition, ICD code, definition...',
      ),
      FilterField.dropdown(
        'category',
        'Category',
        state.availableCategories
            .map((category) => category.displayName)
            .toList(growable: false),
      ),
      FilterField.multiSelect(
        'tags',
        'Tags',
        state.availableTags
            .map((tag) => tag.displayName)
            .toList(growable: false),
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
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.selectedCategoryId.isNotEmpty)
        'category': _categoryNameForId(query.selectedCategoryId),
      if (query.selectedTagIds.isNotEmpty)
        'tags': _tagNamesForIds(query.selectedTagIds),
      if (query.selectedPriority.isNotEmpty) 'priority': query.selectedPriority,
      if (query.selectedHealthcareLevel.isNotEmpty)
        'healthcareLevel': query.selectedHealthcareLevel,
      if (query.selectedTargetPopulation.isNotEmpty)
        'targetPopulation': query.selectedTargetPopulation,
      if (query.showHighPriorityOnly) 'showHighPriorityOnly': true,
    };

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
    var selectedCategoryId = '';

    final categoryName = result.getValue<String>('category')?.trim() ?? '';

    if (categoryName.isNotEmpty) {
      for (final category in state.availableCategories) {
        if (category.displayName == categoryName) {
          selectedCategoryId = category.id;
          break;
        }
      }
    }

    state = state.copyWith(
      query: GuidelinesQuery(
        search: result.getValue<String>('search')?.trim() ?? '',
        selectedCategoryId: selectedCategoryId,
        selectedTagIds: _tagIdsFromFilterResult(result),
        selectedPriority: result.getValue<String>('priority')?.trim() ?? '',
        selectedHealthcareLevel:
            result.getValue<String>('healthcareLevel')?.trim() ?? '',
        selectedTargetPopulation:
            result.getValue<String>('targetPopulation')?.trim() ?? '',
        showHighPriorityOnly:
            result.getValue<bool>('showHighPriorityOnly') ?? false,
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // FILTER OPTIONS
  // ======================================================

  Future<void> _loadFilterOptions() async {
    state = state.copyWith(isLoadingFilters: true, clearFilterError: true);

    try {
      final results = await Future.wait([
        getGuidelineCategories(),
        getGuidelineTags(),
      ]);

      state = state.copyWith(
        availableCategories: List<GuidelineCategory>.unmodifiable(
          results[0] as List<GuidelineCategory>,
        ),
        availableTags: List<GuidelineTag>.unmodifiable(
          results[1] as List<GuidelineTag>,
        ),
      );
    } catch (error) {
      state = state.copyWith(filterError: error.toString());
    } finally {
      state = state.copyWith(isLoadingFilters: false);
    }
  }

  Future<void> reloadFilterOptions() {
    return _loadFilterOptions();
  }

  Future<List<GuidelineCategory>> getGuidelineCategories() async {
    final result = await _contentRepository.categories();

    return result.items;
  }

  Future<List<GuidelineTag>> getGuidelineTags() async {
    final result = await _contentRepository.tags();

    return result.items;
  }

  // ======================================================
  // FILTER HELPERS
  // ======================================================

  String? _categoryNameForId(String id) {
    for (final category in state.availableCategories) {
      if (category.id == id) {
        return category.displayName;
      }
    }

    return null;
  }

  List<String> _tagNamesForIds(List<String> ids) {
    final selected = ids.toSet();

    return state.availableTags
        .where((tag) => selected.contains(tag.id))
        .map((tag) => tag.displayName)
        .toList(growable: false);
  }

  List<String> _tagIdsFromFilterResult(FilterResult result) {
    final values = result.getValue<List>('tags') ?? const [];

    final selectedNames = values.map((value) => value.toString()).toSet();

    if (selectedNames.isEmpty) {
      return const [];
    }

    return state.availableTags
        .where((tag) => selectedNames.contains(tag.displayName))
        .map((tag) => tag.id)
        .toList(growable: false);
  }

  List<String> _resolveEmergencyCategoryIds() {
    return state.availableCategories
        .where(
          (category) => emergencyCategoryNames.contains(
            category.displayName.trim().toLowerCase(),
          ),
        )
        .map((category) => category.id)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  // ======================================================
  // REFRESH
  // ======================================================

  void refreshData() {
    pagingController.refresh();
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

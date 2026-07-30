import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/abbreviation_usage_log.dart';
import 'package:user_app/app/data/models/guideline_category.dart';
import 'package:user_app/app/data/models/guideline_tag.dart';

import '../../data/models/abbreviation.dart';
import '../../data/models/filter_models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import 'widgets/abbreviation_detail_modal.dart';

/// ===============================
/// QUERY MODEL (CLEAN STATE)
/// ===============================
class AbbreviationQuery {
  final String search;
  final String? categoryId;
  final List<String> tagIds;
  final bool showCommonOnly;

  const AbbreviationQuery({
    this.search = '',
    this.categoryId,
    this.tagIds = const [],
    this.showCommonOnly = false,
  });

  bool get hasFilters =>
      search.isNotEmpty ||
      categoryId != null ||
      tagIds.isNotEmpty ||
      showCommonOnly;

  AbbreviationQuery copyWith({
    String? search,
    String? categoryId,
    List<String>? tagIds,
    bool? showCommonOnly,
  }) {
    return AbbreviationQuery(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      showCommonOnly: showCommonOnly ?? this.showCommonOnly,
    );
  }

  static const empty = AbbreviationQuery();
}

/// ===============================
/// CONTROLLER
/// ===============================
class AbbreviationsController extends GetxController {
  late final PagingController<int, Abbreviation> pagingController;

  final Rx<AbbreviationQuery> query = AbbreviationQuery.empty.obs;

  final RxList<GuidelineCategory> availableCategories =
      <GuidelineCategory>[].obs;

  final RxList<GuidelineTag> availableTags = <GuidelineTag>[].obs;

  final RxBool isLoadingFilters = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();

    pagingController = PagingController(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );

    _loadFilterOptions();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    pagingController.dispose();
    super.onClose();
  }

  // ===============================
  // PAGINATION
  // ===============================
  Future<List<Abbreviation>> _loadPage(int pageKey) async {
    try {
      final q = query.value;

      if (q.showCommonOnly) {
        if (pageKey == 1) {
          return getCommonAbbreviations();
        }
        return [];
      }

      if (q.search.isNotEmpty || q.categoryId != null || q.tagIds.isNotEmpty) {
        return _searchAbbreviations(query: q, page: pageKey, perPage: pageSize);
      }

      return getAbbreviations(page: pageKey, perPage: pageSize);
    } catch (e) {
      Common.quickToast(title: 'errorLoadingAbbreviations'.tr);
      rethrow;
    }
  }

  // ===============================
  // FILTER UPDATE (CENTRALIZED)
  // ===============================
  void updateQuery(AbbreviationQuery newQuery) {
    query.value = newQuery;
    _refresh();
  }

  void clearAllFilters() {
    query.value = AbbreviationQuery.empty;
    _refresh();
  }

  void search(String value) {
    query.value = query.value.copyWith(search: value.trim());

    _debouncedRefresh();
  }

  void _debouncedRefresh() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), _refresh);
  }

  void _refresh() {
    pagingController.refresh();
  }

  // ===============================
  // FILTER OPTIONS
  // ===============================
  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      final categories = await getGuidelineCategories();

      final tags = await getGuidelineTags();

      availableCategories.value = categories;
      availableTags.value = tags;
    } finally {
      isLoadingFilters.value = false;
    }
  }

  // ===============================
  // FILTER UI
  // ===============================
  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) return;

    final q = query.value;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'filterAbbreviations'.tr,
      fields: [
        FilterField.text('search', 'search'.tr, hint: 'searchAbbreviations'.tr),
        FilterField.boolean('commonOnly', 'showCommonOnly'.tr),
      ],
      initialValues: {
        if (q.search.isNotEmpty) 'search': q.search,
        if (q.showCommonOnly) 'commonOnly': true,
      },
    );

    if (result == null) return;

    updateQuery(
      AbbreviationQuery(
        search: result.getValue<String>('search') ?? '',
        showCommonOnly: result.getValue<bool>('commonOnly') ?? false,
        categoryId: q.categoryId,
        tagIds: q.tagIds,
      ),
    );
  }

  // ===============================
  // DATA LAYER
  // ===============================
  Future<List<Abbreviation>> getAbbreviations({
    int page = 1,
    int perPage = 30,
  }) async {
    final result = await BackendApiService.to.getResourceList(
      collectionName: Abbreviation.collection,
      page: page,
      perPage: perPage,
      sort: '-created',
      expand: 'category,tags',
    );

    return result.items.map(Abbreviation.fromRecord).toList();
  }

  Future<List<Abbreviation>> getCommonAbbreviations() async {
    final result = await BackendApiService.to.getResourceList(
      collectionName: Abbreviation.collection,
      perPage: 50,
      filter: 'common_usage = true',
      sort: 'abbreviation',
      expand: 'category,tags',
    );

    return result.items.map(Abbreviation.fromRecord).toList();
  }

  Future<List<Abbreviation>> _searchAbbreviations({
    required AbbreviationQuery query,
    required int page,
    required int perPage,
  }) async {
    final filters = <String>[];

    if (query.search.isNotEmpty) {
      final q = BackendApiService.escapeFilterValue(query.search);
      filters.add(
        '(abbreviation ~ "$q" || '
        'meaning ~ "$q" || '
        'description ~ "$q")',
      );
    }

    if (query.categoryId != null) {
      final categoryId = BackendApiService.escapeFilterValue(query.categoryId);
      filters.add('category = "$categoryId"');
    }

    if (query.tagIds.isNotEmpty) {
      final tagFilter = query.tagIds
          .map((e) => 'tags ~ "${BackendApiService.escapeFilterValue(e)}"')
          .join(' || ');

      filters.add('($tagFilter)');
    }

    final result = await BackendApiService.to.getResourceList(
      collectionName: Abbreviation.collection,
      page: page,
      perPage: perPage,
      filter: filters.isEmpty ? null : filters.join(' && '),
      sort: 'abbreviation',
      expand: 'category,tags',
    );

    return result.items.map(Abbreviation.fromRecord).toList();
  }

  // ===============================
  // DETAIL + TRACKING
  // ===============================
  Future<void> showAbbreviationDetail(
    BuildContext context,
    Abbreviation abbreviation,
  ) async {
    _trackUsage(abbreviation.id);

    await AbbreviationDetailModal.show(context, abbreviation);
  }

  Future<void> _trackUsage(String id) async {
    try {
      final user = AuthService.to.currentUser.value;

      if (user == null) return;

      await BackendApiService.to.createResource(
        collectionName: AbbreviationUsageLog.collection,
        data: AbbreviationUsageLog.forCreate(
          userId: user.id,
          abbreviationId: id,
        ),
      );

      await BackendApiService.to.incrementUsageCount(
        Abbreviation.collection,
        id,
      );
    } catch (_) {}
  }

  /// Get all guideline categories
  Future<List<GuidelineCategory>> getGuidelineCategories({
    String? filter,
    String? sort,
  }) async {
    final result = await BackendApiService.to.getResourceList(
      collectionName: GuidelineCategory.collection,
      filter: filter ?? 'status = "active"',
      sort: sort ?? 'sort_order,name',
      expand: 'parent_category',
    );
    return result.items
        .map((record) => GuidelineCategory.fromRecord(record))
        .toList();
  }

  /// Get all guideline tags
  Future<List<GuidelineTag>> getGuidelineTags({
    String? filter,
    String? sort,
  }) async {
    final result = await BackendApiService.to.getResourceList(
      collectionName: GuidelineTag.collection,
      filter: filter,
      sort: sort ?? 'name',
    );
    return result.items
        .map((record) => GuidelineTag.fromRecord(record))
        .toList();
  }
}

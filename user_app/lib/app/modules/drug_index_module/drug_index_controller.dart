import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/models/filter_models.dart';
import '../../data/services/backend_api_service.dart';
import '../../translations/app_translations.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import 'widgets/drug_details_bottom_sheet.dart';

class DrugIndexController extends GetxController {
  final BackendApiService _apiService = BackendApiService.to;

  late final PagingController<int, Drug> pagingController;

  // =========================
  // FILTER STATE
  // =========================
  final RxString searchQuery = ''.obs;
  final RxBool hasActiveFilters = false.obs;

  final RxList<String> selectedCategories = <String>[].obs;
  final RxList<String> selectedTags = <String>[].obs;
  final RxList<String> selectedRoutes = <String>[].obs;
  final RxList<String> selectedPregnancyCategories = <String>[].obs;

  final RxBool whoEmlOnly = false.obs;
  final RxBool antimicrobialOnly = false.obs;

  // =========================
  // FILTER OPTIONS
  // =========================
  final RxList<String> categories = <String>[].obs;
  final RxList<String> tags = <String>[].obs;
  final RxList<String> routes = <String>[].obs;
  final RxList<String> pregnancyCategories = <String>[].obs;
  final RxBool isLoadingFilters = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initPaging();
    _loadFilterOptions();
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  // =========================
  // PAGINATION
  // =========================
  void _initPaging() {
    pagingController = PagingController<int, Drug>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchDrugsPage,
    );
  }

  Future<List<Drug>> _fetchDrugsPage(int pageKey) async {
    try {
      final drugs = await getDrugs(
        page: pageKey,
        perPage: pageSize,
        filter: _buildFilter(),
        sort: 'name',
        expand: 'categories,tags,therapeutic_category',
      );

      return drugs;
    } catch (e) {
      Common.quickToast(title: 'failedToLoadDrugs'.tr);
      rethrow;
    }
  }

  // =========================
  // FILTER OPTIONS
  // =========================
  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      final categoriesResult = await _apiService.getRecordList(
        collectionName: DrugCategory.collection,
        page: 1,
        perPage: 100,
        sort: 'name',
      );

      categories.value = categoriesResult.items
          .map((r) => r.data['name'] as String)
          .toList();

      final tagsResult = await _apiService.getRecordList(
        collectionName: DrugTag.collection,
        page: 1,
        perPage: 100,
        sort: 'name',
      );

      tags.value = tagsResult.items
          .map((r) => r.data['name'] as String)
          .toList();

      routes.value = [
        'oral',
        'IV',
        'IM',
        'topical',
        'inhaled',
        'sublingual',
        'rectal',
        'transdermal',
        'intranasal',
        'subcutaneous',
      ];

      pregnancyCategories.value = ['A', 'B', 'C', 'D', 'X', 'Unknown'];
    } catch (e) {
      Common.quickToast(title: 'errorLoadingFilters'.tr);
    } finally {
      isLoadingFilters.value = false;
    }
  }

  // =========================
  // FILTER BUILDER
  // =========================
  String _buildFilter() {
    final parts = <String>['status = "active"'];

    if (searchQuery.value.isNotEmpty) {
      final q = BackendApiService.escapeFilterValue(searchQuery.value);
      parts.add('(name ~ "$q" || generic_name ~ "$q" || brand_names ~ "$q")');
    }

    if (selectedCategories.isNotEmpty) {
      parts.add(
        '(${selectedCategories.map((e) => 'categories ~ "${BackendApiService.escapeFilterValue(e)}"').join(' || ')})',
      );
    }

    if (selectedTags.isNotEmpty) {
      parts.add(
        '(${selectedTags.map((e) => 'tags ~ "${BackendApiService.escapeFilterValue(e)}"').join(' || ')})',
      );
    }

    if (selectedRoutes.isNotEmpty) {
      parts.add(
        '(${selectedRoutes.map((e) => 'route_of_administration ~ "${BackendApiService.escapeFilterValue(e)}"').join(' || ')})',
      );
    }

    if (selectedPregnancyCategories.isNotEmpty) {
      parts.add(
        '(${selectedPregnancyCategories.map((e) => 'pregnancy_category ~ "${BackendApiService.escapeFilterValue(e)}"').join(' || ')})',
      );
    }

    if (whoEmlOnly.value) parts.add('who_eml_status = true');
    if (antimicrobialOnly.value) parts.add('antimicrobial_status = true');

    return parts.join(' && ');
  }

  // =========================
  // FILTER STATE
  // =========================
  void _updateActiveFilters() {
    hasActiveFilters.value =
        searchQuery.value.isNotEmpty ||
        selectedCategories.isNotEmpty ||
        selectedTags.isNotEmpty ||
        selectedRoutes.isNotEmpty ||
        selectedPregnancyCategories.isNotEmpty ||
        whoEmlOnly.value ||
        antimicrobialOnly.value;
  }

  // =========================
  // ACTIONS
  // =========================
  Future<void> refreshData() async {
    pagingController.refresh();
  }

  void clearAllFilters() {
    searchQuery.value = '';

    selectedCategories.clear();
    selectedTags.clear();
    selectedRoutes.clear();
    selectedPregnancyCategories.clear();

    whoEmlOnly.value = false;
    antimicrobialOnly.value = false;

    hasActiveFilters.value = false;

    pagingController.refresh();
  }

  void toggleCategory(String value) {
    selectedCategories.contains(value)
        ? selectedCategories.remove(value)
        : selectedCategories.add(value);

    _updateActiveFilters();
    pagingController.refresh();
  }

  void toggleTag(String value) {
    selectedTags.contains(value)
        ? selectedTags.remove(value)
        : selectedTags.add(value);

    _updateActiveFilters();
    pagingController.refresh();
  }

  void toggleRoute(String value) {
    selectedRoutes.contains(value)
        ? selectedRoutes.remove(value)
        : selectedRoutes.add(value);

    _updateActiveFilters();
    pagingController.refresh();
  }

  void togglePregnancyCategory(String value) {
    selectedPregnancyCategories.contains(value)
        ? selectedPregnancyCategories.remove(value)
        : selectedPregnancyCategories.add(value);

    _updateActiveFilters();
    pagingController.refresh();
  }

  void toggleWhoEml() {
    whoEmlOnly.value = !whoEmlOnly.value;
    _updateActiveFilters();
    pagingController.refresh();
  }

  void toggleAntimicrobial() {
    antimicrobialOnly.value = !antimicrobialOnly.value;
    _updateActiveFilters();
    pagingController.refresh();
  }

  // =========================
  // FILTER MODAL
  // =========================
  Future<void> showFilterModal(BuildContext context) async {
    if (categories.isEmpty || tags.isEmpty) {
      await _loadFilterOptions();
    }

    if (!context.mounted) {
      return;
    }

    final fields = <FilterField>[
      FilterField.text('search', 'search'.tr),
      FilterField.boolean('whoEmlOnly', AppTranslationKey.whoEmlOnly),
      FilterField.boolean(
        'antimicrobialOnly',
        AppTranslationKey.antimicrobialOnly,
      ),
      FilterField.multiSelect('categories', 'categories'.tr, categories),
      FilterField.multiSelect('tags', 'tags'.tr, tags),
      FilterField.multiSelect('routes', 'routes'.tr, routes),
      FilterField.multiSelect(
        'pregnancyCategories',
        'pregnancyCategories'.tr,
        pregnancyCategories,
      ),
    ];

    final initial = <String, dynamic>{
      if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
      if (whoEmlOnly.value) 'whoEmlOnly': true,
      if (antimicrobialOnly.value) 'antimicrobialOnly': true,
      if (selectedCategories.isNotEmpty) 'categories': selectedCategories,
      if (selectedTags.isNotEmpty) 'tags': selectedTags,
      if (selectedRoutes.isNotEmpty) 'routes': selectedRoutes,
      if (selectedPregnancyCategories.isNotEmpty)
        'pregnancyCategories': selectedPregnancyCategories,
    };

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: AppTranslationKey.filterDrugs,
      fields: fields,
      initialValues: initial,
    );

    if (result != null && result.isNotEmpty) {
      _applyFilters(result);
    }
  }

  void _applyFilters(FilterResult result) {
    clearAllFilters();

    searchQuery.value = result.getValue<String>('search') ?? '';

    whoEmlOnly.value = result.getValue<bool>('whoEmlOnly') ?? false;
    antimicrobialOnly.value =
        result.getValue<bool>('antimicrobialOnly') ?? false;

    selectedCategories.addAll(
      (result.getValue<List>('categories') ?? []).cast<String>(),
    );

    selectedTags.addAll((result.getValue<List>('tags') ?? []).cast<String>());

    selectedRoutes.addAll(
      (result.getValue<List>('routes') ?? []).cast<String>(),
    );

    selectedPregnancyCategories.addAll(
      (result.getValue<List>('pregnancyCategories') ?? []).cast<String>(),
    );

    _updateActiveFilters();
    pagingController.refresh();
  }

  // =========================
  // API
  // =========================
  Future<List<Drug>> getDrugs({
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    final result = await _apiService.getRecordList(
      collectionName: Drug.collection,
      page: page,
      perPage: perPage,
      filter: filter,
      sort: sort,
      expand: expand,
    );

    return result.items.map((e) => Drug.fromRecord(e)).toList();
  }

  Future<void> navigateToDrugDetail(Drug drug) async {
    final context = Get.context;
    if (context == null) return;

    await DrugDetailsBottomSheet.show(context: context, drug: drug);
  }

  void toggleBookmark(Drug drug) {
    Common.quickToast(title: 'Bookmark toggled for ${drug.name}');
  }
}

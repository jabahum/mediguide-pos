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
      final drugs = await getDrugs(page: pageKey, perPage: pageSize);

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

      final categoriesResult = await _apiService.getResourceList(
        collectionName: DrugCategory.collection,
        page: 1,
        perPage: 100,
        sort: 'name',
      );

      categories.value = categoriesResult.items
          .map((r) => r.data['name'] as String)
          .toList();

      final tagsResult = await _apiService.getResourceList(
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
  Future<List<Drug>> getDrugs({int page = 1, int perPage = 30}) async {
    final result = await _apiService.getDrugs(
      page: page,
      perPage: perPage,
      search: searchQuery.value,
      status: 'active',
      route: selectedRoutes.length == 1 ? selectedRoutes.single : null,
      pregnancyCategory: selectedPregnancyCategories.length == 1
          ? selectedPregnancyCategories.single
          : null,
      whoEml: whoEmlOnly.value ? true : null,
      antimicrobial: antimicrobialOnly.value ? true : null,
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

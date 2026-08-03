import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/models/filter_models.dart';
import '../../data/repositories/drug_reference_repository.dart';
import '../../data/repositories/calculator_repository.dart';
import '../../providers/core_providers.dart';
import '../../translations/app_translations.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import 'widgets/drug_details_bottom_sheet.dart';

final drugIndexControllerProvider = ChangeNotifierProvider.autoDispose((ref) {
  return DrugIndexController(
    ref.watch(drugReferenceRepositoryProvider),
    ref.watch(drugRepositoryProvider),
  );
});

class DrugIndexController extends ChangeNotifier {
  DrugIndexController(this._references, this._drugs) {
    _initPaging();
    _loadFilterOptions();
  }

  final DrugReferenceRepository _references;
  final DrugRepository _drugs;

  late final PagingController<int, Drug> pagingController;

  // =========================
  // FILTER STATE
  // =========================
  String searchQuery = '';
  bool hasActiveFilters = false;

  List<String> selectedCategories = [];
  List<String> selectedTags = [];
  List<String> selectedRoutes = [];
  List<String> selectedPregnancyCategories = [];

  bool whoEmlOnly = false;
  bool antimicrobialOnly = false;

  // =========================
  // FILTER OPTIONS
  // =========================
  List<String> categories = [];
  List<String> tags = [];
  List<String> routes = [];
  List<String> pregnancyCategories = [];
  bool isLoadingFilters = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    pagingController.dispose();
    super.dispose();
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
      isLoadingFilters = true;

      categories = await _references.categoryNames();
      tags = await _references.tagNames();

      routes = [
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

      pregnancyCategories = ['A', 'B', 'C', 'D', 'X', 'Unknown'];
    } catch (e) {
      Common.quickToast(title: 'errorLoadingFilters'.tr);
    } finally {
      isLoadingFilters = false;
      if (!_disposed) notifyListeners();
    }
  }

  // =========================
  // FILTER STATE
  // =========================
  void _updateActiveFilters() {
    hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedCategories.isNotEmpty ||
        selectedTags.isNotEmpty ||
        selectedRoutes.isNotEmpty ||
        selectedPregnancyCategories.isNotEmpty ||
        whoEmlOnly ||
        antimicrobialOnly;
    if (!_disposed) notifyListeners();
  }

  // =========================
  // ACTIONS
  // =========================
  Future<void> refreshData() async {
    pagingController.refresh();
  }

  void clearAllFilters() {
    searchQuery = '';

    selectedCategories.clear();
    selectedTags.clear();
    selectedRoutes.clear();
    selectedPregnancyCategories.clear();

    whoEmlOnly = false;
    antimicrobialOnly = false;

    hasActiveFilters = false;
    if (!_disposed) notifyListeners();
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
    whoEmlOnly = !whoEmlOnly;
    _updateActiveFilters();
    pagingController.refresh();
  }

  void toggleAntimicrobial() {
    antimicrobialOnly = !antimicrobialOnly;
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
      if (searchQuery.isNotEmpty) 'search': searchQuery,
      if (whoEmlOnly) 'whoEmlOnly': true,
      if (antimicrobialOnly) 'antimicrobialOnly': true,
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

    searchQuery = result.getValue<String>('search') ?? '';

    whoEmlOnly = result.getValue<bool>('whoEmlOnly') ?? false;
    antimicrobialOnly = result.getValue<bool>('antimicrobialOnly') ?? false;

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
    final result = await _drugs.list(
      page: page,
      perPage: perPage,
      search: searchQuery,
      status: 'active',
      route: selectedRoutes.length == 1 ? selectedRoutes.single : null,
      pregnancyCategory: selectedPregnancyCategories.length == 1
          ? selectedPregnancyCategories.single
          : null,
      whoEml: whoEmlOnly ? true : null,
      antimicrobial: antimicrobialOnly ? true : null,
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

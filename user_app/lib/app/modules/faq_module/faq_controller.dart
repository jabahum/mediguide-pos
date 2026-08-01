import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/models/filter_models.dart';
import '../../data/repositories/help_content_repository.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import '../../translations/app_translations.dart';

class FaqController extends GetxController {
  HelpContentRepository get _repository =>
      HelpContentRepository(BackendApiService.to);
  // Reactive state
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasActiveFilters = false.obs;

  // Pagination
  late PagingController<int, FAQ> pagingController;

  @override
  void onInit() {
    super.onInit();
    initializePagination();
    setupSearchListener();
  }

  void initializePagination() {
    pagingController = PagingController<int, FAQ>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : (state.keys?.last ?? 0) + 1,
      fetchPage: (pageKey) => loadAllFAQs(pageKey),
    );
  }

  void setupSearchListener() {
    debounce(
      searchQuery,
      (_) => pagingController.refresh(),
      time: const Duration(milliseconds: 500),
    );

    ever(searchQuery, (_) => _updateActiveFilters());
  }

  void _updateActiveFilters() {
    hasActiveFilters.value = searchQuery.value.isNotEmpty;
  }

  // =========================
  // DATA LOADING
  // =========================

  Future<List<FAQ>> loadAllFAQs(int pageKey) async {
    try {
      final result = searchQuery.value.isNotEmpty
          ? await _searchFAQs(
              query: searchQuery.value,
              page: pageKey,
              perPage: pageSize,
            )
          : await _getFAQs(page: pageKey, perPage: pageSize);

      return result.items;
    } catch (error) {
      Common.quickToast(
        title: AppTranslationKey.error.tr,
        description: 'Failed to load FAQs: $error',
      );
      rethrow;
    }
  }

  Future<PagedResult<FAQ>> _getFAQs({int page = 1, int perPage = 10}) async {
    return _repository.listFAQs(page: page, perPage: perPage);
  }

  Future<PagedResult<FAQ>> _searchFAQs({
    required String query,
    int page = 1,
    int perPage = 10,
  }) async {
    return _repository.listFAQs(page: page, perPage: perPage, search: query);
  }

  // =========================
  // ACTIONS
  // =========================

  void searchFAQs(String query) {
    searchQuery.value = query.trim();
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  void clearAllFilters() {
    searchQuery.value = '';
    hasActiveFilters.value = false;
    pagingController.refresh();
  }

  void refreshFAQs() {
    pagingController.refresh();
  }

  void retryLastFailedRequest() {
    pagingController.refresh();
  }

  // =========================
  // FILTER BOTTOM SHEET
  // =========================

  Future<void> showFilterModal(BuildContext context) async {
    final fields = <FilterField>[
      FilterField.text('search', 'search'.tr, hint: 'searchFAQs'.tr),
    ];

    final values = <String, dynamic>{};
    if (searchQuery.value.isNotEmpty) {
      values['search'] = searchQuery.value;
    }

    if (!context.mounted) return;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'searchFAQs'.tr,
      fields: fields,
      initialValues: values,
    );

    if (result != null && result.isNotEmpty) {
      _applyFilters(result);
    }
  }

  void _applyFilters(FilterResult result) {
    searchQuery.value = '';

    final search = result.getValue<String>('search');
    if (search != null && search.isNotEmpty) {
      searchQuery.value = search;
    }

    _updateActiveFilters();
    pagingController.refresh();
  }

  // =========================
  // DETAILS
  // =========================

  Future<List<FAQ>> getFeaturedFAQs({int limit = 5}) async {
    final result = await _repository.listFAQs(
      page: 1,
      perPage: limit,
      featured: true,
    );

    return result.items;
  }

  Future<FAQ?> getFAQById({required String faqId}) async {
    return _repository.getFAQ(faqId);
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }
}

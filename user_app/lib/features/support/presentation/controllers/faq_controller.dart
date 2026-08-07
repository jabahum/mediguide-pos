import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/features/support/data/repositories/help_content_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';
import 'package:user_app/l10n/app_translations.dart';

final faqControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => FaqController(ref.watch(helpContentRepositoryProvider)),
);

class FaqController extends ChangeNotifier {
  FaqController(this._repository) {
    initializePagination();
  }

  final HelpContentRepository _repository;
  bool isLoading = false;
  String searchQuery = '';
  bool hasActiveFilters = false;
  Timer? _debounce;

  // Pagination
  late PagingController<int, FAQ> pagingController;

  void initializePagination() {
    pagingController = PagingController<int, FAQ>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : (state.keys?.last ?? 0) + 1,
      fetchPage: (pageKey) => loadAllFAQs(pageKey),
    );
  }

  void _updateActiveFilters() {
    hasActiveFilters = searchQuery.isNotEmpty;
    notifyListeners();
  }

  // =========================
  // DATA LOADING
  // =========================

  Future<List<FAQ>> loadAllFAQs(int pageKey) async {
    try {
      final result = searchQuery.isNotEmpty
          ? await _searchFAQs(
              query: searchQuery,
              page: pageKey,
              perPage: AppConstants.pageSize,
            )
          : await _getFAQs(page: pageKey, perPage: AppConstants.pageSize);

      return result.items;
    } catch (error) {
      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'Failed to load FAQs: $error',
      );

      rethrow;
    }
  }

  Future<PaginatedResponse<FAQ>> _getFAQs({
    int page = 1,
    int perPage = 10,
  }) async {
    return _repository.listFAQs(page: page, perPage: perPage);
  }

  Future<PaginatedResponse<FAQ>> _searchFAQs({
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
    searchQuery = query.trim();
    _updateActiveFilters();
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      pagingController.refresh,
    );
  }

  void clearSearch() {
    searchQuery = '';
    _updateActiveFilters();
    pagingController.refresh();
  }

  void clearAllFilters() {
    searchQuery = '';
    hasActiveFilters = false;
    notifyListeners();
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
    if (searchQuery.isNotEmpty) {
      values['search'] = searchQuery;
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
    searchQuery = '';

    final search = result.getValue<String>('search');
    if (search != null && search.isNotEmpty) {
      searchQuery = search;
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
  void dispose() {
    _debounce?.cancel();
    pagingController.dispose();
    super.dispose();
  }
}

// faq_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/support/data/repositories/help_content_repository.dart';
import 'package:user_app/features/support/presentation/controllers/faq_state.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'faq_controller.g.dart';

@riverpod
class FaqController extends _$FaqController {
  Timer? _debounce;

  late final PagingController<int, FAQ> pagingController;

  HelpContentRepository get _repository =>
      ref.read(helpContentRepositoryProvider);

  @override
  FaqState build() {
    pagingController = PagingController<int, FAQ>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: loadAllFAQs,
    );

    ref.onDispose(() {
      _debounce?.cancel();
      pagingController.dispose();
    });

    return const FaqState();
  }

  // ======================================================
  // DATA LOADING
  // ======================================================

  Future<List<FAQ>> loadAllFAQs(int pageKey) async {
    try {
      final query = state.searchQuery.trim();

      final result = query.isNotEmpty
          ? await _searchFAQs(
              query: query,
              page: pageKey,
              perPage: AppConstants.pageSize,
            )
          : await _getFAQs(page: pageKey, perPage: AppConstants.pageSize);

      return result.items;
    } catch (error) {
      _showError('Failed to load FAQs: $error');

      rethrow;
    }
  }

  Future<PaginatedResponse<FAQ>> _getFAQs({int page = 1, int perPage = 10}) {
    return _repository.listFAQs(page: page, perPage: perPage);
  }

  Future<PaginatedResponse<FAQ>> _searchFAQs({
    required String query,
    int page = 1,
    int perPage = 10,
  }) {
    return _repository.listFAQs(page: page, perPage: perPage, search: query);
  }

  // ======================================================
  // SEARCH
  // ======================================================

  void searchFAQs(String query) {
    state = state.copyWith(searchQuery: query.trim());

    _scheduleRefresh();
  }

  void clearSearch() {
    _debounce?.cancel();

    state = const FaqState();

    pagingController.refresh();
  }

  void clearAllFilters() {
    clearSearch();
  }

  // ======================================================
  // REFRESH
  // ======================================================

  void refreshFAQs() {
    pagingController.refresh();
  }

  void retryLastFailedRequest() {
    pagingController.refresh();
  }

  void _scheduleRefresh() {
    _debounce?.cancel();

    _debounce = Timer(AppConstants.searchDebounce, pagingController.refresh);
  }

  // ======================================================
  // FILTER BOTTOM SHEET
  // ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'searchFAQs'.tr,
      fields: [FilterField.text('search', 'search'.tr, hint: 'searchFAQs'.tr)],
      initialValues: {
        if (state.searchQuery.isNotEmpty) 'search': state.searchQuery,
      },
    );

    if (result == null) {
      return;
    }

    _applyFilters(result);
  }

  void _applyFilters(FilterResult result) {
    state = state.copyWith(
      searchQuery: result.getValue<String>('search')?.trim() ?? '',
    );

    pagingController.refresh();
  }

  // ======================================================
  // DETAILS
  // ======================================================

  Future<List<FAQ>> getFeaturedFAQs({int limit = 5}) async {
    final result = await _repository.listFAQs(
      page: 1,
      perPage: limit,
      featured: true,
    );

    return result.items;
  }

  Future<FAQ?> getFAQById({required String faqId}) {
    return _repository.getFAQ(faqId);
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

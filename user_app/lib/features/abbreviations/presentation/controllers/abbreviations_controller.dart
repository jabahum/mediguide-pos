import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
import 'package:user_app/features/abbreviations/presentation/widgets/abbreviation_detail_modal.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

import 'package:user_app/features/guidelines/data/models/guideline_category.dart';
import 'package:user_app/features/guidelines/data/models/guideline_tag.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'abbreviations_controller.g.dart';

/// ======================================================
/// QUERY
/// ======================================================

class AbbreviationQuery {
  const AbbreviationQuery({
    this.search = '',
    this.categoryId,
    this.tagIds = const [],
    this.showCommonOnly = false,
  });

  final String search;
  final String? categoryId;
  final List<String> tagIds;
  final bool showCommonOnly;

  static const empty = AbbreviationQuery();

  bool get hasFilters =>
      search.isNotEmpty ||
      categoryId != null ||
      tagIds.isNotEmpty ||
      showCommonOnly;

  AbbreviationQuery copyWith({
    String? search,
    String? categoryId,
    bool clearCategory = false,
    List<String>? tagIds,
    bool? showCommonOnly,
  }) {
    return AbbreviationQuery(
      search: search ?? this.search,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      showCommonOnly: showCommonOnly ?? this.showCommonOnly,
    );
  }
}

/// ======================================================
/// STATE
/// ======================================================

class AbbreviationsState {
  const AbbreviationsState({
    this.query = AbbreviationQuery.empty,
    this.availableCategories = const [],
    this.availableTags = const [],
    this.isLoadingFilters = false,
  });

  final AbbreviationQuery query;

  final List<GuidelineCategory> availableCategories;

  final List<GuidelineTag> availableTags;

  final bool isLoadingFilters;

  AbbreviationsState copyWith({
    AbbreviationQuery? query,
    List<GuidelineCategory>? availableCategories,
    List<GuidelineTag>? availableTags,
    bool? isLoadingFilters,
  }) {
    return AbbreviationsState(
      query: query ?? this.query,
      availableCategories: availableCategories ?? this.availableCategories,
      availableTags: availableTags ?? this.availableTags,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
    );
  }
}

/// ======================================================
/// CONTROLLER
/// ======================================================

@riverpod
class AbbreviationsController extends _$AbbreviationsController {
  Timer? _debounce;

  late final PagingController<int, Abbreviation> pagingController;

  GuidelineContentRepository get _contentRepository =>
      ref.read(guidelineContentRepositoryProvider);

  UsageRepository get _usageRepository => ref.read(usageRepositoryProvider);

  bool get _canTrackUsage =>
      ref.read(authControllerProvider).valueOrNull?.user != null;

  @override
  AbbreviationsState build() {
    pagingController = PagingController<int, Abbreviation>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: _loadPage,
    );

    ref.onDispose(() {
      _debounce?.cancel();
      pagingController.dispose();
    });

    Future.microtask(_loadFilterOptions);

    return const AbbreviationsState();
  }

  // ======================================================
  // PAGINATION
  // ======================================================

  Future<List<Abbreviation>> _loadPage(int pageKey) async {
    try {
      final query = state.query;

      if (query.showCommonOnly) {
        if (pageKey == 1) {
          return getCommonAbbreviations();
        }

        return [];
      }

      if (query.search.isNotEmpty ||
          query.categoryId != null ||
          query.tagIds.isNotEmpty) {
        return _searchAbbreviations(
          query: query,
          page: pageKey,
          perPage: AppConstants.pageSize,
        );
      }

      return getAbbreviations(page: pageKey, perPage: AppConstants.pageSize);
    } catch (error) {
      final context = AppKeys.navigatorKey.currentContext;

      if (context != null) {
        AppMessage.error(context, error.toString());
      }

      rethrow;
    }
  }

  // ======================================================
  // QUERY / FILTER STATE
  // ======================================================

  void updateQuery(AbbreviationQuery query) {
    state = state.copyWith(query: query);

    refresh();
  }

  void clearAllFilters() {
    state = state.copyWith(query: AbbreviationQuery.empty);

    refresh();
  }

  void search(String value) {
    final updatedQuery = state.query.copyWith(search: value.trim());

    state = state.copyWith(query: updatedQuery);

    _debouncedRefresh();
  }

  void setCategory(String? categoryId) {
    final updatedQuery = categoryId == null
        ? state.query.copyWith(clearCategory: true)
        : state.query.copyWith(categoryId: categoryId);

    state = state.copyWith(query: updatedQuery);

    refresh();
  }

  void setTags(List<String> tagIds) {
    state = state.copyWith(query: state.query.copyWith(tagIds: tagIds));

    refresh();
  }

  void setCommonOnly(bool value) {
    state = state.copyWith(query: state.query.copyWith(showCommonOnly: value));

    refresh();
  }

  void _debouncedRefresh() {
    _debounce?.cancel();

    _debounce = Timer(AppConstants.searchDebounce, refresh);
  }

  void refresh() {
    pagingController.refresh();
  }

  // ======================================================
  // FILTER OPTIONS
  // ======================================================

  Future<void> _loadFilterOptions() async {
    state = state.copyWith(isLoadingFilters: true);

    try {
      final results = await Future.wait([
        getGuidelineCategories(),
        getGuidelineTags(),
      ]);

      state = state.copyWith(
        availableCategories: results[0] as List<GuidelineCategory>,
        availableTags: results[1] as List<GuidelineTag>,
      );
    } catch (error) {
      final context = AppKeys.navigatorKey.currentContext;

      if (context != null) {
        AppMessage.error(context, 'Unable to load filter options: $error');
      }
    } finally {
      state = state.copyWith(isLoadingFilters: false);
    }
  }

  Future<void> reloadFilterOptions() async {
    await _loadFilterOptions();
  }

  // ======================================================
  // FILTER UI
  // ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) return;

    final query = state.query;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'filterAbbreviations'.tr,
      fields: [
        FilterField.text('search', 'search'.tr, hint: 'searchAbbreviations'.tr),
        FilterField.boolean('commonOnly', 'showCommonOnly'.tr),
      ],
      initialValues: {
        if (query.search.isNotEmpty) 'search': query.search,
        if (query.showCommonOnly) 'commonOnly': true,
      },
    );

    if (result == null) return;

    updateQuery(
      AbbreviationQuery(
        search: result.getValue<String>('search')?.trim() ?? '',
        showCommonOnly: result.getValue<bool>('commonOnly') ?? false,
        categoryId: query.categoryId,
        tagIds: query.tagIds,
      ),
    );
  }

  // ======================================================
  // ABBREVIATIONS
  // ======================================================

  Future<List<Abbreviation>> getAbbreviations({
    int page = 1,
    int perPage = 30,
  }) async {
    final result = await _contentRepository.abbreviations(
      page: page,
      perPage: perPage,
    );

    return result.items;
  }

  Future<List<Abbreviation>> getCommonAbbreviations() async {
    final result = await _contentRepository.abbreviations(
      page: 1,
      perPage: 50,
      commonUsage: true,
    );

    return result.items;
  }

  Future<List<Abbreviation>> _searchAbbreviations({
    required AbbreviationQuery query,
    required int page,
    required int perPage,
  }) async {
    final result = await _contentRepository.abbreviations(
      page: page,
      perPage: perPage,
      search: query.search.isEmpty ? null : query.search,
      categoryId: query.categoryId,
      tagId: query.tagIds.isEmpty ? null : query.tagIds.join(','),
    );

    return result.items;
  }

  // ======================================================
  // DETAIL
  // ======================================================

  Future<void> showAbbreviationDetail(
    BuildContext context,
    Abbreviation abbreviation,
  ) async {
    unawaited(_trackUsage(abbreviation.id));

    await AbbreviationDetailModal.show(context, abbreviation);
  }

  // ======================================================
  // USAGE TRACKING
  // ======================================================

  Future<void> _trackUsage(String id) async {
    if (!_canTrackUsage) return;

    try {
      await _usageRepository.abbreviation(id);
    } catch (_) {
      // Usage tracking should never interrupt
      // the user's clinical workflow.
    }
  }

  // ======================================================
  // FILTER DATA
  // ======================================================

  Future<List<GuidelineCategory>> getGuidelineCategories() async {
    final result = await _contentRepository.categories();

    return result.items;
  }

  Future<List<GuidelineTag>> getGuidelineTags() async {
    final result = await _contentRepository.tags();

    return result.items;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/features/guidelines/data/models/guideline_category.dart';
import 'package:user_app/features/guidelines/data/models/guideline_tag.dart';

import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';
import 'package:user_app/features/abbreviations/presentation/widgets/abbreviation_detail_modal.dart';

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
final abbreviationsControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => AbbreviationsController(
    ref.watch(usageRepositoryProvider),
    ref.watch(guidelineContentRepositoryProvider),
    canTrackUsage: ref.watch(authControllerProvider).valueOrNull?.user != null,
  ),
);

class AbbreviationsController extends ChangeNotifier {
  AbbreviationsController(
    this._usageRepository,
    this._contentRepository, {
    required this.canTrackUsage,
  }) {
    pagingController = PagingController(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );
    unawaited(_loadFilterOptions());
  }

  final UsageRepository _usageRepository;
  final GuidelineContentRepository _contentRepository;
  final bool canTrackUsage;
  late final PagingController<int, Abbreviation> pagingController;

  AbbreviationQuery query = AbbreviationQuery.empty;

  List<GuidelineCategory> availableCategories = [];

  List<GuidelineTag> availableTags = [];

  bool isLoadingFilters = false;

  Timer? _debounce;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    pagingController.dispose();
    super.dispose();
  }

  // ===============================
  // PAGINATION
  // ===============================
  Future<List<Abbreviation>> _loadPage(int pageKey) async {
    try {
      final q = query;

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
    query = newQuery;
    _notify();
    _refresh();
  }

  void clearAllFilters() {
    query = AbbreviationQuery.empty;
    _notify();
    _refresh();
  }

  void search(String value) {
    query = query.copyWith(search: value.trim());
    _notify();

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
      isLoadingFilters = true;
      _notify();

      final categories = await getGuidelineCategories();

      final tags = await getGuidelineTags();

      availableCategories = categories;
      availableTags = tags;
    } finally {
      isLoadingFilters = false;
      _notify();
    }
  }

  // ===============================
  // FILTER UI
  // ===============================
  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) return;

    final q = query;

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
    final result = await _contentRepository.abbreviations(
      page: page,
      perPage: perPage,
    );

    return result.items.map(Abbreviation.fromRecord).toList();
  }

  Future<List<Abbreviation>> getCommonAbbreviations() async {
    final result = await _contentRepository.abbreviations(
      perPage: 50,
      commonUsage: true,
    );

    return result.items.map(Abbreviation.fromRecord).toList();
  }

  Future<List<Abbreviation>> _searchAbbreviations({
    required AbbreviationQuery query,
    required int page,
    required int perPage,
  }) async {
    final result = await _contentRepository.abbreviations(
      page: page,
      perPage: perPage,
      search: query.search,
      categoryId: query.categoryId,
      tagId: query.tagIds.isEmpty ? null : query.tagIds.join(','),
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
      if (!canTrackUsage) return;

      await _usageRepository.abbreviation(id);
    } catch (_) {}
  }

  /// Get all guideline categories
  Future<List<GuidelineCategory>> getGuidelineCategories({
    String? filter,
    String? sort,
  }) async {
    final result = await _contentRepository.categories();
    return result.items
        .map((record) => GuidelineCategory.fromRecord(record))
        .toList();
  }

  /// Get all guideline tags
  Future<List<GuidelineTag>> getGuidelineTags({
    String? filter,
    String? sort,
  }) async {
    final result = await _contentRepository.tags();
    return result.items
        .map((record) => GuidelineTag.fromRecord(record))
        .toList();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

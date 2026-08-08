import 'package:user_app/features/guidelines/data/repositories/guildline_content_local_repository.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

import 'package:user_app/features/abbreviations/data/repositories/abbreviation_local_repository.dart';

final class GuidelineContentRepository {
  GuidelineContentRepository(this._api, this._local, this._abbreviationsLocal);

  final BackendApiService _api;
  final GuidelineContentLocalRepository _local;
  final AbbreviationLocalRepository _abbreviationsLocal;

  // =========================================================
  // GUIDELINES
  // =========================================================

  Future<PaginatedResponse<Guideline>> guidelines({
    int page = 1,
    int perPage = 30,
    String? search,
    String? status,
    String? categoryId,
    String? tagId,
    String? indexId,
    String? priority,
    String? healthcareLevel,
    String? targetPopulation,
    bool? published,
    String sort = 'updated_at',
    String order = 'desc',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    try {
      final response = await _typedList<Guideline>(
        '/api/v2/medical-guidelines',
        Guideline.fromJson,
        page: safePage,
        perPage: safePerPage,
        query: {
          if (_present(search)) 'search': search!.trim(),
          if (_present(status)) 'status': status!,
          if (_present(categoryId)) 'category_id': categoryId!,
          if (_present(tagId)) 'tag_id': tagId!,
          if (_present(indexId)) 'parent_id': indexId!,
          if (_present(priority)) 'priority': priority!,
          if (_present(healthcareLevel)) 'healthcare_level': healthcareLevel!,
          if (_present(targetPopulation))
            'target_population': targetPopulation!,
          if (published != null) 'is_published': '$published',
          'sort': sort,
          'order': order,
        },
      );

      // Cache successful remote data.
      try {
        await _local.saveGuidelines(response.items);
      } catch (_) {
        // Cache failure must not block valid server data.
      }

      return response;
    } catch (_) {
      final cached = await _local.getGuidelines(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        status: status ?? '',
        categoryIds: _splitIds(categoryId),
        tagIds: _splitIds(tagId),
        indexId: indexId ?? '',
        priority: priority ?? '',
        healthcareLevel: healthcareLevel ?? '',
        targetPopulation: targetPopulation ?? '',
        published: published,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return _offlinePage(items: cached, page: safePage, perPage: safePerPage);
    }
  }

  // =========================================================
  // GUIDELINE DETAIL
  // =========================================================

  Future<Guideline> guideline(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Guideline id is required');
    }

    try {
      final guideline = await _get<Guideline>(
        '/api/v2/medical-guidelines/$normalizedId',
        Guideline.fromJson,
      );

      try {
        await _local.saveGuideline(guideline);
      } catch (_) {
        // Best effort cache.
      }

      return guideline;
    } catch (_) {
      final cached = await _local.getGuideline(normalizedId);

      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  // =========================================================
  // CATEGORIES
  // =========================================================

  Future<PaginatedResponse<GuidelineCategory>> categories({
    int page = 1,
    int perPage = 100,
    String? search,
    String? status = 'active',
    String? parentId,
    bool rootOnly = false,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    try {
      final response = await _typedList<GuidelineCategory>(
        '/api/v2/guideline-categories',
        GuidelineCategory.fromJson,
        page: safePage,
        perPage: safePerPage,
        query: {
          if (_present(search)) 'search': search!.trim(),
          if (_present(status)) 'status': status!,
          if (_present(parentId)) 'parent_id': parentId!,
          if (rootOnly) 'root_only': 'true',
          'sort': 'sort_order',
          'order': 'asc',
        },
      );

      try {
        await _local.saveCategories(response.items);
      } catch (_) {}

      return response;
    } catch (_) {
      final cached = await _local.getCategories(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        status: status ?? '',
        parentId: parentId ?? '',
        rootOnly: rootOnly,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return _offlinePage(items: cached, page: safePage, perPage: safePerPage);
    }
  }

  // =========================================================
  // TAGS
  // =========================================================

  Future<PaginatedResponse<GuidelineTag>> tags({
    int page = 1,
    int perPage = 100,
    String? search,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    try {
      final response = await _typedList<GuidelineTag>(
        '/api/v2/guideline-tags',
        GuidelineTag.fromJson,
        page: safePage,
        perPage: safePerPage,
        query: {
          if (_present(search)) 'search': search!.trim(),
          'sort': 'name',
          'order': 'asc',
        },
      );

      try {
        await _local.saveTags(response.items);
      } catch (_) {}

      return response;
    } catch (_) {
      final cached = await _local.getTags(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return _offlinePage(items: cached, page: safePage, perPage: safePerPage);
    }
  }

  // =========================================================
  // GUIDELINE INDEX
  // =========================================================

  Future<PaginatedResponse<GuidelineIndex>> index({
    int page = 1,
    int perPage = 100,
    String? search,
    String? parentId,
    int? level,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    try {
      final response = await _typedList<GuidelineIndex>(
        '/api/v2/guideline-index',
        GuidelineIndex.fromJson,
        page: safePage,
        perPage: safePerPage,
        query: {
          if (_present(search)) 'search': search!.trim(),
          if (_present(parentId)) 'parent_id': parentId!,
          if (level != null) 'level': '$level',
          'sort': 'sort_order',
          'order': 'asc',
        },
      );

      try {
        await _local.saveIndexItems(response.items);
      } catch (_) {}

      return response;
    } catch (_) {
      final cached = await _local.getIndexItems(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        parentId: parentId ?? '',
        level: level,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return _offlinePage(items: cached, page: safePage, perPage: safePerPage);
    }
  }

  // =========================================================
  // INDEX CHILDREN
  // =========================================================

  Future<PaginatedResponse<GuidelineIndex>> indexChildren(
    String id, {
    int page = 1,
    int perPage = 100,
  }) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Guideline index id is required');
    }

    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    try {
      final response = await _typedList<GuidelineIndex>(
        '/api/v2/guideline-index/$normalizedId/children',
        GuidelineIndex.fromJson,
        page: safePage,
        perPage: safePerPage,
      );

      try {
        await _local.saveIndexItems(response.items);
      } catch (_) {}

      return response;
    } catch (_) {
      final cached = await _local.getIndexItems(
        page: safePage,
        perPage: safePerPage,
        parentId: normalizedId,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return _offlinePage(items: cached, page: safePage, perPage: safePerPage);
    }
  }

  // =========================================================
  // ABBREVIATIONS
  // =========================================================

  Future<PaginatedResponse<Abbreviation>> abbreviations({
    int page = 1,
    int perPage = 30,
    String? search,
    bool? commonUsage,
    String? categoryId,
    String? tagId,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    try {
      final response = await _typedList<Abbreviation>(
        '/api/v2/abbreviations',
        Abbreviation.fromJson,
        page: safePage,
        perPage: safePerPage,
        query: {
          if (_present(search)) 'search': search!.trim(),
          if (commonUsage != null) 'common_usage': '$commonUsage',
          if (_present(categoryId)) 'category_id': categoryId!,
          if (_present(tagId)) 'tag_id': tagId!,
          'sort': 'abbreviation',
          'order': 'asc',
        },
      );

      try {
        await _abbreviationsLocal.saveAbbreviations(response.items);
      } catch (_) {}

      return response;
    } catch (_) {
      List<Abbreviation> cached;

      if (commonUsage == true) {
        cached = await _abbreviationsLocal.getCommonAbbreviations(
          limit: safePerPage,
        );
      } else {
        cached = await _abbreviationsLocal.getAbbreviations(
          page: safePage,
          perPage: safePerPage,
          search: search ?? '',
        );
      }

      //
      // Temporary secondary filtering.
      //
      // Once LocalCacheService supports metadata filtering directly,
      // category/tag filtering should move into SQLite.
      //
      if (_present(categoryId) || _present(tagId)) {
        cached = cached
            .where(
              (item) => _matchesAbbreviationFilters(
                item,
                categoryIds: _splitIds(categoryId),
                tagIds: _splitIds(tagId),
              ),
            )
            .toList(growable: false);
      }

      if (cached.isEmpty) {
        rethrow;
      }

      return _offlinePage(items: cached, page: safePage, perPage: safePerPage);
    }
  }

  // =========================================================
  // ABBREVIATION DETAIL
  // =========================================================

  Future<Abbreviation> abbreviation(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Abbreviation id is required');
    }

    try {
      final abbreviation = await _get<Abbreviation>(
        '/api/v2/abbreviations/$normalizedId',
        Abbreviation.fromJson,
      );

      try {
        await _abbreviationsLocal.saveAbbreviation(abbreviation);
      } catch (_) {}

      return abbreviation;
    } catch (_) {
      final cached = await _abbreviationsLocal.getAbbreviation(normalizedId);

      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedGuidelines() {
    return _local.hasCachedGuidelines();
  }

  Future<bool> isGuidelineCacheStale({
    Duration maxAge = const Duration(hours: 24),
  }) {
    return _local.isGuidelineCacheStale(maxAge: maxAge);
  }

  // =========================================================
  // CLEAR CACHE
  // =========================================================

  Future<void> clearPersistentCache() async {
    await Future.wait([_local.clear(), _abbreviationsLocal.clear()]);
  }

  // =========================================================
  // REMOTE LIST
  // =========================================================

  Future<PaginatedResponse<T>> _typedList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    int page = 1,
    int perPage = 100,
    Map<String, String> query = const {},
  }) async {
    final response = await _api.requestJson(
      path,
      method: 'GET',
      query: {'page': '$page', 'per_page': '$perPage', ...query},
    );

    final data = _data(response);

    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => fromJson(Map<String, dynamic>.from(value)))
        .toList(growable: false);

    return PaginatedResponse<T>(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages:
          (data['total_pages'] as num?)?.toInt() ??
          _totalPages(items.length, perPage),
      items: items,
    );
  }

  // =========================================================
  // REMOTE SINGLE
  // =========================================================

  Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _api.requestJson(path, method: 'GET');

    return fromJson(_data(response));
  }

  // =========================================================
  // RESPONSE DATA
  // =========================================================

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];

    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  // =========================================================
  // ABBREVIATION FILTER FALLBACK
  // =========================================================

  bool _matchesAbbreviationFilters(
    Abbreviation abbreviation, {
    required List<String> categoryIds,
    required List<String> tagIds,
  }) {
    //
    // We intentionally return true for now because we haven't
    // confirmed the exact category/tag fields exposed on your
    // Abbreviation model.
    //
    // Once those fields are known this can become:
    //
    // if (categoryIds.isNotEmpty &&
    //     !categoryIds.contains(abbreviation.categoryId)) {
    //   return false;
    // }
    //
    // if (tagIds.isNotEmpty &&
    //     abbreviation.tags.every(
    //       (tag) => !tagIds.contains(tag.id),
    //     )) {
    //   return false;
    // }
    //
    return true;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  static bool _present(String? value) {
    return value?.trim().isNotEmpty == true;
  }

  static List<String> _splitIds(String? value) {
    if (!_present(value)) {
      return const [];
    }

    return value!
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static int _totalPages(int totalItems, int perPage) {
    if (totalItems <= 0 || perPage <= 0) {
      return 0;
    }

    return (totalItems / perPage).ceil();
  }

  static PaginatedResponse<T> _offlinePage<T>({
    required List<T> items,
    required int page,
    required int perPage,
  }) {
    return PaginatedResponse<T>(
      page: page,
      perPage: perPage,
      totalItems: items.length,
      totalPages: items.isEmpty ? 0 : _totalPages(items.length, perPage),
      items: items,
    );
  }
}

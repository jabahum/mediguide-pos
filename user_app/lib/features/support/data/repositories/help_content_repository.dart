import 'dart:convert';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';

import 'package:user_app/features/support/data/repositories/help_content_local_repository.dart';

final class HelpContentRepository {
  HelpContentRepository(this._api, this._local, {TtlResponseCache? cache})
    : _cache = cache ?? TtlResponseCache();

  final BackendApiService _api;
  final HelpContentLocalRepository _local;
  final TtlResponseCache _cache;

  // =========================================================
  // FAQ LIST
  // =========================================================

  Future<PaginatedResponse<FAQ>> listFAQs({
    int page = 1,
    int perPage = 10,
    String? search,
    bool? featured,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 10 : perPage;

    final query = {
      'page': '$safePage',
      'per_page': '$safePerPage',
      'sort': 'sort_order',
      'order': 'asc',
      if (_present(search)) 'search': search!.trim(),
      if (featured != null) 'is_featured': '$featured',
    };

    Future<Map<String, dynamic>> load() {
      return _api.requestJson('/api/v2/faqs', method: 'GET', query: query);
    }

    try {
      final response = _present(search)
          ? await load()
          : await _cache.getOrLoad(
              key: 'published-faqs:${jsonEncode(query)}',
              ttl: const Duration(minutes: 15),
              load: load,
            );

      final data = _data(response);

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => FAQ.fromJson(
              _normalize(Map<String, dynamic>.from(value), 'faqs'),
            ),
          )
          .toList(growable: false);

      // -------------------------------------------------------
      // Persistent cache.
      // -------------------------------------------------------

      try {
        await _local.saveFAQs(items);
      } catch (_) {}

      return PaginatedResponse<FAQ>(
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
        items: items,
      );
    } catch (_) {
      // =======================================================
      // OFFLINE FALLBACK
      // =======================================================

      final cached = await _local.getFAQs(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        featured: featured,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<FAQ>(
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: _totalPages(cached.length, safePerPage),
        items: cached,
      );
    }
  }

  // =========================================================
  // FAQ DETAIL
  // =========================================================

  Future<FAQ> getFAQ(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'FAQ id is required');
    }

    try {
      final response = await _cache.getOrLoad(
        key: 'published-faq:$normalizedId',
        ttl: const Duration(minutes: 15),
        load: () => _api.requestJson(
          '/api/v2/faqs/${Uri.encodeComponent(normalizedId)}',
          method: 'GET',
        ),
      );

      final faq = FAQ.fromJson(_normalize(_data(response), 'faqs'));

      try {
        await _local.saveFAQ(faq);
      } catch (_) {}

      return faq;
    } catch (_) {
      final cached = await _local.getFAQ(normalizedId);

      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  // =========================================================
  // DOCUMENTATION LIST
  // =========================================================

  Future<PaginatedResponse<Documentation>> listDocumentation({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 20 : perPage;

    final query = {
      'page': '$safePage',
      'per_page': '$safePerPage',
      if (_present(search)) 'search': search!.trim(),
      if (_present(category)) 'category': category!.trim(),
    };

    Future<Map<String, dynamic>> load() {
      return _api.requestJson(
        '/api/v2/documentation',
        method: 'GET',
        query: query,
      );
    }

    try {
      final response = _present(search)
          ? await load()
          : await _cache.getOrLoad(
              key: 'published-documentation:${jsonEncode(query)}',
              ttl: const Duration(minutes: 15),
              load: load,
            );

      final data = _data(response);

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => Documentation.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);

      try {
        await _local.saveDocumentationItems(items);
      } catch (_) {}

      return PaginatedResponse<Documentation>(
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
        items: items,
      );
    } catch (_) {
      // =======================================================
      // OFFLINE FALLBACK
      // =======================================================

      final cached = await _local.getDocumentationItems(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        category: category ?? '',
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<Documentation>(
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: _totalPages(cached.length, safePerPage),
        items: cached,
      );
    }
  }

  // =========================================================
  // CACHE
  // =========================================================

  Future<bool> hasCachedFAQs() {
    return _local.hasCachedFAQs();
  }

  Future<bool> hasCachedDocumentation() {
    return _local.hasCachedDocumentation();
  }

  Future<void> clearPersistentCache() {
    return _local.clear();
  }

  // =========================================================
  // RESPONSE DATA
  // =========================================================

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];

    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  // =========================================================
  // NORMALIZE FAQ
  // =========================================================

  Map<String, dynamic> _normalize(Map<String, dynamic> raw, String collection) {
    return {
      ...raw,

      if (raw['author'] == null && raw['author_id'] != null)
        'author': raw['author_id'],

      if (raw['reviewer'] == null && raw['reviewer_id'] != null)
        'reviewer': raw['reviewer_id'],

      'collectionName': collection,
      'collectionId': collection,

      'created':
          raw['created_at']?.toString() ?? raw['created']?.toString() ?? '',

      'updated':
          raw['updated_at']?.toString() ?? raw['updated']?.toString() ?? '',
    };
  }

  // =========================================================
  // HELPERS
  // =========================================================

  static bool _present(String? value) {
    return value?.trim().isNotEmpty == true;
  }

  static int _totalPages(int totalItems, int perPage) {
    if (totalItems <= 0 || perPage <= 0) {
      return 0;
    }

    return (totalItems / perPage).ceil();
  }
}

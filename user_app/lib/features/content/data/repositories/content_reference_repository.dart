import 'package:user_app/shared/models/paginated_response.dart';
import 'package:user_app/features/content/data/models/language_model.dart';
import 'package:user_app/features/content/data/models/ministry_directory.dart';
import 'package:user_app/features/content/data/models/generic_page.dart';

import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';

import 'package:user_app/features/content/data/repositories/generic_page_local_repository.dart';
import 'package:user_app/features/content/data/repositories/ministry_directory_local_repository.dart';

/// ===========================================================
/// GENERIC PAGES
/// ===========================================================

final class GenericPageRepository {
  GenericPageRepository(this._api, this._local);

  final BackendApiService _api;
  final GenericPageLocalRepository _local;

  /// =========================================================
  /// LIST
  /// =========================================================
  ///
  /// Strategy:
  ///
  /// 1. Try remote API
  /// 2. Save successful response locally
  /// 3. Return remote response
  /// 4. On network/API failure, return locally cached data
  ///
  Future<PaginatedResponse<GenericPage>> list({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 50 : perPage;
    final normalizedSearch = search?.trim() ?? '';

    try {
      final data = _data(
        await _api.requestJson(
          '/api/v2/pages',
          method: 'GET',
          query: {
            'page': '$safePage',
            'per_page': '$safePerPage',
            if (_present(normalizedSearch)) 'search': normalizedSearch,
          },
        ),
      );

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => GenericPage.fromJson(
              _normalize(Map<String, dynamic>.from(value)),
            ),
          )
          .toList(growable: false);

      // -------------------------------------------------------
      // Cache successful remote results.
      //
      // Cache failure should not cause an otherwise successful
      // API request to fail.
      // -------------------------------------------------------

      try {
        await _local.savePages(items);
      } catch (_) {
        // Local cache writes are best effort.
      }

      return PaginatedResponse<GenericPage>(
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
        items: items,
      );
    } catch (remoteError) {
      // -------------------------------------------------------
      // OFFLINE FALLBACK
      // -------------------------------------------------------

      final cached = await _local.getPages(
        page: safePage,
        perPage: safePerPage,
        search: normalizedSearch,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<GenericPage>(
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: cached.isEmpty ? 0 : 1,
        items: cached,
      );
    }
  }

  /// =========================================================
  /// GET PAGE BY KEY
  /// =========================================================

  Future<GenericPage> byKey(String key) async {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Page key is required');
    }

    try {
      final page = GenericPage.fromJson(
        _normalize(
          _data(
            await _api.requestJson(
              '/api/v2/pages/key/${Uri.encodeComponent(normalizedKey)}',
              method: 'GET',
            ),
          ),
        ),
      );

      // Cache the full page after it is successfully fetched.
      try {
        await _local.savePage(page);
      } catch (_) {
        // Cache failure must not block page viewing.
      }

      return page;
    } catch (_) {
      final cached = await _local.getPageByKey(normalizedKey);

      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  /// =========================================================
  /// CACHE STATUS
  /// =========================================================

  Future<bool> hasCachedPages() {
    return _local.hasCachedPages();
  }

  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) {
    return _local.isCacheStale(maxAge: maxAge);
  }

  /// =========================================================
  /// CLEAR CACHE
  /// =========================================================

  Future<void> clearCache() {
    return _local.clear();
  }

  /// =========================================================
  /// NORMALIZATION
  /// =========================================================

  Map<String, dynamic> _normalize(Map<String, dynamic> value) {
    final rawContent = value['content'];

    return {
      ...value,

      'content': rawContent is Map<String, dynamic>
          ? rawContent
          : rawContent is Map
          ? Map<String, dynamic>.from(rawContent)
          : rawContent is String
          ? <String, dynamic>{'content': rawContent}
          : <String, dynamic>{},

      'created':
          value['created_at'] ??
          value['created'] ??
          DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),

      'updated':
          value['updated_at'] ??
          value['updated'] ??
          DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
    };
  }
}

/// ===========================================================
/// MINISTRY DIRECTORY
/// ===========================================================

final class MinistryDirectoryRepository {
  MinistryDirectoryRepository(this._api, this._local);

  final BackendApiService _api;
  final MinistryDirectoryLocalRepository _local;

  /// =========================================================
  /// LIST
  /// =========================================================

  Future<PaginatedResponse<MinistryDirectory>> list({
    int page = 1,
    int perPage = 20,
    String? search,
    String? ministry,
    String? department,
    String? districtId,
    String? regionId,
    String? status,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 20 : perPage;

    final normalizedSearch = search?.trim() ?? '';

    final normalizedMinistry = ministry?.trim() ?? '';

    final normalizedDepartment = department?.trim() ?? '';

    final normalizedDistrictId = districtId?.trim() ?? '';

    final normalizedRegionId = regionId?.trim() ?? '';

    final normalizedStatus = status?.trim() ?? '';

    try {
      final data = _data(
        await _api.requestJson(
          '/api/v2/ministry-directory',
          method: 'GET',
          query: {
            'page': '$safePage',
            'per_page': '$safePerPage',

            if (_present(normalizedSearch)) 'search': normalizedSearch,

            if (_present(normalizedMinistry)) 'ministry': normalizedMinistry,

            if (_present(normalizedDepartment))
              'department': normalizedDepartment,

            if (_present(normalizedDistrictId))
              'district_id': normalizedDistrictId,

            if (_present(normalizedRegionId)) 'region_id': normalizedRegionId,

            if (_present(normalizedStatus)) 'status': normalizedStatus,

            'sort': 'priority_level',
            'order': 'asc',
          },
        ),
      );

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) =>
                MinistryDirectory.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);

      // -------------------------------------------------------
      // Cache successful remote response.
      // -------------------------------------------------------

      try {
        await _local.saveEntries(items);
      } catch (_) {
        // Cache writes must never block valid remote content.
      }

      return PaginatedResponse<MinistryDirectory>(
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
        items: items,
      );
    } catch (_) {
      // -------------------------------------------------------
      // OFFLINE FALLBACK
      // -------------------------------------------------------

      final cached = await _local.getEntries(
        page: safePage,
        perPage: safePerPage,
        search: normalizedSearch,
        ministry: normalizedMinistry,
        department: normalizedDepartment,
        districtId: normalizedDistrictId,
        regionId: normalizedRegionId,
        status: normalizedStatus,
      );

      if (cached.isEmpty) {
        rethrow;
      }

      return PaginatedResponse<MinistryDirectory>(
        page: safePage,
        perPage: safePerPage,
        totalItems: cached.length,
        totalPages: cached.isEmpty ? 0 : 1,
        items: cached,
      );
    }
  }

  /// =========================================================
  /// CACHE STATUS
  /// =========================================================

  Future<bool> hasCachedEntries() {
    return _local.hasCachedEntries();
  }

  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) {
    return _local.isCacheStale(maxAge: maxAge);
  }

  /// =========================================================
  /// CLEAR CACHE
  /// =========================================================

  Future<void> clearCache() {
    return _local.clear();
  }
}

/// ===========================================================
/// LANGUAGES
/// ===========================================================
///
/// Languages currently use the existing in-memory TTL cache.
///
/// This is acceptable because:
///
/// - English fallback already exists in LanguageController
/// - selected language is stored in SharedPreferences
/// - translations are persisted in SharedPreferences
///
/// We can move language metadata itself into Drift later if required.
/// ===========================================================

final class LanguageRepository {
  LanguageRepository(this._api, {TtlResponseCache? cache})
    : _cache = cache ?? TtlResponseCache();

  final BackendApiService _api;
  final TtlResponseCache _cache;

  Future<List<LanguageModel>> available() async {
    final data = _data(
      await _cache.getOrLoad(
        key: 'languages:available',
        ttl: const Duration(minutes: 30),
        load: () => _api.requestJson(
          '/api/v2/languages',
          method: 'GET',
          query: {
            'page': '1',
            'per_page': '100',
            'is_active': 'true',
            'enabled_for_users': 'true',
            'sort': 'name',
            'order': 'asc',
          },
        ),
      ),
    );

    return (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (value) => LanguageModel.fromJson(
            _language(Map<String, dynamic>.from(value)),
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _language(Map<String, dynamic> value) {
    return {
      ...value,

      'translations':
          value['translations'] ??
          value['translations_json'] ??
          <String, dynamic>{},

      'created': value['created_at'] ?? value['created'],

      'updated': value['updated_at'] ?? value['updated'],
    };
  }
}

/// ===========================================================
/// SHARED HELPERS
/// ===========================================================

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];

  return data is Map ? Map<String, dynamic>.from(data) : response;
}

bool _present(String? value) {
  return value != null && value.trim().isNotEmpty;
}

int _totalPages(int totalItems, int perPage) {
  if (totalItems <= 0 || perPage <= 0) {
    return 0;
  }

  return (totalItems / perPage).ceil();
}

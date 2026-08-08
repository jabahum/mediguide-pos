import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/drugs/data/models/drug.dart';
import 'package:user_app/features/drugs/data/repositories/drug_local_repository.dart';
import 'package:user_app/shared/models/paginated_response.dart';

final class DrugRepository {
  DrugRepository(this._api, this._local);

  final BackendApiService _api;
  final DrugLocalRepository _local;

  // =========================================================
  // LIST
  // =========================================================

  Future<PaginatedResponse<Drug>> list({
    int page = 1,
    int perPage = 30,
    String? search,
    String? status,
    String? reviewStatus,
    String? drugClassId,
    String? therapeuticCategoryId,
    String? route,
    String? pregnancyCategory,
    bool? whoEml,
    bool? antimicrobial,
    String sort = 'name',
    String order = 'asc',
  }) async {
    final safePage = page < 1 ? 1 : page;

    final safePerPage = perPage < 1 ? 30 : perPage;

    try {
      final response = await _api.requestJson(
        '/api/v2/drugs',
        method: 'GET',
        query: {
          'page': '$safePage',
          'per_page': '$safePerPage',

          if (_present(search)) 'search': search!.trim(),

          if (_present(status)) 'status': status!,

          if (_present(reviewStatus)) 'review_status': reviewStatus!,

          if (_present(drugClassId)) 'drug_class_id': drugClassId!,

          if (_present(therapeuticCategoryId))
            'therapeutic_category_id': therapeuticCategoryId!,

          if (_present(route)) 'route': route!,

          if (_present(pregnancyCategory))
            'pregnancy_category': pregnancyCategory!,

          if (whoEml != null) 'who_eml': '$whoEml',

          if (antimicrobial != null) 'antimicrobial': '$antimicrobial',

          'sort': sort,
          'order': order,
        },
      );

      final data = _data(response);

      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Drug.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      // -------------------------------------------------------
      // Save successful remote response locally.
      // -------------------------------------------------------

      try {
        await _local.saveDrugs(items);
      } catch (_) {
        // Local caching must not break a successful remote request.
      }

      return PaginatedResponse<Drug>(
        items: items,

        page: (data['page'] as num?)?.toInt() ?? safePage,

        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,

        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,

        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
      );
    } catch (_) {
      // =======================================================
      // OFFLINE FALLBACK
      // =======================================================

      final cached = await _local.list(
        page: safePage,
        perPage: safePerPage,
        search: search ?? '',
        status: status ?? '',
        reviewStatus: reviewStatus ?? '',
        drugClassId: drugClassId ?? '',
        therapeuticCategoryId: therapeuticCategoryId ?? '',
        route: route ?? '',
        pregnancyCategory: pregnancyCategory ?? '',
        whoEml: whoEml,
        antimicrobial: antimicrobial,
        sort: sort,
        order: order,
      );

      if (cached.totalItems == 0) {
        rethrow;
      }

      return PaginatedResponse<Drug>(
        items: cached.items,
        page: cached.page,
        perPage: cached.perPage,
        totalItems: cached.totalItems,
        totalPages: cached.totalPages,
      );
    }
  }

  // =========================================================
  // EXPLICIT CACHED LIST
  // =========================================================

  Future<PaginatedResponse<Drug>> listCached({
    int page = 1,
    int perPage = 30,
    String? search,
    String? status,
    String? reviewStatus,
    String? drugClassId,
    String? therapeuticCategoryId,
    String? route,
    String? pregnancyCategory,
    bool? whoEml,
    bool? antimicrobial,
    String sort = 'name',
    String order = 'asc',
  }) async {
    final cached = await _local.list(
      page: page,
      perPage: perPage,
      search: search ?? '',
      status: status ?? '',
      reviewStatus: reviewStatus ?? '',
      drugClassId: drugClassId ?? '',
      therapeuticCategoryId: therapeuticCategoryId ?? '',
      route: route ?? '',
      pregnancyCategory: pregnancyCategory ?? '',
      whoEml: whoEml,
      antimicrobial: antimicrobial,
      sort: sort,
      order: order,
    );

    return PaginatedResponse<Drug>(
      items: cached.items,
      page: cached.page,
      perPage: cached.perPage,
      totalItems: cached.totalItems,
      totalPages: cached.totalPages,
    );
  }

  // =========================================================
  // GET
  // =========================================================

  Future<Drug?> get(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    try {
      final response = await _api.requestJson(
        '/api/v2/drugs/'
        '${Uri.encodeComponent(normalizedId)}',
        method: 'GET',
      );

      final drug = Drug.fromJson(_itemData(response));

      try {
        await _local.saveDrug(drug);
      } catch (_) {
        // Local cache failure should not hide valid remote data.
      }

      return drug;
    } catch (_) {
      return _local.get(normalizedId);
    }
  }

  // =========================================================
  // GET CACHED
  // =========================================================

  Future<Drug?> getCached(String id) {
    return _local.get(id);
  }

  // =========================================================
  // USAGE
  // =========================================================

  Future<void> recordUsage(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    try {
      await _api.requestJson(
        '/api/v2/drugs/'
        '${Uri.encodeComponent(normalizedId)}'
        '/usage',
        method: 'POST',
      );
    } catch (_) {
      // Usage telemetry is best effort.
      // It must never prevent drug access while offline.
    }
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasOfflineData() {
    return _local.hasData();
  }

  Future<bool> isOfflineDataStale({
    Duration maxAge = const Duration(hours: 24),
  }) {
    return _local.isStale(maxAge: maxAge);
  }

  Future<void> clearOfflineData() {
    return _local.clear();
  }

  Stream<List<Drug>> watchOfflineData() {
    return _local.watch();
  }
}

// ===========================================================
// RESPONSE HELPERS
// ===========================================================

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final value = response['data'];

  return value is Map ? Map<String, dynamic>.from(value) : response;
}

Map<String, dynamic> _itemData(Map<String, dynamic> response) {
  final data = _data(response);

  final item = data['item'];

  return item is Map ? Map<String, dynamic>.from(item) : data;
}

bool _present(String? value) {
  return value?.trim().isNotEmpty == true;
}

int _totalPages(int totalItems, int perPage) {
  if (totalItems <= 0 || perPage <= 0) {
    return 0;
  }

  return (totalItems / perPage).ceil();
}

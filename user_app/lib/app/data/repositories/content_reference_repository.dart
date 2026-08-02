import '../models/api_record.dart';
import '../models/language_model.dart';
import '../models/ministry_directory.dart';
import '../services/backend_api_service.dart';
import '../services/ttl_response_cache.dart';
import '../../models/generic_page.dart';

final class GenericPageRepository {
  GenericPageRepository(this._api);
  final BackendApiService _api;

  Future<PagedResult<GenericPage>> list({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    final data = _data(
      await _api.requestJson(
        '/api/v2/pages',
        method: 'GET',
        query: {
          'page': '$page',
          'per_page': '$perPage',
          if (_present(search)) 'search': search!.trim(),
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
        .toList();
    return PagedResult(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<GenericPage> byKey(String key) async => GenericPage.fromJson(
    _normalize(
      _data(
        await _api.requestJson(
          '/api/v2/pages/key/${Uri.encodeComponent(key)}',
          method: 'GET',
        ),
      ),
    ),
  );

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

final class MinistryDirectoryRepository {
  MinistryDirectoryRepository(this._api);
  final BackendApiService _api;

  Future<PagedResult<MinistryDirectory>> list({
    int page = 1,
    int perPage = 20,
    String? search,
    String? ministry,
    String? department,
    String? districtId,
    String? regionId,
    String? status,
  }) async {
    final data = _data(
      await _api.requestJson(
        '/api/v2/ministry-directory',
        method: 'GET',
        query: {
          'page': '$page',
          'per_page': '$perPage',
          if (_present(search)) 'search': search!.trim(),
          if (_present(ministry)) 'ministry': ministry!,
          if (_present(department)) 'department': department!,
          if (_present(districtId)) 'district_id': districtId!,
          if (_present(regionId)) 'region_id': regionId!,
          if (_present(status)) 'status': status!,
          'sort': 'priority_level',
          'order': 'asc',
        },
      ),
    );
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (value) => MinistryDirectory(
            ApiRecord(_directoryRecord(Map<String, dynamic>.from(value))).data,
          ),
        )
        .toList();
    return PagedResult(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> _directoryRecord(Map<String, dynamic> value) {
    final districtId = value['district_id']?.toString() ?? '';
    final regionId = value['region_id']?.toString() ?? '';
    return {
      ...value,
      'collectionId': MinistryDirectory.collection,
      'collectionName': MinistryDirectory.collection,
      'created': value['created_at'] ?? value['created'] ?? '',
      'updated': value['updated_at'] ?? value['updated'] ?? '',
      'district': districtId,
      'region': regionId,
      'alternativePhone': value['alternative_phone'] ?? '',
      'expand': {
        if (districtId.isNotEmpty)
          'district': {'id': districtId, 'name': value['district_name'] ?? ''},
        if (regionId.isNotEmpty)
          'region': {'id': regionId, 'name': value['region_name'] ?? ''},
      },
    };
  }
}

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
        .toList();
  }

  Map<String, dynamic> _language(Map<String, dynamic> value) => {
    ...value,
    'translations':
        value['translations'] ??
        value['translations_json'] ??
        <String, dynamic>{},
    'created': value['created_at'] ?? value['created'],
    'updated': value['updated_at'] ?? value['updated'],
  };
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : response;
}

bool _present(String? value) => value != null && value.trim().isNotEmpty;

import 'dart:convert';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';

final class FacilityRepository {
  FacilityRepository(this._api, {TtlResponseCache? cache})
    : _cache = cache ?? TtlResponseCache();

  final BackendApiService _api;
  final TtlResponseCache _cache;

  Future<PagedResult<ApiRecord>> listFacilities({
    required int page,
    required int perPage,
    String? search,
    String? regionId,
    String? districtId,
    String? facilityLevelId,
    String? ownershipTypeId,
  }) => _list(
    '/api/v2/facilities',
    HealthFacility.collection,
    page: page,
    perPage: perPage,
    query: {
      if (_present(search)) 'search': search!.trim(),
      if (_present(regionId)) 'region_id': regionId!,
      if (_present(districtId)) 'district_id': districtId!,
      if (_present(facilityLevelId)) 'facility_level_id': facilityLevelId!,
      if (_present(ownershipTypeId)) 'ownership_type_id': ownershipTypeId!,
      'sort': 'name',
      'order': 'asc',
    },
  );

  Future<PagedResult<ApiRecord>> regions({int page = 1, int perPage = 100}) =>
      _list('/api/v2/regions', Region.collection, page: page, perPage: perPage);

  Future<PagedResult<ApiRecord>> districts({
    String? regionId,
    int page = 1,
    int perPage = 100,
  }) => _list(
    '/api/v2/districts',
    District.collection,
    page: page,
    perPage: perPage,
    query: {if (_present(regionId)) 'region_id': regionId!},
  );

  Future<PagedResult<ApiRecord>> levels() =>
      _list('/api/v2/facility-levels', FacilityLevel.collection);

  Future<PagedResult<ApiRecord>> ownershipTypes() =>
      _list('/api/v2/ownership-types', OwnershipType.collection);

  Future<void> recordUsage(String facilityId) async {
    await _api.requestJson(
      '/api/v2/facilities/$facilityId/usage',
      method: 'POST',
    );
  }

  Future<PagedResult<ApiRecord>> _list(
    String path,
    String collectionName, {
    int page = 1,
    int perPage = 100,
    Map<String, String> query = const {},
  }) async {
    final requestQuery = {'page': '$page', 'per_page': '$perPage', ...query};
    Future<Map<String, dynamic>> load() =>
        _api.requestJson(path, method: 'GET', query: requestQuery);
    final response = collectionName == HealthFacility.collection
        ? await load()
        : await _cache.getOrLoad(
            key: 'facility-reference:$path:${jsonEncode(requestQuery)}',
            ttl: const Duration(minutes: 30),
            load: load,
          );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (value) => ApiRecord(
            _normalize(Map<String, dynamic>.from(value), collectionName),
          ),
        )
        .toList();
    return PagedResult<ApiRecord>(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  Map<String, dynamic> _normalize(
    Map<String, dynamic> raw,
    String collectionName,
  ) {
    final result = <String, dynamic>{
      ...raw,
      'collectionName': collectionName,
      'collectionId': collectionName,
      'created': raw['created_at']?.toString() ?? '',
      'updated': raw['updated_at']?.toString() ?? '',
    };
    if (collectionName == HealthFacility.collection) {
      const relations = {
        'facility_level': 'facility_levels',
        'authority': 'authorities',
        'ownership_type': 'ownership_types',
        'health_sub_district': 'health_sub_districts',
        'parish': 'parishes',
        'subcounty': 'subcounties',
        'county': 'counties',
        'district': 'districts',
        'health_sub_region': 'health_sub_regions',
        'region': 'regions',
      };
      final expand = <String, dynamic>{};
      for (final entry in relations.entries) {
        final id = raw['${entry.key}_id']?.toString() ?? '';
        result[entry.key] = id;
        if (id.isNotEmpty) {
          expand[entry.key] = {
            'id': id,
            'name': raw['${entry.key}_name']?.toString() ?? '',
            'collectionName': entry.value,
            'collectionId': entry.value,
          };
        }
      }
      result['expand'] = expand;
    }
    return result;
  }

  static bool _present(String? value) => value?.trim().isNotEmpty == true;
}

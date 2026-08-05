import 'dart:convert';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';

final class FacilityRepository {
  FacilityRepository(this._api, {TtlResponseCache? cache})
    : _cache = cache ?? TtlResponseCache();

  final BackendApiService _api;
  final TtlResponseCache _cache;

  Future<PaginatedResponse<HealthFacility>> listFacilities({
    required int page,
    required int perPage,
    String? search,
    String? regionId,
    String? districtId,
    String? facilityLevelId,
    String? ownershipTypeId,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/facilities',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (_present(search)) 'search': search!.trim(),
        if (_present(regionId)) 'region_id': regionId!,
        if (_present(districtId)) 'district_id': districtId!,
        if (_present(facilityLevelId)) 'facility_level_id': facilityLevelId!,
        if (_present(ownershipTypeId)) 'ownership_type_id': ownershipTypeId!,
        'sort': 'name',
        'order': 'asc',
      },
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (value) => HealthFacility.fromJson(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
    return PaginatedResponse(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<HealthFacility> facility(String id) async => _facilityItem(
    await _api.requestJson('/api/v2/facilities/$id', method: 'GET'),
  );

  Future<HealthFacility> createFacility(HealthFacilityRequest request) async =>
      _facilityItem(
        await _api.requestJson(
          '/api/v2/facilities',
          method: 'POST',
          body: request.toJson(),
        ),
      );

  Future<HealthFacility> updateFacility(
    String id,
    HealthFacilityRequest request,
  ) async => _facilityItem(
    await _api.requestJson(
      '/api/v2/facilities/$id',
      method: 'PATCH',
      body: request.toJson(),
    ),
  );

  Future<void> deleteFacility(String id) async {
    await _api.requestJson('/api/v2/facilities/$id', method: 'DELETE');
  }

  Future<PaginatedResponse<Region>> regions({
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/regions',
    Region.fromJson,
    page: page,
    perPage: perPage,
  );

  Future<PaginatedResponse<District>> districts({
    String? regionId,
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/districts',
    District.fromJson,
    page: page,
    perPage: perPage,
    query: {if (_present(regionId)) 'region_id': regionId!},
  );

  Future<PaginatedResponse<HealthSubRegion>> healthSubRegions({
    String? regionId,
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/health-sub-regions',
    HealthSubRegion.fromJson,
    page: page,
    perPage: perPage,
    query: {if (_present(regionId)) 'region_id': regionId!},
  );

  Future<PaginatedResponse<HealthSubDistrict>> healthSubDistricts({
    String? districtId,
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/health-sub-districts',
    HealthSubDistrict.fromJson,
    page: page,
    perPage: perPage,
    query: {if (_present(districtId)) 'district_id': districtId!},
  );

  Future<PaginatedResponse<County>> counties({
    String? districtId,
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/counties',
    County.fromJson,
    page: page,
    perPage: perPage,
    query: {if (_present(districtId)) 'district_id': districtId!},
  );

  Future<PaginatedResponse<Subcounty>> subcounties({
    String? districtId,
    String? countyId,
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/subcounties',
    Subcounty.fromJson,
    page: page,
    perPage: perPage,
    query: {
      if (_present(districtId)) 'district_id': districtId!,
      if (_present(countyId)) 'county_id': countyId!,
    },
  );

  Future<PaginatedResponse<Parish>> parishes({
    String? subcountyId,
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/parishes',
    Parish.fromJson,
    page: page,
    perPage: perPage,
    query: {if (_present(subcountyId)) 'subcounty_id': subcountyId!},
  );

  Future<PaginatedResponse<Authority>> authorities({
    String? ownershipTypeId,
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/authorities',
    Authority.fromJson,
    page: page,
    perPage: perPage,
    query: {
      if (_present(ownershipTypeId)) 'ownership_type_id': ownershipTypeId!,
    },
  );

  Future<PaginatedResponse<FacilityLevel>> levels() =>
      _referenceList('/api/v2/facility-levels', FacilityLevel.fromJson);

  Future<PaginatedResponse<OwnershipType>> ownershipTypes() =>
      _referenceList('/api/v2/ownership-types', OwnershipType.fromJson);

  Future<void> recordUsage(String facilityId) async {
    await _api.requestJson(
      '/api/v2/facilities/$facilityId/usage',
      method: 'POST',
    );
  }

  Future<PaginatedResponse<T>> _referenceList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    int page = 1,
    int perPage = 100,
    Map<String, String> query = const {},
  }) async {
    final requestQuery = {'page': '$page', 'per_page': '$perPage', ...query};
    final response = await _cache.getOrLoad(
      key: 'facility-reference:$path:${jsonEncode(requestQuery)}',
      ttl: const Duration(minutes: 30),
      load: () => _api.requestJson(path, method: 'GET', query: requestQuery),
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
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  HealthFacility _facilityItem(Map<String, dynamic> response) {
    final data = _data(response);
    final item = data['item'];
    return HealthFacility.fromJson(
      item is Map ? Map<String, dynamic>.from(item) : data,
    );
  }

  static bool _present(String? value) => value?.trim().isNotEmpty == true;
}

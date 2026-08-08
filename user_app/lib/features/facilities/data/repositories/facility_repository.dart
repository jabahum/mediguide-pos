import 'dart:convert';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';
import 'package:user_app/core/storage/local_page.dart';
import 'package:user_app/features/facilities/data/repositories/facility_local_repository.dart';

final class FacilityRepository {
  FacilityRepository(this._api, this._local, {TtlResponseCache? cache})
    : _cache = cache ?? TtlResponseCache();

  final BackendApiService _api;
  final FacilityLocalRepository _local;
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
    try {
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
            (value) =>
                HealthFacility.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
      await _bestEffort(() => _local.saveFacilities(items));
      return PaginatedResponse(
        page: (data['page'] as num?)?.toInt() ?? page,
        perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
        items: items,
      );
    } catch (_) {
      final cached = await _local.listFacilities(
        page: page,
        perPage: perPage,
        search: search ?? '',
        regionId: regionId ?? '',
        districtId: districtId ?? '',
        facilityLevelId: facilityLevelId ?? '',
        ownershipTypeId: ownershipTypeId ?? '',
      );
      if (cached.items.isEmpty) rethrow;
      return _fromLocal(cached);
    }
  }

  Future<HealthFacility> facility(String id) async {
    try {
      final item = _facilityItem(
        await _api.requestJson('/api/v2/facilities/$id', method: 'GET'),
      );
      await _bestEffort(() => _local.saveFacility(item));
      return item;
    } catch (_) {
      final cached = await _local.getFacility(id);
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<HealthFacility> createFacility(HealthFacilityRequest request) async {
    final item = _facilityItem(
      await _api.requestJson(
        '/api/v2/facilities',
        method: 'POST',
        body: request.toJson(),
      ),
    );
    await _bestEffort(() => _local.saveFacility(item));
    return item;
  }

  Future<HealthFacility> updateFacility(
    String id,
    HealthFacilityRequest request,
  ) async {
    final item = _facilityItem(
      await _api.requestJson(
        '/api/v2/facilities/$id',
        method: 'PATCH',
        body: request.toJson(),
      ),
    );
    await _bestEffort(() => _local.saveFacility(item));
    return item;
  }

  Future<void> deleteFacility(String id) async {
    await _api.requestJson('/api/v2/facilities/$id', method: 'DELETE');
    await _bestEffort(() => _local.removeFacility(id));
  }

  Future<PaginatedResponse<Region>> regions({
    int page = 1,
    int perPage = 100,
  }) => _referenceList(
    '/api/v2/regions',
    Region.fromJson,
    page: page,
    perPage: perPage,
    save: _local.saveRegions,
    local: () => _local.regions(page: page, perPage: perPage),
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
    save: _local.saveDistricts,
    local: () => _local.districts(
      page: page,
      perPage: perPage,
      regionId: regionId ?? '',
    ),
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
    save: _local.saveHealthSubRegions,
    local: () => _local.healthSubRegions(
      page: page,
      perPage: perPage,
      regionId: regionId ?? '',
    ),
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
    save: _local.saveHealthSubDistricts,
    local: () => _local.healthSubDistricts(
      page: page,
      perPage: perPage,
      districtId: districtId ?? '',
    ),
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
    save: _local.saveCounties,
    local: () => _local.counties(
      page: page,
      perPage: perPage,
      districtId: districtId ?? '',
    ),
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
    save: _local.saveSubcounties,
    local: () => _local.subcounties(
      page: page,
      perPage: perPage,
      districtId: districtId ?? '',
      countyId: countyId ?? '',
    ),
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
    save: _local.saveParishes,
    local: () => _local.parishes(
      page: page,
      perPage: perPage,
      subcountyId: subcountyId ?? '',
    ),
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
    save: _local.saveAuthorities,
    local: () => _local.authorities(
      page: page,
      perPage: perPage,
      ownershipTypeId: ownershipTypeId ?? '',
    ),
  );

  Future<PaginatedResponse<FacilityLevel>> levels() => _referenceList(
    '/api/v2/facility-levels',
    FacilityLevel.fromJson,
    save: _local.saveFacilityLevels,
    local: _local.facilityLevels,
  );

  Future<PaginatedResponse<OwnershipType>> ownershipTypes() => _referenceList(
    '/api/v2/ownership-types',
    OwnershipType.fromJson,
    save: _local.saveOwnershipTypes,
    local: _local.ownershipTypes,
  );

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
    required Future<void> Function(Iterable<T>) save,
    required Future<LocalPage<T>> Function() local,
  }) async {
    try {
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
      await _bestEffort(() => save(items));
      return PaginatedResponse<T>(
        page: (data['page'] as num?)?.toInt() ?? page,
        perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
        items: items,
      );
    } catch (_) {
      final cached = await local();
      if (cached.items.isEmpty) rethrow;
      return _fromLocal(cached);
    }
  }

  PaginatedResponse<T> _fromLocal<T>(LocalPage<T> page) => PaginatedResponse<T>(
    page: page.page,
    perPage: page.perPage,
    totalItems: page.totalItems,
    totalPages: page.totalPages,
    items: page.items,
  );

  Future<void> _bestEffort(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // A cache write must never turn a successful API request into a failure.
    }
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/core/storage/local_page.dart';
import 'package:user_app/shared/models/models.dart';

final facilityLocalRepositoryProvider = Provider<FacilityLocalRepository>((
  ref,
) {
  return FacilityLocalRepository(ref.watch(localCacheServiceProvider));
});

final class FacilityLocalRepository {
  FacilityLocalRepository(this._cache);

  final LocalCacheService _cache;

  static const String _scope = 'public';

  static const String _facilityType = 'health_facility';

  static const String _regionType = 'facility_region';
  static const String _districtType = 'facility_district';
  static const String _healthSubRegionType = 'health_sub_region';
  static const String _healthSubDistrictType = 'health_sub_district';
  static const String _countyType = 'facility_county';
  static const String _subcountyType = 'facility_subcounty';
  static const String _parishType = 'facility_parish';
  static const String _authorityType = 'facility_authority';
  static const String _facilityLevelType = 'facility_level';
  static const String _ownershipType = 'facility_ownership_type';

  // =========================================================
  // FACILITIES - SAVE
  // =========================================================

  Future<void> saveFacility(HealthFacility facility) {
    final json = facility.toJson();

    return _cache.put(
      type: _facilityType,
      id: facility.id,
      scope: _scope,
      data: json,
      searchableText: _facilitySearchableText(json),
      metadata: _facilityMetadata(json),
      remoteUpdatedAt: _updatedAt(json),
    );
  }

  Future<void> saveFacilities(Iterable<HealthFacility> facilities) async {
    if (facilities.isEmpty) {
      return;
    }

    await _cache.putMany(
      type: _facilityType,
      scope: _scope,
      entities: facilities.map((facility) {
        final json = facility.toJson();

        return CachedEntityInput(
          id: facility.id,
          data: json,
          searchableText: _facilitySearchableText(json),
          metadata: _facilityMetadata(json),
          remoteUpdatedAt: _updatedAt(json),
        );
      }),
    );
  }

  // =========================================================
  // FACILITIES - GET
  // =========================================================

  Future<HealthFacility?> getFacility(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final row = await _cache.get(
      type: _facilityType,
      id: normalizedId,
      scope: _scope,
    );

    if (row == null) {
      return null;
    }

    try {
      return HealthFacility.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // FACILITIES - LIST
  // =========================================================

  Future<LocalPage<HealthFacility>> listFacilities({
    int page = 1,
    int perPage = 30,
    String search = '',
    String regionId = '',
    String districtId = '',
    String facilityLevelId = '',
    String ownershipTypeId = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    final rows = await _cache.list(
      type: _facilityType,
      scope: _scope,
      search: search.trim(),
      limit: 10000,
      offset: 0,
    );

    final facilities = <HealthFacility>[];

    for (final row in rows) {
      if (!_matchesFacility(
        row,
        regionId: regionId,
        districtId: districtId,
        facilityLevelId: facilityLevelId,
        ownershipTypeId: ownershipTypeId,
      )) {
        continue;
      }

      try {
        facilities.add(HealthFacility.fromJson(row));
      } catch (_) {
        // Ignore invalid cached rows.
      }
    }

    facilities.sort(
      (a, b) =>
          a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()),
    );

    return LocalPage<HealthFacility>(
      items: _paginate(facilities, page: safePage, perPage: safePerPage),
      totalItems: facilities.length,
      page: safePage,
      perPage: safePerPage,
    );
  }

  // =========================================================
  // FACILITY DELETE
  // =========================================================

  Future<void> removeFacility(String id) {
    return _cache.remove(type: _facilityType, id: id, scope: _scope);
  }

  // =========================================================
  // REGIONS
  // =========================================================

  Future<void> saveRegions(Iterable<Region> items) {
    return _saveReferences(
      type: _regionType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
    );
  }

  Future<LocalPage<Region>> regions({int page = 1, int perPage = 100}) {
    return _referencePage(
      type: _regionType,
      page: page,
      perPage: perPage,
      fromJson: Region.fromJson,
    );
  }

  // =========================================================
  // DISTRICTS
  // =========================================================

  Future<void> saveDistricts(Iterable<District> items) {
    return _saveReferences(
      type: _districtType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
      metadata: (json) => {'regionId': json['region_id'] ?? json['regionId']},
    );
  }

  Future<LocalPage<District>> districts({
    int page = 1,
    int perPage = 100,
    String regionId = '',
  }) {
    return _referencePage(
      type: _districtType,
      page: page,
      perPage: perPage,
      fromJson: District.fromJson,
      filter: (json) =>
          _matchesString(json['region_id'] ?? json['regionId'], regionId),
    );
  }

  // =========================================================
  // HEALTH SUB REGIONS
  // =========================================================

  Future<void> saveHealthSubRegions(Iterable<HealthSubRegion> items) {
    return _saveReferences(
      type: _healthSubRegionType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
      metadata: (json) => {'regionId': json['region_id'] ?? json['regionId']},
    );
  }

  Future<LocalPage<HealthSubRegion>> healthSubRegions({
    int page = 1,
    int perPage = 100,
    String regionId = '',
  }) {
    return _referencePage(
      type: _healthSubRegionType,
      page: page,
      perPage: perPage,
      fromJson: HealthSubRegion.fromJson,
      filter: (json) =>
          _matchesString(json['region_id'] ?? json['regionId'], regionId),
    );
  }

  // =========================================================
  // HEALTH SUB DISTRICTS
  // =========================================================

  Future<void> saveHealthSubDistricts(Iterable<HealthSubDistrict> items) {
    return _saveReferences(
      type: _healthSubDistrictType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
      metadata: (json) => {
        'districtId': json['district_id'] ?? json['districtId'],
      },
    );
  }

  Future<LocalPage<HealthSubDistrict>> healthSubDistricts({
    int page = 1,
    int perPage = 100,
    String districtId = '',
  }) {
    return _referencePage(
      type: _healthSubDistrictType,
      page: page,
      perPage: perPage,
      fromJson: HealthSubDistrict.fromJson,
      filter: (json) =>
          _matchesString(json['district_id'] ?? json['districtId'], districtId),
    );
  }

  // =========================================================
  // COUNTIES
  // =========================================================

  Future<void> saveCounties(Iterable<County> items) {
    return _saveReferences(
      type: _countyType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
      metadata: (json) => {
        'districtId': json['district_id'] ?? json['districtId'],
      },
    );
  }

  Future<LocalPage<County>> counties({
    int page = 1,
    int perPage = 100,
    String districtId = '',
  }) {
    return _referencePage(
      type: _countyType,
      page: page,
      perPage: perPage,
      fromJson: County.fromJson,
      filter: (json) =>
          _matchesString(json['district_id'] ?? json['districtId'], districtId),
    );
  }

  // =========================================================
  // SUBCOUNTIES
  // =========================================================

  Future<void> saveSubcounties(Iterable<Subcounty> items) {
    return _saveReferences(
      type: _subcountyType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
      metadata: (json) => {
        'districtId': json['district_id'] ?? json['districtId'],
        'countyId': json['county_id'] ?? json['countyId'],
      },
    );
  }

  Future<LocalPage<Subcounty>> subcounties({
    int page = 1,
    int perPage = 100,
    String districtId = '',
    String countyId = '',
  }) {
    return _referencePage(
      type: _subcountyType,
      page: page,
      perPage: perPage,
      fromJson: Subcounty.fromJson,
      filter: (json) {
        return _matchesString(
              json['district_id'] ?? json['districtId'],
              districtId,
            ) &&
            _matchesString(json['county_id'] ?? json['countyId'], countyId);
      },
    );
  }

  // =========================================================
  // PARISHES
  // =========================================================

  Future<void> saveParishes(Iterable<Parish> items) {
    return _saveReferences(
      type: _parishType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
      metadata: (json) => {
        'subcountyId': json['subcounty_id'] ?? json['subcountyId'],
      },
    );
  }

  Future<LocalPage<Parish>> parishes({
    int page = 1,
    int perPage = 100,
    String subcountyId = '',
  }) {
    return _referencePage(
      type: _parishType,
      page: page,
      perPage: perPage,
      fromJson: Parish.fromJson,
      filter: (json) => _matchesString(
        json['subcounty_id'] ?? json['subcountyId'],
        subcountyId,
      ),
    );
  }

  // =========================================================
  // AUTHORITIES
  // =========================================================

  Future<void> saveAuthorities(Iterable<Authority> items) {
    return _saveReferences(
      type: _authorityType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
      metadata: (json) => {
        'ownershipTypeId': json['ownership_type_id'] ?? json['ownershipTypeId'],
      },
    );
  }

  Future<LocalPage<Authority>> authorities({
    int page = 1,
    int perPage = 100,
    String ownershipTypeId = '',
  }) {
    return _referencePage(
      type: _authorityType,
      page: page,
      perPage: perPage,
      fromJson: Authority.fromJson,
      filter: (json) => _matchesString(
        json['ownership_type_id'] ?? json['ownershipTypeId'],
        ownershipTypeId,
      ),
    );
  }

  // =========================================================
  // FACILITY LEVELS
  // =========================================================

  Future<void> saveFacilityLevels(Iterable<FacilityLevel> items) {
    return _saveReferences(
      type: _facilityLevelType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
    );
  }

  Future<LocalPage<FacilityLevel>> facilityLevels({
    int page = 1,
    int perPage = 100,
  }) {
    return _referencePage(
      type: _facilityLevelType,
      page: page,
      perPage: perPage,
      fromJson: FacilityLevel.fromJson,
    );
  }

  // =========================================================
  // OWNERSHIP TYPES
  // =========================================================

  Future<void> saveOwnershipTypes(Iterable<OwnershipType> items) {
    return _saveReferences(
      type: _ownershipType,
      items: items,
      id: (item) => item.id,
      json: (item) => item.toJson(),
    );
  }

  Future<LocalPage<OwnershipType>> ownershipTypes({
    int page = 1,
    int perPage = 100,
  }) {
    return _referencePage(
      type: _ownershipType,
      page: page,
      perPage: perPage,
      fromJson: OwnershipType.fromJson,
    );
  }

  // =========================================================
  // GENERIC REFERENCE SAVE
  // =========================================================

  Future<void> _saveReferences<T>({
    required String type,
    required Iterable<T> items,
    required String Function(T item) id,
    required Map<String, dynamic> Function(T item) json,
    Map<String, dynamic> Function(Map<String, dynamic> json)? metadata,
  }) async {
    if (items.isEmpty) {
      return;
    }

    await _cache.putMany(
      type: type,
      scope: _scope,
      entities: items.map((item) {
        final value = json(item);

        return CachedEntityInput(
          id: id(item),
          data: value,
          searchableText: _referenceSearchableText(value),
          metadata: metadata?.call(value) ?? const {},
          remoteUpdatedAt: _updatedAt(value),
        );
      }),
    );
  }

  // =========================================================
  // GENERIC REFERENCE PAGE
  // =========================================================

  Future<LocalPage<T>> _referencePage<T>({
    required String type,
    required int page,
    required int perPage,
    required T Function(Map<String, dynamic>) fromJson,
    bool Function(Map<String, dynamic>)? filter,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    final rows = await _cache.list(
      type: type,
      scope: _scope,
      limit: 10000,
      offset: 0,
    );

    final values = <T>[];

    for (final row in rows) {
      if (filter != null && !filter(row)) {
        continue;
      }

      try {
        values.add(fromJson(row));
      } catch (_) {
        // Ignore corrupt reference row.
      }
    }

    values.sort((a, b) => _referenceName(a).compareTo(_referenceName(b)));

    return LocalPage<T>(
      items: _paginate(values, page: safePage, perPage: safePerPage),
      totalItems: values.length,
      page: safePage,
      perPage: safePerPage,
    );
  }

  String _referenceName(dynamic item) {
    try {
      final value = item.toJson();

      return (value['name'] ?? value['title'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
    } catch (_) {
      return item.toString().toLowerCase();
    }
  }

  // =========================================================
  // FACILITY FILTERS
  // =========================================================

  bool _matchesFacility(
    Map<String, dynamic> json, {
    required String regionId,
    required String districtId,
    required String facilityLevelId,
    required String ownershipTypeId,
  }) {
    if (!_matchesString(json['region_id'] ?? json['regionId'], regionId)) {
      return false;
    }

    if (!_matchesString(
      json['district_id'] ?? json['districtId'],
      districtId,
    )) {
      return false;
    }

    if (!_matchesString(
      json['facility_level_id'] ?? json['facilityLevelId'],
      facilityLevelId,
    )) {
      return false;
    }

    if (!_matchesString(
      json['ownership_type_id'] ?? json['ownershipTypeId'],
      ownershipTypeId,
    )) {
      return false;
    }

    return true;
  }

  bool _matchesString(dynamic value, String filter) {
    final normalizedFilter = filter.trim().toLowerCase();

    if (normalizedFilter.isEmpty) {
      return true;
    }

    return (value ?? '').toString().trim().toLowerCase() == normalizedFilter;
  }

  // =========================================================
  // SEARCHABLE TEXT
  // =========================================================

  String _facilitySearchableText(Map<String, dynamic> json) {
    return [
          json['name'],
          json['nhpi_code'],
          json['nhpiCode'],
          json['hsdt_code'],
          json['hsdtCode'],
          json['region_name'],
          json['regionName'],
          json['district_name'],
          json['districtName'],
          json['county_name'],
          json['countyName'],
          json['subcounty_name'],
          json['subcountyName'],
          json['parish_name'],
          json['parishName'],
          json['facility_level_name'],
          json['facilityLevelName'],
          json['ownership_display'],
          json['ownershipDisplay'],
          json['authority_name'],
          json['authorityName'],
        ]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .join(' ')
        .toLowerCase();
  }

  String _referenceSearchableText(Map<String, dynamic> json) {
    return [json['name'], json['code'], json['title'], json['description']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .join(' ')
        .toLowerCase();
  }

  Map<String, dynamic> _facilityMetadata(Map<String, dynamic> json) {
    return {
      'regionId': json['region_id'] ?? json['regionId'],
      'districtId': json['district_id'] ?? json['districtId'],
      'facilityLevelId': json['facility_level_id'] ?? json['facilityLevelId'],
      'ownershipTypeId': json['ownership_type_id'] ?? json['ownershipTypeId'],
      'nhpiCode': json['nhpi_code'] ?? json['nhpiCode'],
    };
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasFacilities() {
    return _cache.hasData(type: _facilityType, scope: _scope);
  }

  Future<bool> facilitiesAreStale({
    Duration maxAge = const Duration(hours: 24),
  }) {
    return _cache.isStale(type: _facilityType, scope: _scope, maxAge: maxAge);
  }

  Future<void> clearFacilities() {
    return _cache.clearType(type: _facilityType, scope: _scope);
  }

  Future<void> clearAll() async {
    for (final type in [
      _facilityType,
      _regionType,
      _districtType,
      _healthSubRegionType,
      _healthSubDistrictType,
      _countyType,
      _subcountyType,
      _parishType,
      _authorityType,
      _facilityLevelType,
      _ownershipType,
    ]) {
      await _cache.clearType(type: type, scope: _scope);
    }
  }

  // =========================================================
  // WATCH
  // =========================================================

  Stream<List<HealthFacility>> watchFacilities() {
    return _cache.watch(type: _facilityType, scope: _scope).map((rows) {
      final values = <HealthFacility>[];

      for (final row in rows) {
        try {
          values.add(HealthFacility.fromJson(row));
        } catch (_) {}
      }

      values.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return List<HealthFacility>.unmodifiable(values);
    });
  }

  // =========================================================
  // PAGINATION
  // =========================================================

  List<T> _paginate<T>(
    List<T> items, {
    required int page,
    required int perPage,
  }) {
    final start = (page - 1) * perPage;

    if (start >= items.length) {
      return <T>[];
    }

    final end = (start + perPage).clamp(0, items.length);

    return items.sublist(start, end);
  }

  // =========================================================
  // DATE
  // =========================================================

  DateTime? _updatedAt(Map<String, dynamic> json) {
    final value =
        json['updated_at'] ??
        json['updated'] ??
        json['created_at'] ??
        json['created'];

    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}

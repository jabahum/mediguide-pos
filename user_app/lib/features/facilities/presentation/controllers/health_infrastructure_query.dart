final class HealthInfrastructureQuery {
  const HealthInfrastructureQuery({
    this.search = '',
    this.regionId = '',
    this.districtId = '',
    this.facilityLevelId = '',
    this.ownershipTypeId = '',
    this.treeFilters = const {},
  });

  static const empty = HealthInfrastructureQuery();

  final String search;
  final String regionId;
  final String districtId;
  final String facilityLevelId;
  final String ownershipTypeId;

  final Map<String, dynamic> treeFilters;

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      regionId.isNotEmpty ||
      districtId.isNotEmpty ||
      facilityLevelId.isNotEmpty ||
      ownershipTypeId.isNotEmpty;

  HealthInfrastructureQuery copyWith({
    String? search,
    String? regionId,
    String? districtId,
    String? facilityLevelId,
    String? ownershipTypeId,
    Map<String, dynamic>? treeFilters,
  }) {
    return HealthInfrastructureQuery(
      search: search ?? this.search,
      regionId: regionId ?? this.regionId,
      districtId: districtId ?? this.districtId,
      facilityLevelId: facilityLevelId ?? this.facilityLevelId,
      ownershipTypeId: ownershipTypeId ?? this.ownershipTypeId,
      treeFilters: treeFilters ?? this.treeFilters,
    );
  }

  factory HealthInfrastructureQuery.fromArguments(Object? arguments) {
    if (arguments is! Map) {
      return HealthInfrastructureQuery.empty;
    }

    final rawTreeFilters = arguments['treeFilters'];

    if (rawTreeFilters is! Map) {
      return HealthInfrastructureQuery.empty;
    }

    final filters = Map<String, dynamic>.from(rawTreeFilters);

    return HealthInfrastructureQuery(
      regionId: filters['region']?.toString().trim() ?? '',
      districtId: filters['district']?.toString().trim() ?? '',
      facilityLevelId: filters['facility_level']?.toString().trim() ?? '',
      ownershipTypeId: filters['ownership_type']?.toString().trim() ?? '',
      treeFilters: filters,
    );
  }
}

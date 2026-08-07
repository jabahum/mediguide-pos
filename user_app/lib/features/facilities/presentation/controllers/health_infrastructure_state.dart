import 'package:user_app/features/facilities/presentation/controllers/health_infrastructure_query.dart';
import 'package:user_app/shared/models/models.dart';

final class HealthInfrastructureState {
  const HealthInfrastructureState({
    this.query = HealthInfrastructureQuery.empty,
    this.availableRegions = const [],
    this.availableDistricts = const [],
    this.availableFacilityLevels = const [],
    this.availableOwnershipTypes = const [],
    this.isLoadingFilters = false,
    this.filterError,
  });

  final HealthInfrastructureQuery query;

  final List<Region> availableRegions;
  final List<District> availableDistricts;
  final List<FacilityLevel> availableFacilityLevels;
  final List<OwnershipType> availableOwnershipTypes;

  final bool isLoadingFilters;
  final String? filterError;

  bool get hasActiveFilters => query.hasActiveFilters;

  bool get isFiltering => query.hasActiveFilters;

  String get searchQuery => query.search;
  String get regionId => query.regionId;
  String get districtId => query.districtId;
  String get facilityLevelId => query.facilityLevelId;
  String get ownershipTypeId => query.ownershipTypeId;

  Map<String, dynamic> get treeFilters => query.treeFilters;

  HealthInfrastructureState copyWith({
    HealthInfrastructureQuery? query,
    List<Region>? availableRegions,
    List<District>? availableDistricts,
    List<FacilityLevel>? availableFacilityLevels,
    List<OwnershipType>? availableOwnershipTypes,
    bool? isLoadingFilters,
    String? filterError,
    bool clearFilterError = false,
  }) {
    return HealthInfrastructureState(
      query: query ?? this.query,
      availableRegions: availableRegions ?? this.availableRegions,
      availableDistricts: availableDistricts ?? this.availableDistricts,
      availableFacilityLevels:
          availableFacilityLevels ?? this.availableFacilityLevels,
      availableOwnershipTypes:
          availableOwnershipTypes ?? this.availableOwnershipTypes,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      filterError: clearFilterError ? null : filterError ?? this.filterError,
    );
  }
}

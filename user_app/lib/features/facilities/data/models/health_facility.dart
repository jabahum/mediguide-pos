import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/facilities/data/models/authority.dart';
import 'package:user_app/features/facilities/data/models/county.dart';
import 'package:user_app/features/facilities/data/models/district.dart';
import 'package:user_app/features/facilities/data/models/facility_level.dart';
import 'package:user_app/features/facilities/data/models/health_sub_district.dart';
import 'package:user_app/features/facilities/data/models/health_sub_region.dart';
import 'package:user_app/features/facilities/data/models/ownership_type.dart';
import 'package:user_app/features/facilities/data/models/parish.dart';
import 'package:user_app/features/facilities/data/models/region.dart';
import 'package:user_app/features/facilities/data/models/subcounty.dart';

part 'health_facility.freezed.dart';
part 'health_facility.g.dart';

@freezed
abstract class HealthFacility with _$HealthFacility {
  const HealthFacility._();

  const factory HealthFacility({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'facility_level_id') String? facilityLevelId,
    @JsonKey(name: 'facility_level_name') @Default('') String facilityLevelName,
    @JsonKey(name: 'facility_level_code') @Default('') String facilityLevelCode,
    @JsonKey(name: 'authority_id') String? authorityId,
    @JsonKey(name: 'authority_name') @Default('') String authorityName,
    @JsonKey(name: 'authority_code') @Default('') String authorityCode,
    @JsonKey(name: 'ownership_type_id') String? ownershipTypeId,
    @JsonKey(name: 'ownership_type_name') @Default('') String ownershipTypeName,
    @JsonKey(name: 'ownership_type_code') @Default('') String ownershipTypeCode,
    @JsonKey(name: 'health_sub_district_id') String? healthSubDistrictId,
    @JsonKey(name: 'health_sub_district_name')
    @Default('')
    String healthSubDistrictName,
    @JsonKey(name: 'parish_id') String? parishId,
    @JsonKey(name: 'parish_name') @Default('') String parishName,
    @JsonKey(name: 'subcounty_id') String? subcountyId,
    @JsonKey(name: 'subcounty_name') @Default('') String subcountyName,
    @JsonKey(name: 'county_id') String? countyId,
    @JsonKey(name: 'county_name') @Default('') String countyName,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'district_name') @Default('') String districtName,
    @JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,
    @JsonKey(name: 'health_sub_region_name')
    @Default('')
    String healthSubRegionName,
    @JsonKey(name: 'region_id') String? regionId,
    @JsonKey(name: 'region_name') @Default('') String regionName,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _HealthFacility;

  factory HealthFacility.fromJson(Map<String, dynamic> json) =>
      _$HealthFacilityFromJson(json);

  FacilityLevel? get facilityLevel => _has(facilityLevelId, facilityLevelName)
      ? FacilityLevel(
          id: facilityLevelId ?? '',
          name: facilityLevelName,
          code: facilityLevelCode,
        )
      : null;
  Authority? get authority => _has(authorityId, authorityName)
      ? Authority(
          id: authorityId ?? '',
          name: authorityName,
          code: authorityCode,
        )
      : null;
  OwnershipType? get ownershipType => _has(ownershipTypeId, ownershipTypeName)
      ? OwnershipType(
          id: ownershipTypeId ?? '',
          name: ownershipTypeName,
          code: ownershipTypeCode,
        )
      : null;
  HealthSubDistrict? get healthSubDistrict =>
      _has(healthSubDistrictId, healthSubDistrictName)
      ? HealthSubDistrict(
          id: healthSubDistrictId ?? '',
          name: healthSubDistrictName,
          districtId: districtId,
          districtName: districtName,
        )
      : null;
  Parish? get parish => _has(parishId, parishName)
      ? Parish(id: parishId ?? '', name: parishName, subcountyId: subcountyId)
      : null;
  Subcounty? get subcounty => _has(subcountyId, subcountyName)
      ? Subcounty(
          id: subcountyId ?? '',
          name: subcountyName,
          countyId: countyId,
          countyName: countyName,
          districtId: districtId,
          districtName: districtName,
        )
      : null;
  County? get county => _has(countyId, countyName)
      ? County(
          id: countyId ?? '',
          name: countyName,
          districtId: districtId,
          districtName: districtName,
        )
      : null;
  District? get district => _has(districtId, districtName)
      ? District(
          id: districtId ?? '',
          name: districtName,
          regionId: regionId,
          regionName: regionName,
          healthSubRegionId: healthSubRegionId,
          healthSubRegionName: healthSubRegionName,
        )
      : null;
  HealthSubRegion? get healthSubRegion =>
      _has(healthSubRegionId, healthSubRegionName)
      ? HealthSubRegion(
          id: healthSubRegionId ?? '',
          name: healthSubRegionName,
          regionId: regionId,
          regionName: regionName,
        )
      : null;
  Region? get region => _has(regionId, regionName)
      ? Region(id: regionId ?? '', name: regionName)
      : null;

  String get ownershipDisplay => ownershipTypeName.isNotEmpty
      ? ownershipTypeName
      : ownershipTypeCode.isNotEmpty
      ? 'Type: $ownershipTypeCode'
      : 'Unknown Ownership';
  String get fullAddress => [
    parishName,
    subcountyName,
    countyName,
    districtName,
    regionName,
  ].where((value) => value.isNotEmpty).join(', ');
  String get shortAddress => [
    subcountyName,
    districtName,
  ].where((value) => value.isNotEmpty).join(', ');
}

bool _has(String? id, String name) => id?.isNotEmpty == true || name.isNotEmpty;

@freezed
abstract class HealthFacilityRequest with _$HealthFacilityRequest {
  @JsonSerializable(includeIfNull: false)
  const factory HealthFacilityRequest({
    String? name,
    @JsonKey(name: 'nhpi_code') String? nhpiCode,
    @JsonKey(name: 'hsdt_code') String? hsdtCode,
    @JsonKey(name: 'facility_level_id') String? facilityLevelId,
    @JsonKey(name: 'authority_id') String? authorityId,
    @JsonKey(name: 'ownership_type_id') String? ownershipTypeId,
    @JsonKey(name: 'health_sub_district_id') String? healthSubDistrictId,
    @JsonKey(name: 'parish_id') String? parishId,
    @JsonKey(name: 'subcounty_id') String? subcountyId,
    @JsonKey(name: 'county_id') String? countyId,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,
    @JsonKey(name: 'region_id') String? regionId,
  }) = _HealthFacilityRequest;

  factory HealthFacilityRequest.fromJson(Map<String, dynamic> json) =>
      _$HealthFacilityRequestFromJson(json);
}

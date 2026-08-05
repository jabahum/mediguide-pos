import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'facility_reference.freezed.dart';
part 'facility_reference.g.dart';

@freezed
abstract class Region with _$Region {
  const factory Region({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Region;
  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);
}

@freezed
abstract class HealthSubRegion with _$HealthSubRegion {
  const factory HealthSubRegion({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'region_id') String? regionId,
    @JsonKey(name: 'region_name') @Default('') String regionName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _HealthSubRegion;
  factory HealthSubRegion.fromJson(Map<String, dynamic> json) =>
      _$HealthSubRegionFromJson(json);
}

@freezed
abstract class District with _$District {
  const factory District({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'region_id') String? regionId,
    @JsonKey(name: 'region_name') @Default('') String regionName,
    @JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,
    @JsonKey(name: 'health_sub_region_name')
    @Default('')
    String healthSubRegionName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _District;
  factory District.fromJson(Map<String, dynamic> json) =>
      _$DistrictFromJson(json);
}

@freezed
abstract class HealthSubDistrict with _$HealthSubDistrict {
  const factory HealthSubDistrict({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'district_name') @Default('') String districtName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _HealthSubDistrict;
  factory HealthSubDistrict.fromJson(Map<String, dynamic> json) =>
      _$HealthSubDistrictFromJson(json);
}

@freezed
abstract class County with _$County {
  const factory County({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'district_name') @Default('') String districtName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _County;
  factory County.fromJson(Map<String, dynamic> json) => _$CountyFromJson(json);
}

@freezed
abstract class Subcounty with _$Subcounty {
  const factory Subcounty({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'county_id') String? countyId,
    @JsonKey(name: 'county_name') @Default('') String countyName,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'district_name') @Default('') String districtName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Subcounty;
  factory Subcounty.fromJson(Map<String, dynamic> json) =>
      _$SubcountyFromJson(json);
}

@freezed
abstract class Parish with _$Parish {
  const factory Parish({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'nhpi_code') @Default('') String nhpiCode,
    @JsonKey(name: 'hsdt_code') @Default('') String hsdtCode,
    @JsonKey(name: 'subcounty_id') String? subcountyId,
    @JsonKey(name: 'subcounty_name') @Default('') String subcountyName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Parish;
  factory Parish.fromJson(Map<String, dynamic> json) => _$ParishFromJson(json);
}

@freezed
abstract class FacilityLevel with _$FacilityLevel {
  const factory FacilityLevel({
    required String id,
    @Default('') String name,
    @Default('') String code,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _FacilityLevel;
  factory FacilityLevel.fromJson(Map<String, dynamic> json) =>
      _$FacilityLevelFromJson(json);
}

@freezed
abstract class OwnershipType with _$OwnershipType {
  const factory OwnershipType({
    required String id,
    @Default('') String name,
    @Default('') String code,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _OwnershipType;
  factory OwnershipType.fromJson(Map<String, dynamic> json) =>
      _$OwnershipTypeFromJson(json);
}

@freezed
abstract class Authority with _$Authority {
  const factory Authority({
    required String id,
    @Default('') String name,
    String? code,
    @JsonKey(name: 'ownership_type_id') String? ownershipTypeId,
    @JsonKey(name: 'ownership_type_name') @Default('') String ownershipTypeName,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Authority;
  factory Authority.fromJson(Map<String, dynamic> json) =>
      _$AuthorityFromJson(json);
}

/// Typed write contract shared by the backend facility-reference endpoints.
@freezed
abstract class FacilityReferenceRequest with _$FacilityReferenceRequest {
  @JsonSerializable(includeIfNull: false)
  const factory FacilityReferenceRequest({
    String? name,
    String? code,
    @JsonKey(name: 'nhpi_code') String? nhpiCode,
    @JsonKey(name: 'hsdt_code') String? hsdtCode,
    @JsonKey(name: 'region_id') String? regionId,
    @JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'county_id') String? countyId,
    @JsonKey(name: 'subcounty_id') String? subcountyId,
    @JsonKey(name: 'ownership_type_id') String? ownershipTypeId,
  }) = _FacilityReferenceRequest;
  factory FacilityReferenceRequest.fromJson(Map<String, dynamic> json) =>
      _$FacilityReferenceRequestFromJson(json);
}

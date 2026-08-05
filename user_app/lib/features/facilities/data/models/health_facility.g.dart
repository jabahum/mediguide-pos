// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_facility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthFacility _$HealthFacilityFromJson(Map<String, dynamic> json) =>
    _HealthFacility(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nhpiCode: json['nhpi_code'] as String? ?? '',
      hsdtCode: json['hsdt_code'] as String? ?? '',
      facilityLevelId: json['facility_level_id'] as String?,
      facilityLevelName: json['facility_level_name'] as String? ?? '',
      facilityLevelCode: json['facility_level_code'] as String? ?? '',
      authorityId: json['authority_id'] as String?,
      authorityName: json['authority_name'] as String? ?? '',
      authorityCode: json['authority_code'] as String? ?? '',
      ownershipTypeId: json['ownership_type_id'] as String?,
      ownershipTypeName: json['ownership_type_name'] as String? ?? '',
      ownershipTypeCode: json['ownership_type_code'] as String? ?? '',
      healthSubDistrictId: json['health_sub_district_id'] as String?,
      healthSubDistrictName: json['health_sub_district_name'] as String? ?? '',
      parishId: json['parish_id'] as String?,
      parishName: json['parish_name'] as String? ?? '',
      subcountyId: json['subcounty_id'] as String?,
      subcountyName: json['subcounty_name'] as String? ?? '',
      countyId: json['county_id'] as String?,
      countyName: json['county_name'] as String? ?? '',
      districtId: json['district_id'] as String?,
      districtName: json['district_name'] as String? ?? '',
      healthSubRegionId: json['health_sub_region_id'] as String?,
      healthSubRegionName: json['health_sub_region_name'] as String? ?? '',
      regionId: json['region_id'] as String?,
      regionName: json['region_name'] as String? ?? '',
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$HealthFacilityToJson(
  _HealthFacility instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'facility_level_id': instance.facilityLevelId,
  'facility_level_name': instance.facilityLevelName,
  'facility_level_code': instance.facilityLevelCode,
  'authority_id': instance.authorityId,
  'authority_name': instance.authorityName,
  'authority_code': instance.authorityCode,
  'ownership_type_id': instance.ownershipTypeId,
  'ownership_type_name': instance.ownershipTypeName,
  'ownership_type_code': instance.ownershipTypeCode,
  'health_sub_district_id': instance.healthSubDistrictId,
  'health_sub_district_name': instance.healthSubDistrictName,
  'parish_id': instance.parishId,
  'parish_name': instance.parishName,
  'subcounty_id': instance.subcountyId,
  'subcounty_name': instance.subcountyName,
  'county_id': instance.countyId,
  'county_name': instance.countyName,
  'district_id': instance.districtId,
  'district_name': instance.districtName,
  'health_sub_region_id': instance.healthSubRegionId,
  'health_sub_region_name': instance.healthSubRegionName,
  'region_id': instance.regionId,
  'region_name': instance.regionName,
  'usage_count': instance.usageCount,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_HealthFacilityRequest _$HealthFacilityRequestFromJson(
  Map<String, dynamic> json,
) => _HealthFacilityRequest(
  name: json['name'] as String?,
  nhpiCode: json['nhpi_code'] as String?,
  hsdtCode: json['hsdt_code'] as String?,
  facilityLevelId: json['facility_level_id'] as String?,
  authorityId: json['authority_id'] as String?,
  ownershipTypeId: json['ownership_type_id'] as String?,
  healthSubDistrictId: json['health_sub_district_id'] as String?,
  parishId: json['parish_id'] as String?,
  subcountyId: json['subcounty_id'] as String?,
  countyId: json['county_id'] as String?,
  districtId: json['district_id'] as String?,
  healthSubRegionId: json['health_sub_region_id'] as String?,
  regionId: json['region_id'] as String?,
);

Map<String, dynamic> _$HealthFacilityRequestToJson(
  _HealthFacilityRequest instance,
) => <String, dynamic>{
  if (instance.name case final value?) 'name': value,
  if (instance.nhpiCode case final value?) 'nhpi_code': value,
  if (instance.hsdtCode case final value?) 'hsdt_code': value,
  if (instance.facilityLevelId case final value?) 'facility_level_id': value,
  if (instance.authorityId case final value?) 'authority_id': value,
  if (instance.ownershipTypeId case final value?) 'ownership_type_id': value,
  if (instance.healthSubDistrictId case final value?)
    'health_sub_district_id': value,
  if (instance.parishId case final value?) 'parish_id': value,
  if (instance.subcountyId case final value?) 'subcounty_id': value,
  if (instance.countyId case final value?) 'county_id': value,
  if (instance.districtId case final value?) 'district_id': value,
  if (instance.healthSubRegionId case final value?)
    'health_sub_region_id': value,
  if (instance.regionId case final value?) 'region_id': value,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Region _$RegionFromJson(Map<String, dynamic> json) => _Region(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  nhpiCode: json['nhpi_code'] as String? ?? '',
  hsdtCode: json['hsdt_code'] as String? ?? '',
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$RegionToJson(_Region instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_HealthSubRegion _$HealthSubRegionFromJson(Map<String, dynamic> json) =>
    _HealthSubRegion(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nhpiCode: json['nhpi_code'] as String? ?? '',
      hsdtCode: json['hsdt_code'] as String? ?? '',
      regionId: json['region_id'] as String?,
      regionName: json['region_name'] as String? ?? '',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$HealthSubRegionToJson(
  _HealthSubRegion instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'region_id': instance.regionId,
  'region_name': instance.regionName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_District _$DistrictFromJson(Map<String, dynamic> json) => _District(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  nhpiCode: json['nhpi_code'] as String? ?? '',
  hsdtCode: json['hsdt_code'] as String? ?? '',
  regionId: json['region_id'] as String?,
  regionName: json['region_name'] as String? ?? '',
  healthSubRegionId: json['health_sub_region_id'] as String?,
  healthSubRegionName: json['health_sub_region_name'] as String? ?? '',
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$DistrictToJson(_District instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'region_id': instance.regionId,
  'region_name': instance.regionName,
  'health_sub_region_id': instance.healthSubRegionId,
  'health_sub_region_name': instance.healthSubRegionName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_HealthSubDistrict _$HealthSubDistrictFromJson(Map<String, dynamic> json) =>
    _HealthSubDistrict(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nhpiCode: json['nhpi_code'] as String? ?? '',
      hsdtCode: json['hsdt_code'] as String? ?? '',
      districtId: json['district_id'] as String?,
      districtName: json['district_name'] as String? ?? '',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$HealthSubDistrictToJson(
  _HealthSubDistrict instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'district_id': instance.districtId,
  'district_name': instance.districtName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_County _$CountyFromJson(Map<String, dynamic> json) => _County(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  nhpiCode: json['nhpi_code'] as String? ?? '',
  hsdtCode: json['hsdt_code'] as String? ?? '',
  districtId: json['district_id'] as String?,
  districtName: json['district_name'] as String? ?? '',
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$CountyToJson(_County instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'district_id': instance.districtId,
  'district_name': instance.districtName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_Subcounty _$SubcountyFromJson(Map<String, dynamic> json) => _Subcounty(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  nhpiCode: json['nhpi_code'] as String? ?? '',
  hsdtCode: json['hsdt_code'] as String? ?? '',
  countyId: json['county_id'] as String?,
  countyName: json['county_name'] as String? ?? '',
  districtId: json['district_id'] as String?,
  districtName: json['district_name'] as String? ?? '',
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$SubcountyToJson(
  _Subcounty instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'county_id': instance.countyId,
  'county_name': instance.countyName,
  'district_id': instance.districtId,
  'district_name': instance.districtName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_Parish _$ParishFromJson(Map<String, dynamic> json) => _Parish(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  nhpiCode: json['nhpi_code'] as String? ?? '',
  hsdtCode: json['hsdt_code'] as String? ?? '',
  subcountyId: json['subcounty_id'] as String?,
  subcountyName: json['subcounty_name'] as String? ?? '',
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$ParishToJson(_Parish instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nhpi_code': instance.nhpiCode,
  'hsdt_code': instance.hsdtCode,
  'subcounty_id': instance.subcountyId,
  'subcounty_name': instance.subcountyName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_FacilityLevel _$FacilityLevelFromJson(Map<String, dynamic> json) =>
    _FacilityLevel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$FacilityLevelToJson(
  _FacilityLevel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_OwnershipType _$OwnershipTypeFromJson(Map<String, dynamic> json) =>
    _OwnershipType(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$OwnershipTypeToJson(
  _OwnershipType instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_Authority _$AuthorityFromJson(Map<String, dynamic> json) => _Authority(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  code: json['code'] as String?,
  ownershipTypeId: json['ownership_type_id'] as String?,
  ownershipTypeName: json['ownership_type_name'] as String? ?? '',
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$AuthorityToJson(
  _Authority instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'ownership_type_id': instance.ownershipTypeId,
  'ownership_type_name': instance.ownershipTypeName,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_FacilityReferenceRequest _$FacilityReferenceRequestFromJson(
  Map<String, dynamic> json,
) => _FacilityReferenceRequest(
  name: json['name'] as String?,
  code: json['code'] as String?,
  nhpiCode: json['nhpi_code'] as String?,
  hsdtCode: json['hsdt_code'] as String?,
  regionId: json['region_id'] as String?,
  healthSubRegionId: json['health_sub_region_id'] as String?,
  districtId: json['district_id'] as String?,
  countyId: json['county_id'] as String?,
  subcountyId: json['subcounty_id'] as String?,
  ownershipTypeId: json['ownership_type_id'] as String?,
);

Map<String, dynamic> _$FacilityReferenceRequestToJson(
  _FacilityReferenceRequest instance,
) => <String, dynamic>{
  if (instance.name case final value?) 'name': value,
  if (instance.code case final value?) 'code': value,
  if (instance.nhpiCode case final value?) 'nhpi_code': value,
  if (instance.hsdtCode case final value?) 'hsdt_code': value,
  if (instance.regionId case final value?) 'region_id': value,
  if (instance.healthSubRegionId case final value?)
    'health_sub_region_id': value,
  if (instance.districtId case final value?) 'district_id': value,
  if (instance.countyId case final value?) 'county_id': value,
  if (instance.subcountyId case final value?) 'subcounty_id': value,
  if (instance.ownershipTypeId case final value?) 'ownership_type_id': value,
};

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_facility.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthFacility {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'facility_level_id') String? get facilityLevelId;@JsonKey(name: 'facility_level_name') String get facilityLevelName;@JsonKey(name: 'facility_level_code') String get facilityLevelCode;@JsonKey(name: 'authority_id') String? get authorityId;@JsonKey(name: 'authority_name') String get authorityName;@JsonKey(name: 'authority_code') String get authorityCode;@JsonKey(name: 'ownership_type_id') String? get ownershipTypeId;@JsonKey(name: 'ownership_type_name') String get ownershipTypeName;@JsonKey(name: 'ownership_type_code') String get ownershipTypeCode;@JsonKey(name: 'health_sub_district_id') String? get healthSubDistrictId;@JsonKey(name: 'health_sub_district_name') String get healthSubDistrictName;@JsonKey(name: 'parish_id') String? get parishId;@JsonKey(name: 'parish_name') String get parishName;@JsonKey(name: 'subcounty_id') String? get subcountyId;@JsonKey(name: 'subcounty_name') String get subcountyName;@JsonKey(name: 'county_id') String? get countyId;@JsonKey(name: 'county_name') String get countyName;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'district_name') String get districtName;@JsonKey(name: 'health_sub_region_id') String? get healthSubRegionId;@JsonKey(name: 'health_sub_region_name') String get healthSubRegionName;@JsonKey(name: 'region_id') String? get regionId;@JsonKey(name: 'region_name') String get regionName;@JsonKey(name: 'usage_count') int get usageCount;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of HealthFacility
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthFacilityCopyWith<HealthFacility> get copyWith => _$HealthFacilityCopyWithImpl<HealthFacility>(this as HealthFacility, _$identity);

  /// Serializes this HealthFacility to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthFacility&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.facilityLevelId, facilityLevelId) || other.facilityLevelId == facilityLevelId)&&(identical(other.facilityLevelName, facilityLevelName) || other.facilityLevelName == facilityLevelName)&&(identical(other.facilityLevelCode, facilityLevelCode) || other.facilityLevelCode == facilityLevelCode)&&(identical(other.authorityId, authorityId) || other.authorityId == authorityId)&&(identical(other.authorityName, authorityName) || other.authorityName == authorityName)&&(identical(other.authorityCode, authorityCode) || other.authorityCode == authorityCode)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId)&&(identical(other.ownershipTypeName, ownershipTypeName) || other.ownershipTypeName == ownershipTypeName)&&(identical(other.ownershipTypeCode, ownershipTypeCode) || other.ownershipTypeCode == ownershipTypeCode)&&(identical(other.healthSubDistrictId, healthSubDistrictId) || other.healthSubDistrictId == healthSubDistrictId)&&(identical(other.healthSubDistrictName, healthSubDistrictName) || other.healthSubDistrictName == healthSubDistrictName)&&(identical(other.parishId, parishId) || other.parishId == parishId)&&(identical(other.parishName, parishName) || other.parishName == parishName)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.subcountyName, subcountyName) || other.subcountyName == subcountyName)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.countyName, countyName) || other.countyName == countyName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.healthSubRegionName, healthSubRegionName) || other.healthSubRegionName == healthSubRegionName)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,nhpiCode,hsdtCode,facilityLevelId,facilityLevelName,facilityLevelCode,authorityId,authorityName,authorityCode,ownershipTypeId,ownershipTypeName,ownershipTypeCode,healthSubDistrictId,healthSubDistrictName,parishId,parishName,subcountyId,subcountyName,countyId,countyName,districtId,districtName,healthSubRegionId,healthSubRegionName,regionId,regionName,usageCount,createdAt,updatedAt]);

@override
String toString() {
  return 'HealthFacility(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, facilityLevelId: $facilityLevelId, facilityLevelName: $facilityLevelName, facilityLevelCode: $facilityLevelCode, authorityId: $authorityId, authorityName: $authorityName, authorityCode: $authorityCode, ownershipTypeId: $ownershipTypeId, ownershipTypeName: $ownershipTypeName, ownershipTypeCode: $ownershipTypeCode, healthSubDistrictId: $healthSubDistrictId, healthSubDistrictName: $healthSubDistrictName, parishId: $parishId, parishName: $parishName, subcountyId: $subcountyId, subcountyName: $subcountyName, countyId: $countyId, countyName: $countyName, districtId: $districtId, districtName: $districtName, healthSubRegionId: $healthSubRegionId, healthSubRegionName: $healthSubRegionName, regionId: $regionId, regionName: $regionName, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $HealthFacilityCopyWith<$Res>  {
  factory $HealthFacilityCopyWith(HealthFacility value, $Res Function(HealthFacility) _then) = _$HealthFacilityCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'facility_level_id') String? facilityLevelId,@JsonKey(name: 'facility_level_name') String facilityLevelName,@JsonKey(name: 'facility_level_code') String facilityLevelCode,@JsonKey(name: 'authority_id') String? authorityId,@JsonKey(name: 'authority_name') String authorityName,@JsonKey(name: 'authority_code') String authorityCode,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId,@JsonKey(name: 'ownership_type_name') String ownershipTypeName,@JsonKey(name: 'ownership_type_code') String ownershipTypeCode,@JsonKey(name: 'health_sub_district_id') String? healthSubDistrictId,@JsonKey(name: 'health_sub_district_name') String healthSubDistrictName,@JsonKey(name: 'parish_id') String? parishId,@JsonKey(name: 'parish_name') String parishName,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'subcounty_name') String subcountyName,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'county_name') String countyName,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'health_sub_region_name') String healthSubRegionName,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$HealthFacilityCopyWithImpl<$Res>
    implements $HealthFacilityCopyWith<$Res> {
  _$HealthFacilityCopyWithImpl(this._self, this._then);

  final HealthFacility _self;
  final $Res Function(HealthFacility) _then;

/// Create a copy of HealthFacility
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? facilityLevelId = freezed,Object? facilityLevelName = null,Object? facilityLevelCode = null,Object? authorityId = freezed,Object? authorityName = null,Object? authorityCode = null,Object? ownershipTypeId = freezed,Object? ownershipTypeName = null,Object? ownershipTypeCode = null,Object? healthSubDistrictId = freezed,Object? healthSubDistrictName = null,Object? parishId = freezed,Object? parishName = null,Object? subcountyId = freezed,Object? subcountyName = null,Object? countyId = freezed,Object? countyName = null,Object? districtId = freezed,Object? districtName = null,Object? healthSubRegionId = freezed,Object? healthSubRegionName = null,Object? regionId = freezed,Object? regionName = null,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,facilityLevelId: freezed == facilityLevelId ? _self.facilityLevelId : facilityLevelId // ignore: cast_nullable_to_non_nullable
as String?,facilityLevelName: null == facilityLevelName ? _self.facilityLevelName : facilityLevelName // ignore: cast_nullable_to_non_nullable
as String,facilityLevelCode: null == facilityLevelCode ? _self.facilityLevelCode : facilityLevelCode // ignore: cast_nullable_to_non_nullable
as String,authorityId: freezed == authorityId ? _self.authorityId : authorityId // ignore: cast_nullable_to_non_nullable
as String?,authorityName: null == authorityName ? _self.authorityName : authorityName // ignore: cast_nullable_to_non_nullable
as String,authorityCode: null == authorityCode ? _self.authorityCode : authorityCode // ignore: cast_nullable_to_non_nullable
as String,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeName: null == ownershipTypeName ? _self.ownershipTypeName : ownershipTypeName // ignore: cast_nullable_to_non_nullable
as String,ownershipTypeCode: null == ownershipTypeCode ? _self.ownershipTypeCode : ownershipTypeCode // ignore: cast_nullable_to_non_nullable
as String,healthSubDistrictId: freezed == healthSubDistrictId ? _self.healthSubDistrictId : healthSubDistrictId // ignore: cast_nullable_to_non_nullable
as String?,healthSubDistrictName: null == healthSubDistrictName ? _self.healthSubDistrictName : healthSubDistrictName // ignore: cast_nullable_to_non_nullable
as String,parishId: freezed == parishId ? _self.parishId : parishId // ignore: cast_nullable_to_non_nullable
as String?,parishName: null == parishName ? _self.parishName : parishName // ignore: cast_nullable_to_non_nullable
as String,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,subcountyName: null == subcountyName ? _self.subcountyName : subcountyName // ignore: cast_nullable_to_non_nullable
as String,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,countyName: null == countyName ? _self.countyName : countyName // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionName: null == healthSubRegionName ? _self.healthSubRegionName : healthSubRegionName // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _HealthFacility extends HealthFacility {
  const _HealthFacility({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'facility_level_id') this.facilityLevelId, @JsonKey(name: 'facility_level_name') this.facilityLevelName = '', @JsonKey(name: 'facility_level_code') this.facilityLevelCode = '', @JsonKey(name: 'authority_id') this.authorityId, @JsonKey(name: 'authority_name') this.authorityName = '', @JsonKey(name: 'authority_code') this.authorityCode = '', @JsonKey(name: 'ownership_type_id') this.ownershipTypeId, @JsonKey(name: 'ownership_type_name') this.ownershipTypeName = '', @JsonKey(name: 'ownership_type_code') this.ownershipTypeCode = '', @JsonKey(name: 'health_sub_district_id') this.healthSubDistrictId, @JsonKey(name: 'health_sub_district_name') this.healthSubDistrictName = '', @JsonKey(name: 'parish_id') this.parishId, @JsonKey(name: 'parish_name') this.parishName = '', @JsonKey(name: 'subcounty_id') this.subcountyId, @JsonKey(name: 'subcounty_name') this.subcountyName = '', @JsonKey(name: 'county_id') this.countyId, @JsonKey(name: 'county_name') this.countyName = '', @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'district_name') this.districtName = '', @JsonKey(name: 'health_sub_region_id') this.healthSubRegionId, @JsonKey(name: 'health_sub_region_name') this.healthSubRegionName = '', @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'region_name') this.regionName = '', @JsonKey(name: 'usage_count') this.usageCount = 0, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _HealthFacility.fromJson(Map<String, dynamic> json) => _$HealthFacilityFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'facility_level_id') final  String? facilityLevelId;
@override@JsonKey(name: 'facility_level_name') final  String facilityLevelName;
@override@JsonKey(name: 'facility_level_code') final  String facilityLevelCode;
@override@JsonKey(name: 'authority_id') final  String? authorityId;
@override@JsonKey(name: 'authority_name') final  String authorityName;
@override@JsonKey(name: 'authority_code') final  String authorityCode;
@override@JsonKey(name: 'ownership_type_id') final  String? ownershipTypeId;
@override@JsonKey(name: 'ownership_type_name') final  String ownershipTypeName;
@override@JsonKey(name: 'ownership_type_code') final  String ownershipTypeCode;
@override@JsonKey(name: 'health_sub_district_id') final  String? healthSubDistrictId;
@override@JsonKey(name: 'health_sub_district_name') final  String healthSubDistrictName;
@override@JsonKey(name: 'parish_id') final  String? parishId;
@override@JsonKey(name: 'parish_name') final  String parishName;
@override@JsonKey(name: 'subcounty_id') final  String? subcountyId;
@override@JsonKey(name: 'subcounty_name') final  String subcountyName;
@override@JsonKey(name: 'county_id') final  String? countyId;
@override@JsonKey(name: 'county_name') final  String countyName;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'district_name') final  String districtName;
@override@JsonKey(name: 'health_sub_region_id') final  String? healthSubRegionId;
@override@JsonKey(name: 'health_sub_region_name') final  String healthSubRegionName;
@override@JsonKey(name: 'region_id') final  String? regionId;
@override@JsonKey(name: 'region_name') final  String regionName;
@override@JsonKey(name: 'usage_count') final  int usageCount;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of HealthFacility
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthFacilityCopyWith<_HealthFacility> get copyWith => __$HealthFacilityCopyWithImpl<_HealthFacility>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthFacilityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthFacility&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.facilityLevelId, facilityLevelId) || other.facilityLevelId == facilityLevelId)&&(identical(other.facilityLevelName, facilityLevelName) || other.facilityLevelName == facilityLevelName)&&(identical(other.facilityLevelCode, facilityLevelCode) || other.facilityLevelCode == facilityLevelCode)&&(identical(other.authorityId, authorityId) || other.authorityId == authorityId)&&(identical(other.authorityName, authorityName) || other.authorityName == authorityName)&&(identical(other.authorityCode, authorityCode) || other.authorityCode == authorityCode)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId)&&(identical(other.ownershipTypeName, ownershipTypeName) || other.ownershipTypeName == ownershipTypeName)&&(identical(other.ownershipTypeCode, ownershipTypeCode) || other.ownershipTypeCode == ownershipTypeCode)&&(identical(other.healthSubDistrictId, healthSubDistrictId) || other.healthSubDistrictId == healthSubDistrictId)&&(identical(other.healthSubDistrictName, healthSubDistrictName) || other.healthSubDistrictName == healthSubDistrictName)&&(identical(other.parishId, parishId) || other.parishId == parishId)&&(identical(other.parishName, parishName) || other.parishName == parishName)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.subcountyName, subcountyName) || other.subcountyName == subcountyName)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.countyName, countyName) || other.countyName == countyName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.healthSubRegionName, healthSubRegionName) || other.healthSubRegionName == healthSubRegionName)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,nhpiCode,hsdtCode,facilityLevelId,facilityLevelName,facilityLevelCode,authorityId,authorityName,authorityCode,ownershipTypeId,ownershipTypeName,ownershipTypeCode,healthSubDistrictId,healthSubDistrictName,parishId,parishName,subcountyId,subcountyName,countyId,countyName,districtId,districtName,healthSubRegionId,healthSubRegionName,regionId,regionName,usageCount,createdAt,updatedAt]);

@override
String toString() {
  return 'HealthFacility(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, facilityLevelId: $facilityLevelId, facilityLevelName: $facilityLevelName, facilityLevelCode: $facilityLevelCode, authorityId: $authorityId, authorityName: $authorityName, authorityCode: $authorityCode, ownershipTypeId: $ownershipTypeId, ownershipTypeName: $ownershipTypeName, ownershipTypeCode: $ownershipTypeCode, healthSubDistrictId: $healthSubDistrictId, healthSubDistrictName: $healthSubDistrictName, parishId: $parishId, parishName: $parishName, subcountyId: $subcountyId, subcountyName: $subcountyName, countyId: $countyId, countyName: $countyName, districtId: $districtId, districtName: $districtName, healthSubRegionId: $healthSubRegionId, healthSubRegionName: $healthSubRegionName, regionId: $regionId, regionName: $regionName, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HealthFacilityCopyWith<$Res> implements $HealthFacilityCopyWith<$Res> {
  factory _$HealthFacilityCopyWith(_HealthFacility value, $Res Function(_HealthFacility) _then) = __$HealthFacilityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'facility_level_id') String? facilityLevelId,@JsonKey(name: 'facility_level_name') String facilityLevelName,@JsonKey(name: 'facility_level_code') String facilityLevelCode,@JsonKey(name: 'authority_id') String? authorityId,@JsonKey(name: 'authority_name') String authorityName,@JsonKey(name: 'authority_code') String authorityCode,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId,@JsonKey(name: 'ownership_type_name') String ownershipTypeName,@JsonKey(name: 'ownership_type_code') String ownershipTypeCode,@JsonKey(name: 'health_sub_district_id') String? healthSubDistrictId,@JsonKey(name: 'health_sub_district_name') String healthSubDistrictName,@JsonKey(name: 'parish_id') String? parishId,@JsonKey(name: 'parish_name') String parishName,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'subcounty_name') String subcountyName,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'county_name') String countyName,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'health_sub_region_name') String healthSubRegionName,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$HealthFacilityCopyWithImpl<$Res>
    implements _$HealthFacilityCopyWith<$Res> {
  __$HealthFacilityCopyWithImpl(this._self, this._then);

  final _HealthFacility _self;
  final $Res Function(_HealthFacility) _then;

/// Create a copy of HealthFacility
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? facilityLevelId = freezed,Object? facilityLevelName = null,Object? facilityLevelCode = null,Object? authorityId = freezed,Object? authorityName = null,Object? authorityCode = null,Object? ownershipTypeId = freezed,Object? ownershipTypeName = null,Object? ownershipTypeCode = null,Object? healthSubDistrictId = freezed,Object? healthSubDistrictName = null,Object? parishId = freezed,Object? parishName = null,Object? subcountyId = freezed,Object? subcountyName = null,Object? countyId = freezed,Object? countyName = null,Object? districtId = freezed,Object? districtName = null,Object? healthSubRegionId = freezed,Object? healthSubRegionName = null,Object? regionId = freezed,Object? regionName = null,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_HealthFacility(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,facilityLevelId: freezed == facilityLevelId ? _self.facilityLevelId : facilityLevelId // ignore: cast_nullable_to_non_nullable
as String?,facilityLevelName: null == facilityLevelName ? _self.facilityLevelName : facilityLevelName // ignore: cast_nullable_to_non_nullable
as String,facilityLevelCode: null == facilityLevelCode ? _self.facilityLevelCode : facilityLevelCode // ignore: cast_nullable_to_non_nullable
as String,authorityId: freezed == authorityId ? _self.authorityId : authorityId // ignore: cast_nullable_to_non_nullable
as String?,authorityName: null == authorityName ? _self.authorityName : authorityName // ignore: cast_nullable_to_non_nullable
as String,authorityCode: null == authorityCode ? _self.authorityCode : authorityCode // ignore: cast_nullable_to_non_nullable
as String,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeName: null == ownershipTypeName ? _self.ownershipTypeName : ownershipTypeName // ignore: cast_nullable_to_non_nullable
as String,ownershipTypeCode: null == ownershipTypeCode ? _self.ownershipTypeCode : ownershipTypeCode // ignore: cast_nullable_to_non_nullable
as String,healthSubDistrictId: freezed == healthSubDistrictId ? _self.healthSubDistrictId : healthSubDistrictId // ignore: cast_nullable_to_non_nullable
as String?,healthSubDistrictName: null == healthSubDistrictName ? _self.healthSubDistrictName : healthSubDistrictName // ignore: cast_nullable_to_non_nullable
as String,parishId: freezed == parishId ? _self.parishId : parishId // ignore: cast_nullable_to_non_nullable
as String?,parishName: null == parishName ? _self.parishName : parishName // ignore: cast_nullable_to_non_nullable
as String,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,subcountyName: null == subcountyName ? _self.subcountyName : subcountyName // ignore: cast_nullable_to_non_nullable
as String,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,countyName: null == countyName ? _self.countyName : countyName // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionName: null == healthSubRegionName ? _self.healthSubRegionName : healthSubRegionName // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$HealthFacilityRequest {

 String? get name;@JsonKey(name: 'nhpi_code') String? get nhpiCode;@JsonKey(name: 'hsdt_code') String? get hsdtCode;@JsonKey(name: 'facility_level_id') String? get facilityLevelId;@JsonKey(name: 'authority_id') String? get authorityId;@JsonKey(name: 'ownership_type_id') String? get ownershipTypeId;@JsonKey(name: 'health_sub_district_id') String? get healthSubDistrictId;@JsonKey(name: 'parish_id') String? get parishId;@JsonKey(name: 'subcounty_id') String? get subcountyId;@JsonKey(name: 'county_id') String? get countyId;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'health_sub_region_id') String? get healthSubRegionId;@JsonKey(name: 'region_id') String? get regionId;
/// Create a copy of HealthFacilityRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthFacilityRequestCopyWith<HealthFacilityRequest> get copyWith => _$HealthFacilityRequestCopyWithImpl<HealthFacilityRequest>(this as HealthFacilityRequest, _$identity);

  /// Serializes this HealthFacilityRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthFacilityRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.facilityLevelId, facilityLevelId) || other.facilityLevelId == facilityLevelId)&&(identical(other.authorityId, authorityId) || other.authorityId == authorityId)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId)&&(identical(other.healthSubDistrictId, healthSubDistrictId) || other.healthSubDistrictId == healthSubDistrictId)&&(identical(other.parishId, parishId) || other.parishId == parishId)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.regionId, regionId) || other.regionId == regionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,nhpiCode,hsdtCode,facilityLevelId,authorityId,ownershipTypeId,healthSubDistrictId,parishId,subcountyId,countyId,districtId,healthSubRegionId,regionId);

@override
String toString() {
  return 'HealthFacilityRequest(name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, facilityLevelId: $facilityLevelId, authorityId: $authorityId, ownershipTypeId: $ownershipTypeId, healthSubDistrictId: $healthSubDistrictId, parishId: $parishId, subcountyId: $subcountyId, countyId: $countyId, districtId: $districtId, healthSubRegionId: $healthSubRegionId, regionId: $regionId)';
}


}

/// @nodoc
abstract mixin class $HealthFacilityRequestCopyWith<$Res>  {
  factory $HealthFacilityRequestCopyWith(HealthFacilityRequest value, $Res Function(HealthFacilityRequest) _then) = _$HealthFacilityRequestCopyWithImpl;
@useResult
$Res call({
 String? name,@JsonKey(name: 'nhpi_code') String? nhpiCode,@JsonKey(name: 'hsdt_code') String? hsdtCode,@JsonKey(name: 'facility_level_id') String? facilityLevelId,@JsonKey(name: 'authority_id') String? authorityId,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId,@JsonKey(name: 'health_sub_district_id') String? healthSubDistrictId,@JsonKey(name: 'parish_id') String? parishId,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'region_id') String? regionId
});




}
/// @nodoc
class _$HealthFacilityRequestCopyWithImpl<$Res>
    implements $HealthFacilityRequestCopyWith<$Res> {
  _$HealthFacilityRequestCopyWithImpl(this._self, this._then);

  final HealthFacilityRequest _self;
  final $Res Function(HealthFacilityRequest) _then;

/// Create a copy of HealthFacilityRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? nhpiCode = freezed,Object? hsdtCode = freezed,Object? facilityLevelId = freezed,Object? authorityId = freezed,Object? ownershipTypeId = freezed,Object? healthSubDistrictId = freezed,Object? parishId = freezed,Object? subcountyId = freezed,Object? countyId = freezed,Object? districtId = freezed,Object? healthSubRegionId = freezed,Object? regionId = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nhpiCode: freezed == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String?,hsdtCode: freezed == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String?,facilityLevelId: freezed == facilityLevelId ? _self.facilityLevelId : facilityLevelId // ignore: cast_nullable_to_non_nullable
as String?,authorityId: freezed == authorityId ? _self.authorityId : authorityId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,healthSubDistrictId: freezed == healthSubDistrictId ? _self.healthSubDistrictId : healthSubDistrictId // ignore: cast_nullable_to_non_nullable
as String?,parishId: freezed == parishId ? _self.parishId : parishId // ignore: cast_nullable_to_non_nullable
as String?,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _HealthFacilityRequest implements HealthFacilityRequest {
  const _HealthFacilityRequest({this.name, @JsonKey(name: 'nhpi_code') this.nhpiCode, @JsonKey(name: 'hsdt_code') this.hsdtCode, @JsonKey(name: 'facility_level_id') this.facilityLevelId, @JsonKey(name: 'authority_id') this.authorityId, @JsonKey(name: 'ownership_type_id') this.ownershipTypeId, @JsonKey(name: 'health_sub_district_id') this.healthSubDistrictId, @JsonKey(name: 'parish_id') this.parishId, @JsonKey(name: 'subcounty_id') this.subcountyId, @JsonKey(name: 'county_id') this.countyId, @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'health_sub_region_id') this.healthSubRegionId, @JsonKey(name: 'region_id') this.regionId});
  factory _HealthFacilityRequest.fromJson(Map<String, dynamic> json) => _$HealthFacilityRequestFromJson(json);

@override final  String? name;
@override@JsonKey(name: 'nhpi_code') final  String? nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String? hsdtCode;
@override@JsonKey(name: 'facility_level_id') final  String? facilityLevelId;
@override@JsonKey(name: 'authority_id') final  String? authorityId;
@override@JsonKey(name: 'ownership_type_id') final  String? ownershipTypeId;
@override@JsonKey(name: 'health_sub_district_id') final  String? healthSubDistrictId;
@override@JsonKey(name: 'parish_id') final  String? parishId;
@override@JsonKey(name: 'subcounty_id') final  String? subcountyId;
@override@JsonKey(name: 'county_id') final  String? countyId;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'health_sub_region_id') final  String? healthSubRegionId;
@override@JsonKey(name: 'region_id') final  String? regionId;

/// Create a copy of HealthFacilityRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthFacilityRequestCopyWith<_HealthFacilityRequest> get copyWith => __$HealthFacilityRequestCopyWithImpl<_HealthFacilityRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthFacilityRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthFacilityRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.facilityLevelId, facilityLevelId) || other.facilityLevelId == facilityLevelId)&&(identical(other.authorityId, authorityId) || other.authorityId == authorityId)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId)&&(identical(other.healthSubDistrictId, healthSubDistrictId) || other.healthSubDistrictId == healthSubDistrictId)&&(identical(other.parishId, parishId) || other.parishId == parishId)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.regionId, regionId) || other.regionId == regionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,nhpiCode,hsdtCode,facilityLevelId,authorityId,ownershipTypeId,healthSubDistrictId,parishId,subcountyId,countyId,districtId,healthSubRegionId,regionId);

@override
String toString() {
  return 'HealthFacilityRequest(name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, facilityLevelId: $facilityLevelId, authorityId: $authorityId, ownershipTypeId: $ownershipTypeId, healthSubDistrictId: $healthSubDistrictId, parishId: $parishId, subcountyId: $subcountyId, countyId: $countyId, districtId: $districtId, healthSubRegionId: $healthSubRegionId, regionId: $regionId)';
}


}

/// @nodoc
abstract mixin class _$HealthFacilityRequestCopyWith<$Res> implements $HealthFacilityRequestCopyWith<$Res> {
  factory _$HealthFacilityRequestCopyWith(_HealthFacilityRequest value, $Res Function(_HealthFacilityRequest) _then) = __$HealthFacilityRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name,@JsonKey(name: 'nhpi_code') String? nhpiCode,@JsonKey(name: 'hsdt_code') String? hsdtCode,@JsonKey(name: 'facility_level_id') String? facilityLevelId,@JsonKey(name: 'authority_id') String? authorityId,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId,@JsonKey(name: 'health_sub_district_id') String? healthSubDistrictId,@JsonKey(name: 'parish_id') String? parishId,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'region_id') String? regionId
});




}
/// @nodoc
class __$HealthFacilityRequestCopyWithImpl<$Res>
    implements _$HealthFacilityRequestCopyWith<$Res> {
  __$HealthFacilityRequestCopyWithImpl(this._self, this._then);

  final _HealthFacilityRequest _self;
  final $Res Function(_HealthFacilityRequest) _then;

/// Create a copy of HealthFacilityRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? nhpiCode = freezed,Object? hsdtCode = freezed,Object? facilityLevelId = freezed,Object? authorityId = freezed,Object? ownershipTypeId = freezed,Object? healthSubDistrictId = freezed,Object? parishId = freezed,Object? subcountyId = freezed,Object? countyId = freezed,Object? districtId = freezed,Object? healthSubRegionId = freezed,Object? regionId = freezed,}) {
  return _then(_HealthFacilityRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nhpiCode: freezed == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String?,hsdtCode: freezed == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String?,facilityLevelId: freezed == facilityLevelId ? _self.facilityLevelId : facilityLevelId // ignore: cast_nullable_to_non_nullable
as String?,authorityId: freezed == authorityId ? _self.authorityId : authorityId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,healthSubDistrictId: freezed == healthSubDistrictId ? _self.healthSubDistrictId : healthSubDistrictId // ignore: cast_nullable_to_non_nullable
as String?,parishId: freezed == parishId ? _self.parishId : parishId // ignore: cast_nullable_to_non_nullable
as String?,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

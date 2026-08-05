// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'facility_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Region {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionCopyWith<Region> get copyWith => _$RegionCopyWithImpl<Region>(this as Region, _$identity);

  /// Serializes this Region to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Region&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,createdAt,updatedAt);

@override
String toString() {
  return 'Region(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RegionCopyWith<$Res>  {
  factory $RegionCopyWith(Region value, $Res Function(Region) _then) = _$RegionCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$RegionCopyWithImpl<$Res>
    implements $RegionCopyWith<$Res> {
  _$RegionCopyWithImpl(this._self, this._then);

  final Region _self;
  final $Res Function(Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Region implements Region {
  const _Region({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegionCopyWith<_Region> get copyWith => __$RegionCopyWithImpl<_Region>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Region&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,createdAt,updatedAt);

@override
String toString() {
  return 'Region(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RegionCopyWith<$Res> implements $RegionCopyWith<$Res> {
  factory _$RegionCopyWith(_Region value, $Res Function(_Region) _then) = __$RegionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$RegionCopyWithImpl<$Res>
    implements _$RegionCopyWith<$Res> {
  __$RegionCopyWithImpl(this._self, this._then);

  final _Region _self;
  final $Res Function(_Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Region(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$HealthSubRegion {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'region_id') String? get regionId;@JsonKey(name: 'region_name') String get regionName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of HealthSubRegion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthSubRegionCopyWith<HealthSubRegion> get copyWith => _$HealthSubRegionCopyWithImpl<HealthSubRegion>(this as HealthSubRegion, _$identity);

  /// Serializes this HealthSubRegion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthSubRegion&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,regionId,regionName,createdAt,updatedAt);

@override
String toString() {
  return 'HealthSubRegion(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, regionId: $regionId, regionName: $regionName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $HealthSubRegionCopyWith<$Res>  {
  factory $HealthSubRegionCopyWith(HealthSubRegion value, $Res Function(HealthSubRegion) _then) = _$HealthSubRegionCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$HealthSubRegionCopyWithImpl<$Res>
    implements $HealthSubRegionCopyWith<$Res> {
  _$HealthSubRegionCopyWithImpl(this._self, this._then);

  final HealthSubRegion _self;
  final $Res Function(HealthSubRegion) _then;

/// Create a copy of HealthSubRegion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? regionId = freezed,Object? regionName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _HealthSubRegion implements HealthSubRegion {
  const _HealthSubRegion({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'region_name') this.regionName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _HealthSubRegion.fromJson(Map<String, dynamic> json) => _$HealthSubRegionFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'region_id') final  String? regionId;
@override@JsonKey(name: 'region_name') final  String regionName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of HealthSubRegion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthSubRegionCopyWith<_HealthSubRegion> get copyWith => __$HealthSubRegionCopyWithImpl<_HealthSubRegion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthSubRegionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthSubRegion&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,regionId,regionName,createdAt,updatedAt);

@override
String toString() {
  return 'HealthSubRegion(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, regionId: $regionId, regionName: $regionName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HealthSubRegionCopyWith<$Res> implements $HealthSubRegionCopyWith<$Res> {
  factory _$HealthSubRegionCopyWith(_HealthSubRegion value, $Res Function(_HealthSubRegion) _then) = __$HealthSubRegionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$HealthSubRegionCopyWithImpl<$Res>
    implements _$HealthSubRegionCopyWith<$Res> {
  __$HealthSubRegionCopyWithImpl(this._self, this._then);

  final _HealthSubRegion _self;
  final $Res Function(_HealthSubRegion) _then;

/// Create a copy of HealthSubRegion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? regionId = freezed,Object? regionName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_HealthSubRegion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$District {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'region_id') String? get regionId;@JsonKey(name: 'region_name') String get regionName;@JsonKey(name: 'health_sub_region_id') String? get healthSubRegionId;@JsonKey(name: 'health_sub_region_name') String get healthSubRegionName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of District
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DistrictCopyWith<District> get copyWith => _$DistrictCopyWithImpl<District>(this as District, _$identity);

  /// Serializes this District to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is District&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.healthSubRegionName, healthSubRegionName) || other.healthSubRegionName == healthSubRegionName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,regionId,regionName,healthSubRegionId,healthSubRegionName,createdAt,updatedAt);

@override
String toString() {
  return 'District(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, regionId: $regionId, regionName: $regionName, healthSubRegionId: $healthSubRegionId, healthSubRegionName: $healthSubRegionName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DistrictCopyWith<$Res>  {
  factory $DistrictCopyWith(District value, $Res Function(District) _then) = _$DistrictCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'health_sub_region_name') String healthSubRegionName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$DistrictCopyWithImpl<$Res>
    implements $DistrictCopyWith<$Res> {
  _$DistrictCopyWithImpl(this._self, this._then);

  final District _self;
  final $Res Function(District) _then;

/// Create a copy of District
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? regionId = freezed,Object? regionName = null,Object? healthSubRegionId = freezed,Object? healthSubRegionName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionName: null == healthSubRegionName ? _self.healthSubRegionName : healthSubRegionName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _District implements District {
  const _District({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'region_name') this.regionName = '', @JsonKey(name: 'health_sub_region_id') this.healthSubRegionId, @JsonKey(name: 'health_sub_region_name') this.healthSubRegionName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _District.fromJson(Map<String, dynamic> json) => _$DistrictFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'region_id') final  String? regionId;
@override@JsonKey(name: 'region_name') final  String regionName;
@override@JsonKey(name: 'health_sub_region_id') final  String? healthSubRegionId;
@override@JsonKey(name: 'health_sub_region_name') final  String healthSubRegionName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of District
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DistrictCopyWith<_District> get copyWith => __$DistrictCopyWithImpl<_District>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DistrictToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _District&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.healthSubRegionName, healthSubRegionName) || other.healthSubRegionName == healthSubRegionName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,regionId,regionName,healthSubRegionId,healthSubRegionName,createdAt,updatedAt);

@override
String toString() {
  return 'District(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, regionId: $regionId, regionName: $regionName, healthSubRegionId: $healthSubRegionId, healthSubRegionName: $healthSubRegionName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DistrictCopyWith<$Res> implements $DistrictCopyWith<$Res> {
  factory _$DistrictCopyWith(_District value, $Res Function(_District) _then) = __$DistrictCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'health_sub_region_name') String healthSubRegionName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$DistrictCopyWithImpl<$Res>
    implements _$DistrictCopyWith<$Res> {
  __$DistrictCopyWithImpl(this._self, this._then);

  final _District _self;
  final $Res Function(_District) _then;

/// Create a copy of District
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? regionId = freezed,Object? regionName = null,Object? healthSubRegionId = freezed,Object? healthSubRegionName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_District(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionName: null == healthSubRegionName ? _self.healthSubRegionName : healthSubRegionName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$HealthSubDistrict {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'district_name') String get districtName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of HealthSubDistrict
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthSubDistrictCopyWith<HealthSubDistrict> get copyWith => _$HealthSubDistrictCopyWithImpl<HealthSubDistrict>(this as HealthSubDistrict, _$identity);

  /// Serializes this HealthSubDistrict to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthSubDistrict&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,districtId,districtName,createdAt,updatedAt);

@override
String toString() {
  return 'HealthSubDistrict(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, districtId: $districtId, districtName: $districtName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $HealthSubDistrictCopyWith<$Res>  {
  factory $HealthSubDistrictCopyWith(HealthSubDistrict value, $Res Function(HealthSubDistrict) _then) = _$HealthSubDistrictCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$HealthSubDistrictCopyWithImpl<$Res>
    implements $HealthSubDistrictCopyWith<$Res> {
  _$HealthSubDistrictCopyWithImpl(this._self, this._then);

  final HealthSubDistrict _self;
  final $Res Function(HealthSubDistrict) _then;

/// Create a copy of HealthSubDistrict
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? districtId = freezed,Object? districtName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _HealthSubDistrict implements HealthSubDistrict {
  const _HealthSubDistrict({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'district_name') this.districtName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _HealthSubDistrict.fromJson(Map<String, dynamic> json) => _$HealthSubDistrictFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'district_name') final  String districtName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of HealthSubDistrict
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthSubDistrictCopyWith<_HealthSubDistrict> get copyWith => __$HealthSubDistrictCopyWithImpl<_HealthSubDistrict>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthSubDistrictToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthSubDistrict&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,districtId,districtName,createdAt,updatedAt);

@override
String toString() {
  return 'HealthSubDistrict(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, districtId: $districtId, districtName: $districtName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HealthSubDistrictCopyWith<$Res> implements $HealthSubDistrictCopyWith<$Res> {
  factory _$HealthSubDistrictCopyWith(_HealthSubDistrict value, $Res Function(_HealthSubDistrict) _then) = __$HealthSubDistrictCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$HealthSubDistrictCopyWithImpl<$Res>
    implements _$HealthSubDistrictCopyWith<$Res> {
  __$HealthSubDistrictCopyWithImpl(this._self, this._then);

  final _HealthSubDistrict _self;
  final $Res Function(_HealthSubDistrict) _then;

/// Create a copy of HealthSubDistrict
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? districtId = freezed,Object? districtName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_HealthSubDistrict(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$County {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'district_name') String get districtName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of County
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CountyCopyWith<County> get copyWith => _$CountyCopyWithImpl<County>(this as County, _$identity);

  /// Serializes this County to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is County&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,districtId,districtName,createdAt,updatedAt);

@override
String toString() {
  return 'County(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, districtId: $districtId, districtName: $districtName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CountyCopyWith<$Res>  {
  factory $CountyCopyWith(County value, $Res Function(County) _then) = _$CountyCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$CountyCopyWithImpl<$Res>
    implements $CountyCopyWith<$Res> {
  _$CountyCopyWithImpl(this._self, this._then);

  final County _self;
  final $Res Function(County) _then;

/// Create a copy of County
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? districtId = freezed,Object? districtName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _County implements County {
  const _County({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'district_name') this.districtName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _County.fromJson(Map<String, dynamic> json) => _$CountyFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'district_name') final  String districtName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of County
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CountyCopyWith<_County> get copyWith => __$CountyCopyWithImpl<_County>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CountyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _County&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,districtId,districtName,createdAt,updatedAt);

@override
String toString() {
  return 'County(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, districtId: $districtId, districtName: $districtName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CountyCopyWith<$Res> implements $CountyCopyWith<$Res> {
  factory _$CountyCopyWith(_County value, $Res Function(_County) _then) = __$CountyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$CountyCopyWithImpl<$Res>
    implements _$CountyCopyWith<$Res> {
  __$CountyCopyWithImpl(this._self, this._then);

  final _County _self;
  final $Res Function(_County) _then;

/// Create a copy of County
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? districtId = freezed,Object? districtName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_County(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Subcounty {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'county_id') String? get countyId;@JsonKey(name: 'county_name') String get countyName;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'district_name') String get districtName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Subcounty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubcountyCopyWith<Subcounty> get copyWith => _$SubcountyCopyWithImpl<Subcounty>(this as Subcounty, _$identity);

  /// Serializes this Subcounty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subcounty&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.countyName, countyName) || other.countyName == countyName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,countyId,countyName,districtId,districtName,createdAt,updatedAt);

@override
String toString() {
  return 'Subcounty(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, countyId: $countyId, countyName: $countyName, districtId: $districtId, districtName: $districtName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SubcountyCopyWith<$Res>  {
  factory $SubcountyCopyWith(Subcounty value, $Res Function(Subcounty) _then) = _$SubcountyCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'county_name') String countyName,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$SubcountyCopyWithImpl<$Res>
    implements $SubcountyCopyWith<$Res> {
  _$SubcountyCopyWithImpl(this._self, this._then);

  final Subcounty _self;
  final $Res Function(Subcounty) _then;

/// Create a copy of Subcounty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? countyId = freezed,Object? countyName = null,Object? districtId = freezed,Object? districtName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,countyName: null == countyName ? _self.countyName : countyName // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Subcounty implements Subcounty {
  const _Subcounty({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'county_id') this.countyId, @JsonKey(name: 'county_name') this.countyName = '', @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'district_name') this.districtName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _Subcounty.fromJson(Map<String, dynamic> json) => _$SubcountyFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'county_id') final  String? countyId;
@override@JsonKey(name: 'county_name') final  String countyName;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'district_name') final  String districtName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Subcounty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubcountyCopyWith<_Subcounty> get copyWith => __$SubcountyCopyWithImpl<_Subcounty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubcountyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subcounty&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.countyName, countyName) || other.countyName == countyName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,countyId,countyName,districtId,districtName,createdAt,updatedAt);

@override
String toString() {
  return 'Subcounty(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, countyId: $countyId, countyName: $countyName, districtId: $districtId, districtName: $districtName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SubcountyCopyWith<$Res> implements $SubcountyCopyWith<$Res> {
  factory _$SubcountyCopyWith(_Subcounty value, $Res Function(_Subcounty) _then) = __$SubcountyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'county_name') String countyName,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$SubcountyCopyWithImpl<$Res>
    implements _$SubcountyCopyWith<$Res> {
  __$SubcountyCopyWithImpl(this._self, this._then);

  final _Subcounty _self;
  final $Res Function(_Subcounty) _then;

/// Create a copy of Subcounty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? countyId = freezed,Object? countyName = null,Object? districtId = freezed,Object? districtName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Subcounty(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,countyName: null == countyName ? _self.countyName : countyName // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Parish {

 String get id; String get name;@JsonKey(name: 'nhpi_code') String get nhpiCode;@JsonKey(name: 'hsdt_code') String get hsdtCode;@JsonKey(name: 'subcounty_id') String? get subcountyId;@JsonKey(name: 'subcounty_name') String get subcountyName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParishCopyWith<Parish> get copyWith => _$ParishCopyWithImpl<Parish>(this as Parish, _$identity);

  /// Serializes this Parish to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Parish&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.subcountyName, subcountyName) || other.subcountyName == subcountyName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,subcountyId,subcountyName,createdAt,updatedAt);

@override
String toString() {
  return 'Parish(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, subcountyId: $subcountyId, subcountyName: $subcountyName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ParishCopyWith<$Res>  {
  factory $ParishCopyWith(Parish value, $Res Function(Parish) _then) = _$ParishCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'subcounty_name') String subcountyName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ParishCopyWithImpl<$Res>
    implements $ParishCopyWith<$Res> {
  _$ParishCopyWithImpl(this._self, this._then);

  final Parish _self;
  final $Res Function(Parish) _then;

/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? subcountyId = freezed,Object? subcountyName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,subcountyName: null == subcountyName ? _self.subcountyName : subcountyName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Parish implements Parish {
  const _Parish({required this.id, this.name = '', @JsonKey(name: 'nhpi_code') this.nhpiCode = '', @JsonKey(name: 'hsdt_code') this.hsdtCode = '', @JsonKey(name: 'subcounty_id') this.subcountyId, @JsonKey(name: 'subcounty_name') this.subcountyName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _Parish.fromJson(Map<String, dynamic> json) => _$ParishFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'nhpi_code') final  String nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String hsdtCode;
@override@JsonKey(name: 'subcounty_id') final  String? subcountyId;
@override@JsonKey(name: 'subcounty_name') final  String subcountyName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParishCopyWith<_Parish> get copyWith => __$ParishCopyWithImpl<_Parish>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParishToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Parish&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.subcountyName, subcountyName) || other.subcountyName == subcountyName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nhpiCode,hsdtCode,subcountyId,subcountyName,createdAt,updatedAt);

@override
String toString() {
  return 'Parish(id: $id, name: $name, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, subcountyId: $subcountyId, subcountyName: $subcountyName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ParishCopyWith<$Res> implements $ParishCopyWith<$Res> {
  factory _$ParishCopyWith(_Parish value, $Res Function(_Parish) _then) = __$ParishCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'nhpi_code') String nhpiCode,@JsonKey(name: 'hsdt_code') String hsdtCode,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'subcounty_name') String subcountyName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ParishCopyWithImpl<$Res>
    implements _$ParishCopyWith<$Res> {
  __$ParishCopyWithImpl(this._self, this._then);

  final _Parish _self;
  final $Res Function(_Parish) _then;

/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nhpiCode = null,Object? hsdtCode = null,Object? subcountyId = freezed,Object? subcountyName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Parish(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nhpiCode: null == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String,hsdtCode: null == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,subcountyName: null == subcountyName ? _self.subcountyName : subcountyName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$FacilityLevel {

 String get id; String get name; String get code;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of FacilityLevel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FacilityLevelCopyWith<FacilityLevel> get copyWith => _$FacilityLevelCopyWithImpl<FacilityLevel>(this as FacilityLevel, _$identity);

  /// Serializes this FacilityLevel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FacilityLevel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,createdAt,updatedAt);

@override
String toString() {
  return 'FacilityLevel(id: $id, name: $name, code: $code, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FacilityLevelCopyWith<$Res>  {
  factory $FacilityLevelCopyWith(FacilityLevel value, $Res Function(FacilityLevel) _then) = _$FacilityLevelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String code,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$FacilityLevelCopyWithImpl<$Res>
    implements $FacilityLevelCopyWith<$Res> {
  _$FacilityLevelCopyWithImpl(this._self, this._then);

  final FacilityLevel _self;
  final $Res Function(FacilityLevel) _then;

/// Create a copy of FacilityLevel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _FacilityLevel implements FacilityLevel {
  const _FacilityLevel({required this.id, this.name = '', this.code = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _FacilityLevel.fromJson(Map<String, dynamic> json) => _$FacilityLevelFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String code;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of FacilityLevel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FacilityLevelCopyWith<_FacilityLevel> get copyWith => __$FacilityLevelCopyWithImpl<_FacilityLevel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FacilityLevelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FacilityLevel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,createdAt,updatedAt);

@override
String toString() {
  return 'FacilityLevel(id: $id, name: $name, code: $code, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FacilityLevelCopyWith<$Res> implements $FacilityLevelCopyWith<$Res> {
  factory _$FacilityLevelCopyWith(_FacilityLevel value, $Res Function(_FacilityLevel) _then) = __$FacilityLevelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String code,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$FacilityLevelCopyWithImpl<$Res>
    implements _$FacilityLevelCopyWith<$Res> {
  __$FacilityLevelCopyWithImpl(this._self, this._then);

  final _FacilityLevel _self;
  final $Res Function(_FacilityLevel) _then;

/// Create a copy of FacilityLevel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_FacilityLevel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$OwnershipType {

 String get id; String get name; String get code;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of OwnershipType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnershipTypeCopyWith<OwnershipType> get copyWith => _$OwnershipTypeCopyWithImpl<OwnershipType>(this as OwnershipType, _$identity);

  /// Serializes this OwnershipType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnershipType&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,createdAt,updatedAt);

@override
String toString() {
  return 'OwnershipType(id: $id, name: $name, code: $code, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $OwnershipTypeCopyWith<$Res>  {
  factory $OwnershipTypeCopyWith(OwnershipType value, $Res Function(OwnershipType) _then) = _$OwnershipTypeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String code,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$OwnershipTypeCopyWithImpl<$Res>
    implements $OwnershipTypeCopyWith<$Res> {
  _$OwnershipTypeCopyWithImpl(this._self, this._then);

  final OwnershipType _self;
  final $Res Function(OwnershipType) _then;

/// Create a copy of OwnershipType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _OwnershipType implements OwnershipType {
  const _OwnershipType({required this.id, this.name = '', this.code = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _OwnershipType.fromJson(Map<String, dynamic> json) => _$OwnershipTypeFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String code;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of OwnershipType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnershipTypeCopyWith<_OwnershipType> get copyWith => __$OwnershipTypeCopyWithImpl<_OwnershipType>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnershipTypeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnershipType&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,createdAt,updatedAt);

@override
String toString() {
  return 'OwnershipType(id: $id, name: $name, code: $code, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$OwnershipTypeCopyWith<$Res> implements $OwnershipTypeCopyWith<$Res> {
  factory _$OwnershipTypeCopyWith(_OwnershipType value, $Res Function(_OwnershipType) _then) = __$OwnershipTypeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String code,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$OwnershipTypeCopyWithImpl<$Res>
    implements _$OwnershipTypeCopyWith<$Res> {
  __$OwnershipTypeCopyWithImpl(this._self, this._then);

  final _OwnershipType _self;
  final $Res Function(_OwnershipType) _then;

/// Create a copy of OwnershipType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_OwnershipType(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Authority {

 String get id; String get name; String? get code;@JsonKey(name: 'ownership_type_id') String? get ownershipTypeId;@JsonKey(name: 'ownership_type_name') String get ownershipTypeName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Authority
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthorityCopyWith<Authority> get copyWith => _$AuthorityCopyWithImpl<Authority>(this as Authority, _$identity);

  /// Serializes this Authority to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Authority&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId)&&(identical(other.ownershipTypeName, ownershipTypeName) || other.ownershipTypeName == ownershipTypeName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,ownershipTypeId,ownershipTypeName,createdAt,updatedAt);

@override
String toString() {
  return 'Authority(id: $id, name: $name, code: $code, ownershipTypeId: $ownershipTypeId, ownershipTypeName: $ownershipTypeName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AuthorityCopyWith<$Res>  {
  factory $AuthorityCopyWith(Authority value, $Res Function(Authority) _then) = _$AuthorityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? code,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId,@JsonKey(name: 'ownership_type_name') String ownershipTypeName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$AuthorityCopyWithImpl<$Res>
    implements $AuthorityCopyWith<$Res> {
  _$AuthorityCopyWithImpl(this._self, this._then);

  final Authority _self;
  final $Res Function(Authority) _then;

/// Create a copy of Authority
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = freezed,Object? ownershipTypeId = freezed,Object? ownershipTypeName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeName: null == ownershipTypeName ? _self.ownershipTypeName : ownershipTypeName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Authority implements Authority {
  const _Authority({required this.id, this.name = '', this.code, @JsonKey(name: 'ownership_type_id') this.ownershipTypeId, @JsonKey(name: 'ownership_type_name') this.ownershipTypeName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _Authority.fromJson(Map<String, dynamic> json) => _$AuthorityFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override final  String? code;
@override@JsonKey(name: 'ownership_type_id') final  String? ownershipTypeId;
@override@JsonKey(name: 'ownership_type_name') final  String ownershipTypeName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Authority
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthorityCopyWith<_Authority> get copyWith => __$AuthorityCopyWithImpl<_Authority>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthorityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Authority&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId)&&(identical(other.ownershipTypeName, ownershipTypeName) || other.ownershipTypeName == ownershipTypeName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,ownershipTypeId,ownershipTypeName,createdAt,updatedAt);

@override
String toString() {
  return 'Authority(id: $id, name: $name, code: $code, ownershipTypeId: $ownershipTypeId, ownershipTypeName: $ownershipTypeName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AuthorityCopyWith<$Res> implements $AuthorityCopyWith<$Res> {
  factory _$AuthorityCopyWith(_Authority value, $Res Function(_Authority) _then) = __$AuthorityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? code,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId,@JsonKey(name: 'ownership_type_name') String ownershipTypeName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$AuthorityCopyWithImpl<$Res>
    implements _$AuthorityCopyWith<$Res> {
  __$AuthorityCopyWithImpl(this._self, this._then);

  final _Authority _self;
  final $Res Function(_Authority) _then;

/// Create a copy of Authority
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = freezed,Object? ownershipTypeId = freezed,Object? ownershipTypeName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Authority(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeName: null == ownershipTypeName ? _self.ownershipTypeName : ownershipTypeName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$FacilityReferenceRequest {

 String? get name; String? get code;@JsonKey(name: 'nhpi_code') String? get nhpiCode;@JsonKey(name: 'hsdt_code') String? get hsdtCode;@JsonKey(name: 'region_id') String? get regionId;@JsonKey(name: 'health_sub_region_id') String? get healthSubRegionId;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'county_id') String? get countyId;@JsonKey(name: 'subcounty_id') String? get subcountyId;@JsonKey(name: 'ownership_type_id') String? get ownershipTypeId;
/// Create a copy of FacilityReferenceRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FacilityReferenceRequestCopyWith<FacilityReferenceRequest> get copyWith => _$FacilityReferenceRequestCopyWithImpl<FacilityReferenceRequest>(this as FacilityReferenceRequest, _$identity);

  /// Serializes this FacilityReferenceRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FacilityReferenceRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,code,nhpiCode,hsdtCode,regionId,healthSubRegionId,districtId,countyId,subcountyId,ownershipTypeId);

@override
String toString() {
  return 'FacilityReferenceRequest(name: $name, code: $code, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, regionId: $regionId, healthSubRegionId: $healthSubRegionId, districtId: $districtId, countyId: $countyId, subcountyId: $subcountyId, ownershipTypeId: $ownershipTypeId)';
}


}

/// @nodoc
abstract mixin class $FacilityReferenceRequestCopyWith<$Res>  {
  factory $FacilityReferenceRequestCopyWith(FacilityReferenceRequest value, $Res Function(FacilityReferenceRequest) _then) = _$FacilityReferenceRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? code,@JsonKey(name: 'nhpi_code') String? nhpiCode,@JsonKey(name: 'hsdt_code') String? hsdtCode,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId
});




}
/// @nodoc
class _$FacilityReferenceRequestCopyWithImpl<$Res>
    implements $FacilityReferenceRequestCopyWith<$Res> {
  _$FacilityReferenceRequestCopyWithImpl(this._self, this._then);

  final FacilityReferenceRequest _self;
  final $Res Function(FacilityReferenceRequest) _then;

/// Create a copy of FacilityReferenceRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? code = freezed,Object? nhpiCode = freezed,Object? hsdtCode = freezed,Object? regionId = freezed,Object? healthSubRegionId = freezed,Object? districtId = freezed,Object? countyId = freezed,Object? subcountyId = freezed,Object? ownershipTypeId = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,nhpiCode: freezed == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String?,hsdtCode: freezed == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _FacilityReferenceRequest implements FacilityReferenceRequest {
  const _FacilityReferenceRequest({this.name, this.code, @JsonKey(name: 'nhpi_code') this.nhpiCode, @JsonKey(name: 'hsdt_code') this.hsdtCode, @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'health_sub_region_id') this.healthSubRegionId, @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'county_id') this.countyId, @JsonKey(name: 'subcounty_id') this.subcountyId, @JsonKey(name: 'ownership_type_id') this.ownershipTypeId});
  factory _FacilityReferenceRequest.fromJson(Map<String, dynamic> json) => _$FacilityReferenceRequestFromJson(json);

@override final  String? name;
@override final  String? code;
@override@JsonKey(name: 'nhpi_code') final  String? nhpiCode;
@override@JsonKey(name: 'hsdt_code') final  String? hsdtCode;
@override@JsonKey(name: 'region_id') final  String? regionId;
@override@JsonKey(name: 'health_sub_region_id') final  String? healthSubRegionId;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'county_id') final  String? countyId;
@override@JsonKey(name: 'subcounty_id') final  String? subcountyId;
@override@JsonKey(name: 'ownership_type_id') final  String? ownershipTypeId;

/// Create a copy of FacilityReferenceRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FacilityReferenceRequestCopyWith<_FacilityReferenceRequest> get copyWith => __$FacilityReferenceRequestCopyWithImpl<_FacilityReferenceRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FacilityReferenceRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FacilityReferenceRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.nhpiCode, nhpiCode) || other.nhpiCode == nhpiCode)&&(identical(other.hsdtCode, hsdtCode) || other.hsdtCode == hsdtCode)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.healthSubRegionId, healthSubRegionId) || other.healthSubRegionId == healthSubRegionId)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.countyId, countyId) || other.countyId == countyId)&&(identical(other.subcountyId, subcountyId) || other.subcountyId == subcountyId)&&(identical(other.ownershipTypeId, ownershipTypeId) || other.ownershipTypeId == ownershipTypeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,code,nhpiCode,hsdtCode,regionId,healthSubRegionId,districtId,countyId,subcountyId,ownershipTypeId);

@override
String toString() {
  return 'FacilityReferenceRequest(name: $name, code: $code, nhpiCode: $nhpiCode, hsdtCode: $hsdtCode, regionId: $regionId, healthSubRegionId: $healthSubRegionId, districtId: $districtId, countyId: $countyId, subcountyId: $subcountyId, ownershipTypeId: $ownershipTypeId)';
}


}

/// @nodoc
abstract mixin class _$FacilityReferenceRequestCopyWith<$Res> implements $FacilityReferenceRequestCopyWith<$Res> {
  factory _$FacilityReferenceRequestCopyWith(_FacilityReferenceRequest value, $Res Function(_FacilityReferenceRequest) _then) = __$FacilityReferenceRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? code,@JsonKey(name: 'nhpi_code') String? nhpiCode,@JsonKey(name: 'hsdt_code') String? hsdtCode,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'health_sub_region_id') String? healthSubRegionId,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'county_id') String? countyId,@JsonKey(name: 'subcounty_id') String? subcountyId,@JsonKey(name: 'ownership_type_id') String? ownershipTypeId
});




}
/// @nodoc
class __$FacilityReferenceRequestCopyWithImpl<$Res>
    implements _$FacilityReferenceRequestCopyWith<$Res> {
  __$FacilityReferenceRequestCopyWithImpl(this._self, this._then);

  final _FacilityReferenceRequest _self;
  final $Res Function(_FacilityReferenceRequest) _then;

/// Create a copy of FacilityReferenceRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? code = freezed,Object? nhpiCode = freezed,Object? hsdtCode = freezed,Object? regionId = freezed,Object? healthSubRegionId = freezed,Object? districtId = freezed,Object? countyId = freezed,Object? subcountyId = freezed,Object? ownershipTypeId = freezed,}) {
  return _then(_FacilityReferenceRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,nhpiCode: freezed == nhpiCode ? _self.nhpiCode : nhpiCode // ignore: cast_nullable_to_non_nullable
as String?,hsdtCode: freezed == hsdtCode ? _self.hsdtCode : hsdtCode // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,healthSubRegionId: freezed == healthSubRegionId ? _self.healthSubRegionId : healthSubRegionId // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,countyId: freezed == countyId ? _self.countyId : countyId // ignore: cast_nullable_to_non_nullable
as String?,subcountyId: freezed == subcountyId ? _self.subcountyId : subcountyId // ignore: cast_nullable_to_non_nullable
as String?,ownershipTypeId: freezed == ownershipTypeId ? _self.ownershipTypeId : ownershipTypeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'facility_usage_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FacilityUsageLog {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'facility_id') String get facilityId;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of FacilityUsageLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FacilityUsageLogCopyWith<FacilityUsageLog> get copyWith => _$FacilityUsageLogCopyWithImpl<FacilityUsageLog>(this as FacilityUsageLog, _$identity);

  /// Serializes this FacilityUsageLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FacilityUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.facilityId, facilityId) || other.facilityId == facilityId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,facilityId,createdAt,updatedAt);

@override
String toString() {
  return 'FacilityUsageLog(id: $id, userId: $userId, facilityId: $facilityId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FacilityUsageLogCopyWith<$Res>  {
  factory $FacilityUsageLogCopyWith(FacilityUsageLog value, $Res Function(FacilityUsageLog) _then) = _$FacilityUsageLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'facility_id') String facilityId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$FacilityUsageLogCopyWithImpl<$Res>
    implements $FacilityUsageLogCopyWith<$Res> {
  _$FacilityUsageLogCopyWithImpl(this._self, this._then);

  final FacilityUsageLog _self;
  final $Res Function(FacilityUsageLog) _then;

/// Create a copy of FacilityUsageLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? facilityId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,facilityId: null == facilityId ? _self.facilityId : facilityId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _FacilityUsageLog extends FacilityUsageLog {
  const _FacilityUsageLog({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'facility_id') required this.facilityId, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _FacilityUsageLog.fromJson(Map<String, dynamic> json) => _$FacilityUsageLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'facility_id') final  String facilityId;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of FacilityUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FacilityUsageLogCopyWith<_FacilityUsageLog> get copyWith => __$FacilityUsageLogCopyWithImpl<_FacilityUsageLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FacilityUsageLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FacilityUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.facilityId, facilityId) || other.facilityId == facilityId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,facilityId,createdAt,updatedAt);

@override
String toString() {
  return 'FacilityUsageLog(id: $id, userId: $userId, facilityId: $facilityId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FacilityUsageLogCopyWith<$Res> implements $FacilityUsageLogCopyWith<$Res> {
  factory _$FacilityUsageLogCopyWith(_FacilityUsageLog value, $Res Function(_FacilityUsageLog) _then) = __$FacilityUsageLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'facility_id') String facilityId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$FacilityUsageLogCopyWithImpl<$Res>
    implements _$FacilityUsageLogCopyWith<$Res> {
  __$FacilityUsageLogCopyWithImpl(this._self, this._then);

  final _FacilityUsageLog _self;
  final $Res Function(_FacilityUsageLog) _then;

/// Create a copy of FacilityUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? facilityId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_FacilityUsageLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,facilityId: null == facilityId ? _self.facilityId : facilityId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

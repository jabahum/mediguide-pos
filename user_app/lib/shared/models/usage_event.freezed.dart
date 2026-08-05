// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AbbreviationUsageLog {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'abbreviation_id') String get abbreviationId;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of AbbreviationUsageLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AbbreviationUsageLogCopyWith<AbbreviationUsageLog> get copyWith => _$AbbreviationUsageLogCopyWithImpl<AbbreviationUsageLog>(this as AbbreviationUsageLog, _$identity);

  /// Serializes this AbbreviationUsageLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AbbreviationUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.abbreviationId, abbreviationId) || other.abbreviationId == abbreviationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,abbreviationId,createdAt,updatedAt);

@override
String toString() {
  return 'AbbreviationUsageLog(id: $id, userId: $userId, abbreviationId: $abbreviationId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AbbreviationUsageLogCopyWith<$Res>  {
  factory $AbbreviationUsageLogCopyWith(AbbreviationUsageLog value, $Res Function(AbbreviationUsageLog) _then) = _$AbbreviationUsageLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'abbreviation_id') String abbreviationId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$AbbreviationUsageLogCopyWithImpl<$Res>
    implements $AbbreviationUsageLogCopyWith<$Res> {
  _$AbbreviationUsageLogCopyWithImpl(this._self, this._then);

  final AbbreviationUsageLog _self;
  final $Res Function(AbbreviationUsageLog) _then;

/// Create a copy of AbbreviationUsageLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? abbreviationId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,abbreviationId: null == abbreviationId ? _self.abbreviationId : abbreviationId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AbbreviationUsageLog implements AbbreviationUsageLog {
  const _AbbreviationUsageLog({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'abbreviation_id') required this.abbreviationId, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _AbbreviationUsageLog.fromJson(Map<String, dynamic> json) => _$AbbreviationUsageLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'abbreviation_id') final  String abbreviationId;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of AbbreviationUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AbbreviationUsageLogCopyWith<_AbbreviationUsageLog> get copyWith => __$AbbreviationUsageLogCopyWithImpl<_AbbreviationUsageLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AbbreviationUsageLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AbbreviationUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.abbreviationId, abbreviationId) || other.abbreviationId == abbreviationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,abbreviationId,createdAt,updatedAt);

@override
String toString() {
  return 'AbbreviationUsageLog(id: $id, userId: $userId, abbreviationId: $abbreviationId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AbbreviationUsageLogCopyWith<$Res> implements $AbbreviationUsageLogCopyWith<$Res> {
  factory _$AbbreviationUsageLogCopyWith(_AbbreviationUsageLog value, $Res Function(_AbbreviationUsageLog) _then) = __$AbbreviationUsageLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'abbreviation_id') String abbreviationId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$AbbreviationUsageLogCopyWithImpl<$Res>
    implements _$AbbreviationUsageLogCopyWith<$Res> {
  __$AbbreviationUsageLogCopyWithImpl(this._self, this._then);

  final _AbbreviationUsageLog _self;
  final $Res Function(_AbbreviationUsageLog) _then;

/// Create a copy of AbbreviationUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? abbreviationId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_AbbreviationUsageLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,abbreviationId: null == abbreviationId ? _self.abbreviationId : abbreviationId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AiUsageLog {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of AiUsageLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiUsageLogCopyWith<AiUsageLog> get copyWith => _$AiUsageLogCopyWithImpl<AiUsageLog>(this as AiUsageLog, _$identity);

  /// Serializes this AiUsageLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt,updatedAt);

@override
String toString() {
  return 'AiUsageLog(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AiUsageLogCopyWith<$Res>  {
  factory $AiUsageLogCopyWith(AiUsageLog value, $Res Function(AiUsageLog) _then) = _$AiUsageLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$AiUsageLogCopyWithImpl<$Res>
    implements $AiUsageLogCopyWith<$Res> {
  _$AiUsageLogCopyWithImpl(this._self, this._then);

  final AiUsageLog _self;
  final $Res Function(AiUsageLog) _then;

/// Create a copy of AiUsageLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AiUsageLog implements AiUsageLog {
  const _AiUsageLog({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _AiUsageLog.fromJson(Map<String, dynamic> json) => _$AiUsageLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of AiUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiUsageLogCopyWith<_AiUsageLog> get copyWith => __$AiUsageLogCopyWithImpl<_AiUsageLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiUsageLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt,updatedAt);

@override
String toString() {
  return 'AiUsageLog(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AiUsageLogCopyWith<$Res> implements $AiUsageLogCopyWith<$Res> {
  factory _$AiUsageLogCopyWith(_AiUsageLog value, $Res Function(_AiUsageLog) _then) = __$AiUsageLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$AiUsageLogCopyWithImpl<$Res>
    implements _$AiUsageLogCopyWith<$Res> {
  __$AiUsageLogCopyWithImpl(this._self, this._then);

  final _AiUsageLog _self;
  final $Res Function(_AiUsageLog) _then;

/// Create a copy of AiUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_AiUsageLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ConsultantUsageLog {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'consultant_id') String get consultantId;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of ConsultantUsageLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsultantUsageLogCopyWith<ConsultantUsageLog> get copyWith => _$ConsultantUsageLogCopyWithImpl<ConsultantUsageLog>(this as ConsultantUsageLog, _$identity);

  /// Serializes this ConsultantUsageLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsultantUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.consultantId, consultantId) || other.consultantId == consultantId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,consultantId,createdAt,updatedAt);

@override
String toString() {
  return 'ConsultantUsageLog(id: $id, userId: $userId, consultantId: $consultantId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ConsultantUsageLogCopyWith<$Res>  {
  factory $ConsultantUsageLogCopyWith(ConsultantUsageLog value, $Res Function(ConsultantUsageLog) _then) = _$ConsultantUsageLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'consultant_id') String consultantId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ConsultantUsageLogCopyWithImpl<$Res>
    implements $ConsultantUsageLogCopyWith<$Res> {
  _$ConsultantUsageLogCopyWithImpl(this._self, this._then);

  final ConsultantUsageLog _self;
  final $Res Function(ConsultantUsageLog) _then;

/// Create a copy of ConsultantUsageLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? consultantId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,consultantId: null == consultantId ? _self.consultantId : consultantId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ConsultantUsageLog implements ConsultantUsageLog {
  const _ConsultantUsageLog({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'consultant_id') required this.consultantId, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _ConsultantUsageLog.fromJson(Map<String, dynamic> json) => _$ConsultantUsageLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'consultant_id') final  String consultantId;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of ConsultantUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsultantUsageLogCopyWith<_ConsultantUsageLog> get copyWith => __$ConsultantUsageLogCopyWithImpl<_ConsultantUsageLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsultantUsageLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsultantUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.consultantId, consultantId) || other.consultantId == consultantId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,consultantId,createdAt,updatedAt);

@override
String toString() {
  return 'ConsultantUsageLog(id: $id, userId: $userId, consultantId: $consultantId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ConsultantUsageLogCopyWith<$Res> implements $ConsultantUsageLogCopyWith<$Res> {
  factory _$ConsultantUsageLogCopyWith(_ConsultantUsageLog value, $Res Function(_ConsultantUsageLog) _then) = __$ConsultantUsageLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'consultant_id') String consultantId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ConsultantUsageLogCopyWithImpl<$Res>
    implements _$ConsultantUsageLogCopyWith<$Res> {
  __$ConsultantUsageLogCopyWithImpl(this._self, this._then);

  final _ConsultantUsageLog _self;
  final $Res Function(_ConsultantUsageLog) _then;

/// Create a copy of ConsultantUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? consultantId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ConsultantUsageLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,consultantId: null == consultantId ? _self.consultantId : consultantId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$DrugUsageLog {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'drug_id') String get drugId;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of DrugUsageLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrugUsageLogCopyWith<DrugUsageLog> get copyWith => _$DrugUsageLogCopyWithImpl<DrugUsageLog>(this as DrugUsageLog, _$identity);

  /// Serializes this DrugUsageLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrugUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.drugId, drugId) || other.drugId == drugId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,drugId,createdAt,updatedAt);

@override
String toString() {
  return 'DrugUsageLog(id: $id, userId: $userId, drugId: $drugId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DrugUsageLogCopyWith<$Res>  {
  factory $DrugUsageLogCopyWith(DrugUsageLog value, $Res Function(DrugUsageLog) _then) = _$DrugUsageLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'drug_id') String drugId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$DrugUsageLogCopyWithImpl<$Res>
    implements $DrugUsageLogCopyWith<$Res> {
  _$DrugUsageLogCopyWithImpl(this._self, this._then);

  final DrugUsageLog _self;
  final $Res Function(DrugUsageLog) _then;

/// Create a copy of DrugUsageLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? drugId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,drugId: null == drugId ? _self.drugId : drugId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _DrugUsageLog implements DrugUsageLog {
  const _DrugUsageLog({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'drug_id') required this.drugId, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _DrugUsageLog.fromJson(Map<String, dynamic> json) => _$DrugUsageLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'drug_id') final  String drugId;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of DrugUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrugUsageLogCopyWith<_DrugUsageLog> get copyWith => __$DrugUsageLogCopyWithImpl<_DrugUsageLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrugUsageLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrugUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.drugId, drugId) || other.drugId == drugId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,drugId,createdAt,updatedAt);

@override
String toString() {
  return 'DrugUsageLog(id: $id, userId: $userId, drugId: $drugId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DrugUsageLogCopyWith<$Res> implements $DrugUsageLogCopyWith<$Res> {
  factory _$DrugUsageLogCopyWith(_DrugUsageLog value, $Res Function(_DrugUsageLog) _then) = __$DrugUsageLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'drug_id') String drugId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$DrugUsageLogCopyWithImpl<$Res>
    implements _$DrugUsageLogCopyWith<$Res> {
  __$DrugUsageLogCopyWithImpl(this._self, this._then);

  final _DrugUsageLog _self;
  final $Res Function(_DrugUsageLog) _then;

/// Create a copy of DrugUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? drugId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_DrugUsageLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,drugId: null == drugId ? _self.drugId : drugId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$GuidelineUsageLog {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'guideline_id') String get guidelineId;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of GuidelineUsageLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineUsageLogCopyWith<GuidelineUsageLog> get copyWith => _$GuidelineUsageLogCopyWithImpl<GuidelineUsageLog>(this as GuidelineUsageLog, _$identity);

  /// Serializes this GuidelineUsageLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,guidelineId,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineUsageLog(id: $id, userId: $userId, guidelineId: $guidelineId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GuidelineUsageLogCopyWith<$Res>  {
  factory $GuidelineUsageLogCopyWith(GuidelineUsageLog value, $Res Function(GuidelineUsageLog) _then) = _$GuidelineUsageLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$GuidelineUsageLogCopyWithImpl<$Res>
    implements $GuidelineUsageLogCopyWith<$Res> {
  _$GuidelineUsageLogCopyWithImpl(this._self, this._then);

  final GuidelineUsageLog _self;
  final $Res Function(GuidelineUsageLog) _then;

/// Create a copy of GuidelineUsageLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? guidelineId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineUsageLog implements GuidelineUsageLog {
  const _GuidelineUsageLog({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'guideline_id') required this.guidelineId, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _GuidelineUsageLog.fromJson(Map<String, dynamic> json) => _$GuidelineUsageLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'guideline_id') final  String guidelineId;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of GuidelineUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineUsageLogCopyWith<_GuidelineUsageLog> get copyWith => __$GuidelineUsageLogCopyWithImpl<_GuidelineUsageLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineUsageLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,guidelineId,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineUsageLog(id: $id, userId: $userId, guidelineId: $guidelineId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GuidelineUsageLogCopyWith<$Res> implements $GuidelineUsageLogCopyWith<$Res> {
  factory _$GuidelineUsageLogCopyWith(_GuidelineUsageLog value, $Res Function(_GuidelineUsageLog) _then) = __$GuidelineUsageLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$GuidelineUsageLogCopyWithImpl<$Res>
    implements _$GuidelineUsageLogCopyWith<$Res> {
  __$GuidelineUsageLogCopyWithImpl(this._self, this._then);

  final _GuidelineUsageLog _self;
  final $Res Function(_GuidelineUsageLog) _then;

/// Create a copy of GuidelineUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? guidelineId = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_GuidelineUsageLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CalculatorUsageLog {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'calculator_id') String get calculatorId;@JsonKey(name: 'session_start') DateTime get sessionStart;@JsonKey(name: 'session_end') DateTime? get sessionEnd;@JsonKey(name: 'calculator_type') String get calculatorTypeValue;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of CalculatorUsageLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalculatorUsageLogCopyWith<CalculatorUsageLog> get copyWith => _$CalculatorUsageLogCopyWithImpl<CalculatorUsageLog>(this as CalculatorUsageLog, _$identity);

  /// Serializes this CalculatorUsageLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalculatorUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.calculatorId, calculatorId) || other.calculatorId == calculatorId)&&(identical(other.sessionStart, sessionStart) || other.sessionStart == sessionStart)&&(identical(other.sessionEnd, sessionEnd) || other.sessionEnd == sessionEnd)&&(identical(other.calculatorTypeValue, calculatorTypeValue) || other.calculatorTypeValue == calculatorTypeValue)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,calculatorId,sessionStart,sessionEnd,calculatorTypeValue,createdAt,updatedAt);

@override
String toString() {
  return 'CalculatorUsageLog(id: $id, userId: $userId, calculatorId: $calculatorId, sessionStart: $sessionStart, sessionEnd: $sessionEnd, calculatorTypeValue: $calculatorTypeValue, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CalculatorUsageLogCopyWith<$Res>  {
  factory $CalculatorUsageLogCopyWith(CalculatorUsageLog value, $Res Function(CalculatorUsageLog) _then) = _$CalculatorUsageLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'calculator_id') String calculatorId,@JsonKey(name: 'session_start') DateTime sessionStart,@JsonKey(name: 'session_end') DateTime? sessionEnd,@JsonKey(name: 'calculator_type') String calculatorTypeValue,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$CalculatorUsageLogCopyWithImpl<$Res>
    implements $CalculatorUsageLogCopyWith<$Res> {
  _$CalculatorUsageLogCopyWithImpl(this._self, this._then);

  final CalculatorUsageLog _self;
  final $Res Function(CalculatorUsageLog) _then;

/// Create a copy of CalculatorUsageLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? calculatorId = null,Object? sessionStart = null,Object? sessionEnd = freezed,Object? calculatorTypeValue = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,calculatorId: null == calculatorId ? _self.calculatorId : calculatorId // ignore: cast_nullable_to_non_nullable
as String,sessionStart: null == sessionStart ? _self.sessionStart : sessionStart // ignore: cast_nullable_to_non_nullable
as DateTime,sessionEnd: freezed == sessionEnd ? _self.sessionEnd : sessionEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,calculatorTypeValue: null == calculatorTypeValue ? _self.calculatorTypeValue : calculatorTypeValue // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _CalculatorUsageLog extends CalculatorUsageLog {
  const _CalculatorUsageLog({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'calculator_id') required this.calculatorId, @JsonKey(name: 'session_start') required this.sessionStart, @JsonKey(name: 'session_end') this.sessionEnd, @JsonKey(name: 'calculator_type') this.calculatorTypeValue = 'calculator', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _CalculatorUsageLog.fromJson(Map<String, dynamic> json) => _$CalculatorUsageLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'calculator_id') final  String calculatorId;
@override@JsonKey(name: 'session_start') final  DateTime sessionStart;
@override@JsonKey(name: 'session_end') final  DateTime? sessionEnd;
@override@JsonKey(name: 'calculator_type') final  String calculatorTypeValue;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of CalculatorUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalculatorUsageLogCopyWith<_CalculatorUsageLog> get copyWith => __$CalculatorUsageLogCopyWithImpl<_CalculatorUsageLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalculatorUsageLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalculatorUsageLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.calculatorId, calculatorId) || other.calculatorId == calculatorId)&&(identical(other.sessionStart, sessionStart) || other.sessionStart == sessionStart)&&(identical(other.sessionEnd, sessionEnd) || other.sessionEnd == sessionEnd)&&(identical(other.calculatorTypeValue, calculatorTypeValue) || other.calculatorTypeValue == calculatorTypeValue)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,calculatorId,sessionStart,sessionEnd,calculatorTypeValue,createdAt,updatedAt);

@override
String toString() {
  return 'CalculatorUsageLog(id: $id, userId: $userId, calculatorId: $calculatorId, sessionStart: $sessionStart, sessionEnd: $sessionEnd, calculatorTypeValue: $calculatorTypeValue, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CalculatorUsageLogCopyWith<$Res> implements $CalculatorUsageLogCopyWith<$Res> {
  factory _$CalculatorUsageLogCopyWith(_CalculatorUsageLog value, $Res Function(_CalculatorUsageLog) _then) = __$CalculatorUsageLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'calculator_id') String calculatorId,@JsonKey(name: 'session_start') DateTime sessionStart,@JsonKey(name: 'session_end') DateTime? sessionEnd,@JsonKey(name: 'calculator_type') String calculatorTypeValue,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$CalculatorUsageLogCopyWithImpl<$Res>
    implements _$CalculatorUsageLogCopyWith<$Res> {
  __$CalculatorUsageLogCopyWithImpl(this._self, this._then);

  final _CalculatorUsageLog _self;
  final $Res Function(_CalculatorUsageLog) _then;

/// Create a copy of CalculatorUsageLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? calculatorId = null,Object? sessionStart = null,Object? sessionEnd = freezed,Object? calculatorTypeValue = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CalculatorUsageLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,calculatorId: null == calculatorId ? _self.calculatorId : calculatorId // ignore: cast_nullable_to_non_nullable
as String,sessionStart: null == sessionStart ? _self.sessionStart : sessionStart // ignore: cast_nullable_to_non_nullable
as DateTime,sessionEnd: freezed == sessionEnd ? _self.sessionEnd : sessionEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,calculatorTypeValue: null == calculatorTypeValue ? _self.calculatorTypeValue : calculatorTypeValue // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CalculatorUsageRequest {

@JsonKey(name: 'calculator_id') String? get calculatorId;@JsonKey(name: 'session_start') DateTime? get sessionStart;@JsonKey(name: 'session_end') DateTime? get sessionEnd;@JsonKey(name: 'calculator_type') String? get calculatorType;
/// Create a copy of CalculatorUsageRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalculatorUsageRequestCopyWith<CalculatorUsageRequest> get copyWith => _$CalculatorUsageRequestCopyWithImpl<CalculatorUsageRequest>(this as CalculatorUsageRequest, _$identity);

  /// Serializes this CalculatorUsageRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalculatorUsageRequest&&(identical(other.calculatorId, calculatorId) || other.calculatorId == calculatorId)&&(identical(other.sessionStart, sessionStart) || other.sessionStart == sessionStart)&&(identical(other.sessionEnd, sessionEnd) || other.sessionEnd == sessionEnd)&&(identical(other.calculatorType, calculatorType) || other.calculatorType == calculatorType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,calculatorId,sessionStart,sessionEnd,calculatorType);

@override
String toString() {
  return 'CalculatorUsageRequest(calculatorId: $calculatorId, sessionStart: $sessionStart, sessionEnd: $sessionEnd, calculatorType: $calculatorType)';
}


}

/// @nodoc
abstract mixin class $CalculatorUsageRequestCopyWith<$Res>  {
  factory $CalculatorUsageRequestCopyWith(CalculatorUsageRequest value, $Res Function(CalculatorUsageRequest) _then) = _$CalculatorUsageRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'calculator_id') String? calculatorId,@JsonKey(name: 'session_start') DateTime? sessionStart,@JsonKey(name: 'session_end') DateTime? sessionEnd,@JsonKey(name: 'calculator_type') String? calculatorType
});




}
/// @nodoc
class _$CalculatorUsageRequestCopyWithImpl<$Res>
    implements $CalculatorUsageRequestCopyWith<$Res> {
  _$CalculatorUsageRequestCopyWithImpl(this._self, this._then);

  final CalculatorUsageRequest _self;
  final $Res Function(CalculatorUsageRequest) _then;

/// Create a copy of CalculatorUsageRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? calculatorId = freezed,Object? sessionStart = freezed,Object? sessionEnd = freezed,Object? calculatorType = freezed,}) {
  return _then(_self.copyWith(
calculatorId: freezed == calculatorId ? _self.calculatorId : calculatorId // ignore: cast_nullable_to_non_nullable
as String?,sessionStart: freezed == sessionStart ? _self.sessionStart : sessionStart // ignore: cast_nullable_to_non_nullable
as DateTime?,sessionEnd: freezed == sessionEnd ? _self.sessionEnd : sessionEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,calculatorType: freezed == calculatorType ? _self.calculatorType : calculatorType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CalculatorUsageRequest implements CalculatorUsageRequest {
  const _CalculatorUsageRequest({@JsonKey(name: 'calculator_id') this.calculatorId, @JsonKey(name: 'session_start') this.sessionStart, @JsonKey(name: 'session_end') this.sessionEnd, @JsonKey(name: 'calculator_type') this.calculatorType});
  factory _CalculatorUsageRequest.fromJson(Map<String, dynamic> json) => _$CalculatorUsageRequestFromJson(json);

@override@JsonKey(name: 'calculator_id') final  String? calculatorId;
@override@JsonKey(name: 'session_start') final  DateTime? sessionStart;
@override@JsonKey(name: 'session_end') final  DateTime? sessionEnd;
@override@JsonKey(name: 'calculator_type') final  String? calculatorType;

/// Create a copy of CalculatorUsageRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalculatorUsageRequestCopyWith<_CalculatorUsageRequest> get copyWith => __$CalculatorUsageRequestCopyWithImpl<_CalculatorUsageRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalculatorUsageRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalculatorUsageRequest&&(identical(other.calculatorId, calculatorId) || other.calculatorId == calculatorId)&&(identical(other.sessionStart, sessionStart) || other.sessionStart == sessionStart)&&(identical(other.sessionEnd, sessionEnd) || other.sessionEnd == sessionEnd)&&(identical(other.calculatorType, calculatorType) || other.calculatorType == calculatorType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,calculatorId,sessionStart,sessionEnd,calculatorType);

@override
String toString() {
  return 'CalculatorUsageRequest(calculatorId: $calculatorId, sessionStart: $sessionStart, sessionEnd: $sessionEnd, calculatorType: $calculatorType)';
}


}

/// @nodoc
abstract mixin class _$CalculatorUsageRequestCopyWith<$Res> implements $CalculatorUsageRequestCopyWith<$Res> {
  factory _$CalculatorUsageRequestCopyWith(_CalculatorUsageRequest value, $Res Function(_CalculatorUsageRequest) _then) = __$CalculatorUsageRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'calculator_id') String? calculatorId,@JsonKey(name: 'session_start') DateTime? sessionStart,@JsonKey(name: 'session_end') DateTime? sessionEnd,@JsonKey(name: 'calculator_type') String? calculatorType
});




}
/// @nodoc
class __$CalculatorUsageRequestCopyWithImpl<$Res>
    implements _$CalculatorUsageRequestCopyWith<$Res> {
  __$CalculatorUsageRequestCopyWithImpl(this._self, this._then);

  final _CalculatorUsageRequest _self;
  final $Res Function(_CalculatorUsageRequest) _then;

/// Create a copy of CalculatorUsageRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? calculatorId = freezed,Object? sessionStart = freezed,Object? sessionEnd = freezed,Object? calculatorType = freezed,}) {
  return _then(_CalculatorUsageRequest(
calculatorId: freezed == calculatorId ? _self.calculatorId : calculatorId // ignore: cast_nullable_to_non_nullable
as String?,sessionStart: freezed == sessionStart ? _self.sessionStart : sessionStart // ignore: cast_nullable_to_non_nullable
as DateTime?,sessionEnd: freezed == sessionEnd ? _self.sessionEnd : sessionEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,calculatorType: freezed == calculatorType ? _self.calculatorType : calculatorType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

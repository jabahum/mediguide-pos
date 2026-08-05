// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'therapeutic_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TherapeuticCategory {

 String get id; String get name; String get description;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(unknownEnumValue: Status.unknown) Status get status;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of TherapeuticCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TherapeuticCategoryCopyWith<TherapeuticCategory> get copyWith => _$TherapeuticCategoryCopyWithImpl<TherapeuticCategory>(this as TherapeuticCategory, _$identity);

  /// Serializes this TherapeuticCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TherapeuticCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,sortOrder,status,createdAt,updatedAt);

@override
String toString() {
  return 'TherapeuticCategory(id: $id, name: $name, description: $description, sortOrder: $sortOrder, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TherapeuticCategoryCopyWith<$Res>  {
  factory $TherapeuticCategoryCopyWith(TherapeuticCategory value, $Res Function(TherapeuticCategory) _then) = _$TherapeuticCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$TherapeuticCategoryCopyWithImpl<$Res>
    implements $TherapeuticCategoryCopyWith<$Res> {
  _$TherapeuticCategoryCopyWithImpl(this._self, this._then);

  final TherapeuticCategory _self;
  final $Res Function(TherapeuticCategory) _then;

/// Create a copy of TherapeuticCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? sortOrder = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _TherapeuticCategory implements TherapeuticCategory {
  const _TherapeuticCategory({required this.id, this.name = '', this.description = '', @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(unknownEnumValue: Status.unknown) this.status = Status.active, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _TherapeuticCategory.fromJson(Map<String, dynamic> json) => _$TherapeuticCategoryFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey(unknownEnumValue: Status.unknown) final  Status status;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of TherapeuticCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TherapeuticCategoryCopyWith<_TherapeuticCategory> get copyWith => __$TherapeuticCategoryCopyWithImpl<_TherapeuticCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TherapeuticCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TherapeuticCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,sortOrder,status,createdAt,updatedAt);

@override
String toString() {
  return 'TherapeuticCategory(id: $id, name: $name, description: $description, sortOrder: $sortOrder, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TherapeuticCategoryCopyWith<$Res> implements $TherapeuticCategoryCopyWith<$Res> {
  factory _$TherapeuticCategoryCopyWith(_TherapeuticCategory value, $Res Function(_TherapeuticCategory) _then) = __$TherapeuticCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$TherapeuticCategoryCopyWithImpl<$Res>
    implements _$TherapeuticCategoryCopyWith<$Res> {
  __$TherapeuticCategoryCopyWithImpl(this._self, this._then);

  final _TherapeuticCategory _self;
  final $Res Function(_TherapeuticCategory) _then;

/// Create a copy of TherapeuticCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? sortOrder = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_TherapeuticCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateTherapeuticCategoryRequest {

 String get name; String? get description;@JsonKey(name: 'sort_order') int? get sortOrder; Status? get status;
/// Create a copy of CreateTherapeuticCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTherapeuticCategoryRequestCopyWith<CreateTherapeuticCategoryRequest> get copyWith => _$CreateTherapeuticCategoryRequestCopyWithImpl<CreateTherapeuticCategoryRequest>(this as CreateTherapeuticCategoryRequest, _$identity);

  /// Serializes this CreateTherapeuticCategoryRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTherapeuticCategoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,sortOrder,status);

@override
String toString() {
  return 'CreateTherapeuticCategoryRequest(name: $name, description: $description, sortOrder: $sortOrder, status: $status)';
}


}

/// @nodoc
abstract mixin class $CreateTherapeuticCategoryRequestCopyWith<$Res>  {
  factory $CreateTherapeuticCategoryRequestCopyWith(CreateTherapeuticCategoryRequest value, $Res Function(CreateTherapeuticCategoryRequest) _then) = _$CreateTherapeuticCategoryRequestCopyWithImpl;
@useResult
$Res call({
 String name, String? description,@JsonKey(name: 'sort_order') int? sortOrder, Status? status
});




}
/// @nodoc
class _$CreateTherapeuticCategoryRequestCopyWithImpl<$Res>
    implements $CreateTherapeuticCategoryRequestCopyWith<$Res> {
  _$CreateTherapeuticCategoryRequestCopyWithImpl(this._self, this._then);

  final CreateTherapeuticCategoryRequest _self;
  final $Res Function(CreateTherapeuticCategoryRequest) _then;

/// Create a copy of CreateTherapeuticCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? sortOrder = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CreateTherapeuticCategoryRequest implements CreateTherapeuticCategoryRequest {
  const _CreateTherapeuticCategoryRequest({required this.name, this.description, @JsonKey(name: 'sort_order') this.sortOrder, this.status});
  factory _CreateTherapeuticCategoryRequest.fromJson(Map<String, dynamic> json) => _$CreateTherapeuticCategoryRequestFromJson(json);

@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;
@override final  Status? status;

/// Create a copy of CreateTherapeuticCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTherapeuticCategoryRequestCopyWith<_CreateTherapeuticCategoryRequest> get copyWith => __$CreateTherapeuticCategoryRequestCopyWithImpl<_CreateTherapeuticCategoryRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTherapeuticCategoryRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTherapeuticCategoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,sortOrder,status);

@override
String toString() {
  return 'CreateTherapeuticCategoryRequest(name: $name, description: $description, sortOrder: $sortOrder, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CreateTherapeuticCategoryRequestCopyWith<$Res> implements $CreateTherapeuticCategoryRequestCopyWith<$Res> {
  factory _$CreateTherapeuticCategoryRequestCopyWith(_CreateTherapeuticCategoryRequest value, $Res Function(_CreateTherapeuticCategoryRequest) _then) = __$CreateTherapeuticCategoryRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description,@JsonKey(name: 'sort_order') int? sortOrder, Status? status
});




}
/// @nodoc
class __$CreateTherapeuticCategoryRequestCopyWithImpl<$Res>
    implements _$CreateTherapeuticCategoryRequestCopyWith<$Res> {
  __$CreateTherapeuticCategoryRequestCopyWithImpl(this._self, this._then);

  final _CreateTherapeuticCategoryRequest _self;
  final $Res Function(_CreateTherapeuticCategoryRequest) _then;

/// Create a copy of CreateTherapeuticCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? sortOrder = freezed,Object? status = freezed,}) {
  return _then(_CreateTherapeuticCategoryRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,
  ));
}


}

// dart format on

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drug_class.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrugClass {

 String get id; String get name; String get description;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(unknownEnumValue: Status.unknown) Status get status;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of DrugClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrugClassCopyWith<DrugClass> get copyWith => _$DrugClassCopyWithImpl<DrugClass>(this as DrugClass, _$identity);

  /// Serializes this DrugClass to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrugClass&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,sortOrder,status,createdAt,updatedAt);

@override
String toString() {
  return 'DrugClass(id: $id, name: $name, description: $description, sortOrder: $sortOrder, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DrugClassCopyWith<$Res>  {
  factory $DrugClassCopyWith(DrugClass value, $Res Function(DrugClass) _then) = _$DrugClassCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$DrugClassCopyWithImpl<$Res>
    implements $DrugClassCopyWith<$Res> {
  _$DrugClassCopyWithImpl(this._self, this._then);

  final DrugClass _self;
  final $Res Function(DrugClass) _then;

/// Create a copy of DrugClass
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

class _DrugClass implements DrugClass {
  const _DrugClass({required this.id, this.name = '', this.description = '', @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(unknownEnumValue: Status.unknown) this.status = Status.active, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _DrugClass.fromJson(Map<String, dynamic> json) => _$DrugClassFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey(unknownEnumValue: Status.unknown) final  Status status;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of DrugClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrugClassCopyWith<_DrugClass> get copyWith => __$DrugClassCopyWithImpl<_DrugClass>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrugClassToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrugClass&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,sortOrder,status,createdAt,updatedAt);

@override
String toString() {
  return 'DrugClass(id: $id, name: $name, description: $description, sortOrder: $sortOrder, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DrugClassCopyWith<$Res> implements $DrugClassCopyWith<$Res> {
  factory _$DrugClassCopyWith(_DrugClass value, $Res Function(_DrugClass) _then) = __$DrugClassCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$DrugClassCopyWithImpl<$Res>
    implements _$DrugClassCopyWith<$Res> {
  __$DrugClassCopyWithImpl(this._self, this._then);

  final _DrugClass _self;
  final $Res Function(_DrugClass) _then;

/// Create a copy of DrugClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? sortOrder = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_DrugClass(
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
mixin _$CreateDrugClassRequest {

 String get name; String? get description;@JsonKey(name: 'sort_order') int? get sortOrder; Status? get status;
/// Create a copy of CreateDrugClassRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateDrugClassRequestCopyWith<CreateDrugClassRequest> get copyWith => _$CreateDrugClassRequestCopyWithImpl<CreateDrugClassRequest>(this as CreateDrugClassRequest, _$identity);

  /// Serializes this CreateDrugClassRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateDrugClassRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,sortOrder,status);

@override
String toString() {
  return 'CreateDrugClassRequest(name: $name, description: $description, sortOrder: $sortOrder, status: $status)';
}


}

/// @nodoc
abstract mixin class $CreateDrugClassRequestCopyWith<$Res>  {
  factory $CreateDrugClassRequestCopyWith(CreateDrugClassRequest value, $Res Function(CreateDrugClassRequest) _then) = _$CreateDrugClassRequestCopyWithImpl;
@useResult
$Res call({
 String name, String? description,@JsonKey(name: 'sort_order') int? sortOrder, Status? status
});




}
/// @nodoc
class _$CreateDrugClassRequestCopyWithImpl<$Res>
    implements $CreateDrugClassRequestCopyWith<$Res> {
  _$CreateDrugClassRequestCopyWithImpl(this._self, this._then);

  final CreateDrugClassRequest _self;
  final $Res Function(CreateDrugClassRequest) _then;

/// Create a copy of CreateDrugClassRequest
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
class _CreateDrugClassRequest implements CreateDrugClassRequest {
  const _CreateDrugClassRequest({required this.name, this.description, @JsonKey(name: 'sort_order') this.sortOrder, this.status});
  factory _CreateDrugClassRequest.fromJson(Map<String, dynamic> json) => _$CreateDrugClassRequestFromJson(json);

@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;
@override final  Status? status;

/// Create a copy of CreateDrugClassRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateDrugClassRequestCopyWith<_CreateDrugClassRequest> get copyWith => __$CreateDrugClassRequestCopyWithImpl<_CreateDrugClassRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateDrugClassRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateDrugClassRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,sortOrder,status);

@override
String toString() {
  return 'CreateDrugClassRequest(name: $name, description: $description, sortOrder: $sortOrder, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CreateDrugClassRequestCopyWith<$Res> implements $CreateDrugClassRequestCopyWith<$Res> {
  factory _$CreateDrugClassRequestCopyWith(_CreateDrugClassRequest value, $Res Function(_CreateDrugClassRequest) _then) = __$CreateDrugClassRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description,@JsonKey(name: 'sort_order') int? sortOrder, Status? status
});




}
/// @nodoc
class __$CreateDrugClassRequestCopyWithImpl<$Res>
    implements _$CreateDrugClassRequestCopyWith<$Res> {
  __$CreateDrugClassRequestCopyWithImpl(this._self, this._then);

  final _CreateDrugClassRequest _self;
  final $Res Function(_CreateDrugClassRequest) _then;

/// Create a copy of CreateDrugClassRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? sortOrder = freezed,Object? status = freezed,}) {
  return _then(_CreateDrugClassRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,
  ));
}


}

// dart format on

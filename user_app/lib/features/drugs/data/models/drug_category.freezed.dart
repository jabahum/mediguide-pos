// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drug_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrugCategory {

 String get id; String get name; String get description; String get color; String get icon;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(unknownEnumValue: Status.unknown) Status get status;@JsonKey(name: 'parent_category_id') String? get parentCategoryId;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of DrugCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrugCategoryCopyWith<DrugCategory> get copyWith => _$DrugCategoryCopyWithImpl<DrugCategory>(this as DrugCategory, _$identity);

  /// Serializes this DrugCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrugCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,color,icon,sortOrder,status,parentCategoryId,createdAt,updatedAt);

@override
String toString() {
  return 'DrugCategory(id: $id, name: $name, description: $description, color: $color, icon: $icon, sortOrder: $sortOrder, status: $status, parentCategoryId: $parentCategoryId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DrugCategoryCopyWith<$Res>  {
  factory $DrugCategoryCopyWith(DrugCategory value, $Res Function(DrugCategory) _then) = _$DrugCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String color, String icon,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'parent_category_id') String? parentCategoryId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$DrugCategoryCopyWithImpl<$Res>
    implements $DrugCategoryCopyWith<$Res> {
  _$DrugCategoryCopyWithImpl(this._self, this._then);

  final DrugCategory _self;
  final $Res Function(DrugCategory) _then;

/// Create a copy of DrugCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? color = null,Object? icon = null,Object? sortOrder = null,Object? status = null,Object? parentCategoryId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _DrugCategory extends DrugCategory {
  const _DrugCategory({required this.id, this.name = '', this.description = '', this.color = '', this.icon = '', @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(unknownEnumValue: Status.unknown) this.status = Status.active, @JsonKey(name: 'parent_category_id') this.parentCategoryId, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _DrugCategory.fromJson(Map<String, dynamic> json) => _$DrugCategoryFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String color;
@override@JsonKey() final  String icon;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey(unknownEnumValue: Status.unknown) final  Status status;
@override@JsonKey(name: 'parent_category_id') final  String? parentCategoryId;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of DrugCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrugCategoryCopyWith<_DrugCategory> get copyWith => __$DrugCategoryCopyWithImpl<_DrugCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrugCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrugCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,color,icon,sortOrder,status,parentCategoryId,createdAt,updatedAt);

@override
String toString() {
  return 'DrugCategory(id: $id, name: $name, description: $description, color: $color, icon: $icon, sortOrder: $sortOrder, status: $status, parentCategoryId: $parentCategoryId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DrugCategoryCopyWith<$Res> implements $DrugCategoryCopyWith<$Res> {
  factory _$DrugCategoryCopyWith(_DrugCategory value, $Res Function(_DrugCategory) _then) = __$DrugCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String color, String icon,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'parent_category_id') String? parentCategoryId,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$DrugCategoryCopyWithImpl<$Res>
    implements _$DrugCategoryCopyWith<$Res> {
  __$DrugCategoryCopyWithImpl(this._self, this._then);

  final _DrugCategory _self;
  final $Res Function(_DrugCategory) _then;

/// Create a copy of DrugCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? color = null,Object? icon = null,Object? sortOrder = null,Object? status = null,Object? parentCategoryId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_DrugCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateDrugCategoryRequest {

 String get name; String? get description; String? get color; String? get icon;@JsonKey(name: 'sort_order') int? get sortOrder; Status? get status;@JsonKey(name: 'parent_category_id') String? get parentCategoryId;
/// Create a copy of CreateDrugCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateDrugCategoryRequestCopyWith<CreateDrugCategoryRequest> get copyWith => _$CreateDrugCategoryRequestCopyWithImpl<CreateDrugCategoryRequest>(this as CreateDrugCategoryRequest, _$identity);

  /// Serializes this CreateDrugCategoryRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateDrugCategoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,color,icon,sortOrder,status,parentCategoryId);

@override
String toString() {
  return 'CreateDrugCategoryRequest(name: $name, description: $description, color: $color, icon: $icon, sortOrder: $sortOrder, status: $status, parentCategoryId: $parentCategoryId)';
}


}

/// @nodoc
abstract mixin class $CreateDrugCategoryRequestCopyWith<$Res>  {
  factory $CreateDrugCategoryRequestCopyWith(CreateDrugCategoryRequest value, $Res Function(CreateDrugCategoryRequest) _then) = _$CreateDrugCategoryRequestCopyWithImpl;
@useResult
$Res call({
 String name, String? description, String? color, String? icon,@JsonKey(name: 'sort_order') int? sortOrder, Status? status,@JsonKey(name: 'parent_category_id') String? parentCategoryId
});




}
/// @nodoc
class _$CreateDrugCategoryRequestCopyWithImpl<$Res>
    implements $CreateDrugCategoryRequestCopyWith<$Res> {
  _$CreateDrugCategoryRequestCopyWithImpl(this._self, this._then);

  final CreateDrugCategoryRequest _self;
  final $Res Function(CreateDrugCategoryRequest) _then;

/// Create a copy of CreateDrugCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? color = freezed,Object? icon = freezed,Object? sortOrder = freezed,Object? status = freezed,Object? parentCategoryId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CreateDrugCategoryRequest implements CreateDrugCategoryRequest {
  const _CreateDrugCategoryRequest({required this.name, this.description, this.color, this.icon, @JsonKey(name: 'sort_order') this.sortOrder, this.status, @JsonKey(name: 'parent_category_id') this.parentCategoryId});
  factory _CreateDrugCategoryRequest.fromJson(Map<String, dynamic> json) => _$CreateDrugCategoryRequestFromJson(json);

@override final  String name;
@override final  String? description;
@override final  String? color;
@override final  String? icon;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;
@override final  Status? status;
@override@JsonKey(name: 'parent_category_id') final  String? parentCategoryId;

/// Create a copy of CreateDrugCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateDrugCategoryRequestCopyWith<_CreateDrugCategoryRequest> get copyWith => __$CreateDrugCategoryRequestCopyWithImpl<_CreateDrugCategoryRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateDrugCategoryRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateDrugCategoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,color,icon,sortOrder,status,parentCategoryId);

@override
String toString() {
  return 'CreateDrugCategoryRequest(name: $name, description: $description, color: $color, icon: $icon, sortOrder: $sortOrder, status: $status, parentCategoryId: $parentCategoryId)';
}


}

/// @nodoc
abstract mixin class _$CreateDrugCategoryRequestCopyWith<$Res> implements $CreateDrugCategoryRequestCopyWith<$Res> {
  factory _$CreateDrugCategoryRequestCopyWith(_CreateDrugCategoryRequest value, $Res Function(_CreateDrugCategoryRequest) _then) = __$CreateDrugCategoryRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description, String? color, String? icon,@JsonKey(name: 'sort_order') int? sortOrder, Status? status,@JsonKey(name: 'parent_category_id') String? parentCategoryId
});




}
/// @nodoc
class __$CreateDrugCategoryRequestCopyWithImpl<$Res>
    implements _$CreateDrugCategoryRequestCopyWith<$Res> {
  __$CreateDrugCategoryRequestCopyWithImpl(this._self, this._then);

  final _CreateDrugCategoryRequest _self;
  final $Res Function(_CreateDrugCategoryRequest) _then;

/// Create a copy of CreateDrugCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? color = freezed,Object? icon = freezed,Object? sortOrder = freezed,Object? status = freezed,Object? parentCategoryId = freezed,}) {
  return _then(_CreateDrugCategoryRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

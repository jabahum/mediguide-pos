// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guideline_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuidelineCategory {

 String get id; String get name; String get slug; String get description;@JsonKey(name: 'sort_order') int get sortOrder; String get color; String get icon;@JsonKey(name: 'parent_category_id') String? get parentCategoryId;@JsonKey(name: 'parent_name') String? get parentName; GuidelineCategoryStatus get status;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of GuidelineCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineCategoryCopyWith<GuidelineCategory> get copyWith => _$GuidelineCategoryCopyWithImpl<GuidelineCategory>(this as GuidelineCategory, _$identity);

  /// Serializes this GuidelineCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId)&&(identical(other.parentName, parentName) || other.parentName == parentName)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,description,sortOrder,color,icon,parentCategoryId,parentName,status,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineCategory(id: $id, name: $name, slug: $slug, description: $description, sortOrder: $sortOrder, color: $color, icon: $icon, parentCategoryId: $parentCategoryId, parentName: $parentName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GuidelineCategoryCopyWith<$Res>  {
  factory $GuidelineCategoryCopyWith(GuidelineCategory value, $Res Function(GuidelineCategory) _then) = _$GuidelineCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String description,@JsonKey(name: 'sort_order') int sortOrder, String color, String icon,@JsonKey(name: 'parent_category_id') String? parentCategoryId,@JsonKey(name: 'parent_name') String? parentName, GuidelineCategoryStatus status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$GuidelineCategoryCopyWithImpl<$Res>
    implements $GuidelineCategoryCopyWith<$Res> {
  _$GuidelineCategoryCopyWithImpl(this._self, this._then);

  final GuidelineCategory _self;
  final $Res Function(GuidelineCategory) _then;

/// Create a copy of GuidelineCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? description = null,Object? sortOrder = null,Object? color = null,Object? icon = null,Object? parentCategoryId = freezed,Object? parentName = freezed,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,parentName: freezed == parentName ? _self.parentName : parentName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GuidelineCategoryStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineCategory extends GuidelineCategory {
  const _GuidelineCategory({required this.id, this.name = '', this.slug = '', this.description = '', @JsonKey(name: 'sort_order') this.sortOrder = 0, this.color = '', this.icon = '', @JsonKey(name: 'parent_category_id') this.parentCategoryId, @JsonKey(name: 'parent_name') this.parentName, this.status = GuidelineCategoryStatus.active, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _GuidelineCategory.fromJson(Map<String, dynamic> json) => _$GuidelineCategoryFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String slug;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey() final  String color;
@override@JsonKey() final  String icon;
@override@JsonKey(name: 'parent_category_id') final  String? parentCategoryId;
@override@JsonKey(name: 'parent_name') final  String? parentName;
@override@JsonKey() final  GuidelineCategoryStatus status;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of GuidelineCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineCategoryCopyWith<_GuidelineCategory> get copyWith => __$GuidelineCategoryCopyWithImpl<_GuidelineCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId)&&(identical(other.parentName, parentName) || other.parentName == parentName)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,description,sortOrder,color,icon,parentCategoryId,parentName,status,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineCategory(id: $id, name: $name, slug: $slug, description: $description, sortOrder: $sortOrder, color: $color, icon: $icon, parentCategoryId: $parentCategoryId, parentName: $parentName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GuidelineCategoryCopyWith<$Res> implements $GuidelineCategoryCopyWith<$Res> {
  factory _$GuidelineCategoryCopyWith(_GuidelineCategory value, $Res Function(_GuidelineCategory) _then) = __$GuidelineCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String description,@JsonKey(name: 'sort_order') int sortOrder, String color, String icon,@JsonKey(name: 'parent_category_id') String? parentCategoryId,@JsonKey(name: 'parent_name') String? parentName, GuidelineCategoryStatus status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$GuidelineCategoryCopyWithImpl<$Res>
    implements _$GuidelineCategoryCopyWith<$Res> {
  __$GuidelineCategoryCopyWithImpl(this._self, this._then);

  final _GuidelineCategory _self;
  final $Res Function(_GuidelineCategory) _then;

/// Create a copy of GuidelineCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? description = null,Object? sortOrder = null,Object? color = null,Object? icon = null,Object? parentCategoryId = freezed,Object? parentName = freezed,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_GuidelineCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,parentName: freezed == parentName ? _self.parentName : parentName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GuidelineCategoryStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateGuidelineCategoryRequest {

 String get name; String? get slug; String? get description;@JsonKey(name: 'sort_order') int? get sortOrder; GuidelineCategoryStatus? get status; String? get color; String? get icon;@JsonKey(name: 'parent_category_id') String? get parentCategoryId;
/// Create a copy of CreateGuidelineCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateGuidelineCategoryRequestCopyWith<CreateGuidelineCategoryRequest> get copyWith => _$CreateGuidelineCategoryRequestCopyWithImpl<CreateGuidelineCategoryRequest>(this as CreateGuidelineCategoryRequest, _$identity);

  /// Serializes this CreateGuidelineCategoryRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateGuidelineCategoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,description,sortOrder,status,color,icon,parentCategoryId);

@override
String toString() {
  return 'CreateGuidelineCategoryRequest(name: $name, slug: $slug, description: $description, sortOrder: $sortOrder, status: $status, color: $color, icon: $icon, parentCategoryId: $parentCategoryId)';
}


}

/// @nodoc
abstract mixin class $CreateGuidelineCategoryRequestCopyWith<$Res>  {
  factory $CreateGuidelineCategoryRequestCopyWith(CreateGuidelineCategoryRequest value, $Res Function(CreateGuidelineCategoryRequest) _then) = _$CreateGuidelineCategoryRequestCopyWithImpl;
@useResult
$Res call({
 String name, String? slug, String? description,@JsonKey(name: 'sort_order') int? sortOrder, GuidelineCategoryStatus? status, String? color, String? icon,@JsonKey(name: 'parent_category_id') String? parentCategoryId
});




}
/// @nodoc
class _$CreateGuidelineCategoryRequestCopyWithImpl<$Res>
    implements $CreateGuidelineCategoryRequestCopyWith<$Res> {
  _$CreateGuidelineCategoryRequestCopyWithImpl(this._self, this._then);

  final CreateGuidelineCategoryRequest _self;
  final $Res Function(CreateGuidelineCategoryRequest) _then;

/// Create a copy of CreateGuidelineCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? slug = freezed,Object? description = freezed,Object? sortOrder = freezed,Object? status = freezed,Object? color = freezed,Object? icon = freezed,Object? parentCategoryId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GuidelineCategoryStatus?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CreateGuidelineCategoryRequest implements CreateGuidelineCategoryRequest {
  const _CreateGuidelineCategoryRequest({required this.name, this.slug, this.description, @JsonKey(name: 'sort_order') this.sortOrder, this.status, this.color, this.icon, @JsonKey(name: 'parent_category_id') this.parentCategoryId});
  factory _CreateGuidelineCategoryRequest.fromJson(Map<String, dynamic> json) => _$CreateGuidelineCategoryRequestFromJson(json);

@override final  String name;
@override final  String? slug;
@override final  String? description;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;
@override final  GuidelineCategoryStatus? status;
@override final  String? color;
@override final  String? icon;
@override@JsonKey(name: 'parent_category_id') final  String? parentCategoryId;

/// Create a copy of CreateGuidelineCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateGuidelineCategoryRequestCopyWith<_CreateGuidelineCategoryRequest> get copyWith => __$CreateGuidelineCategoryRequestCopyWithImpl<_CreateGuidelineCategoryRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateGuidelineCategoryRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateGuidelineCategoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,description,sortOrder,status,color,icon,parentCategoryId);

@override
String toString() {
  return 'CreateGuidelineCategoryRequest(name: $name, slug: $slug, description: $description, sortOrder: $sortOrder, status: $status, color: $color, icon: $icon, parentCategoryId: $parentCategoryId)';
}


}

/// @nodoc
abstract mixin class _$CreateGuidelineCategoryRequestCopyWith<$Res> implements $CreateGuidelineCategoryRequestCopyWith<$Res> {
  factory _$CreateGuidelineCategoryRequestCopyWith(_CreateGuidelineCategoryRequest value, $Res Function(_CreateGuidelineCategoryRequest) _then) = __$CreateGuidelineCategoryRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String? slug, String? description,@JsonKey(name: 'sort_order') int? sortOrder, GuidelineCategoryStatus? status, String? color, String? icon,@JsonKey(name: 'parent_category_id') String? parentCategoryId
});




}
/// @nodoc
class __$CreateGuidelineCategoryRequestCopyWithImpl<$Res>
    implements _$CreateGuidelineCategoryRequestCopyWith<$Res> {
  __$CreateGuidelineCategoryRequestCopyWithImpl(this._self, this._then);

  final _CreateGuidelineCategoryRequest _self;
  final $Res Function(_CreateGuidelineCategoryRequest) _then;

/// Create a copy of CreateGuidelineCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? slug = freezed,Object? description = freezed,Object? sortOrder = freezed,Object? status = freezed,Object? color = freezed,Object? icon = freezed,Object? parentCategoryId = freezed,}) {
  return _then(_CreateGuidelineCategoryRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GuidelineCategoryStatus?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

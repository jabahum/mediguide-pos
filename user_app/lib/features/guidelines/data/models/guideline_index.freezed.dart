// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guideline_index.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuidelineIndex {

 String get id; String get title; String get description;@JsonKey(name: 'parent_id') String? get parentId;@JsonKey(name: 'parent_title') String? get parentTitle;@JsonKey(name: 'sort_order') int get order; int get level;@JsonKey(name: 'has_children') bool get hasChildren;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of GuidelineIndex
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineIndexCopyWith<GuidelineIndex> get copyWith => _$GuidelineIndexCopyWithImpl<GuidelineIndex>(this as GuidelineIndex, _$identity);

  /// Serializes this GuidelineIndex to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineIndex&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.parentTitle, parentTitle) || other.parentTitle == parentTitle)&&(identical(other.order, order) || other.order == order)&&(identical(other.level, level) || other.level == level)&&(identical(other.hasChildren, hasChildren) || other.hasChildren == hasChildren)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,parentId,parentTitle,order,level,hasChildren,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineIndex(id: $id, title: $title, description: $description, parentId: $parentId, parentTitle: $parentTitle, order: $order, level: $level, hasChildren: $hasChildren, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GuidelineIndexCopyWith<$Res>  {
  factory $GuidelineIndexCopyWith(GuidelineIndex value, $Res Function(GuidelineIndex) _then) = _$GuidelineIndexCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description,@JsonKey(name: 'parent_id') String? parentId,@JsonKey(name: 'parent_title') String? parentTitle,@JsonKey(name: 'sort_order') int order, int level,@JsonKey(name: 'has_children') bool hasChildren,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$GuidelineIndexCopyWithImpl<$Res>
    implements $GuidelineIndexCopyWith<$Res> {
  _$GuidelineIndexCopyWithImpl(this._self, this._then);

  final GuidelineIndex _self;
  final $Res Function(GuidelineIndex) _then;

/// Create a copy of GuidelineIndex
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? parentId = freezed,Object? parentTitle = freezed,Object? order = null,Object? level = null,Object? hasChildren = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,parentTitle: freezed == parentTitle ? _self.parentTitle : parentTitle // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,hasChildren: null == hasChildren ? _self.hasChildren : hasChildren // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineIndex extends GuidelineIndex {
  const _GuidelineIndex({required this.id, this.title = '', this.description = '', @JsonKey(name: 'parent_id') this.parentId, @JsonKey(name: 'parent_title') this.parentTitle, @JsonKey(name: 'sort_order') this.order = 0, this.level = 0, @JsonKey(name: 'has_children') this.hasChildren = false, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _GuidelineIndex.fromJson(Map<String, dynamic> json) => _$GuidelineIndexFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'parent_id') final  String? parentId;
@override@JsonKey(name: 'parent_title') final  String? parentTitle;
@override@JsonKey(name: 'sort_order') final  int order;
@override@JsonKey() final  int level;
@override@JsonKey(name: 'has_children') final  bool hasChildren;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of GuidelineIndex
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineIndexCopyWith<_GuidelineIndex> get copyWith => __$GuidelineIndexCopyWithImpl<_GuidelineIndex>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineIndexToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineIndex&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.parentTitle, parentTitle) || other.parentTitle == parentTitle)&&(identical(other.order, order) || other.order == order)&&(identical(other.level, level) || other.level == level)&&(identical(other.hasChildren, hasChildren) || other.hasChildren == hasChildren)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,parentId,parentTitle,order,level,hasChildren,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineIndex(id: $id, title: $title, description: $description, parentId: $parentId, parentTitle: $parentTitle, order: $order, level: $level, hasChildren: $hasChildren, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GuidelineIndexCopyWith<$Res> implements $GuidelineIndexCopyWith<$Res> {
  factory _$GuidelineIndexCopyWith(_GuidelineIndex value, $Res Function(_GuidelineIndex) _then) = __$GuidelineIndexCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description,@JsonKey(name: 'parent_id') String? parentId,@JsonKey(name: 'parent_title') String? parentTitle,@JsonKey(name: 'sort_order') int order, int level,@JsonKey(name: 'has_children') bool hasChildren,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$GuidelineIndexCopyWithImpl<$Res>
    implements _$GuidelineIndexCopyWith<$Res> {
  __$GuidelineIndexCopyWithImpl(this._self, this._then);

  final _GuidelineIndex _self;
  final $Res Function(_GuidelineIndex) _then;

/// Create a copy of GuidelineIndex
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? parentId = freezed,Object? parentTitle = freezed,Object? order = null,Object? level = null,Object? hasChildren = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_GuidelineIndex(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,parentTitle: freezed == parentTitle ? _self.parentTitle : parentTitle // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,hasChildren: null == hasChildren ? _self.hasChildren : hasChildren // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateGuidelineIndexRequest {

 String get title; String? get description;@JsonKey(name: 'parent_id') String? get parentId;@JsonKey(name: 'sort_order') int? get sortOrder; int? get level;
/// Create a copy of CreateGuidelineIndexRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateGuidelineIndexRequestCopyWith<CreateGuidelineIndexRequest> get copyWith => _$CreateGuidelineIndexRequestCopyWithImpl<CreateGuidelineIndexRequest>(this as CreateGuidelineIndexRequest, _$identity);

  /// Serializes this CreateGuidelineIndexRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateGuidelineIndexRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,parentId,sortOrder,level);

@override
String toString() {
  return 'CreateGuidelineIndexRequest(title: $title, description: $description, parentId: $parentId, sortOrder: $sortOrder, level: $level)';
}


}

/// @nodoc
abstract mixin class $CreateGuidelineIndexRequestCopyWith<$Res>  {
  factory $CreateGuidelineIndexRequestCopyWith(CreateGuidelineIndexRequest value, $Res Function(CreateGuidelineIndexRequest) _then) = _$CreateGuidelineIndexRequestCopyWithImpl;
@useResult
$Res call({
 String title, String? description,@JsonKey(name: 'parent_id') String? parentId,@JsonKey(name: 'sort_order') int? sortOrder, int? level
});




}
/// @nodoc
class _$CreateGuidelineIndexRequestCopyWithImpl<$Res>
    implements $CreateGuidelineIndexRequestCopyWith<$Res> {
  _$CreateGuidelineIndexRequestCopyWithImpl(this._self, this._then);

  final CreateGuidelineIndexRequest _self;
  final $Res Function(CreateGuidelineIndexRequest) _then;

/// Create a copy of CreateGuidelineIndexRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = freezed,Object? parentId = freezed,Object? sortOrder = freezed,Object? level = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CreateGuidelineIndexRequest implements CreateGuidelineIndexRequest {
  const _CreateGuidelineIndexRequest({required this.title, this.description, @JsonKey(name: 'parent_id') this.parentId, @JsonKey(name: 'sort_order') this.sortOrder, this.level});
  factory _CreateGuidelineIndexRequest.fromJson(Map<String, dynamic> json) => _$CreateGuidelineIndexRequestFromJson(json);

@override final  String title;
@override final  String? description;
@override@JsonKey(name: 'parent_id') final  String? parentId;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;
@override final  int? level;

/// Create a copy of CreateGuidelineIndexRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateGuidelineIndexRequestCopyWith<_CreateGuidelineIndexRequest> get copyWith => __$CreateGuidelineIndexRequestCopyWithImpl<_CreateGuidelineIndexRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateGuidelineIndexRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateGuidelineIndexRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,parentId,sortOrder,level);

@override
String toString() {
  return 'CreateGuidelineIndexRequest(title: $title, description: $description, parentId: $parentId, sortOrder: $sortOrder, level: $level)';
}


}

/// @nodoc
abstract mixin class _$CreateGuidelineIndexRequestCopyWith<$Res> implements $CreateGuidelineIndexRequestCopyWith<$Res> {
  factory _$CreateGuidelineIndexRequestCopyWith(_CreateGuidelineIndexRequest value, $Res Function(_CreateGuidelineIndexRequest) _then) = __$CreateGuidelineIndexRequestCopyWithImpl;
@override @useResult
$Res call({
 String title, String? description,@JsonKey(name: 'parent_id') String? parentId,@JsonKey(name: 'sort_order') int? sortOrder, int? level
});




}
/// @nodoc
class __$CreateGuidelineIndexRequestCopyWithImpl<$Res>
    implements _$CreateGuidelineIndexRequestCopyWith<$Res> {
  __$CreateGuidelineIndexRequestCopyWithImpl(this._self, this._then);

  final _CreateGuidelineIndexRequest _self;
  final $Res Function(_CreateGuidelineIndexRequest) _then;

/// Create a copy of CreateGuidelineIndexRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = freezed,Object? parentId = freezed,Object? sortOrder = freezed,Object? level = freezed,}) {
  return _then(_CreateGuidelineIndexRequest(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

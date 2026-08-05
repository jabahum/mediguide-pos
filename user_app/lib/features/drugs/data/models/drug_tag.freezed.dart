// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drug_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrugTag {

 String get id; String get name; String get description; String get color;@JsonKey(name: 'tag_category') String get tagCategory;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(unknownEnumValue: Status.unknown) Status get status;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of DrugTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrugTagCopyWith<DrugTag> get copyWith => _$DrugTagCopyWithImpl<DrugTag>(this as DrugTag, _$identity);

  /// Serializes this DrugTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrugTag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.tagCategory, tagCategory) || other.tagCategory == tagCategory)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,color,tagCategory,sortOrder,status,createdAt,updatedAt);

@override
String toString() {
  return 'DrugTag(id: $id, name: $name, description: $description, color: $color, tagCategory: $tagCategory, sortOrder: $sortOrder, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DrugTagCopyWith<$Res>  {
  factory $DrugTagCopyWith(DrugTag value, $Res Function(DrugTag) _then) = _$DrugTagCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String color,@JsonKey(name: 'tag_category') String tagCategory,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$DrugTagCopyWithImpl<$Res>
    implements $DrugTagCopyWith<$Res> {
  _$DrugTagCopyWithImpl(this._self, this._then);

  final DrugTag _self;
  final $Res Function(DrugTag) _then;

/// Create a copy of DrugTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? color = null,Object? tagCategory = null,Object? sortOrder = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,tagCategory: null == tagCategory ? _self.tagCategory : tagCategory // ignore: cast_nullable_to_non_nullable
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

class _DrugTag implements DrugTag {
  const _DrugTag({required this.id, this.name = '', this.description = '', this.color = '', @JsonKey(name: 'tag_category') this.tagCategory = '', @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(unknownEnumValue: Status.unknown) this.status = Status.active, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt});
  factory _DrugTag.fromJson(Map<String, dynamic> json) => _$DrugTagFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String color;
@override@JsonKey(name: 'tag_category') final  String tagCategory;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey(unknownEnumValue: Status.unknown) final  Status status;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of DrugTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrugTagCopyWith<_DrugTag> get copyWith => __$DrugTagCopyWithImpl<_DrugTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrugTagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrugTag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.tagCategory, tagCategory) || other.tagCategory == tagCategory)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,color,tagCategory,sortOrder,status,createdAt,updatedAt);

@override
String toString() {
  return 'DrugTag(id: $id, name: $name, description: $description, color: $color, tagCategory: $tagCategory, sortOrder: $sortOrder, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DrugTagCopyWith<$Res> implements $DrugTagCopyWith<$Res> {
  factory _$DrugTagCopyWith(_DrugTag value, $Res Function(_DrugTag) _then) = __$DrugTagCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String color,@JsonKey(name: 'tag_category') String tagCategory,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(unknownEnumValue: Status.unknown) Status status,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$DrugTagCopyWithImpl<$Res>
    implements _$DrugTagCopyWith<$Res> {
  __$DrugTagCopyWithImpl(this._self, this._then);

  final _DrugTag _self;
  final $Res Function(_DrugTag) _then;

/// Create a copy of DrugTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? color = null,Object? tagCategory = null,Object? sortOrder = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_DrugTag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,tagCategory: null == tagCategory ? _self.tagCategory : tagCategory // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateDrugTagRequest {

 String get name; String? get description; String? get color;@JsonKey(name: 'tag_category') String? get tagCategory;@JsonKey(name: 'sort_order') int? get sortOrder; Status? get status;
/// Create a copy of CreateDrugTagRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateDrugTagRequestCopyWith<CreateDrugTagRequest> get copyWith => _$CreateDrugTagRequestCopyWithImpl<CreateDrugTagRequest>(this as CreateDrugTagRequest, _$identity);

  /// Serializes this CreateDrugTagRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateDrugTagRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.tagCategory, tagCategory) || other.tagCategory == tagCategory)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,color,tagCategory,sortOrder,status);

@override
String toString() {
  return 'CreateDrugTagRequest(name: $name, description: $description, color: $color, tagCategory: $tagCategory, sortOrder: $sortOrder, status: $status)';
}


}

/// @nodoc
abstract mixin class $CreateDrugTagRequestCopyWith<$Res>  {
  factory $CreateDrugTagRequestCopyWith(CreateDrugTagRequest value, $Res Function(CreateDrugTagRequest) _then) = _$CreateDrugTagRequestCopyWithImpl;
@useResult
$Res call({
 String name, String? description, String? color,@JsonKey(name: 'tag_category') String? tagCategory,@JsonKey(name: 'sort_order') int? sortOrder, Status? status
});




}
/// @nodoc
class _$CreateDrugTagRequestCopyWithImpl<$Res>
    implements $CreateDrugTagRequestCopyWith<$Res> {
  _$CreateDrugTagRequestCopyWithImpl(this._self, this._then);

  final CreateDrugTagRequest _self;
  final $Res Function(CreateDrugTagRequest) _then;

/// Create a copy of CreateDrugTagRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? color = freezed,Object? tagCategory = freezed,Object? sortOrder = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,tagCategory: freezed == tagCategory ? _self.tagCategory : tagCategory // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CreateDrugTagRequest implements CreateDrugTagRequest {
  const _CreateDrugTagRequest({required this.name, this.description, this.color, @JsonKey(name: 'tag_category') this.tagCategory, @JsonKey(name: 'sort_order') this.sortOrder, this.status});
  factory _CreateDrugTagRequest.fromJson(Map<String, dynamic> json) => _$CreateDrugTagRequestFromJson(json);

@override final  String name;
@override final  String? description;
@override final  String? color;
@override@JsonKey(name: 'tag_category') final  String? tagCategory;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;
@override final  Status? status;

/// Create a copy of CreateDrugTagRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateDrugTagRequestCopyWith<_CreateDrugTagRequest> get copyWith => __$CreateDrugTagRequestCopyWithImpl<_CreateDrugTagRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateDrugTagRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateDrugTagRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.tagCategory, tagCategory) || other.tagCategory == tagCategory)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,color,tagCategory,sortOrder,status);

@override
String toString() {
  return 'CreateDrugTagRequest(name: $name, description: $description, color: $color, tagCategory: $tagCategory, sortOrder: $sortOrder, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CreateDrugTagRequestCopyWith<$Res> implements $CreateDrugTagRequestCopyWith<$Res> {
  factory _$CreateDrugTagRequestCopyWith(_CreateDrugTagRequest value, $Res Function(_CreateDrugTagRequest) _then) = __$CreateDrugTagRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description, String? color,@JsonKey(name: 'tag_category') String? tagCategory,@JsonKey(name: 'sort_order') int? sortOrder, Status? status
});




}
/// @nodoc
class __$CreateDrugTagRequestCopyWithImpl<$Res>
    implements _$CreateDrugTagRequestCopyWith<$Res> {
  __$CreateDrugTagRequestCopyWithImpl(this._self, this._then);

  final _CreateDrugTagRequest _self;
  final $Res Function(_CreateDrugTagRequest) _then;

/// Create a copy of CreateDrugTagRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? color = freezed,Object? tagCategory = freezed,Object? sortOrder = freezed,Object? status = freezed,}) {
  return _then(_CreateDrugTagRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,tagCategory: freezed == tagCategory ? _self.tagCategory : tagCategory // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,
  ));
}


}

// dart format on

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guideline_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuidelineTag {

 String get id; String get name; String get description;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of GuidelineTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineTagCopyWith<GuidelineTag> get copyWith => _$GuidelineTagCopyWithImpl<GuidelineTag>(this as GuidelineTag, _$identity);

  /// Serializes this GuidelineTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineTag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineTag(id: $id, name: $name, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GuidelineTagCopyWith<$Res>  {
  factory $GuidelineTagCopyWith(GuidelineTag value, $Res Function(GuidelineTag) _then) = _$GuidelineTagCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$GuidelineTagCopyWithImpl<$Res>
    implements $GuidelineTagCopyWith<$Res> {
  _$GuidelineTagCopyWithImpl(this._self, this._then);

  final GuidelineTag _self;
  final $Res Function(GuidelineTag) _then;

/// Create a copy of GuidelineTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineTag extends GuidelineTag {
  const _GuidelineTag({required this.id, this.name = '', this.description = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _GuidelineTag.fromJson(Map<String, dynamic> json) => _$GuidelineTagFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of GuidelineTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineTagCopyWith<_GuidelineTag> get copyWith => __$GuidelineTagCopyWithImpl<_GuidelineTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineTagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineTag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,createdAt,updatedAt);

@override
String toString() {
  return 'GuidelineTag(id: $id, name: $name, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GuidelineTagCopyWith<$Res> implements $GuidelineTagCopyWith<$Res> {
  factory _$GuidelineTagCopyWith(_GuidelineTag value, $Res Function(_GuidelineTag) _then) = __$GuidelineTagCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$GuidelineTagCopyWithImpl<$Res>
    implements _$GuidelineTagCopyWith<$Res> {
  __$GuidelineTagCopyWithImpl(this._self, this._then);

  final _GuidelineTag _self;
  final $Res Function(_GuidelineTag) _then;

/// Create a copy of GuidelineTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_GuidelineTag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateGuidelineTagRequest {

 String get name; String? get description;
/// Create a copy of CreateGuidelineTagRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateGuidelineTagRequestCopyWith<CreateGuidelineTagRequest> get copyWith => _$CreateGuidelineTagRequestCopyWithImpl<CreateGuidelineTagRequest>(this as CreateGuidelineTagRequest, _$identity);

  /// Serializes this CreateGuidelineTagRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateGuidelineTagRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'CreateGuidelineTagRequest(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $CreateGuidelineTagRequestCopyWith<$Res>  {
  factory $CreateGuidelineTagRequestCopyWith(CreateGuidelineTagRequest value, $Res Function(CreateGuidelineTagRequest) _then) = _$CreateGuidelineTagRequestCopyWithImpl;
@useResult
$Res call({
 String name, String? description
});




}
/// @nodoc
class _$CreateGuidelineTagRequestCopyWithImpl<$Res>
    implements $CreateGuidelineTagRequestCopyWith<$Res> {
  _$CreateGuidelineTagRequestCopyWithImpl(this._self, this._then);

  final CreateGuidelineTagRequest _self;
  final $Res Function(CreateGuidelineTagRequest) _then;

/// Create a copy of CreateGuidelineTagRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CreateGuidelineTagRequest implements CreateGuidelineTagRequest {
  const _CreateGuidelineTagRequest({required this.name, this.description});
  factory _CreateGuidelineTagRequest.fromJson(Map<String, dynamic> json) => _$CreateGuidelineTagRequestFromJson(json);

@override final  String name;
@override final  String? description;

/// Create a copy of CreateGuidelineTagRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateGuidelineTagRequestCopyWith<_CreateGuidelineTagRequest> get copyWith => __$CreateGuidelineTagRequestCopyWithImpl<_CreateGuidelineTagRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateGuidelineTagRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateGuidelineTagRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'CreateGuidelineTagRequest(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$CreateGuidelineTagRequestCopyWith<$Res> implements $CreateGuidelineTagRequestCopyWith<$Res> {
  factory _$CreateGuidelineTagRequestCopyWith(_CreateGuidelineTagRequest value, $Res Function(_CreateGuidelineTagRequest) _then) = __$CreateGuidelineTagRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description
});




}
/// @nodoc
class __$CreateGuidelineTagRequestCopyWithImpl<$Res>
    implements _$CreateGuidelineTagRequestCopyWith<$Res> {
  __$CreateGuidelineTagRequestCopyWithImpl(this._self, this._then);

  final _CreateGuidelineTagRequest _self;
  final $Res Function(_CreateGuidelineTagRequest) _then;

/// Create a copy of CreateGuidelineTagRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,}) {
  return _then(_CreateGuidelineTagRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

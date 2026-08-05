// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Settings {

 String get id; String get key; Object? get value; String get category; String get description;@JsonKey(name: 'is_public') bool get isPublic;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsCopyWith<Settings> get copyWith => _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settings&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,const DeepCollectionEquality().hash(value),category,description,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'Settings(id: $id, key: $key, value: $value, category: $category, description: $description, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res>  {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) = _$SettingsCopyWithImpl;
@useResult
$Res call({
 String id, String key, Object? value, String category, String description,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$SettingsCopyWithImpl<$Res>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? value = freezed,Object? category = null,Object? description = null,Object? isPublic = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Settings extends Settings {
  const _Settings({required this.id, required this.key, this.value, this.category = '', this.description = '', @JsonKey(name: 'is_public') this.isPublic = false, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

@override final  String id;
@override final  String key;
@override final  Object? value;
@override@JsonKey() final  String category;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'is_public') final  bool isPublic;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsCopyWith<_Settings> get copyWith => __$SettingsCopyWithImpl<_Settings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settings&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,const DeepCollectionEquality().hash(value),category,description,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'Settings(id: $id, key: $key, value: $value, category: $category, description: $description, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res> implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) = __$SettingsCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, Object? value, String category, String description,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$SettingsCopyWithImpl<$Res>
    implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? value = freezed,Object? category = null,Object? description = null,Object? isPublic = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Settings(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SettingsRequest {

 String? get key; Object? get value; String? get category; String? get description;@JsonKey(name: 'is_public') bool? get isPublic;
/// Create a copy of SettingsRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsRequestCopyWith<SettingsRequest> get copyWith => _$SettingsRequestCopyWithImpl<SettingsRequest>(this as SettingsRequest, _$identity);

  /// Serializes this SettingsRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsRequest&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(value),category,description,isPublic);

@override
String toString() {
  return 'SettingsRequest(key: $key, value: $value, category: $category, description: $description, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class $SettingsRequestCopyWith<$Res>  {
  factory $SettingsRequestCopyWith(SettingsRequest value, $Res Function(SettingsRequest) _then) = _$SettingsRequestCopyWithImpl;
@useResult
$Res call({
 String? key, Object? value, String? category, String? description,@JsonKey(name: 'is_public') bool? isPublic
});




}
/// @nodoc
class _$SettingsRequestCopyWithImpl<$Res>
    implements $SettingsRequestCopyWith<$Res> {
  _$SettingsRequestCopyWithImpl(this._self, this._then);

  final SettingsRequest _self;
  final $Res Function(SettingsRequest) _then;

/// Create a copy of SettingsRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = freezed,Object? value = freezed,Object? category = freezed,Object? description = freezed,Object? isPublic = freezed,}) {
  return _then(_self.copyWith(
key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,value: freezed == value ? _self.value : value ,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isPublic: freezed == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _SettingsRequest implements SettingsRequest {
  const _SettingsRequest({this.key, this.value, this.category, this.description, @JsonKey(name: 'is_public') this.isPublic});
  factory _SettingsRequest.fromJson(Map<String, dynamic> json) => _$SettingsRequestFromJson(json);

@override final  String? key;
@override final  Object? value;
@override final  String? category;
@override final  String? description;
@override@JsonKey(name: 'is_public') final  bool? isPublic;

/// Create a copy of SettingsRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsRequestCopyWith<_SettingsRequest> get copyWith => __$SettingsRequestCopyWithImpl<_SettingsRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsRequest&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(value),category,description,isPublic);

@override
String toString() {
  return 'SettingsRequest(key: $key, value: $value, category: $category, description: $description, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class _$SettingsRequestCopyWith<$Res> implements $SettingsRequestCopyWith<$Res> {
  factory _$SettingsRequestCopyWith(_SettingsRequest value, $Res Function(_SettingsRequest) _then) = __$SettingsRequestCopyWithImpl;
@override @useResult
$Res call({
 String? key, Object? value, String? category, String? description,@JsonKey(name: 'is_public') bool? isPublic
});




}
/// @nodoc
class __$SettingsRequestCopyWithImpl<$Res>
    implements _$SettingsRequestCopyWith<$Res> {
  __$SettingsRequestCopyWithImpl(this._self, this._then);

  final _SettingsRequest _self;
  final $Res Function(_SettingsRequest) _then;

/// Create a copy of SettingsRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = freezed,Object? value = freezed,Object? category = freezed,Object? description = freezed,Object? isPublic = freezed,}) {
  return _then(_SettingsRequest(
key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,value: freezed == value ? _self.value : value ,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isPublic: freezed == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

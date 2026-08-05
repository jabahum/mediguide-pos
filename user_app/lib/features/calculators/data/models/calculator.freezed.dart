// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calculator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Calculator {

 String get id; String get name; String get description; String get icon; String get color;@JsonKey(name: 'background_color') String get backgroundColor;@JsonKey(name: 'app_file') String get appFile; String get version;@JsonKey(name: 'added_by_user_id') String? get addedByUserId;@JsonKey(name: 'type') String get typeValue;@JsonKey(name: 'status') String get statusValue;@JsonKey(name: 'usage_count') int get usageCount; bool get featured;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Calculator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalculatorCopyWith<Calculator> get copyWith => _$CalculatorCopyWithImpl<Calculator>(this as Calculator, _$identity);

  /// Serializes this Calculator to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Calculator&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.appFile, appFile) || other.appFile == appFile)&&(identical(other.version, version) || other.version == version)&&(identical(other.addedByUserId, addedByUserId) || other.addedByUserId == addedByUserId)&&(identical(other.typeValue, typeValue) || other.typeValue == typeValue)&&(identical(other.statusValue, statusValue) || other.statusValue == statusValue)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.featured, featured) || other.featured == featured)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,color,backgroundColor,appFile,version,addedByUserId,typeValue,statusValue,usageCount,featured,createdAt,updatedAt);

@override
String toString() {
  return 'Calculator(id: $id, name: $name, description: $description, icon: $icon, color: $color, backgroundColor: $backgroundColor, appFile: $appFile, version: $version, addedByUserId: $addedByUserId, typeValue: $typeValue, statusValue: $statusValue, usageCount: $usageCount, featured: $featured, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CalculatorCopyWith<$Res>  {
  factory $CalculatorCopyWith(Calculator value, $Res Function(Calculator) _then) = _$CalculatorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String icon, String color,@JsonKey(name: 'background_color') String backgroundColor,@JsonKey(name: 'app_file') String appFile, String version,@JsonKey(name: 'added_by_user_id') String? addedByUserId,@JsonKey(name: 'type') String typeValue,@JsonKey(name: 'status') String statusValue,@JsonKey(name: 'usage_count') int usageCount, bool featured,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$CalculatorCopyWithImpl<$Res>
    implements $CalculatorCopyWith<$Res> {
  _$CalculatorCopyWithImpl(this._self, this._then);

  final Calculator _self;
  final $Res Function(Calculator) _then;

/// Create a copy of Calculator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? backgroundColor = null,Object? appFile = null,Object? version = null,Object? addedByUserId = freezed,Object? typeValue = null,Object? statusValue = null,Object? usageCount = null,Object? featured = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,appFile: null == appFile ? _self.appFile : appFile // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,addedByUserId: freezed == addedByUserId ? _self.addedByUserId : addedByUserId // ignore: cast_nullable_to_non_nullable
as String?,typeValue: null == typeValue ? _self.typeValue : typeValue // ignore: cast_nullable_to_non_nullable
as String,statusValue: null == statusValue ? _self.statusValue : statusValue // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,featured: null == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Calculator extends Calculator {
  const _Calculator({required this.id, this.name = '', this.description = '', this.icon = '', this.color = '', @JsonKey(name: 'background_color') this.backgroundColor = '', @JsonKey(name: 'app_file') this.appFile = '', this.version = '', @JsonKey(name: 'added_by_user_id') this.addedByUserId, @JsonKey(name: 'type') this.typeValue = 'calculator', @JsonKey(name: 'status') this.statusValue = 'draft', @JsonKey(name: 'usage_count') this.usageCount = 0, this.featured = false, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _Calculator.fromJson(Map<String, dynamic> json) => _$CalculatorFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey(name: 'background_color') final  String backgroundColor;
@override@JsonKey(name: 'app_file') final  String appFile;
@override@JsonKey() final  String version;
@override@JsonKey(name: 'added_by_user_id') final  String? addedByUserId;
@override@JsonKey(name: 'type') final  String typeValue;
@override@JsonKey(name: 'status') final  String statusValue;
@override@JsonKey(name: 'usage_count') final  int usageCount;
@override@JsonKey() final  bool featured;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Calculator
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalculatorCopyWith<_Calculator> get copyWith => __$CalculatorCopyWithImpl<_Calculator>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalculatorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Calculator&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.appFile, appFile) || other.appFile == appFile)&&(identical(other.version, version) || other.version == version)&&(identical(other.addedByUserId, addedByUserId) || other.addedByUserId == addedByUserId)&&(identical(other.typeValue, typeValue) || other.typeValue == typeValue)&&(identical(other.statusValue, statusValue) || other.statusValue == statusValue)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.featured, featured) || other.featured == featured)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,color,backgroundColor,appFile,version,addedByUserId,typeValue,statusValue,usageCount,featured,createdAt,updatedAt);

@override
String toString() {
  return 'Calculator(id: $id, name: $name, description: $description, icon: $icon, color: $color, backgroundColor: $backgroundColor, appFile: $appFile, version: $version, addedByUserId: $addedByUserId, typeValue: $typeValue, statusValue: $statusValue, usageCount: $usageCount, featured: $featured, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CalculatorCopyWith<$Res> implements $CalculatorCopyWith<$Res> {
  factory _$CalculatorCopyWith(_Calculator value, $Res Function(_Calculator) _then) = __$CalculatorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String icon, String color,@JsonKey(name: 'background_color') String backgroundColor,@JsonKey(name: 'app_file') String appFile, String version,@JsonKey(name: 'added_by_user_id') String? addedByUserId,@JsonKey(name: 'type') String typeValue,@JsonKey(name: 'status') String statusValue,@JsonKey(name: 'usage_count') int usageCount, bool featured,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$CalculatorCopyWithImpl<$Res>
    implements _$CalculatorCopyWith<$Res> {
  __$CalculatorCopyWithImpl(this._self, this._then);

  final _Calculator _self;
  final $Res Function(_Calculator) _then;

/// Create a copy of Calculator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? backgroundColor = null,Object? appFile = null,Object? version = null,Object? addedByUserId = freezed,Object? typeValue = null,Object? statusValue = null,Object? usageCount = null,Object? featured = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Calculator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,appFile: null == appFile ? _self.appFile : appFile // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,addedByUserId: freezed == addedByUserId ? _self.addedByUserId : addedByUserId // ignore: cast_nullable_to_non_nullable
as String?,typeValue: null == typeValue ? _self.typeValue : typeValue // ignore: cast_nullable_to_non_nullable
as String,statusValue: null == statusValue ? _self.statusValue : statusValue // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,featured: null == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CalculatorRequest {

 String? get name; String? get description; String? get icon; String? get color;@JsonKey(name: 'background_color') String? get backgroundColor;@JsonKey(name: 'app_file') Map<String, dynamic>? get appFile; String? get version;@JsonKey(name: 'added_by_user_id') String? get addedByUserId; String? get type; String? get status; bool? get featured;
/// Create a copy of CalculatorRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalculatorRequestCopyWith<CalculatorRequest> get copyWith => _$CalculatorRequestCopyWithImpl<CalculatorRequest>(this as CalculatorRequest, _$identity);

  /// Serializes this CalculatorRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalculatorRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&const DeepCollectionEquality().equals(other.appFile, appFile)&&(identical(other.version, version) || other.version == version)&&(identical(other.addedByUserId, addedByUserId) || other.addedByUserId == addedByUserId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.featured, featured) || other.featured == featured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,icon,color,backgroundColor,const DeepCollectionEquality().hash(appFile),version,addedByUserId,type,status,featured);

@override
String toString() {
  return 'CalculatorRequest(name: $name, description: $description, icon: $icon, color: $color, backgroundColor: $backgroundColor, appFile: $appFile, version: $version, addedByUserId: $addedByUserId, type: $type, status: $status, featured: $featured)';
}


}

/// @nodoc
abstract mixin class $CalculatorRequestCopyWith<$Res>  {
  factory $CalculatorRequestCopyWith(CalculatorRequest value, $Res Function(CalculatorRequest) _then) = _$CalculatorRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? description, String? icon, String? color,@JsonKey(name: 'background_color') String? backgroundColor,@JsonKey(name: 'app_file') Map<String, dynamic>? appFile, String? version,@JsonKey(name: 'added_by_user_id') String? addedByUserId, String? type, String? status, bool? featured
});




}
/// @nodoc
class _$CalculatorRequestCopyWithImpl<$Res>
    implements $CalculatorRequestCopyWith<$Res> {
  _$CalculatorRequestCopyWithImpl(this._self, this._then);

  final CalculatorRequest _self;
  final $Res Function(CalculatorRequest) _then;

/// Create a copy of CalculatorRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? description = freezed,Object? icon = freezed,Object? color = freezed,Object? backgroundColor = freezed,Object? appFile = freezed,Object? version = freezed,Object? addedByUserId = freezed,Object? type = freezed,Object? status = freezed,Object? featured = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,appFile: freezed == appFile ? _self.appFile : appFile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,addedByUserId: freezed == addedByUserId ? _self.addedByUserId : addedByUserId // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,featured: freezed == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CalculatorRequest implements CalculatorRequest {
  const _CalculatorRequest({this.name, this.description, this.icon, this.color, @JsonKey(name: 'background_color') this.backgroundColor, @JsonKey(name: 'app_file') final  Map<String, dynamic>? appFile, this.version, @JsonKey(name: 'added_by_user_id') this.addedByUserId, this.type, this.status, this.featured}): _appFile = appFile;
  factory _CalculatorRequest.fromJson(Map<String, dynamic> json) => _$CalculatorRequestFromJson(json);

@override final  String? name;
@override final  String? description;
@override final  String? icon;
@override final  String? color;
@override@JsonKey(name: 'background_color') final  String? backgroundColor;
 final  Map<String, dynamic>? _appFile;
@override@JsonKey(name: 'app_file') Map<String, dynamic>? get appFile {
  final value = _appFile;
  if (value == null) return null;
  if (_appFile is EqualUnmodifiableMapView) return _appFile;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? version;
@override@JsonKey(name: 'added_by_user_id') final  String? addedByUserId;
@override final  String? type;
@override final  String? status;
@override final  bool? featured;

/// Create a copy of CalculatorRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalculatorRequestCopyWith<_CalculatorRequest> get copyWith => __$CalculatorRequestCopyWithImpl<_CalculatorRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalculatorRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalculatorRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&const DeepCollectionEquality().equals(other._appFile, _appFile)&&(identical(other.version, version) || other.version == version)&&(identical(other.addedByUserId, addedByUserId) || other.addedByUserId == addedByUserId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.featured, featured) || other.featured == featured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,icon,color,backgroundColor,const DeepCollectionEquality().hash(_appFile),version,addedByUserId,type,status,featured);

@override
String toString() {
  return 'CalculatorRequest(name: $name, description: $description, icon: $icon, color: $color, backgroundColor: $backgroundColor, appFile: $appFile, version: $version, addedByUserId: $addedByUserId, type: $type, status: $status, featured: $featured)';
}


}

/// @nodoc
abstract mixin class _$CalculatorRequestCopyWith<$Res> implements $CalculatorRequestCopyWith<$Res> {
  factory _$CalculatorRequestCopyWith(_CalculatorRequest value, $Res Function(_CalculatorRequest) _then) = __$CalculatorRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? description, String? icon, String? color,@JsonKey(name: 'background_color') String? backgroundColor,@JsonKey(name: 'app_file') Map<String, dynamic>? appFile, String? version,@JsonKey(name: 'added_by_user_id') String? addedByUserId, String? type, String? status, bool? featured
});




}
/// @nodoc
class __$CalculatorRequestCopyWithImpl<$Res>
    implements _$CalculatorRequestCopyWith<$Res> {
  __$CalculatorRequestCopyWithImpl(this._self, this._then);

  final _CalculatorRequest _self;
  final $Res Function(_CalculatorRequest) _then;

/// Create a copy of CalculatorRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? description = freezed,Object? icon = freezed,Object? color = freezed,Object? backgroundColor = freezed,Object? appFile = freezed,Object? version = freezed,Object? addedByUserId = freezed,Object? type = freezed,Object? status = freezed,Object? featured = freezed,}) {
  return _then(_CalculatorRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String?,appFile: freezed == appFile ? _self._appFile : appFile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,addedByUserId: freezed == addedByUserId ? _self.addedByUserId : addedByUserId // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,featured: freezed == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

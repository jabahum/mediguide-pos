// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'language_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LanguageModel {

 String get id; String get code; String get name;@JsonKey(name: 'native_name') String get nativeName;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'is_default') bool get isDefault;@JsonKey(name: 'translations_url') String get translationsUrl; Map<String, dynamic> get translations; double get version;@NullableDateTimeConverter() DateTime? get created;@NullableDateTimeConverter() DateTime? get updated;
/// Create a copy of LanguageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguageModelCopyWith<LanguageModel> get copyWith => _$LanguageModelCopyWithImpl<LanguageModel>(this as LanguageModel, _$identity);

  /// Serializes this LanguageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanguageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nativeName, nativeName) || other.nativeName == nativeName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.translationsUrl, translationsUrl) || other.translationsUrl == translationsUrl)&&const DeepCollectionEquality().equals(other.translations, translations)&&(identical(other.version, version) || other.version == version)&&(identical(other.created, created) || other.created == created)&&(identical(other.updated, updated) || other.updated == updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,nativeName,isActive,isDefault,translationsUrl,const DeepCollectionEquality().hash(translations),version,created,updated);

@override
String toString() {
  return 'LanguageModel(id: $id, code: $code, name: $name, nativeName: $nativeName, isActive: $isActive, isDefault: $isDefault, translationsUrl: $translationsUrl, translations: $translations, version: $version, created: $created, updated: $updated)';
}


}

/// @nodoc
abstract mixin class $LanguageModelCopyWith<$Res>  {
  factory $LanguageModelCopyWith(LanguageModel value, $Res Function(LanguageModel) _then) = _$LanguageModelCopyWithImpl;
@useResult
$Res call({
 String id, String code, String name,@JsonKey(name: 'native_name') String nativeName,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_default') bool isDefault,@JsonKey(name: 'translations_url') String translationsUrl, Map<String, dynamic> translations, double version,@NullableDateTimeConverter() DateTime? created,@NullableDateTimeConverter() DateTime? updated
});




}
/// @nodoc
class _$LanguageModelCopyWithImpl<$Res>
    implements $LanguageModelCopyWith<$Res> {
  _$LanguageModelCopyWithImpl(this._self, this._then);

  final LanguageModel _self;
  final $Res Function(LanguageModel) _then;

/// Create a copy of LanguageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? nativeName = null,Object? isActive = null,Object? isDefault = null,Object? translationsUrl = null,Object? translations = null,Object? version = null,Object? created = freezed,Object? updated = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nativeName: null == nativeName ? _self.nativeName : nativeName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,translationsUrl: null == translationsUrl ? _self.translationsUrl : translationsUrl // ignore: cast_nullable_to_non_nullable
as String,translations: null == translations ? _self.translations : translations // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as double,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,updated: freezed == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _LanguageModel extends LanguageModel {
  const _LanguageModel({required this.id, required this.code, required this.name, @JsonKey(name: 'native_name') this.nativeName = '', @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'is_default') this.isDefault = false, @JsonKey(name: 'translations_url') this.translationsUrl = '', final  Map<String, dynamic> translations = const {}, this.version = 1, @NullableDateTimeConverter() this.created, @NullableDateTimeConverter() this.updated}): _translations = translations,super._();
  factory _LanguageModel.fromJson(Map<String, dynamic> json) => _$LanguageModelFromJson(json);

@override final  String id;
@override final  String code;
@override final  String name;
@override@JsonKey(name: 'native_name') final  String nativeName;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'is_default') final  bool isDefault;
@override@JsonKey(name: 'translations_url') final  String translationsUrl;
 final  Map<String, dynamic> _translations;
@override@JsonKey() Map<String, dynamic> get translations {
  if (_translations is EqualUnmodifiableMapView) return _translations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_translations);
}

@override@JsonKey() final  double version;
@override@NullableDateTimeConverter() final  DateTime? created;
@override@NullableDateTimeConverter() final  DateTime? updated;

/// Create a copy of LanguageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanguageModelCopyWith<_LanguageModel> get copyWith => __$LanguageModelCopyWithImpl<_LanguageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LanguageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanguageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nativeName, nativeName) || other.nativeName == nativeName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.translationsUrl, translationsUrl) || other.translationsUrl == translationsUrl)&&const DeepCollectionEquality().equals(other._translations, _translations)&&(identical(other.version, version) || other.version == version)&&(identical(other.created, created) || other.created == created)&&(identical(other.updated, updated) || other.updated == updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,nativeName,isActive,isDefault,translationsUrl,const DeepCollectionEquality().hash(_translations),version,created,updated);

@override
String toString() {
  return 'LanguageModel(id: $id, code: $code, name: $name, nativeName: $nativeName, isActive: $isActive, isDefault: $isDefault, translationsUrl: $translationsUrl, translations: $translations, version: $version, created: $created, updated: $updated)';
}


}

/// @nodoc
abstract mixin class _$LanguageModelCopyWith<$Res> implements $LanguageModelCopyWith<$Res> {
  factory _$LanguageModelCopyWith(_LanguageModel value, $Res Function(_LanguageModel) _then) = __$LanguageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String name,@JsonKey(name: 'native_name') String nativeName,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_default') bool isDefault,@JsonKey(name: 'translations_url') String translationsUrl, Map<String, dynamic> translations, double version,@NullableDateTimeConverter() DateTime? created,@NullableDateTimeConverter() DateTime? updated
});




}
/// @nodoc
class __$LanguageModelCopyWithImpl<$Res>
    implements _$LanguageModelCopyWith<$Res> {
  __$LanguageModelCopyWithImpl(this._self, this._then);

  final _LanguageModel _self;
  final $Res Function(_LanguageModel) _then;

/// Create a copy of LanguageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? nativeName = null,Object? isActive = null,Object? isDefault = null,Object? translationsUrl = null,Object? translations = null,Object? version = null,Object? created = freezed,Object? updated = freezed,}) {
  return _then(_LanguageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nativeName: null == nativeName ? _self.nativeName : nativeName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,translationsUrl: null == translationsUrl ? _self.translationsUrl : translationsUrl // ignore: cast_nullable_to_non_nullable
as String,translations: null == translations ? _self._translations : translations // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as double,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,updated: freezed == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'abbreviation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Abbreviation {

 String get id; String get abbreviation; String get meaning; String get description;@JsonKey(name: 'common_usage') bool get commonUsage;@JsonKey(name: 'category_id') String get categoryId; GuidelineCategory? get category; List<GuidelineTag> get tags;@JsonKey(name: 'usage_count') int get usageCount;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Abbreviation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AbbreviationCopyWith<Abbreviation> get copyWith => _$AbbreviationCopyWithImpl<Abbreviation>(this as Abbreviation, _$identity);

  /// Serializes this Abbreviation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Abbreviation&&(identical(other.id, id) || other.id == id)&&(identical(other.abbreviation, abbreviation) || other.abbreviation == abbreviation)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.description, description) || other.description == description)&&(identical(other.commonUsage, commonUsage) || other.commonUsage == commonUsage)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,abbreviation,meaning,description,commonUsage,categoryId,category,const DeepCollectionEquality().hash(tags),usageCount,createdAt,updatedAt);

@override
String toString() {
  return 'Abbreviation(id: $id, abbreviation: $abbreviation, meaning: $meaning, description: $description, commonUsage: $commonUsage, categoryId: $categoryId, category: $category, tags: $tags, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AbbreviationCopyWith<$Res>  {
  factory $AbbreviationCopyWith(Abbreviation value, $Res Function(Abbreviation) _then) = _$AbbreviationCopyWithImpl;
@useResult
$Res call({
 String id, String abbreviation, String meaning, String description,@JsonKey(name: 'common_usage') bool commonUsage,@JsonKey(name: 'category_id') String categoryId, GuidelineCategory? category, List<GuidelineTag> tags,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


$GuidelineCategoryCopyWith<$Res>? get category;

}
/// @nodoc
class _$AbbreviationCopyWithImpl<$Res>
    implements $AbbreviationCopyWith<$Res> {
  _$AbbreviationCopyWithImpl(this._self, this._then);

  final Abbreviation _self;
  final $Res Function(Abbreviation) _then;

/// Create a copy of Abbreviation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? abbreviation = null,Object? meaning = null,Object? description = null,Object? commonUsage = null,Object? categoryId = null,Object? category = freezed,Object? tags = null,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,abbreviation: null == abbreviation ? _self.abbreviation : abbreviation // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,commonUsage: null == commonUsage ? _self.commonUsage : commonUsage // ignore: cast_nullable_to_non_nullable
as bool,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GuidelineCategory?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<GuidelineTag>,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Abbreviation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $GuidelineCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Abbreviation extends Abbreviation {
  const _Abbreviation({required this.id, this.abbreviation = '', this.meaning = '', this.description = '', @JsonKey(name: 'common_usage') this.commonUsage = false, @JsonKey(name: 'category_id') this.categoryId = '', this.category, final  List<GuidelineTag> tags = const [], @JsonKey(name: 'usage_count') this.usageCount = 0, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): _tags = tags,super._();
  factory _Abbreviation.fromJson(Map<String, dynamic> json) => _$AbbreviationFromJson(json);

@override final  String id;
@override@JsonKey() final  String abbreviation;
@override@JsonKey() final  String meaning;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'common_usage') final  bool commonUsage;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override final  GuidelineCategory? category;
 final  List<GuidelineTag> _tags;
@override@JsonKey() List<GuidelineTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: 'usage_count') final  int usageCount;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Abbreviation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AbbreviationCopyWith<_Abbreviation> get copyWith => __$AbbreviationCopyWithImpl<_Abbreviation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AbbreviationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Abbreviation&&(identical(other.id, id) || other.id == id)&&(identical(other.abbreviation, abbreviation) || other.abbreviation == abbreviation)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.description, description) || other.description == description)&&(identical(other.commonUsage, commonUsage) || other.commonUsage == commonUsage)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,abbreviation,meaning,description,commonUsage,categoryId,category,const DeepCollectionEquality().hash(_tags),usageCount,createdAt,updatedAt);

@override
String toString() {
  return 'Abbreviation(id: $id, abbreviation: $abbreviation, meaning: $meaning, description: $description, commonUsage: $commonUsage, categoryId: $categoryId, category: $category, tags: $tags, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AbbreviationCopyWith<$Res> implements $AbbreviationCopyWith<$Res> {
  factory _$AbbreviationCopyWith(_Abbreviation value, $Res Function(_Abbreviation) _then) = __$AbbreviationCopyWithImpl;
@override @useResult
$Res call({
 String id, String abbreviation, String meaning, String description,@JsonKey(name: 'common_usage') bool commonUsage,@JsonKey(name: 'category_id') String categoryId, GuidelineCategory? category, List<GuidelineTag> tags,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


@override $GuidelineCategoryCopyWith<$Res>? get category;

}
/// @nodoc
class __$AbbreviationCopyWithImpl<$Res>
    implements _$AbbreviationCopyWith<$Res> {
  __$AbbreviationCopyWithImpl(this._self, this._then);

  final _Abbreviation _self;
  final $Res Function(_Abbreviation) _then;

/// Create a copy of Abbreviation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? abbreviation = null,Object? meaning = null,Object? description = null,Object? commonUsage = null,Object? categoryId = null,Object? category = freezed,Object? tags = null,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Abbreviation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,abbreviation: null == abbreviation ? _self.abbreviation : abbreviation // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,commonUsage: null == commonUsage ? _self.commonUsage : commonUsage // ignore: cast_nullable_to_non_nullable
as bool,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GuidelineCategory?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<GuidelineTag>,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Abbreviation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $GuidelineCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$AbbreviationRequest {

 String? get abbreviation; String? get meaning; String? get description;@JsonKey(name: 'common_usage') bool? get commonUsage;@JsonKey(name: 'category_id') String? get categoryId;@JsonKey(name: 'tag_ids') List<String>? get tagIds;
/// Create a copy of AbbreviationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AbbreviationRequestCopyWith<AbbreviationRequest> get copyWith => _$AbbreviationRequestCopyWithImpl<AbbreviationRequest>(this as AbbreviationRequest, _$identity);

  /// Serializes this AbbreviationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AbbreviationRequest&&(identical(other.abbreviation, abbreviation) || other.abbreviation == abbreviation)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.description, description) || other.description == description)&&(identical(other.commonUsage, commonUsage) || other.commonUsage == commonUsage)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.tagIds, tagIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,abbreviation,meaning,description,commonUsage,categoryId,const DeepCollectionEquality().hash(tagIds));

@override
String toString() {
  return 'AbbreviationRequest(abbreviation: $abbreviation, meaning: $meaning, description: $description, commonUsage: $commonUsage, categoryId: $categoryId, tagIds: $tagIds)';
}


}

/// @nodoc
abstract mixin class $AbbreviationRequestCopyWith<$Res>  {
  factory $AbbreviationRequestCopyWith(AbbreviationRequest value, $Res Function(AbbreviationRequest) _then) = _$AbbreviationRequestCopyWithImpl;
@useResult
$Res call({
 String? abbreviation, String? meaning, String? description,@JsonKey(name: 'common_usage') bool? commonUsage,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'tag_ids') List<String>? tagIds
});




}
/// @nodoc
class _$AbbreviationRequestCopyWithImpl<$Res>
    implements $AbbreviationRequestCopyWith<$Res> {
  _$AbbreviationRequestCopyWithImpl(this._self, this._then);

  final AbbreviationRequest _self;
  final $Res Function(AbbreviationRequest) _then;

/// Create a copy of AbbreviationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? abbreviation = freezed,Object? meaning = freezed,Object? description = freezed,Object? commonUsage = freezed,Object? categoryId = freezed,Object? tagIds = freezed,}) {
  return _then(_self.copyWith(
abbreviation: freezed == abbreviation ? _self.abbreviation : abbreviation // ignore: cast_nullable_to_non_nullable
as String?,meaning: freezed == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,commonUsage: freezed == commonUsage ? _self.commonUsage : commonUsage // ignore: cast_nullable_to_non_nullable
as bool?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,tagIds: freezed == tagIds ? _self.tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _AbbreviationRequest implements AbbreviationRequest {
  const _AbbreviationRequest({this.abbreviation, this.meaning, this.description, @JsonKey(name: 'common_usage') this.commonUsage, @JsonKey(name: 'category_id') this.categoryId, @JsonKey(name: 'tag_ids') final  List<String>? tagIds}): _tagIds = tagIds;
  factory _AbbreviationRequest.fromJson(Map<String, dynamic> json) => _$AbbreviationRequestFromJson(json);

@override final  String? abbreviation;
@override final  String? meaning;
@override final  String? description;
@override@JsonKey(name: 'common_usage') final  bool? commonUsage;
@override@JsonKey(name: 'category_id') final  String? categoryId;
 final  List<String>? _tagIds;
@override@JsonKey(name: 'tag_ids') List<String>? get tagIds {
  final value = _tagIds;
  if (value == null) return null;
  if (_tagIds is EqualUnmodifiableListView) return _tagIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AbbreviationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AbbreviationRequestCopyWith<_AbbreviationRequest> get copyWith => __$AbbreviationRequestCopyWithImpl<_AbbreviationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AbbreviationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AbbreviationRequest&&(identical(other.abbreviation, abbreviation) || other.abbreviation == abbreviation)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.description, description) || other.description == description)&&(identical(other.commonUsage, commonUsage) || other.commonUsage == commonUsage)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other._tagIds, _tagIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,abbreviation,meaning,description,commonUsage,categoryId,const DeepCollectionEquality().hash(_tagIds));

@override
String toString() {
  return 'AbbreviationRequest(abbreviation: $abbreviation, meaning: $meaning, description: $description, commonUsage: $commonUsage, categoryId: $categoryId, tagIds: $tagIds)';
}


}

/// @nodoc
abstract mixin class _$AbbreviationRequestCopyWith<$Res> implements $AbbreviationRequestCopyWith<$Res> {
  factory _$AbbreviationRequestCopyWith(_AbbreviationRequest value, $Res Function(_AbbreviationRequest) _then) = __$AbbreviationRequestCopyWithImpl;
@override @useResult
$Res call({
 String? abbreviation, String? meaning, String? description,@JsonKey(name: 'common_usage') bool? commonUsage,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'tag_ids') List<String>? tagIds
});




}
/// @nodoc
class __$AbbreviationRequestCopyWithImpl<$Res>
    implements _$AbbreviationRequestCopyWith<$Res> {
  __$AbbreviationRequestCopyWithImpl(this._self, this._then);

  final _AbbreviationRequest _self;
  final $Res Function(_AbbreviationRequest) _then;

/// Create a copy of AbbreviationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? abbreviation = freezed,Object? meaning = freezed,Object? description = freezed,Object? commonUsage = freezed,Object? categoryId = freezed,Object? tagIds = freezed,}) {
  return _then(_AbbreviationRequest(
abbreviation: freezed == abbreviation ? _self.abbreviation : abbreviation // ignore: cast_nullable_to_non_nullable
as String?,meaning: freezed == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,commonUsage: freezed == commonUsage ? _self.commonUsage : commonUsage // ignore: cast_nullable_to_non_nullable
as bool?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,tagIds: freezed == tagIds ? _self._tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outbreak_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OutbreakMetric {

 String get key; String get label; String get value; String get unit;
/// Create a copy of OutbreakMetric
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutbreakMetricCopyWith<OutbreakMetric> get copyWith => _$OutbreakMetricCopyWithImpl<OutbreakMetric>(this as OutbreakMetric, _$identity);

  /// Serializes this OutbreakMetric to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutbreakMetric&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,value,unit);

@override
String toString() {
  return 'OutbreakMetric(key: $key, label: $label, value: $value, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $OutbreakMetricCopyWith<$Res>  {
  factory $OutbreakMetricCopyWith(OutbreakMetric value, $Res Function(OutbreakMetric) _then) = _$OutbreakMetricCopyWithImpl;
@useResult
$Res call({
 String key, String label, String value, String unit
});




}
/// @nodoc
class _$OutbreakMetricCopyWithImpl<$Res>
    implements $OutbreakMetricCopyWith<$Res> {
  _$OutbreakMetricCopyWithImpl(this._self, this._then);

  final OutbreakMetric _self;
  final $Res Function(OutbreakMetric) _then;

/// Create a copy of OutbreakMetric
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? value = null,Object? unit = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _OutbreakMetric implements OutbreakMetric {
  const _OutbreakMetric({this.key = '', this.label = '', this.value = '', this.unit = ''});
  factory _OutbreakMetric.fromJson(Map<String, dynamic> json) => _$OutbreakMetricFromJson(json);

@override@JsonKey() final  String key;
@override@JsonKey() final  String label;
@override@JsonKey() final  String value;
@override@JsonKey() final  String unit;

/// Create a copy of OutbreakMetric
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutbreakMetricCopyWith<_OutbreakMetric> get copyWith => __$OutbreakMetricCopyWithImpl<_OutbreakMetric>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutbreakMetricToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutbreakMetric&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,value,unit);

@override
String toString() {
  return 'OutbreakMetric(key: $key, label: $label, value: $value, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$OutbreakMetricCopyWith<$Res> implements $OutbreakMetricCopyWith<$Res> {
  factory _$OutbreakMetricCopyWith(_OutbreakMetric value, $Res Function(_OutbreakMetric) _then) = __$OutbreakMetricCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, String value, String unit
});




}
/// @nodoc
class __$OutbreakMetricCopyWithImpl<$Res>
    implements _$OutbreakMetricCopyWith<$Res> {
  __$OutbreakMetricCopyWithImpl(this._self, this._then);

  final _OutbreakMetric _self;
  final $Res Function(_OutbreakMetric) _then;

/// Create a copy of OutbreakMetric
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? value = null,Object? unit = null,}) {
  return _then(_OutbreakMetric(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PublicOutbreak {

 String get id; String get title;@JsonKey(name: 'disease_type') String get diseaseType; String get status;@JsonKey(name: 'geographic_area') String get geographicArea; String get summary;@JsonKey(name: 'start_date') DateTime? get startDate;@JsonKey(name: 'last_update') DateTime? get lastUpdate;@JsonKey(name: 'visual_tone') String get visualTone;@JsonKey(name: 'source_organization') String get sourceOrganization;@JsonKey(name: 'published_at') DateTime? get publishedAt; List<OutbreakMetric> get metrics;
/// Create a copy of PublicOutbreak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicOutbreakCopyWith<PublicOutbreak> get copyWith => _$PublicOutbreakCopyWithImpl<PublicOutbreak>(this as PublicOutbreak, _$identity);

  /// Serializes this PublicOutbreak to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicOutbreak&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.diseaseType, diseaseType) || other.diseaseType == diseaseType)&&(identical(other.status, status) || other.status == status)&&(identical(other.geographicArea, geographicArea) || other.geographicArea == geographicArea)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate)&&(identical(other.visualTone, visualTone) || other.visualTone == visualTone)&&(identical(other.sourceOrganization, sourceOrganization) || other.sourceOrganization == sourceOrganization)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other.metrics, metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,diseaseType,status,geographicArea,summary,startDate,lastUpdate,visualTone,sourceOrganization,publishedAt,const DeepCollectionEquality().hash(metrics));

@override
String toString() {
  return 'PublicOutbreak(id: $id, title: $title, diseaseType: $diseaseType, status: $status, geographicArea: $geographicArea, summary: $summary, startDate: $startDate, lastUpdate: $lastUpdate, visualTone: $visualTone, sourceOrganization: $sourceOrganization, publishedAt: $publishedAt, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class $PublicOutbreakCopyWith<$Res>  {
  factory $PublicOutbreakCopyWith(PublicOutbreak value, $Res Function(PublicOutbreak) _then) = _$PublicOutbreakCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(name: 'disease_type') String diseaseType, String status,@JsonKey(name: 'geographic_area') String geographicArea, String summary,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'last_update') DateTime? lastUpdate,@JsonKey(name: 'visual_tone') String visualTone,@JsonKey(name: 'source_organization') String sourceOrganization,@JsonKey(name: 'published_at') DateTime? publishedAt, List<OutbreakMetric> metrics
});




}
/// @nodoc
class _$PublicOutbreakCopyWithImpl<$Res>
    implements $PublicOutbreakCopyWith<$Res> {
  _$PublicOutbreakCopyWithImpl(this._self, this._then);

  final PublicOutbreak _self;
  final $Res Function(PublicOutbreak) _then;

/// Create a copy of PublicOutbreak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? diseaseType = null,Object? status = null,Object? geographicArea = null,Object? summary = null,Object? startDate = freezed,Object? lastUpdate = freezed,Object? visualTone = null,Object? sourceOrganization = null,Object? publishedAt = freezed,Object? metrics = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,diseaseType: null == diseaseType ? _self.diseaseType : diseaseType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,geographicArea: null == geographicArea ? _self.geographicArea : geographicArea // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUpdate: freezed == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,visualTone: null == visualTone ? _self.visualTone : visualTone // ignore: cast_nullable_to_non_nullable
as String,sourceOrganization: null == sourceOrganization ? _self.sourceOrganization : sourceOrganization // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as List<OutbreakMetric>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PublicOutbreak implements PublicOutbreak {
  const _PublicOutbreak({required this.id, this.title = '', @JsonKey(name: 'disease_type') this.diseaseType = '', this.status = '', @JsonKey(name: 'geographic_area') this.geographicArea = '', this.summary = '', @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'last_update') this.lastUpdate, @JsonKey(name: 'visual_tone') this.visualTone = 'warning', @JsonKey(name: 'source_organization') this.sourceOrganization = '', @JsonKey(name: 'published_at') this.publishedAt, final  List<OutbreakMetric> metrics = const <OutbreakMetric>[]}): _metrics = metrics;
  factory _PublicOutbreak.fromJson(Map<String, dynamic> json) => _$PublicOutbreakFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'disease_type') final  String diseaseType;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'geographic_area') final  String geographicArea;
@override@JsonKey() final  String summary;
@override@JsonKey(name: 'start_date') final  DateTime? startDate;
@override@JsonKey(name: 'last_update') final  DateTime? lastUpdate;
@override@JsonKey(name: 'visual_tone') final  String visualTone;
@override@JsonKey(name: 'source_organization') final  String sourceOrganization;
@override@JsonKey(name: 'published_at') final  DateTime? publishedAt;
 final  List<OutbreakMetric> _metrics;
@override@JsonKey() List<OutbreakMetric> get metrics {
  if (_metrics is EqualUnmodifiableListView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metrics);
}


/// Create a copy of PublicOutbreak
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicOutbreakCopyWith<_PublicOutbreak> get copyWith => __$PublicOutbreakCopyWithImpl<_PublicOutbreak>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicOutbreakToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicOutbreak&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.diseaseType, diseaseType) || other.diseaseType == diseaseType)&&(identical(other.status, status) || other.status == status)&&(identical(other.geographicArea, geographicArea) || other.geographicArea == geographicArea)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate)&&(identical(other.visualTone, visualTone) || other.visualTone == visualTone)&&(identical(other.sourceOrganization, sourceOrganization) || other.sourceOrganization == sourceOrganization)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other._metrics, _metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,diseaseType,status,geographicArea,summary,startDate,lastUpdate,visualTone,sourceOrganization,publishedAt,const DeepCollectionEquality().hash(_metrics));

@override
String toString() {
  return 'PublicOutbreak(id: $id, title: $title, diseaseType: $diseaseType, status: $status, geographicArea: $geographicArea, summary: $summary, startDate: $startDate, lastUpdate: $lastUpdate, visualTone: $visualTone, sourceOrganization: $sourceOrganization, publishedAt: $publishedAt, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class _$PublicOutbreakCopyWith<$Res> implements $PublicOutbreakCopyWith<$Res> {
  factory _$PublicOutbreakCopyWith(_PublicOutbreak value, $Res Function(_PublicOutbreak) _then) = __$PublicOutbreakCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(name: 'disease_type') String diseaseType, String status,@JsonKey(name: 'geographic_area') String geographicArea, String summary,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'last_update') DateTime? lastUpdate,@JsonKey(name: 'visual_tone') String visualTone,@JsonKey(name: 'source_organization') String sourceOrganization,@JsonKey(name: 'published_at') DateTime? publishedAt, List<OutbreakMetric> metrics
});




}
/// @nodoc
class __$PublicOutbreakCopyWithImpl<$Res>
    implements _$PublicOutbreakCopyWith<$Res> {
  __$PublicOutbreakCopyWithImpl(this._self, this._then);

  final _PublicOutbreak _self;
  final $Res Function(_PublicOutbreak) _then;

/// Create a copy of PublicOutbreak
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? diseaseType = null,Object? status = null,Object? geographicArea = null,Object? summary = null,Object? startDate = freezed,Object? lastUpdate = freezed,Object? visualTone = null,Object? sourceOrganization = null,Object? publishedAt = freezed,Object? metrics = null,}) {
  return _then(_PublicOutbreak(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,diseaseType: null == diseaseType ? _self.diseaseType : diseaseType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,geographicArea: null == geographicArea ? _self.geographicArea : geographicArea // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUpdate: freezed == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,visualTone: null == visualTone ? _self.visualTone : visualTone // ignore: cast_nullable_to_non_nullable
as String,sourceOrganization: null == sourceOrganization ? _self.sourceOrganization : sourceOrganization // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metrics: null == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as List<OutbreakMetric>,
  ));
}


}


/// @nodoc
mixin _$PublicOutbreakUpdate {

 String get id;@JsonKey(name: 'outbreak_id') String get outbreakId; String get title; String get summary;@JsonKey(name: 'published_at') DateTime? get publishedAt;
/// Create a copy of PublicOutbreakUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicOutbreakUpdateCopyWith<PublicOutbreakUpdate> get copyWith => _$PublicOutbreakUpdateCopyWithImpl<PublicOutbreakUpdate>(this as PublicOutbreakUpdate, _$identity);

  /// Serializes this PublicOutbreakUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicOutbreakUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.outbreakId, outbreakId) || other.outbreakId == outbreakId)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,outbreakId,title,summary,publishedAt);

@override
String toString() {
  return 'PublicOutbreakUpdate(id: $id, outbreakId: $outbreakId, title: $title, summary: $summary, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $PublicOutbreakUpdateCopyWith<$Res>  {
  factory $PublicOutbreakUpdateCopyWith(PublicOutbreakUpdate value, $Res Function(PublicOutbreakUpdate) _then) = _$PublicOutbreakUpdateCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'outbreak_id') String outbreakId, String title, String summary,@JsonKey(name: 'published_at') DateTime? publishedAt
});




}
/// @nodoc
class _$PublicOutbreakUpdateCopyWithImpl<$Res>
    implements $PublicOutbreakUpdateCopyWith<$Res> {
  _$PublicOutbreakUpdateCopyWithImpl(this._self, this._then);

  final PublicOutbreakUpdate _self;
  final $Res Function(PublicOutbreakUpdate) _then;

/// Create a copy of PublicOutbreakUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? outbreakId = null,Object? title = null,Object? summary = null,Object? publishedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,outbreakId: null == outbreakId ? _self.outbreakId : outbreakId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PublicOutbreakUpdate implements PublicOutbreakUpdate {
  const _PublicOutbreakUpdate({required this.id, @JsonKey(name: 'outbreak_id') required this.outbreakId, this.title = '', this.summary = '', @JsonKey(name: 'published_at') this.publishedAt});
  factory _PublicOutbreakUpdate.fromJson(Map<String, dynamic> json) => _$PublicOutbreakUpdateFromJson(json);

@override final  String id;
@override@JsonKey(name: 'outbreak_id') final  String outbreakId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String summary;
@override@JsonKey(name: 'published_at') final  DateTime? publishedAt;

/// Create a copy of PublicOutbreakUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicOutbreakUpdateCopyWith<_PublicOutbreakUpdate> get copyWith => __$PublicOutbreakUpdateCopyWithImpl<_PublicOutbreakUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicOutbreakUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicOutbreakUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.outbreakId, outbreakId) || other.outbreakId == outbreakId)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,outbreakId,title,summary,publishedAt);

@override
String toString() {
  return 'PublicOutbreakUpdate(id: $id, outbreakId: $outbreakId, title: $title, summary: $summary, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$PublicOutbreakUpdateCopyWith<$Res> implements $PublicOutbreakUpdateCopyWith<$Res> {
  factory _$PublicOutbreakUpdateCopyWith(_PublicOutbreakUpdate value, $Res Function(_PublicOutbreakUpdate) _then) = __$PublicOutbreakUpdateCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'outbreak_id') String outbreakId, String title, String summary,@JsonKey(name: 'published_at') DateTime? publishedAt
});




}
/// @nodoc
class __$PublicOutbreakUpdateCopyWithImpl<$Res>
    implements _$PublicOutbreakUpdateCopyWith<$Res> {
  __$PublicOutbreakUpdateCopyWithImpl(this._self, this._then);

  final _PublicOutbreakUpdate _self;
  final $Res Function(_PublicOutbreakUpdate) _then;

/// Create a copy of PublicOutbreakUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? outbreakId = null,Object? title = null,Object? summary = null,Object? publishedAt = freezed,}) {
  return _then(_PublicOutbreakUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,outbreakId: null == outbreakId ? _self.outbreakId : outbreakId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PublicOutbreakResource {

 String get id;@JsonKey(name: 'outbreak_id') String get outbreakId; String get title;@JsonKey(name: 'resource_type') String get resourceType; String get url;@JsonKey(name: 'asset_url') String get assetUrl;@JsonKey(name: 'sort_order') int get sortOrder;
/// Create a copy of PublicOutbreakResource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicOutbreakResourceCopyWith<PublicOutbreakResource> get copyWith => _$PublicOutbreakResourceCopyWithImpl<PublicOutbreakResource>(this as PublicOutbreakResource, _$identity);

  /// Serializes this PublicOutbreakResource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicOutbreakResource&&(identical(other.id, id) || other.id == id)&&(identical(other.outbreakId, outbreakId) || other.outbreakId == outbreakId)&&(identical(other.title, title) || other.title == title)&&(identical(other.resourceType, resourceType) || other.resourceType == resourceType)&&(identical(other.url, url) || other.url == url)&&(identical(other.assetUrl, assetUrl) || other.assetUrl == assetUrl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,outbreakId,title,resourceType,url,assetUrl,sortOrder);

@override
String toString() {
  return 'PublicOutbreakResource(id: $id, outbreakId: $outbreakId, title: $title, resourceType: $resourceType, url: $url, assetUrl: $assetUrl, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $PublicOutbreakResourceCopyWith<$Res>  {
  factory $PublicOutbreakResourceCopyWith(PublicOutbreakResource value, $Res Function(PublicOutbreakResource) _then) = _$PublicOutbreakResourceCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'outbreak_id') String outbreakId, String title,@JsonKey(name: 'resource_type') String resourceType, String url,@JsonKey(name: 'asset_url') String assetUrl,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class _$PublicOutbreakResourceCopyWithImpl<$Res>
    implements $PublicOutbreakResourceCopyWith<$Res> {
  _$PublicOutbreakResourceCopyWithImpl(this._self, this._then);

  final PublicOutbreakResource _self;
  final $Res Function(PublicOutbreakResource) _then;

/// Create a copy of PublicOutbreakResource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? outbreakId = null,Object? title = null,Object? resourceType = null,Object? url = null,Object? assetUrl = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,outbreakId: null == outbreakId ? _self.outbreakId : outbreakId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,resourceType: null == resourceType ? _self.resourceType : resourceType // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,assetUrl: null == assetUrl ? _self.assetUrl : assetUrl // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PublicOutbreakResource implements PublicOutbreakResource {
  const _PublicOutbreakResource({required this.id, @JsonKey(name: 'outbreak_id') required this.outbreakId, this.title = '', @JsonKey(name: 'resource_type') this.resourceType = 'link', this.url = '', @JsonKey(name: 'asset_url') this.assetUrl = '', @JsonKey(name: 'sort_order') this.sortOrder = 0});
  factory _PublicOutbreakResource.fromJson(Map<String, dynamic> json) => _$PublicOutbreakResourceFromJson(json);

@override final  String id;
@override@JsonKey(name: 'outbreak_id') final  String outbreakId;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'resource_type') final  String resourceType;
@override@JsonKey() final  String url;
@override@JsonKey(name: 'asset_url') final  String assetUrl;
@override@JsonKey(name: 'sort_order') final  int sortOrder;

/// Create a copy of PublicOutbreakResource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicOutbreakResourceCopyWith<_PublicOutbreakResource> get copyWith => __$PublicOutbreakResourceCopyWithImpl<_PublicOutbreakResource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicOutbreakResourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicOutbreakResource&&(identical(other.id, id) || other.id == id)&&(identical(other.outbreakId, outbreakId) || other.outbreakId == outbreakId)&&(identical(other.title, title) || other.title == title)&&(identical(other.resourceType, resourceType) || other.resourceType == resourceType)&&(identical(other.url, url) || other.url == url)&&(identical(other.assetUrl, assetUrl) || other.assetUrl == assetUrl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,outbreakId,title,resourceType,url,assetUrl,sortOrder);

@override
String toString() {
  return 'PublicOutbreakResource(id: $id, outbreakId: $outbreakId, title: $title, resourceType: $resourceType, url: $url, assetUrl: $assetUrl, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$PublicOutbreakResourceCopyWith<$Res> implements $PublicOutbreakResourceCopyWith<$Res> {
  factory _$PublicOutbreakResourceCopyWith(_PublicOutbreakResource value, $Res Function(_PublicOutbreakResource) _then) = __$PublicOutbreakResourceCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'outbreak_id') String outbreakId, String title,@JsonKey(name: 'resource_type') String resourceType, String url,@JsonKey(name: 'asset_url') String assetUrl,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class __$PublicOutbreakResourceCopyWithImpl<$Res>
    implements _$PublicOutbreakResourceCopyWith<$Res> {
  __$PublicOutbreakResourceCopyWithImpl(this._self, this._then);

  final _PublicOutbreakResource _self;
  final $Res Function(_PublicOutbreakResource) _then;

/// Create a copy of PublicOutbreakResource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? outbreakId = null,Object? title = null,Object? resourceType = null,Object? url = null,Object? assetUrl = null,Object? sortOrder = null,}) {
  return _then(_PublicOutbreakResource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,outbreakId: null == outbreakId ? _self.outbreakId : outbreakId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,resourceType: null == resourceType ? _self.resourceType : resourceType // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,assetUrl: null == assetUrl ? _self.assetUrl : assetUrl // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PublicSituationReport {

 String get id;@JsonKey(name: 'outbreak_id') String? get outbreakId; String get title;@JsonKey(name: 'geographic_area') String get geographicArea; String get summary;@JsonKey(name: 'source_organization') String get sourceOrganization;@JsonKey(name: 'publication_date') DateTime? get publicationDate; String get status;@JsonKey(name: 'report_asset_url') String get reportAssetUrl;@JsonKey(name: 'key_highlights') List<String> get keyHighlights; List<OutbreakMetric> get metrics;
/// Create a copy of PublicSituationReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicSituationReportCopyWith<PublicSituationReport> get copyWith => _$PublicSituationReportCopyWithImpl<PublicSituationReport>(this as PublicSituationReport, _$identity);

  /// Serializes this PublicSituationReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicSituationReport&&(identical(other.id, id) || other.id == id)&&(identical(other.outbreakId, outbreakId) || other.outbreakId == outbreakId)&&(identical(other.title, title) || other.title == title)&&(identical(other.geographicArea, geographicArea) || other.geographicArea == geographicArea)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.sourceOrganization, sourceOrganization) || other.sourceOrganization == sourceOrganization)&&(identical(other.publicationDate, publicationDate) || other.publicationDate == publicationDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.reportAssetUrl, reportAssetUrl) || other.reportAssetUrl == reportAssetUrl)&&const DeepCollectionEquality().equals(other.keyHighlights, keyHighlights)&&const DeepCollectionEquality().equals(other.metrics, metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,outbreakId,title,geographicArea,summary,sourceOrganization,publicationDate,status,reportAssetUrl,const DeepCollectionEquality().hash(keyHighlights),const DeepCollectionEquality().hash(metrics));

@override
String toString() {
  return 'PublicSituationReport(id: $id, outbreakId: $outbreakId, title: $title, geographicArea: $geographicArea, summary: $summary, sourceOrganization: $sourceOrganization, publicationDate: $publicationDate, status: $status, reportAssetUrl: $reportAssetUrl, keyHighlights: $keyHighlights, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class $PublicSituationReportCopyWith<$Res>  {
  factory $PublicSituationReportCopyWith(PublicSituationReport value, $Res Function(PublicSituationReport) _then) = _$PublicSituationReportCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'outbreak_id') String? outbreakId, String title,@JsonKey(name: 'geographic_area') String geographicArea, String summary,@JsonKey(name: 'source_organization') String sourceOrganization,@JsonKey(name: 'publication_date') DateTime? publicationDate, String status,@JsonKey(name: 'report_asset_url') String reportAssetUrl,@JsonKey(name: 'key_highlights') List<String> keyHighlights, List<OutbreakMetric> metrics
});




}
/// @nodoc
class _$PublicSituationReportCopyWithImpl<$Res>
    implements $PublicSituationReportCopyWith<$Res> {
  _$PublicSituationReportCopyWithImpl(this._self, this._then);

  final PublicSituationReport _self;
  final $Res Function(PublicSituationReport) _then;

/// Create a copy of PublicSituationReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? outbreakId = freezed,Object? title = null,Object? geographicArea = null,Object? summary = null,Object? sourceOrganization = null,Object? publicationDate = freezed,Object? status = null,Object? reportAssetUrl = null,Object? keyHighlights = null,Object? metrics = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,outbreakId: freezed == outbreakId ? _self.outbreakId : outbreakId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,geographicArea: null == geographicArea ? _self.geographicArea : geographicArea // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,sourceOrganization: null == sourceOrganization ? _self.sourceOrganization : sourceOrganization // ignore: cast_nullable_to_non_nullable
as String,publicationDate: freezed == publicationDate ? _self.publicationDate : publicationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reportAssetUrl: null == reportAssetUrl ? _self.reportAssetUrl : reportAssetUrl // ignore: cast_nullable_to_non_nullable
as String,keyHighlights: null == keyHighlights ? _self.keyHighlights : keyHighlights // ignore: cast_nullable_to_non_nullable
as List<String>,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as List<OutbreakMetric>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PublicSituationReport implements PublicSituationReport {
  const _PublicSituationReport({required this.id, @JsonKey(name: 'outbreak_id') this.outbreakId, this.title = '', @JsonKey(name: 'geographic_area') this.geographicArea = '', this.summary = '', @JsonKey(name: 'source_organization') this.sourceOrganization = '', @JsonKey(name: 'publication_date') this.publicationDate, this.status = 'published', @JsonKey(name: 'report_asset_url') this.reportAssetUrl = '', @JsonKey(name: 'key_highlights') final  List<String> keyHighlights = const <String>[], final  List<OutbreakMetric> metrics = const <OutbreakMetric>[]}): _keyHighlights = keyHighlights,_metrics = metrics;
  factory _PublicSituationReport.fromJson(Map<String, dynamic> json) => _$PublicSituationReportFromJson(json);

@override final  String id;
@override@JsonKey(name: 'outbreak_id') final  String? outbreakId;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'geographic_area') final  String geographicArea;
@override@JsonKey() final  String summary;
@override@JsonKey(name: 'source_organization') final  String sourceOrganization;
@override@JsonKey(name: 'publication_date') final  DateTime? publicationDate;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'report_asset_url') final  String reportAssetUrl;
 final  List<String> _keyHighlights;
@override@JsonKey(name: 'key_highlights') List<String> get keyHighlights {
  if (_keyHighlights is EqualUnmodifiableListView) return _keyHighlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyHighlights);
}

 final  List<OutbreakMetric> _metrics;
@override@JsonKey() List<OutbreakMetric> get metrics {
  if (_metrics is EqualUnmodifiableListView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metrics);
}


/// Create a copy of PublicSituationReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicSituationReportCopyWith<_PublicSituationReport> get copyWith => __$PublicSituationReportCopyWithImpl<_PublicSituationReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicSituationReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicSituationReport&&(identical(other.id, id) || other.id == id)&&(identical(other.outbreakId, outbreakId) || other.outbreakId == outbreakId)&&(identical(other.title, title) || other.title == title)&&(identical(other.geographicArea, geographicArea) || other.geographicArea == geographicArea)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.sourceOrganization, sourceOrganization) || other.sourceOrganization == sourceOrganization)&&(identical(other.publicationDate, publicationDate) || other.publicationDate == publicationDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.reportAssetUrl, reportAssetUrl) || other.reportAssetUrl == reportAssetUrl)&&const DeepCollectionEquality().equals(other._keyHighlights, _keyHighlights)&&const DeepCollectionEquality().equals(other._metrics, _metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,outbreakId,title,geographicArea,summary,sourceOrganization,publicationDate,status,reportAssetUrl,const DeepCollectionEquality().hash(_keyHighlights),const DeepCollectionEquality().hash(_metrics));

@override
String toString() {
  return 'PublicSituationReport(id: $id, outbreakId: $outbreakId, title: $title, geographicArea: $geographicArea, summary: $summary, sourceOrganization: $sourceOrganization, publicationDate: $publicationDate, status: $status, reportAssetUrl: $reportAssetUrl, keyHighlights: $keyHighlights, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class _$PublicSituationReportCopyWith<$Res> implements $PublicSituationReportCopyWith<$Res> {
  factory _$PublicSituationReportCopyWith(_PublicSituationReport value, $Res Function(_PublicSituationReport) _then) = __$PublicSituationReportCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'outbreak_id') String? outbreakId, String title,@JsonKey(name: 'geographic_area') String geographicArea, String summary,@JsonKey(name: 'source_organization') String sourceOrganization,@JsonKey(name: 'publication_date') DateTime? publicationDate, String status,@JsonKey(name: 'report_asset_url') String reportAssetUrl,@JsonKey(name: 'key_highlights') List<String> keyHighlights, List<OutbreakMetric> metrics
});




}
/// @nodoc
class __$PublicSituationReportCopyWithImpl<$Res>
    implements _$PublicSituationReportCopyWith<$Res> {
  __$PublicSituationReportCopyWithImpl(this._self, this._then);

  final _PublicSituationReport _self;
  final $Res Function(_PublicSituationReport) _then;

/// Create a copy of PublicSituationReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? outbreakId = freezed,Object? title = null,Object? geographicArea = null,Object? summary = null,Object? sourceOrganization = null,Object? publicationDate = freezed,Object? status = null,Object? reportAssetUrl = null,Object? keyHighlights = null,Object? metrics = null,}) {
  return _then(_PublicSituationReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,outbreakId: freezed == outbreakId ? _self.outbreakId : outbreakId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,geographicArea: null == geographicArea ? _self.geographicArea : geographicArea // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,sourceOrganization: null == sourceOrganization ? _self.sourceOrganization : sourceOrganization // ignore: cast_nullable_to_non_nullable
as String,publicationDate: freezed == publicationDate ? _self.publicationDate : publicationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reportAssetUrl: null == reportAssetUrl ? _self.reportAssetUrl : reportAssetUrl // ignore: cast_nullable_to_non_nullable
as String,keyHighlights: null == keyHighlights ? _self._keyHighlights : keyHighlights // ignore: cast_nullable_to_non_nullable
as List<String>,metrics: null == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as List<OutbreakMetric>,
  ));
}


}

/// @nodoc
mixin _$PublicOutbreakDetail {

 PublicOutbreak get outbreak; List<PublicOutbreakUpdate> get updates; List<PublicOutbreakResource> get resources; List<PublicSituationReport> get reports;
/// Create a copy of PublicOutbreakDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicOutbreakDetailCopyWith<PublicOutbreakDetail> get copyWith => _$PublicOutbreakDetailCopyWithImpl<PublicOutbreakDetail>(this as PublicOutbreakDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicOutbreakDetail&&(identical(other.outbreak, outbreak) || other.outbreak == outbreak)&&const DeepCollectionEquality().equals(other.updates, updates)&&const DeepCollectionEquality().equals(other.resources, resources)&&const DeepCollectionEquality().equals(other.reports, reports));
}


@override
int get hashCode => Object.hash(runtimeType,outbreak,const DeepCollectionEquality().hash(updates),const DeepCollectionEquality().hash(resources),const DeepCollectionEquality().hash(reports));

@override
String toString() {
  return 'PublicOutbreakDetail(outbreak: $outbreak, updates: $updates, resources: $resources, reports: $reports)';
}


}

/// @nodoc
abstract mixin class $PublicOutbreakDetailCopyWith<$Res>  {
  factory $PublicOutbreakDetailCopyWith(PublicOutbreakDetail value, $Res Function(PublicOutbreakDetail) _then) = _$PublicOutbreakDetailCopyWithImpl;
@useResult
$Res call({
 PublicOutbreak outbreak, List<PublicOutbreakUpdate> updates, List<PublicOutbreakResource> resources, List<PublicSituationReport> reports
});


$PublicOutbreakCopyWith<$Res> get outbreak;

}
/// @nodoc
class _$PublicOutbreakDetailCopyWithImpl<$Res>
    implements $PublicOutbreakDetailCopyWith<$Res> {
  _$PublicOutbreakDetailCopyWithImpl(this._self, this._then);

  final PublicOutbreakDetail _self;
  final $Res Function(PublicOutbreakDetail) _then;

/// Create a copy of PublicOutbreakDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outbreak = null,Object? updates = null,Object? resources = null,Object? reports = null,}) {
  return _then(_self.copyWith(
outbreak: null == outbreak ? _self.outbreak : outbreak // ignore: cast_nullable_to_non_nullable
as PublicOutbreak,updates: null == updates ? _self.updates : updates // ignore: cast_nullable_to_non_nullable
as List<PublicOutbreakUpdate>,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as List<PublicOutbreakResource>,reports: null == reports ? _self.reports : reports // ignore: cast_nullable_to_non_nullable
as List<PublicSituationReport>,
  ));
}
/// Create a copy of PublicOutbreakDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PublicOutbreakCopyWith<$Res> get outbreak {
  
  return $PublicOutbreakCopyWith<$Res>(_self.outbreak, (value) {
    return _then(_self.copyWith(outbreak: value));
  });
}
}


/// @nodoc


class _PublicOutbreakDetail implements PublicOutbreakDetail {
  const _PublicOutbreakDetail({required this.outbreak, final  List<PublicOutbreakUpdate> updates = const <PublicOutbreakUpdate>[], final  List<PublicOutbreakResource> resources = const <PublicOutbreakResource>[], final  List<PublicSituationReport> reports = const <PublicSituationReport>[]}): _updates = updates,_resources = resources,_reports = reports;
  

@override final  PublicOutbreak outbreak;
 final  List<PublicOutbreakUpdate> _updates;
@override@JsonKey() List<PublicOutbreakUpdate> get updates {
  if (_updates is EqualUnmodifiableListView) return _updates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_updates);
}

 final  List<PublicOutbreakResource> _resources;
@override@JsonKey() List<PublicOutbreakResource> get resources {
  if (_resources is EqualUnmodifiableListView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resources);
}

 final  List<PublicSituationReport> _reports;
@override@JsonKey() List<PublicSituationReport> get reports {
  if (_reports is EqualUnmodifiableListView) return _reports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reports);
}


/// Create a copy of PublicOutbreakDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicOutbreakDetailCopyWith<_PublicOutbreakDetail> get copyWith => __$PublicOutbreakDetailCopyWithImpl<_PublicOutbreakDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicOutbreakDetail&&(identical(other.outbreak, outbreak) || other.outbreak == outbreak)&&const DeepCollectionEquality().equals(other._updates, _updates)&&const DeepCollectionEquality().equals(other._resources, _resources)&&const DeepCollectionEquality().equals(other._reports, _reports));
}


@override
int get hashCode => Object.hash(runtimeType,outbreak,const DeepCollectionEquality().hash(_updates),const DeepCollectionEquality().hash(_resources),const DeepCollectionEquality().hash(_reports));

@override
String toString() {
  return 'PublicOutbreakDetail(outbreak: $outbreak, updates: $updates, resources: $resources, reports: $reports)';
}


}

/// @nodoc
abstract mixin class _$PublicOutbreakDetailCopyWith<$Res> implements $PublicOutbreakDetailCopyWith<$Res> {
  factory _$PublicOutbreakDetailCopyWith(_PublicOutbreakDetail value, $Res Function(_PublicOutbreakDetail) _then) = __$PublicOutbreakDetailCopyWithImpl;
@override @useResult
$Res call({
 PublicOutbreak outbreak, List<PublicOutbreakUpdate> updates, List<PublicOutbreakResource> resources, List<PublicSituationReport> reports
});


@override $PublicOutbreakCopyWith<$Res> get outbreak;

}
/// @nodoc
class __$PublicOutbreakDetailCopyWithImpl<$Res>
    implements _$PublicOutbreakDetailCopyWith<$Res> {
  __$PublicOutbreakDetailCopyWithImpl(this._self, this._then);

  final _PublicOutbreakDetail _self;
  final $Res Function(_PublicOutbreakDetail) _then;

/// Create a copy of PublicOutbreakDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outbreak = null,Object? updates = null,Object? resources = null,Object? reports = null,}) {
  return _then(_PublicOutbreakDetail(
outbreak: null == outbreak ? _self.outbreak : outbreak // ignore: cast_nullable_to_non_nullable
as PublicOutbreak,updates: null == updates ? _self._updates : updates // ignore: cast_nullable_to_non_nullable
as List<PublicOutbreakUpdate>,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as List<PublicOutbreakResource>,reports: null == reports ? _self._reports : reports // ignore: cast_nullable_to_non_nullable
as List<PublicSituationReport>,
  ));
}

/// Create a copy of PublicOutbreakDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PublicOutbreakCopyWith<$Res> get outbreak {
  
  return $PublicOutbreakCopyWith<$Res>(_self.outbreak, (value) {
    return _then(_self.copyWith(outbreak: value));
  });
}
}

// dart format on

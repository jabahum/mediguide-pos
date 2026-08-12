// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_download.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OfflineDownload {

 String get id;@JsonKey(name: 'guideline_id') String get guidelineId;@JsonKey(name: 'asset_type') String get assetType; String get title; String get version; String get checksum;@JsonKey(name: 'size_bytes') int get sizeBytes; OfflineDownloadStatus get status; double get progress;@JsonKey(name: 'local_path') String get localPath; String get error; String get scope;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of OfflineDownload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineDownloadCopyWith<OfflineDownload> get copyWith => _$OfflineDownloadCopyWithImpl<OfflineDownload>(this as OfflineDownload, _$identity);

  /// Serializes this OfflineDownload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineDownload&&(identical(other.id, id) || other.id == id)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.assetType, assetType) || other.assetType == assetType)&&(identical(other.title, title) || other.title == title)&&(identical(other.version, version) || other.version == version)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.error, error) || other.error == error)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,guidelineId,assetType,title,version,checksum,sizeBytes,status,progress,localPath,error,scope,updatedAt);

@override
String toString() {
  return 'OfflineDownload(id: $id, guidelineId: $guidelineId, assetType: $assetType, title: $title, version: $version, checksum: $checksum, sizeBytes: $sizeBytes, status: $status, progress: $progress, localPath: $localPath, error: $error, scope: $scope, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $OfflineDownloadCopyWith<$Res>  {
  factory $OfflineDownloadCopyWith(OfflineDownload value, $Res Function(OfflineDownload) _then) = _$OfflineDownloadCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'asset_type') String assetType, String title, String version, String checksum,@JsonKey(name: 'size_bytes') int sizeBytes, OfflineDownloadStatus status, double progress,@JsonKey(name: 'local_path') String localPath, String error, String scope,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$OfflineDownloadCopyWithImpl<$Res>
    implements $OfflineDownloadCopyWith<$Res> {
  _$OfflineDownloadCopyWithImpl(this._self, this._then);

  final OfflineDownload _self;
  final $Res Function(OfflineDownload) _then;

/// Create a copy of OfflineDownload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? guidelineId = null,Object? assetType = null,Object? title = null,Object? version = null,Object? checksum = null,Object? sizeBytes = null,Object? status = null,Object? progress = null,Object? localPath = null,Object? error = null,Object? scope = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,assetType: null == assetType ? _self.assetType : assetType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OfflineDownloadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _OfflineDownload implements OfflineDownload {
  const _OfflineDownload({required this.id, @JsonKey(name: 'guideline_id') required this.guidelineId, @JsonKey(name: 'asset_type') required this.assetType, this.title = '', this.version = '', this.checksum = '', @JsonKey(name: 'size_bytes') this.sizeBytes = 0, this.status = OfflineDownloadStatus.queued, this.progress = 0, @JsonKey(name: 'local_path') this.localPath = '', this.error = '', required this.scope, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _OfflineDownload.fromJson(Map<String, dynamic> json) => _$OfflineDownloadFromJson(json);

@override final  String id;
@override@JsonKey(name: 'guideline_id') final  String guidelineId;
@override@JsonKey(name: 'asset_type') final  String assetType;
@override@JsonKey() final  String title;
@override@JsonKey() final  String version;
@override@JsonKey() final  String checksum;
@override@JsonKey(name: 'size_bytes') final  int sizeBytes;
@override@JsonKey() final  OfflineDownloadStatus status;
@override@JsonKey() final  double progress;
@override@JsonKey(name: 'local_path') final  String localPath;
@override@JsonKey() final  String error;
@override final  String scope;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of OfflineDownload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineDownloadCopyWith<_OfflineDownload> get copyWith => __$OfflineDownloadCopyWithImpl<_OfflineDownload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfflineDownloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineDownload&&(identical(other.id, id) || other.id == id)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.assetType, assetType) || other.assetType == assetType)&&(identical(other.title, title) || other.title == title)&&(identical(other.version, version) || other.version == version)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.error, error) || other.error == error)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,guidelineId,assetType,title,version,checksum,sizeBytes,status,progress,localPath,error,scope,updatedAt);

@override
String toString() {
  return 'OfflineDownload(id: $id, guidelineId: $guidelineId, assetType: $assetType, title: $title, version: $version, checksum: $checksum, sizeBytes: $sizeBytes, status: $status, progress: $progress, localPath: $localPath, error: $error, scope: $scope, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$OfflineDownloadCopyWith<$Res> implements $OfflineDownloadCopyWith<$Res> {
  factory _$OfflineDownloadCopyWith(_OfflineDownload value, $Res Function(_OfflineDownload) _then) = __$OfflineDownloadCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'asset_type') String assetType, String title, String version, String checksum,@JsonKey(name: 'size_bytes') int sizeBytes, OfflineDownloadStatus status, double progress,@JsonKey(name: 'local_path') String localPath, String error, String scope,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$OfflineDownloadCopyWithImpl<$Res>
    implements _$OfflineDownloadCopyWith<$Res> {
  __$OfflineDownloadCopyWithImpl(this._self, this._then);

  final _OfflineDownload _self;
  final $Res Function(_OfflineDownload) _then;

/// Create a copy of OfflineDownload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? guidelineId = null,Object? assetType = null,Object? title = null,Object? version = null,Object? checksum = null,Object? sizeBytes = null,Object? status = null,Object? progress = null,Object? localPath = null,Object? error = null,Object? scope = null,Object? updatedAt = freezed,}) {
  return _then(_OfflineDownload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,assetType: null == assetType ? _self.assetType : assetType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OfflineDownloadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReadingProgress {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'guideline_id') String get guidelineId;@JsonKey(name: 'current_section') String get currentSection;@JsonKey(name: 'total_sections') int get totalSections;@JsonKey(name: 'progress_percentage') double get progressPercentage;@JsonKey(name: 'last_read_at')@NullableDateTimeConverter() DateTime? get lastReadAtValue;@JsonKey(name: 'is_completed') bool get isCompleted;@JsonKey(name: 'is_bookmarked') bool get isBookmarked; String get notes;@JsonKey(name: 'pending_sync') bool get pendingSync;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingProgressCopyWith<ReadingProgress> get copyWith => _$ReadingProgressCopyWithImpl<ReadingProgress>(this as ReadingProgress, _$identity);

  /// Serializes this ReadingProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingProgress&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.currentSection, currentSection) || other.currentSection == currentSection)&&(identical(other.totalSections, totalSections) || other.totalSections == totalSections)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.lastReadAtValue, lastReadAtValue) || other.lastReadAtValue == lastReadAtValue)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.pendingSync, pendingSync) || other.pendingSync == pendingSync)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,guidelineId,currentSection,totalSections,progressPercentage,lastReadAtValue,isCompleted,isBookmarked,notes,pendingSync,createdAt,updatedAt);

@override
String toString() {
  return 'ReadingProgress(id: $id, userId: $userId, guidelineId: $guidelineId, currentSection: $currentSection, totalSections: $totalSections, progressPercentage: $progressPercentage, lastReadAtValue: $lastReadAtValue, isCompleted: $isCompleted, isBookmarked: $isBookmarked, notes: $notes, pendingSync: $pendingSync, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ReadingProgressCopyWith<$Res>  {
  factory $ReadingProgressCopyWith(ReadingProgress value, $Res Function(ReadingProgress) _then) = _$ReadingProgressCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'current_section') String currentSection,@JsonKey(name: 'total_sections') int totalSections,@JsonKey(name: 'progress_percentage') double progressPercentage,@JsonKey(name: 'last_read_at')@NullableDateTimeConverter() DateTime? lastReadAtValue,@JsonKey(name: 'is_completed') bool isCompleted,@JsonKey(name: 'is_bookmarked') bool isBookmarked, String notes,@JsonKey(name: 'pending_sync') bool pendingSync,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ReadingProgressCopyWithImpl<$Res>
    implements $ReadingProgressCopyWith<$Res> {
  _$ReadingProgressCopyWithImpl(this._self, this._then);

  final ReadingProgress _self;
  final $Res Function(ReadingProgress) _then;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? guidelineId = null,Object? currentSection = null,Object? totalSections = null,Object? progressPercentage = null,Object? lastReadAtValue = freezed,Object? isCompleted = null,Object? isBookmarked = null,Object? notes = null,Object? pendingSync = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,currentSection: null == currentSection ? _self.currentSection : currentSection // ignore: cast_nullable_to_non_nullable
as String,totalSections: null == totalSections ? _self.totalSections : totalSections // ignore: cast_nullable_to_non_nullable
as int,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,lastReadAtValue: freezed == lastReadAtValue ? _self.lastReadAtValue : lastReadAtValue // ignore: cast_nullable_to_non_nullable
as DateTime?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,isBookmarked: null == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ReadingProgress extends ReadingProgress {
  const _ReadingProgress({required this.id, @JsonKey(name: 'user_id') this.userId = '', @JsonKey(name: 'guideline_id') this.guidelineId = '', @JsonKey(name: 'current_section') this.currentSection = '', @JsonKey(name: 'total_sections') this.totalSections = 0, @JsonKey(name: 'progress_percentage') this.progressPercentage = 0, @JsonKey(name: 'last_read_at')@NullableDateTimeConverter() this.lastReadAtValue, @JsonKey(name: 'is_completed') this.isCompleted = false, @JsonKey(name: 'is_bookmarked') this.isBookmarked = false, this.notes = '', @JsonKey(name: 'pending_sync') this.pendingSync = false, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _ReadingProgress.fromJson(Map<String, dynamic> json) => _$ReadingProgressFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'guideline_id') final  String guidelineId;
@override@JsonKey(name: 'current_section') final  String currentSection;
@override@JsonKey(name: 'total_sections') final  int totalSections;
@override@JsonKey(name: 'progress_percentage') final  double progressPercentage;
@override@JsonKey(name: 'last_read_at')@NullableDateTimeConverter() final  DateTime? lastReadAtValue;
@override@JsonKey(name: 'is_completed') final  bool isCompleted;
@override@JsonKey(name: 'is_bookmarked') final  bool isBookmarked;
@override@JsonKey() final  String notes;
@override@JsonKey(name: 'pending_sync') final  bool pendingSync;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingProgressCopyWith<_ReadingProgress> get copyWith => __$ReadingProgressCopyWithImpl<_ReadingProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingProgress&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.currentSection, currentSection) || other.currentSection == currentSection)&&(identical(other.totalSections, totalSections) || other.totalSections == totalSections)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.lastReadAtValue, lastReadAtValue) || other.lastReadAtValue == lastReadAtValue)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.pendingSync, pendingSync) || other.pendingSync == pendingSync)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,guidelineId,currentSection,totalSections,progressPercentage,lastReadAtValue,isCompleted,isBookmarked,notes,pendingSync,createdAt,updatedAt);

@override
String toString() {
  return 'ReadingProgress(id: $id, userId: $userId, guidelineId: $guidelineId, currentSection: $currentSection, totalSections: $totalSections, progressPercentage: $progressPercentage, lastReadAtValue: $lastReadAtValue, isCompleted: $isCompleted, isBookmarked: $isBookmarked, notes: $notes, pendingSync: $pendingSync, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ReadingProgressCopyWith<$Res> implements $ReadingProgressCopyWith<$Res> {
  factory _$ReadingProgressCopyWith(_ReadingProgress value, $Res Function(_ReadingProgress) _then) = __$ReadingProgressCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'current_section') String currentSection,@JsonKey(name: 'total_sections') int totalSections,@JsonKey(name: 'progress_percentage') double progressPercentage,@JsonKey(name: 'last_read_at')@NullableDateTimeConverter() DateTime? lastReadAtValue,@JsonKey(name: 'is_completed') bool isCompleted,@JsonKey(name: 'is_bookmarked') bool isBookmarked, String notes,@JsonKey(name: 'pending_sync') bool pendingSync,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ReadingProgressCopyWithImpl<$Res>
    implements _$ReadingProgressCopyWith<$Res> {
  __$ReadingProgressCopyWithImpl(this._self, this._then);

  final _ReadingProgress _self;
  final $Res Function(_ReadingProgress) _then;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? guidelineId = null,Object? currentSection = null,Object? totalSections = null,Object? progressPercentage = null,Object? lastReadAtValue = freezed,Object? isCompleted = null,Object? isBookmarked = null,Object? notes = null,Object? pendingSync = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ReadingProgress(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,currentSection: null == currentSection ? _self.currentSection : currentSection // ignore: cast_nullable_to_non_nullable
as String,totalSections: null == totalSections ? _self.totalSections : totalSections // ignore: cast_nullable_to_non_nullable
as int,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,lastReadAtValue: freezed == lastReadAtValue ? _self.lastReadAtValue : lastReadAtValue // ignore: cast_nullable_to_non_nullable
as DateTime?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,isBookmarked: null == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ReadingProgressRequest {

@JsonKey(name: 'guideline_id') String? get guidelineId;@JsonKey(name: 'current_section') String? get currentSection;@JsonKey(name: 'total_sections') int? get totalSections;@JsonKey(name: 'progress_percentage') double? get progressPercentage;@JsonKey(name: 'last_read_at') DateTime? get lastReadAt;@JsonKey(name: 'is_completed') bool? get isCompleted;@JsonKey(name: 'is_bookmarked') bool? get isBookmarked; String? get notes;
/// Create a copy of ReadingProgressRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingProgressRequestCopyWith<ReadingProgressRequest> get copyWith => _$ReadingProgressRequestCopyWithImpl<ReadingProgressRequest>(this as ReadingProgressRequest, _$identity);

  /// Serializes this ReadingProgressRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingProgressRequest&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.currentSection, currentSection) || other.currentSection == currentSection)&&(identical(other.totalSections, totalSections) || other.totalSections == totalSections)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,guidelineId,currentSection,totalSections,progressPercentage,lastReadAt,isCompleted,isBookmarked,notes);

@override
String toString() {
  return 'ReadingProgressRequest(guidelineId: $guidelineId, currentSection: $currentSection, totalSections: $totalSections, progressPercentage: $progressPercentage, lastReadAt: $lastReadAt, isCompleted: $isCompleted, isBookmarked: $isBookmarked, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ReadingProgressRequestCopyWith<$Res>  {
  factory $ReadingProgressRequestCopyWith(ReadingProgressRequest value, $Res Function(ReadingProgressRequest) _then) = _$ReadingProgressRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'guideline_id') String? guidelineId,@JsonKey(name: 'current_section') String? currentSection,@JsonKey(name: 'total_sections') int? totalSections,@JsonKey(name: 'progress_percentage') double? progressPercentage,@JsonKey(name: 'last_read_at') DateTime? lastReadAt,@JsonKey(name: 'is_completed') bool? isCompleted,@JsonKey(name: 'is_bookmarked') bool? isBookmarked, String? notes
});




}
/// @nodoc
class _$ReadingProgressRequestCopyWithImpl<$Res>
    implements $ReadingProgressRequestCopyWith<$Res> {
  _$ReadingProgressRequestCopyWithImpl(this._self, this._then);

  final ReadingProgressRequest _self;
  final $Res Function(ReadingProgressRequest) _then;

/// Create a copy of ReadingProgressRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? guidelineId = freezed,Object? currentSection = freezed,Object? totalSections = freezed,Object? progressPercentage = freezed,Object? lastReadAt = freezed,Object? isCompleted = freezed,Object? isBookmarked = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
guidelineId: freezed == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String?,currentSection: freezed == currentSection ? _self.currentSection : currentSection // ignore: cast_nullable_to_non_nullable
as String?,totalSections: freezed == totalSections ? _self.totalSections : totalSections // ignore: cast_nullable_to_non_nullable
as int?,progressPercentage: freezed == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isCompleted: freezed == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool?,isBookmarked: freezed == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _ReadingProgressRequest implements ReadingProgressRequest {
  const _ReadingProgressRequest({@JsonKey(name: 'guideline_id') this.guidelineId, @JsonKey(name: 'current_section') this.currentSection, @JsonKey(name: 'total_sections') this.totalSections, @JsonKey(name: 'progress_percentage') this.progressPercentage, @JsonKey(name: 'last_read_at') this.lastReadAt, @JsonKey(name: 'is_completed') this.isCompleted, @JsonKey(name: 'is_bookmarked') this.isBookmarked, this.notes});
  factory _ReadingProgressRequest.fromJson(Map<String, dynamic> json) => _$ReadingProgressRequestFromJson(json);

@override@JsonKey(name: 'guideline_id') final  String? guidelineId;
@override@JsonKey(name: 'current_section') final  String? currentSection;
@override@JsonKey(name: 'total_sections') final  int? totalSections;
@override@JsonKey(name: 'progress_percentage') final  double? progressPercentage;
@override@JsonKey(name: 'last_read_at') final  DateTime? lastReadAt;
@override@JsonKey(name: 'is_completed') final  bool? isCompleted;
@override@JsonKey(name: 'is_bookmarked') final  bool? isBookmarked;
@override final  String? notes;

/// Create a copy of ReadingProgressRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingProgressRequestCopyWith<_ReadingProgressRequest> get copyWith => __$ReadingProgressRequestCopyWithImpl<_ReadingProgressRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingProgressRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingProgressRequest&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.currentSection, currentSection) || other.currentSection == currentSection)&&(identical(other.totalSections, totalSections) || other.totalSections == totalSections)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,guidelineId,currentSection,totalSections,progressPercentage,lastReadAt,isCompleted,isBookmarked,notes);

@override
String toString() {
  return 'ReadingProgressRequest(guidelineId: $guidelineId, currentSection: $currentSection, totalSections: $totalSections, progressPercentage: $progressPercentage, lastReadAt: $lastReadAt, isCompleted: $isCompleted, isBookmarked: $isBookmarked, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ReadingProgressRequestCopyWith<$Res> implements $ReadingProgressRequestCopyWith<$Res> {
  factory _$ReadingProgressRequestCopyWith(_ReadingProgressRequest value, $Res Function(_ReadingProgressRequest) _then) = __$ReadingProgressRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'guideline_id') String? guidelineId,@JsonKey(name: 'current_section') String? currentSection,@JsonKey(name: 'total_sections') int? totalSections,@JsonKey(name: 'progress_percentage') double? progressPercentage,@JsonKey(name: 'last_read_at') DateTime? lastReadAt,@JsonKey(name: 'is_completed') bool? isCompleted,@JsonKey(name: 'is_bookmarked') bool? isBookmarked, String? notes
});




}
/// @nodoc
class __$ReadingProgressRequestCopyWithImpl<$Res>
    implements _$ReadingProgressRequestCopyWith<$Res> {
  __$ReadingProgressRequestCopyWithImpl(this._self, this._then);

  final _ReadingProgressRequest _self;
  final $Res Function(_ReadingProgressRequest) _then;

/// Create a copy of ReadingProgressRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? guidelineId = freezed,Object? currentSection = freezed,Object? totalSections = freezed,Object? progressPercentage = freezed,Object? lastReadAt = freezed,Object? isCompleted = freezed,Object? isBookmarked = freezed,Object? notes = freezed,}) {
  return _then(_ReadingProgressRequest(
guidelineId: freezed == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String?,currentSection: freezed == currentSection ? _self.currentSection : currentSection // ignore: cast_nullable_to_non_nullable
as String?,totalSections: freezed == totalSections ? _self.totalSections : totalSections // ignore: cast_nullable_to_non_nullable
as int?,progressPercentage: freezed == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isCompleted: freezed == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool?,isBookmarked: freezed == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

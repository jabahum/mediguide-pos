// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rag_answer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RagAnswer {

 String get answer; List<RagCitation> get citations;@JsonKey(name: 'session_id') String get sessionId;
/// Create a copy of RagAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RagAnswerCopyWith<RagAnswer> get copyWith => _$RagAnswerCopyWithImpl<RagAnswer>(this as RagAnswer, _$identity);

  /// Serializes this RagAnswer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RagAnswer&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other.citations, citations)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,answer,const DeepCollectionEquality().hash(citations),sessionId);

@override
String toString() {
  return 'RagAnswer(answer: $answer, citations: $citations, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $RagAnswerCopyWith<$Res>  {
  factory $RagAnswerCopyWith(RagAnswer value, $Res Function(RagAnswer) _then) = _$RagAnswerCopyWithImpl;
@useResult
$Res call({
 String answer, List<RagCitation> citations,@JsonKey(name: 'session_id') String sessionId
});




}
/// @nodoc
class _$RagAnswerCopyWithImpl<$Res>
    implements $RagAnswerCopyWith<$Res> {
  _$RagAnswerCopyWithImpl(this._self, this._then);

  final RagAnswer _self;
  final $Res Function(RagAnswer) _then;

/// Create a copy of RagAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? answer = null,Object? citations = null,Object? sessionId = null,}) {
  return _then(_self.copyWith(
answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,citations: null == citations ? _self.citations : citations // ignore: cast_nullable_to_non_nullable
as List<RagCitation>,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RagAnswer extends RagAnswer {
  const _RagAnswer({this.answer = '', final  List<RagCitation> citations = const [], @JsonKey(name: 'session_id') this.sessionId = ''}): _citations = citations,super._();
  factory _RagAnswer.fromJson(Map<String, dynamic> json) => _$RagAnswerFromJson(json);

@override@JsonKey() final  String answer;
 final  List<RagCitation> _citations;
@override@JsonKey() List<RagCitation> get citations {
  if (_citations is EqualUnmodifiableListView) return _citations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citations);
}

@override@JsonKey(name: 'session_id') final  String sessionId;

/// Create a copy of RagAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RagAnswerCopyWith<_RagAnswer> get copyWith => __$RagAnswerCopyWithImpl<_RagAnswer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RagAnswerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RagAnswer&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other._citations, _citations)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,answer,const DeepCollectionEquality().hash(_citations),sessionId);

@override
String toString() {
  return 'RagAnswer(answer: $answer, citations: $citations, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$RagAnswerCopyWith<$Res> implements $RagAnswerCopyWith<$Res> {
  factory _$RagAnswerCopyWith(_RagAnswer value, $Res Function(_RagAnswer) _then) = __$RagAnswerCopyWithImpl;
@override @useResult
$Res call({
 String answer, List<RagCitation> citations,@JsonKey(name: 'session_id') String sessionId
});




}
/// @nodoc
class __$RagAnswerCopyWithImpl<$Res>
    implements _$RagAnswerCopyWith<$Res> {
  __$RagAnswerCopyWithImpl(this._self, this._then);

  final _RagAnswer _self;
  final $Res Function(_RagAnswer) _then;

/// Create a copy of RagAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? answer = null,Object? citations = null,Object? sessionId = null,}) {
  return _then(_RagAnswer(
answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,citations: null == citations ? _self._citations : citations // ignore: cast_nullable_to_non_nullable
as List<RagCitation>,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RagCitation {

@JsonKey(name: 'chunk_id') String get chunkId;@JsonKey(name: 'guideline_id') String get guidelineId;@JsonKey(name: 'section_id') String get sectionId;@JsonKey(name: 'block_id') String get blockId; String get title;@JsonKey(name: 'source_name') String get sourceName;@JsonKey(name: 'source_version') String get sourceVersion;@JsonKey(name: 'page_start') int? get pageStart;@JsonKey(name: 'page_end') int? get pageEnd;
/// Create a copy of RagCitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RagCitationCopyWith<RagCitation> get copyWith => _$RagCitationCopyWithImpl<RagCitation>(this as RagCitation, _$identity);

  /// Serializes this RagCitation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RagCitation&&(identical(other.chunkId, chunkId) || other.chunkId == chunkId)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.sourceVersion, sourceVersion) || other.sourceVersion == sourceVersion)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chunkId,guidelineId,sectionId,blockId,title,sourceName,sourceVersion,pageStart,pageEnd);

@override
String toString() {
  return 'RagCitation(chunkId: $chunkId, guidelineId: $guidelineId, sectionId: $sectionId, blockId: $blockId, title: $title, sourceName: $sourceName, sourceVersion: $sourceVersion, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $RagCitationCopyWith<$Res>  {
  factory $RagCitationCopyWith(RagCitation value, $Res Function(RagCitation) _then) = _$RagCitationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'chunk_id') String chunkId,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'section_id') String sectionId,@JsonKey(name: 'block_id') String blockId, String title,@JsonKey(name: 'source_name') String sourceName,@JsonKey(name: 'source_version') String sourceVersion,@JsonKey(name: 'page_start') int? pageStart,@JsonKey(name: 'page_end') int? pageEnd
});




}
/// @nodoc
class _$RagCitationCopyWithImpl<$Res>
    implements $RagCitationCopyWith<$Res> {
  _$RagCitationCopyWithImpl(this._self, this._then);

  final RagCitation _self;
  final $Res Function(RagCitation) _then;

/// Create a copy of RagCitation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chunkId = null,Object? guidelineId = null,Object? sectionId = null,Object? blockId = null,Object? title = null,Object? sourceName = null,Object? sourceVersion = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(_self.copyWith(
chunkId: null == chunkId ? _self.chunkId : chunkId // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,sectionId: null == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String,blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceName: null == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String,sourceVersion: null == sourceVersion ? _self.sourceVersion : sourceVersion // ignore: cast_nullable_to_non_nullable
as String,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _RagCitation extends RagCitation {
  const _RagCitation({@JsonKey(name: 'chunk_id') this.chunkId = '', @JsonKey(name: 'guideline_id') this.guidelineId = '', @JsonKey(name: 'section_id') this.sectionId = '', @JsonKey(name: 'block_id') this.blockId = '', this.title = '', @JsonKey(name: 'source_name') this.sourceName = '', @JsonKey(name: 'source_version') this.sourceVersion = '', @JsonKey(name: 'page_start') this.pageStart, @JsonKey(name: 'page_end') this.pageEnd}): super._();
  factory _RagCitation.fromJson(Map<String, dynamic> json) => _$RagCitationFromJson(json);

@override@JsonKey(name: 'chunk_id') final  String chunkId;
@override@JsonKey(name: 'guideline_id') final  String guidelineId;
@override@JsonKey(name: 'section_id') final  String sectionId;
@override@JsonKey(name: 'block_id') final  String blockId;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'source_name') final  String sourceName;
@override@JsonKey(name: 'source_version') final  String sourceVersion;
@override@JsonKey(name: 'page_start') final  int? pageStart;
@override@JsonKey(name: 'page_end') final  int? pageEnd;

/// Create a copy of RagCitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RagCitationCopyWith<_RagCitation> get copyWith => __$RagCitationCopyWithImpl<_RagCitation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RagCitationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RagCitation&&(identical(other.chunkId, chunkId) || other.chunkId == chunkId)&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.sourceVersion, sourceVersion) || other.sourceVersion == sourceVersion)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chunkId,guidelineId,sectionId,blockId,title,sourceName,sourceVersion,pageStart,pageEnd);

@override
String toString() {
  return 'RagCitation(chunkId: $chunkId, guidelineId: $guidelineId, sectionId: $sectionId, blockId: $blockId, title: $title, sourceName: $sourceName, sourceVersion: $sourceVersion, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class _$RagCitationCopyWith<$Res> implements $RagCitationCopyWith<$Res> {
  factory _$RagCitationCopyWith(_RagCitation value, $Res Function(_RagCitation) _then) = __$RagCitationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'chunk_id') String chunkId,@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'section_id') String sectionId,@JsonKey(name: 'block_id') String blockId, String title,@JsonKey(name: 'source_name') String sourceName,@JsonKey(name: 'source_version') String sourceVersion,@JsonKey(name: 'page_start') int? pageStart,@JsonKey(name: 'page_end') int? pageEnd
});




}
/// @nodoc
class __$RagCitationCopyWithImpl<$Res>
    implements _$RagCitationCopyWith<$Res> {
  __$RagCitationCopyWithImpl(this._self, this._then);

  final _RagCitation _self;
  final $Res Function(_RagCitation) _then;

/// Create a copy of RagCitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chunkId = null,Object? guidelineId = null,Object? sectionId = null,Object? blockId = null,Object? title = null,Object? sourceName = null,Object? sourceVersion = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(_RagCitation(
chunkId: null == chunkId ? _self.chunkId : chunkId // ignore: cast_nullable_to_non_nullable
as String,guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,sectionId: null == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String,blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceName: null == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String,sourceVersion: null == sourceVersion ? _self.sourceVersion : sourceVersion // ignore: cast_nullable_to_non_nullable
as String,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

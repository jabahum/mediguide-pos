// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faq.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FAQ {

 String get id; String get question; String get answer; String get status; String get priority;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(name: 'is_featured') bool get isFeatured;@JsonKey(name: 'target_audience') String get targetAudience; String get keywords;@JsonKey(name: 'published_at')@NullableDateTimeConverter() DateTime? get publishedAt;@JsonKey(name: 'review_due')@NullableDateTimeConverter() DateTime? get reviewDue; List<String> get tags;@JsonKey(name: 'related_faqs') List<String> get relatedFaqs; String? get author; String? get reviewer;@NullableDateTimeConverter() DateTime? get created;@NullableDateTimeConverter() DateTime? get updated;
/// Create a copy of FAQ
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FAQCopyWith<FAQ> get copyWith => _$FAQCopyWithImpl<FAQ>(this as FAQ, _$identity);

  /// Serializes this FAQ to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FAQ&&(identical(other.id, id) || other.id == id)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.targetAudience, targetAudience) || other.targetAudience == targetAudience)&&(identical(other.keywords, keywords) || other.keywords == keywords)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reviewDue, reviewDue) || other.reviewDue == reviewDue)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.relatedFaqs, relatedFaqs)&&(identical(other.author, author) || other.author == author)&&(identical(other.reviewer, reviewer) || other.reviewer == reviewer)&&(identical(other.created, created) || other.created == created)&&(identical(other.updated, updated) || other.updated == updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,question,answer,status,priority,sortOrder,isFeatured,targetAudience,keywords,publishedAt,reviewDue,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(relatedFaqs),author,reviewer,created,updated);

@override
String toString() {
  return 'FAQ(id: $id, question: $question, answer: $answer, status: $status, priority: $priority, sortOrder: $sortOrder, isFeatured: $isFeatured, targetAudience: $targetAudience, keywords: $keywords, publishedAt: $publishedAt, reviewDue: $reviewDue, tags: $tags, relatedFaqs: $relatedFaqs, author: $author, reviewer: $reviewer, created: $created, updated: $updated)';
}


}

/// @nodoc
abstract mixin class $FAQCopyWith<$Res>  {
  factory $FAQCopyWith(FAQ value, $Res Function(FAQ) _then) = _$FAQCopyWithImpl;
@useResult
$Res call({
 String id, String question, String answer, String status, String priority,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'target_audience') String targetAudience, String keywords,@JsonKey(name: 'published_at')@NullableDateTimeConverter() DateTime? publishedAt,@JsonKey(name: 'review_due')@NullableDateTimeConverter() DateTime? reviewDue, List<String> tags,@JsonKey(name: 'related_faqs') List<String> relatedFaqs, String? author, String? reviewer,@NullableDateTimeConverter() DateTime? created,@NullableDateTimeConverter() DateTime? updated
});




}
/// @nodoc
class _$FAQCopyWithImpl<$Res>
    implements $FAQCopyWith<$Res> {
  _$FAQCopyWithImpl(this._self, this._then);

  final FAQ _self;
  final $Res Function(FAQ) _then;

/// Create a copy of FAQ
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? question = null,Object? answer = null,Object? status = null,Object? priority = null,Object? sortOrder = null,Object? isFeatured = null,Object? targetAudience = null,Object? keywords = null,Object? publishedAt = freezed,Object? reviewDue = freezed,Object? tags = null,Object? relatedFaqs = null,Object? author = freezed,Object? reviewer = freezed,Object? created = freezed,Object? updated = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,targetAudience: null == targetAudience ? _self.targetAudience : targetAudience // ignore: cast_nullable_to_non_nullable
as String,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewDue: freezed == reviewDue ? _self.reviewDue : reviewDue // ignore: cast_nullable_to_non_nullable
as DateTime?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,relatedFaqs: null == relatedFaqs ? _self.relatedFaqs : relatedFaqs // ignore: cast_nullable_to_non_nullable
as List<String>,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,reviewer: freezed == reviewer ? _self.reviewer : reviewer // ignore: cast_nullable_to_non_nullable
as String?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,updated: freezed == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _FAQ extends FAQ {
  const _FAQ({required this.id, this.question = '', this.answer = '', this.status = 'published', this.priority = 'normal', @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(name: 'is_featured') this.isFeatured = false, @JsonKey(name: 'target_audience') this.targetAudience = 'all', this.keywords = '', @JsonKey(name: 'published_at')@NullableDateTimeConverter() this.publishedAt, @JsonKey(name: 'review_due')@NullableDateTimeConverter() this.reviewDue, final  List<String> tags = const [], @JsonKey(name: 'related_faqs') final  List<String> relatedFaqs = const [], this.author, this.reviewer, @NullableDateTimeConverter() this.created, @NullableDateTimeConverter() this.updated}): _tags = tags,_relatedFaqs = relatedFaqs,super._();
  factory _FAQ.fromJson(Map<String, dynamic> json) => _$FAQFromJson(json);

@override final  String id;
@override@JsonKey() final  String question;
@override@JsonKey() final  String answer;
@override@JsonKey() final  String status;
@override@JsonKey() final  String priority;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey(name: 'is_featured') final  bool isFeatured;
@override@JsonKey(name: 'target_audience') final  String targetAudience;
@override@JsonKey() final  String keywords;
@override@JsonKey(name: 'published_at')@NullableDateTimeConverter() final  DateTime? publishedAt;
@override@JsonKey(name: 'review_due')@NullableDateTimeConverter() final  DateTime? reviewDue;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<String> _relatedFaqs;
@override@JsonKey(name: 'related_faqs') List<String> get relatedFaqs {
  if (_relatedFaqs is EqualUnmodifiableListView) return _relatedFaqs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedFaqs);
}

@override final  String? author;
@override final  String? reviewer;
@override@NullableDateTimeConverter() final  DateTime? created;
@override@NullableDateTimeConverter() final  DateTime? updated;

/// Create a copy of FAQ
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FAQCopyWith<_FAQ> get copyWith => __$FAQCopyWithImpl<_FAQ>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FAQToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FAQ&&(identical(other.id, id) || other.id == id)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.targetAudience, targetAudience) || other.targetAudience == targetAudience)&&(identical(other.keywords, keywords) || other.keywords == keywords)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reviewDue, reviewDue) || other.reviewDue == reviewDue)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._relatedFaqs, _relatedFaqs)&&(identical(other.author, author) || other.author == author)&&(identical(other.reviewer, reviewer) || other.reviewer == reviewer)&&(identical(other.created, created) || other.created == created)&&(identical(other.updated, updated) || other.updated == updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,question,answer,status,priority,sortOrder,isFeatured,targetAudience,keywords,publishedAt,reviewDue,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_relatedFaqs),author,reviewer,created,updated);

@override
String toString() {
  return 'FAQ(id: $id, question: $question, answer: $answer, status: $status, priority: $priority, sortOrder: $sortOrder, isFeatured: $isFeatured, targetAudience: $targetAudience, keywords: $keywords, publishedAt: $publishedAt, reviewDue: $reviewDue, tags: $tags, relatedFaqs: $relatedFaqs, author: $author, reviewer: $reviewer, created: $created, updated: $updated)';
}


}

/// @nodoc
abstract mixin class _$FAQCopyWith<$Res> implements $FAQCopyWith<$Res> {
  factory _$FAQCopyWith(_FAQ value, $Res Function(_FAQ) _then) = __$FAQCopyWithImpl;
@override @useResult
$Res call({
 String id, String question, String answer, String status, String priority,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'target_audience') String targetAudience, String keywords,@JsonKey(name: 'published_at')@NullableDateTimeConverter() DateTime? publishedAt,@JsonKey(name: 'review_due')@NullableDateTimeConverter() DateTime? reviewDue, List<String> tags,@JsonKey(name: 'related_faqs') List<String> relatedFaqs, String? author, String? reviewer,@NullableDateTimeConverter() DateTime? created,@NullableDateTimeConverter() DateTime? updated
});




}
/// @nodoc
class __$FAQCopyWithImpl<$Res>
    implements _$FAQCopyWith<$Res> {
  __$FAQCopyWithImpl(this._self, this._then);

  final _FAQ _self;
  final $Res Function(_FAQ) _then;

/// Create a copy of FAQ
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? question = null,Object? answer = null,Object? status = null,Object? priority = null,Object? sortOrder = null,Object? isFeatured = null,Object? targetAudience = null,Object? keywords = null,Object? publishedAt = freezed,Object? reviewDue = freezed,Object? tags = null,Object? relatedFaqs = null,Object? author = freezed,Object? reviewer = freezed,Object? created = freezed,Object? updated = freezed,}) {
  return _then(_FAQ(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,targetAudience: null == targetAudience ? _self.targetAudience : targetAudience // ignore: cast_nullable_to_non_nullable
as String,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewDue: freezed == reviewDue ? _self.reviewDue : reviewDue // ignore: cast_nullable_to_non_nullable
as DateTime?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,relatedFaqs: null == relatedFaqs ? _self._relatedFaqs : relatedFaqs // ignore: cast_nullable_to_non_nullable
as List<String>,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,reviewer: freezed == reviewer ? _self.reviewer : reviewer // ignore: cast_nullable_to_non_nullable
as String?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,updated: freezed == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

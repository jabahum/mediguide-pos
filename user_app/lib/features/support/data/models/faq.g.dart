// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FAQ _$FAQFromJson(Map<String, dynamic> json) => _FAQ(
  id: json['id'] as String,
  question: json['question'] as String? ?? '',
  answer: json['answer'] as String? ?? '',
  status: json['status'] as String? ?? 'published',
  priority: json['priority'] as String? ?? 'normal',
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  isFeatured: json['is_featured'] as bool? ?? false,
  targetAudience: json['target_audience'] as String? ?? 'all',
  keywords: json['keywords'] as String? ?? '',
  publishedAt: const NullableDateTimeConverter().fromJson(json['published_at']),
  reviewDue: const NullableDateTimeConverter().fromJson(json['review_due']),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  relatedFaqs:
      (json['related_faqs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  author: json['author'] as String?,
  reviewer: json['reviewer'] as String?,
  created: const NullableDateTimeConverter().fromJson(json['created']),
  updated: const NullableDateTimeConverter().fromJson(json['updated']),
);

Map<String, dynamic> _$FAQToJson(_FAQ instance) => <String, dynamic>{
  'id': instance.id,
  'question': instance.question,
  'answer': instance.answer,
  'status': instance.status,
  'priority': instance.priority,
  'sort_order': instance.sortOrder,
  'is_featured': instance.isFeatured,
  'target_audience': instance.targetAudience,
  'keywords': instance.keywords,
  'published_at': const NullableDateTimeConverter().toJson(
    instance.publishedAt,
  ),
  'review_due': const NullableDateTimeConverter().toJson(instance.reviewDue),
  'tags': instance.tags,
  'related_faqs': instance.relatedFaqs,
  'author': instance.author,
  'reviewer': instance.reviewer,
  'created': const NullableDateTimeConverter().toJson(instance.created),
  'updated': const NullableDateTimeConverter().toJson(instance.updated),
};

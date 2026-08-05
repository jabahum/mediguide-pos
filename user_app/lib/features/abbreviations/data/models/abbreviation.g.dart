// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'abbreviation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Abbreviation _$AbbreviationFromJson(Map<String, dynamic> json) =>
    _Abbreviation(
      id: json['id'] as String,
      abbreviation: json['abbreviation'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      description: json['description'] as String? ?? '',
      commonUsage: json['common_usage'] as bool? ?? false,
      categoryId: json['category_id'] as String? ?? '',
      category: json['category'] == null
          ? null
          : GuidelineCategory.fromJson(
              json['category'] as Map<String, dynamic>,
            ),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => GuidelineTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$AbbreviationToJson(
  _Abbreviation instance,
) => <String, dynamic>{
  'id': instance.id,
  'abbreviation': instance.abbreviation,
  'meaning': instance.meaning,
  'description': instance.description,
  'common_usage': instance.commonUsage,
  'category_id': instance.categoryId,
  'category': instance.category?.toJson(),
  'tags': instance.tags.map((e) => e.toJson()).toList(),
  'usage_count': instance.usageCount,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_AbbreviationRequest _$AbbreviationRequestFromJson(Map<String, dynamic> json) =>
    _AbbreviationRequest(
      abbreviation: json['abbreviation'] as String?,
      meaning: json['meaning'] as String?,
      description: json['description'] as String?,
      commonUsage: json['common_usage'] as bool?,
      categoryId: json['category_id'] as String?,
      tagIds: (json['tag_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AbbreviationRequestToJson(
  _AbbreviationRequest instance,
) => <String, dynamic>{
  if (instance.abbreviation case final value?) 'abbreviation': value,
  if (instance.meaning case final value?) 'meaning': value,
  if (instance.description case final value?) 'description': value,
  if (instance.commonUsage case final value?) 'common_usage': value,
  if (instance.categoryId case final value?) 'category_id': value,
  if (instance.tagIds case final value?) 'tag_ids': value,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documentation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Documentation _$DocumentationFromJson(Map<String, dynamic> json) =>
    _Documentation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? '',
      status: json['status'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$DocumentationToJson(
  _Documentation instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'content': instance.content,
  'category': instance.category,
  'status': instance.status,
  'tags': instance.tags,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

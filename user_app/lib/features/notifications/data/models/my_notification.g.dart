// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MyNotification _$MyNotificationFromJson(Map<String, dynamic> json) =>
    _MyNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      userId: json['user_id'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      actionUrl: json['action_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$MyNotificationToJson(
  _MyNotification instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'message': instance.message,
  'type': instance.type,
  'user_id': instance.userId,
  'priority': instance.priority,
  'action_url': instance.actionUrl,
  'is_read': instance.isRead,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

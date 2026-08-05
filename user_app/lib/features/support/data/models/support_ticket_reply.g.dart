// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket_reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupportReplyAuthor _$SupportReplyAuthorFromJson(Map<String, dynamic> json) =>
    _SupportReplyAuthor(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );

Map<String, dynamic> _$SupportReplyAuthorToJson(_SupportReplyAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

_SupportTicketReply _$SupportTicketReplyFromJson(Map<String, dynamic> json) =>
    _SupportTicketReply(
      id: json['id'] as String,
      message: json['message'] as String? ?? '',
      isInternal: json['is_internal'] as bool? ?? false,
      ticketId: json['ticket_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      user: json['user'] == null
          ? null
          : SupportReplyAuthor.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$SupportTicketReplyToJson(
  _SupportTicketReply instance,
) => <String, dynamic>{
  'id': instance.id,
  'message': instance.message,
  'is_internal': instance.isInternal,
  'ticket_id': instance.ticketId,
  'user_id': instance.userId,
  'user': instance.user?.toJson(),
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

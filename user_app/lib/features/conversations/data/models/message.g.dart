// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  conversation: json['conversation_id'] as String? ?? '',
  sender: json['sender_user_id'] as String? ?? '',
  content: json['content'] as String? ?? '',
  messageType: json['message_type'] == null
      ? MessageType.text
      : _messageTypeFromJson(json['message_type']),
  replyTo: json['reply_to_id'] as String? ?? '',
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  readBy: json['read_by'] as Map<String, dynamic>? ?? const {},
  reactions: json['reactions'] as Map<String, dynamic>? ?? const {},
  isEdited: json['is_edited'] as bool? ?? false,
  editedAtDate: const NullableDateTimeConverter().fromJson(json['edited_at']),
  senderUser: json['sender'] == null
      ? null
      : User.fromJson(json['sender'] as Map<String, dynamic>),
  replyToMessage: json['reply_to_message'] == null
      ? null
      : Message.fromJson(json['reply_to_message'] as Map<String, dynamic>),
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'conversation_id': instance.conversation,
  'sender_user_id': instance.sender,
  'content': instance.content,
  'message_type': _messageTypeToJson(instance.messageType),
  'reply_to_id': instance.replyTo,
  'attachments': instance.attachments,
  'read_by': instance.readBy,
  'reactions': instance.reactions,
  'is_edited': instance.isEdited,
  'edited_at': const NullableDateTimeConverter().toJson(instance.editedAtDate),
  'sender': instance.senderUser?.toJson(),
  'reply_to_message': instance.replyToMessage?.toJson(),
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_MessageRequest _$MessageRequestFromJson(Map<String, dynamic> json) =>
    _MessageRequest(
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      replyToId: json['reply_to_id'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MessageRequestToJson(_MessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'message_type': instance.messageType,
      if (instance.replyToId case final value?) 'reply_to_id': value,
      if (instance.attachments case final value?) 'attachments': value,
    };

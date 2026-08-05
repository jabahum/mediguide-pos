// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      id: json['id'] as String,
      participant1: json['participant1_user_id'] as String? ?? '',
      participant2: json['participant2_user_id'] as String? ?? '',
      lastMessage: json['last_message_id'] as String? ?? '',
      lastActivityDate: const NullableDateTimeConverter().fromJson(
        json['last_activity'],
      ),
      participant1User: json['participant1'] == null
          ? null
          : User.fromJson(json['participant1'] as Map<String, dynamic>),
      participant2User: json['participant2'] == null
          ? null
          : User.fromJson(json['participant2'] as Map<String, dynamic>),
      lastMessageData: json['last_message_data'] == null
          ? null
          : Message.fromJson(json['last_message_data'] as Map<String, dynamic>),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$ConversationToJson(
  _Conversation instance,
) => <String, dynamic>{
  'id': instance.id,
  'participant1_user_id': instance.participant1,
  'participant2_user_id': instance.participant2,
  'last_message_id': instance.lastMessage,
  'last_activity': const NullableDateTimeConverter().toJson(
    instance.lastActivityDate,
  ),
  'participant1': instance.participant1User?.toJson(),
  'participant2': instance.participant2User?.toJson(),
  'last_message_data': instance.lastMessageData?.toJson(),
  'messages': instance.messages.map((e) => e.toJson()).toList(),
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_ConversationRequest _$ConversationRequestFromJson(Map<String, dynamic> json) =>
    _ConversationRequest(
      otherParticipantId: json['other_participant_id'] as String,
    );

Map<String, dynamic> _$ConversationRequestToJson(
  _ConversationRequest instance,
) => <String, dynamic>{'other_participant_id': instance.otherParticipantId};

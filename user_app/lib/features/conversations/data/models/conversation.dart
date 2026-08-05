import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/conversations/data/models/message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
abstract class Conversation with _$Conversation {
  const Conversation._();
  @JsonSerializable(explicitToJson: true)
  const factory Conversation({
    required String id,
    @JsonKey(name: 'participant1_user_id') @Default('') String participant1,
    @JsonKey(name: 'participant2_user_id') @Default('') String participant2,
    @JsonKey(name: 'last_message_id') @Default('') String lastMessage,
    @JsonKey(name: 'last_activity')
    @NullableDateTimeConverter()
    DateTime? lastActivityDate,
    @JsonKey(name: 'participant1') User? participant1User,
    @JsonKey(name: 'participant2') User? participant2User,
    @JsonKey(name: 'last_message_data') Message? lastMessageData,
    @Default([]) List<Message> messages,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Conversation;
  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(_normalizeConversation(json));

  DateTime? get createdDate => createdAt;
  String getOtherParticipantId(String currentUserId) =>
      participant1 == currentUserId ? participant2 : participant1;
  User? getOtherParticipant(String currentUserId) =>
      participant1 == currentUserId ? participant2User : participant1User;
  String get latestMessageContent => messages.isNotEmpty
      ? (messages.toList()..sort((a, b) => b.created.compareTo(a.created)))
            .first
            .content
      : (lastMessageData?.content ?? '');
  bool hasParticipant(String userId) =>
      participant1 == userId || participant2 == userId;
  String getDisplayName(String currentUserId) {
    final other = getOtherParticipant(currentUserId);
    return other?.name.isNotEmpty == true
        ? other!.name
        : (other?.email ?? 'Unknown');
  }

  String getAvatarUrl(String currentUserId, String baseUrl) {
    final other = getOtherParticipant(currentUserId);
    final avatar = other?.avatar ?? '';
    return avatar.isEmpty
        ? ''
        : '$baseUrl/api/files/users/${other!.id}/$avatar';
  }
}

Map<String, dynamic> _normalizeConversation(Map<String, dynamic> json) {
  Map<String, dynamic>? user(String prefix) {
    final direct = json[prefix];
    if (direct is Map) return Map<String, dynamic>.from(direct);
    final id = json['${prefix}_user_id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return {
      'id': id,
      'name': json['${prefix}_name'] ?? '',
      'email': json['${prefix}_email'] ?? '',
      'avatar': json['${prefix}_avatar'] ?? '',
      'verified': json['${prefix}_verified'] ?? false,
    };
  }

  return {
    ...json,
    'participant1': user('participant1'),
    'participant2': user('participant2'),
  };
}

@freezed
abstract class ConversationRequest with _$ConversationRequest {
  const factory ConversationRequest({
    @JsonKey(name: 'other_participant_id') required String otherParticipantId,
  }) = _ConversationRequest;
  factory ConversationRequest.fromJson(Map<String, dynamic> json) =>
      _$ConversationRequestFromJson(json);
}

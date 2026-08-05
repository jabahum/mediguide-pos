import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/authentication/data/models/user.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum MessageType { text, image, file, voice }

@freezed
abstract class Message with _$Message {
  const Message._();
  @JsonSerializable(explicitToJson: true)
  const factory Message({
    required String id,
    @JsonKey(name: 'conversation_id') @Default('') String conversation,
    @JsonKey(name: 'sender_user_id') @Default('') String sender,
    @Default('') String content,
    @JsonKey(
      name: 'message_type',
      fromJson: _messageTypeFromJson,
      toJson: _messageTypeToJson,
    )
    @Default(MessageType.text)
    MessageType messageType,
    @JsonKey(name: 'reply_to_id') @Default('') String replyTo,
    @Default([]) List<String> attachments,
    @JsonKey(name: 'read_by') @Default({}) Map<String, dynamic> readBy,
    @Default({}) Map<String, dynamic> reactions,
    @JsonKey(name: 'is_edited') @Default(false) bool isEdited,
    @JsonKey(name: 'edited_at')
    @NullableDateTimeConverter()
    DateTime? editedAtDate,
    @JsonKey(name: 'sender') User? senderUser,
    @JsonKey(name: 'reply_to_message') Message? replyToMessage,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Message;
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(_normalizeMessage(json));

  DateTime get created => createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? get createdDate => createdAt;
  String get messageTypeString => messageType.name;
  bool isReadBy(String userId) => readBy.containsKey(userId);
  bool get hasReactions => reactions.isNotEmpty;
  int get reactionCount => reactions.values.fold(
    0,
    (sum, value) => sum + (value is List ? value.length : 0),
  );
  bool hasUserReacted(String userId, String emoji) =>
      reactions[emoji] is List && (reactions[emoji] as List).contains(userId);
}

Map<String, dynamic> _normalizeMessage(Map<String, dynamic> json) {
  final sender = json['sender'];
  final senderId = json['sender_user_id']?.toString() ?? '';
  return {
    ...json,
    'read_by': json['read_by'] is Map
        ? Map<String, dynamic>.from(json['read_by'] as Map)
        : <String, dynamic>{},
    'reactions': json['reactions'] is Map
        ? Map<String, dynamic>.from(json['reactions'] as Map)
        : <String, dynamic>{},
    if (sender is! Map && senderId.isNotEmpty)
      'sender': {
        'id': senderId,
        'name': json['sender_name'] ?? '',
        'email': json['sender_email'] ?? '',
        'avatar': json['sender_avatar'] ?? '',
      },
  };
}

MessageType _messageTypeFromJson(Object? value) =>
    MessageType.values.firstWhere(
      (e) => e.name == value?.toString(),
      orElse: () => MessageType.text,
    );
String _messageTypeToJson(MessageType value) => value.name;

@freezed
abstract class MessageRequest with _$MessageRequest {
  @JsonSerializable(includeIfNull: false)
  const factory MessageRequest({
    required String content,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @JsonKey(name: 'reply_to_id') String? replyToId,
    List<String>? attachments,
  }) = _MessageRequest;
  factory MessageRequest.fromJson(Map<String, dynamic> json) =>
      _$MessageRequestFromJson(json);
}

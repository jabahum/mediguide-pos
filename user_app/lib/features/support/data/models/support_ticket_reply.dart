import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'support_ticket_reply.freezed.dart';
part 'support_ticket_reply.g.dart';

@freezed
abstract class SupportReplyAuthor with _$SupportReplyAuthor {
  const factory SupportReplyAuthor({
    required String id,
    @Default('') String name,
    @Default('') String email,
  }) = _SupportReplyAuthor;

  factory SupportReplyAuthor.fromJson(Map<String, dynamic> json) =>
      _$SupportReplyAuthorFromJson(json);
}

@freezed
abstract class SupportTicketReply with _$SupportTicketReply {
  const SupportTicketReply._();

  @JsonSerializable(explicitToJson: true)
  const factory SupportTicketReply({
    required String id,
    @Default('') String message,
    @JsonKey(name: 'is_internal') @Default(false) bool isInternal,
    @JsonKey(name: 'ticket_id') @Default('') String ticketId,
    @JsonKey(name: 'user_id') @Default('') String userId,
    SupportReplyAuthor? user,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _SupportTicketReply;

  factory SupportTicketReply.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketReplyFromJson(_normalizeReply(json));

  bool get isPublic => !isInternal;
  bool get isFromSupport => isInternal;

  bool isFromUser(String currentUserId) => userId == currentUserId;

  String get timeAgo {
    final value = createdAt;
    if (value == null) return '';
    final difference = DateTime.now().difference(value);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'Just now';
  }

  String get authorName {
    final author = user;
    if (author != null) {
      if (author.name.isNotEmpty) return author.name;
      if (author.email.isNotEmpty) return author.email;
    }
    return isInternal ? 'Support Team' : 'User';
  }

  String get authorInitials {
    final name = authorName;
    if (name.length < 2) return name.toUpperCase();
    final parts = name.split(' ');
    return parts.length > 1
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, 2).toUpperCase();
  }
}

Map<String, dynamic> _normalizeReply(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  if (normalized['user'] == null &&
      normalized['user_id']?.toString().isNotEmpty == true) {
    normalized['user'] = {
      'id': normalized['user_id'],
      'name': normalized['user_name'] ?? '',
      'email': normalized['user_email'] ?? '',
    };
  }
  return normalized;
}

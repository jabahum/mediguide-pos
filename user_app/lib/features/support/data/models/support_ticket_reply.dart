// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/authentication/data/models/user.dart';

/// Support Ticket Reply model for ticket conversations
class SupportTicketReply extends BaseModel {
  SupportTicketReply(super.data);

  /// backend resource API collection name
  static const String collection = 'support_ticket_replies';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => SupportTicketReply(data));
    return true;
  })();

  /// Create SupportTicketReply from backend resource API record
  factory SupportTicketReply.fromRecord(ApiRecord record) {
    return SupportTicketReply(record.data);
  }

  // Core fields
  late final String message = get<String>("message", "");
  late final bool isInternal = get<bool>("is_internal", false);

  // Relations
  late final String ticketId = get<String>("ticket_id", "");
  late final String userId = get<String>("user_id", "");

  // Expanded relations
  User? get user => getRelation<User>("user_id");

  // Display helpers
  bool get isPublic => !isInternal;
  bool get isFromSupport =>
      isInternal; // Internal replies are from support staff

  // Check if this reply is from a specific user
  bool isFromUser(String currentUserId) {
    return userId == currentUserId;
  }

  // Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final createdAt = createdDate;
    if (createdAt == null) return '';

    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Get author display name
  String get authorName {
    final userModel = user;
    if (userModel != null) {
      return userModel.name.isNotEmpty ? userModel.name : userModel.email;
    }
    return isInternal ? 'Support Team' : 'User';
  }

  // Get author initials for avatar
  String get authorInitials {
    final name = authorName;
    if (name.length < 2) return name.toUpperCase();

    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 2).toUpperCase();
    }
  }

  @override
  String toString() {
    return 'SupportTicketReply(id: $id, ticketId: $ticketId, isInternal: $isInternal, author: $authorName)';
  }
}

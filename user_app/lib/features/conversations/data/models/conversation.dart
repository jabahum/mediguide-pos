// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/conversations/data/models/message.dart';

/// Conversation model for one-on-one chat functionality
class Conversation extends BaseModel {
  Conversation(super.data);

  /// backend resource API collection name
  static const String collection = 'conversations';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Conversation(data));
    return true;
  })();

  // Ensure registration is triggered
  static void ensureRegistration() {
    // Access _registered to trigger the initialization
    _registered;
  }

  /// Create Conversation from backend resource API record
  static Conversation fromRecord(ApiRecord record) => Conversation(record.data);

  /// Create JSON for new conversation record
  static Map<String, dynamic> forCreate({
    required String participant1,
    required String participant2,
  }) {
    return {
      'participant1': participant1,
      'participant2': participant2,
      'last_activity': DateTime.now().toIso8601String(),
    };
  }

  /// Create JSON for updating conversation
  static Map<String, dynamic> forUpdate({
    String? lastMessage,
    DateTime? lastActivity,
  }) {
    return {
      'last_message': ?lastMessage,
      if (lastActivity != null) 'last_activity': lastActivity.toIso8601String(),
    };
  }

  // Direct properties - late final for performance
  late final String participant1 = get<String>("participant1", "");
  late final String participant2 = get<String>("participant2", "");
  late final String lastMessage = get<String>("last_message", "");
  late final String lastActivity = get<String>("last_activity", "");

  // Convenience getters
  late final DateTime? lastActivityDate = _parseDateTime(lastActivity);

  // Private helper for date parsing
  DateTime? _parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  // Related models - using expand functionality
  User? get participant1User => getRelation<User>("participant1");
  User? get participant2User => getRelation<User>("participant2");
  Message? get lastMessageData => getRelation<Message>("last_message");

  /// Get the other participant's ID based on current user ID
  String getOtherParticipantId(String currentUserId) {
    return participant1 == currentUserId ? participant2 : participant1;
  }

  /// Get the other participant's user model based on current user ID
  User? getOtherParticipant(String currentUserId) {
    return participant1 == currentUserId ? participant2User : participant1User;
  }

  /// Get messages from back-relation expand (messages_via_conversation)
  List<Message> get messages =>
      getRelationList<Message>("messages_via_conversation");

  /// Get latest message content from the expanded back-relation
  String get latestMessageContent {
    final msgs = messages;
    if (msgs.isEmpty) return '';
    // Sort by created desc and return the latest content
    msgs.sort((a, b) => b.created.compareTo(a.created));
    return msgs.first.content;
  }

  /// Check if user is participant in this conversation
  bool hasParticipant(String userId) {
    return participant1 == userId || participant2 == userId;
  }

  /// Get conversation display name for the current user
  String getDisplayName(String currentUserId) {
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.name.isNotEmpty == true
        ? otherParticipant!.name
        : otherParticipant?.email ?? 'Unknown';
  }

  /// Get conversation avatar for the current user (other participant's avatar)
  String getAvatarUrl(String currentUserId, String baseUrl) {
    final otherParticipant = getOtherParticipant(currentUserId);
    if (otherParticipant?.get<String>('avatar', '').isNotEmpty == true) {
      final avatar = otherParticipant!.get<String>('avatar', '');
      return '$baseUrl/api/files/${otherParticipant.collectionName}/${otherParticipant.id}/$avatar';
    }
    return '';
  }
}
